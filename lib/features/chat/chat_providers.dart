import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gemini_service.dart';

/// Un mensaje del chat (equivalente al ChatMessage del proyecto Kotlin).
class ChatMessage {
  final String texto;
  final bool esUsuario;
  final DateTime hora;

  ChatMessage({required this.texto, required this.esUsuario, DateTime? hora})
      : hora = hora ?? DateTime.now();
}

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

/// Estado del chat: historial de mensajes + envío a Gemini.
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier(this._gemini) : super([_bienvenida]);
  final GeminiService _gemini;

  static final _bienvenida = ChatMessage(
    texto: '¡Hola pescador! 🎣 Soy Huka. Preguntame sobre técnicas, carnadas, '
        'especies o el mejor momento para salir.',
    esUsuario: false,
  );

  bool _escribiendo = false;
  bool get escribiendo => _escribiendo;

  Future<void> enviar(String texto) async {
    final msg = texto.trim();
    if (msg.isEmpty || _escribiendo) return;

    state = [...state, ChatMessage(texto: msg, esUsuario: true)];
    _escribiendo = true;
    // Notifica el cambio de "escribiendo" forzando un rebuild.
    state = [...state];

    final respuesta = await _gemini.enviar(msg);

    _escribiendo = false;
    state = [...state, ChatMessage(texto: respuesta, esUsuario: false)];
  }

  void limpiar() {
    state = [_bienvenida];
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref.watch(geminiServiceProvider));
});
