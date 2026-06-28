import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import 'chat_providers.dart';

/// Accesos rápidos del menú (equivalente a las opciones EXTERNAL_LINK del
/// chatbot_config.json).
const _enlaces = <(String, String)>[
  ('🌊 Mareas', 'https://www.hidro.gov.ar/oceanografia/tmareas/form_tmareas.asp'),
  ('🚫 Vedas', 'https://www.argentina.gob.ar/inidep/areas-de-veda'),
  ('💨 Viento', 'https://www.windguru.cz/53'),
  ('🌙 Calendario lunar', 'https://www.pescaargentina.com.ar/fases-lunares/'),
];

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  // Voz (entrada) y lectura (salida).
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _escuchando = false;
  bool _leerVoz = false;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('es-ES');
    _tts.setSpeechRate(0.5);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_escuchando) {
      await _speech.stop();
      setState(() => _escuchando = false);
      return;
    }
    final disponible = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _escuchando = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _escuchando = false);
      },
    );
    if (!disponible) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se pudo acceder al micrófono.')));
      }
      return;
    }
    setState(() => _escuchando = true);
    _speech.listen(
      onResult: (r) => setState(() => _ctrl.text = r.recognizedWords),
      listenOptions: stt.SpeechListenOptions(localeId: 'es_AR'),
    );
  }

  void _enviar() {
    final texto = _ctrl.text;
    if (texto.trim().isEmpty) return;
    _ctrl.clear();
    ref.read(chatProvider.notifier).enviar(texto);
    _scrollAbajo();
  }

  void _scrollAbajo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _abrir(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mensajes = ref.watch(chatProvider);
    final escribiendo = ref.watch(chatProvider.notifier).escribiendo;
    _scrollAbajo();

    // Lee en voz alta la última respuesta de Huka si está activado.
    ref.listen(chatProvider, (prev, next) {
      if (!_leerVoz || next.isEmpty || next.last.esUsuario) return;
      if (next.length > (prev?.length ?? 0)) {
        _tts.speak(next.last.texto);
      }
    });

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: _leerVoz ? 'Lectura activada' : 'Leer respuestas',
              icon: Icon(_leerVoz ? Icons.volume_up : Icons.volume_off),
              color: _leerVoz ? Theme.of(context).colorScheme.primary : null,
              onPressed: () {
                setState(() => _leerVoz = !_leerVoz);
                if (!_leerVoz) _tts.stop();
              },
            ),
            Expanded(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: _enlaces
                      .map((e) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: ActionChip(
                              label: Text(e.$1),
                              onPressed: () => _abrir(e.$2),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: mensajes.length + (escribiendo ? 1 : 0),
            itemBuilder: (context, i) {
              if (escribiendo && i == mensajes.length) {
                return const _Burbuja(
                  texto: 'Huka está escribiendo…',
                  esUsuario: false,
                  atenuado: true,
                );
              }
              final m = mensajes[i];
              return _Burbuja(texto: m.texto, esUsuario: m.esUsuario);
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _enviar(),
                    decoration: InputDecoration(
                      hintText: 'Escribí tu consulta...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: _escuchando ? 'Detener' : 'Hablar',
                  onPressed: _toggleMic,
                  icon: Icon(_escuchando ? Icons.mic : Icons.mic_none),
                  color: _escuchando ? Colors.red : null,
                ),
                IconButton.filled(
                  onPressed: escribiendo ? null : _enviar,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({
    required this.texto,
    required this.esUsuario,
    this.atenuado = false,
  });
  final String texto;
  final bool esUsuario;
  final bool atenuado;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = esUsuario ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = esUsuario ? scheme.onPrimary : scheme.onSurface;
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: fg,
            fontStyle: atenuado ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}
