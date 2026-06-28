import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Servicio de chat con Gemini (equivalente a GeminiPescaService.kt).
///
/// La API key se inyecta en tiempo de compilación con:
///   flutter run --dart-define=GEMINI_API_KEY=tu_clave
/// (equivale al BuildConfig.GEMINI_API_KEY de local.properties en Android).
class GeminiService {
  GeminiService() {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    _disponible = apiKey.isNotEmpty;
    if (_disponible) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: apiKey,
        systemInstruction: Content.system(_systemPrompt),
        generationConfig: GenerationConfig(temperature: 0.7),
      );
      _chat = _model.startChat();
    }
  }

  late final GenerativeModel _model;
  ChatSession? _chat;
  bool _disponible = false;

  bool get disponible => _disponible;

  Future<String> enviar(String pregunta) async {
    if (!_disponible) {
      return 'El asistente no está configurado. Falta la GEMINI_API_KEY '
          '(ver README_MIGRACION.md).';
    }
    try {
      final res = await _chat!.sendMessage(Content.text(pregunta));
      return res.text?.trim() ??
          'No pude generar una respuesta en este momento.';
    } catch (e) {
      return 'Hubo un error al consultar a Huka: $e';
    }
  }

  /// Identifica un pez a partir de una foto (equivalente a identifyWithGemini).
  Future<String> identificarPorFoto(String imagePath) async {
    if (!_disponible) {
      return 'El asistente no está configurado. Falta la GEMINI_API_KEY '
          '(ver README_MIGRACION.md).';
    }
    try {
      final Uint8List bytes = await File(imagePath).readAsBytes();
      final res = await _model.generateContent([
        Content.multi([
          TextPart(_promptIdentificacion),
          DataPart('image/jpeg', bytes),
        ])
      ]);
      return res.text?.trim() ?? 'No pude identificar el pez en esta foto.';
    } catch (e) {
      return 'Hubo un error al identificar la foto: $e';
    }
  }

  static const _promptIdentificacion = '''
Actuá como guía de pesca experto y biólogo. Analizá la foto de este pez y dame
un reporte útil para un pescador deportivo, con emojis y en estos 4 puntos:

1. 🆔 Identificación: nombre común y nombre científico.
2. 🎣 Técnica de pesca: mejor carnada o señuelo, y dónde buscarlo.
3. 🍽️ Cocina: ¿buena carne?, ¿muchas espinas?, ¿frito, parrilla o chupín?
4. ⚠️ Cuidados: manipulación, devolución y normativa si aplica.

Si no es un pez o no se distingue, decilo con humor y pedí otra foto.''';

  /// System prompt migrado 1:1 de GeminiPescaService.kt.
  static const _systemPrompt = '''
Sos un guía experto en pesca deportiva argentina. Respondés a pescadores que ya
conocen el oficio y buscan información práctica y concreta.

ESTILO:
- Conciso. Datos primero, contexto después.
- No empieces respuestas con "Qué buena idea", "Excelente pregunta", "Genial",
  "Qué interesante" ni con ningún elogio genérico.
- No uses signos de exclamación salvo casos puntuales (avisos de seguridad o
  algún chiste).
- Tratá al usuario como alguien que ya sabe lo básico — no expliques de cero
  salvo que te pregunten algo elemental.
- Recomendaciones cortas y específicas, sin relleno motivacional.
- Voseo argentino natural ("vos", "sabés", "podés").

CONTENIDO QUE DOMINÁS:
- Especies argentinas (dorado, surubí, pejerrey, tararira, boga, pacú, sábalo,
  trucha arcoíris, etc.)
- Técnicas y equipos según la especie y zona
- Mejores horarios, estaciones y condiciones climáticas
- Lugares de pesca populares en Argentina
- Regulaciones de pesca deportiva vigentes
- Si el usuario menciona una ubicación, adaptá los consejos a esa zona.

PREGUNTAS QUE NO SON DE PESCA:
Si el usuario te pregunta algo que no tiene nada que ver con la pesca
(matemática, fútbol, cocina, política, etc.), respondé con humor — un chiste
corto, una ironía amable o una vuelta cómica para traerlo al tema de la pesca.
Nunca seas grosero ni cortante. La idea es mantener la conversación liviana y
reencauzar.
''';
}
