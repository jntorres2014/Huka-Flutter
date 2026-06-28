# Migración de Huka (Juka) a Flutter — Guía y plan

Este proyecto es el **esqueleto Flutter** de tu app de pesca Huka, migrada desde
Kotlin + Jetpack Compose. Funciona en **Android e iOS** con un solo código.

Esta **Fase 1** incluye: estructura del proyecto, tema Material 3 (tu paleta
púrpura), navegación con menú lateral (las 9 pantallas), login con Google/Apple
y placeholders de cada feature listos para llenar.

---

## 1. Requisitos previos (instalar una sola vez)

1. **Flutter SDK** — https://docs.flutter.dev/get-started/install
   Verificá con: `flutter doctor`
2. **Android Studio** (ya lo tenés) con el plugin de Flutter y Dart.
3. Para **iOS**: una **Mac con Xcode** (o un servicio de build en la nube como
   Codemagic). Sin macOS no se puede compilar iOS — es limitación de Apple.

---

## 2. Generar las carpetas de plataforma (android/ ios/)

Este esqueleto trae `lib/` y `pubspec.yaml`, pero **no** las carpetas nativas.
Generalas así (no pisan tu código de `lib/`):

```bash
cd juka_flutter
flutter create . --org com.example --project-name juka_flutter
flutter pub get
```

`flutter create .` crea `android/`, `ios/`, etc. Luego `flutter pub get` baja
todas las dependencias del `pubspec.yaml`.

---

## 3. Configurar Firebase (paso obligatorio)

La app usa el mismo Firebase que tu versión Android.

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

- Elegí tu proyecto de Firebase existente.
- Seleccioná **Android** e **iOS**.

Esto **reemplaza** `lib/firebase_options.dart` (hoy es un placeholder que tira
error a propósito) y crea `google-services.json` y `GoogleService-Info.plist`
automáticamente.

> Para Google Sign-In en Android necesitás registrar la huella **SHA-1** en
> Firebase (Configuración del proyecto → tus apps). Sacala con:
> `cd android && ./gradlew signingReport`

---

## 4. Copiar tus assets

Copiá desde el proyecto Android:

- `modelo_nuevo.tflite`  →  `juka_flutter/assets/models/modelo_nuevo.tflite`
  (OBLIGATORIO para "Identificar pez" en modo offline)
- el JSON de la Pescadex (de `app/src/main/assets/`)  →  `juka_flutter/assets/`
  (ya copié `peces_argentinos.json` y `chatbot_config.json`)

Ya están declarados en `pubspec.yaml`.

### Permisos de cámara (para Identificar pez)

- **Android:** el `image_picker` no requiere permisos extra para la galería; la
  cámara se maneja sola.
- **iOS:** agregá en `ios/Runner/Info.plist`:
  `NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription` con un texto
  explicando el uso (ej: "Para identificar peces con una foto").

---

## 5. Correr la app

```bash
flutter run            # en el dispositivo/emulador conectado
```

### Clave de Gemini (para el Chat)

El Chat usa Gemini y necesita tu API key (equivale a `GEMINI_API_KEY` de
`local.properties` en Android). Pasala al correr:

```bash
flutter run --dart-define=GEMINI_API_KEY=tu_clave_aca
```

Sin la clave, el resto de la app funciona igual; solo el Chat avisa que no está
configurado.

En tu iPhone podés instalarla solo desde una Mac con Xcode (cable + confiar en
el certificado de desarrollador).

---

## Equivalencias Kotlin → Flutter (qué reemplaza a qué)

| Android (Kotlin)                     | Flutter (este proyecto)                  |
|--------------------------------------|------------------------------------------|
| Jetpack Compose (UI)                 | Widgets de Flutter (Material 3)          |
| MVVM + ViewModel                     | Riverpod (`StateNotifier` / providers)   |
| Navigation Compose                   | `go_router`                              |
| Firebase BoM + KTX                   | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `firebase_analytics` |
| play-services-auth (Google Sign-In)  | `google_sign_in` (+ `sign_in_with_apple` para iOS) |
| osmdroid (OpenStreetMap)             | `flutter_map` + `latlong2`               |
| play-services-location               | `geolocator`                             |
| Gemini (`generativeai`)              | `google_generative_ai`                   |
| LiteRT / TFLite                      | `tflite_flutter`                         |
| ML Kit (varios)                      | `google_mlkit_*` (text_recognition, language_id, translation, smart_reply, entity_extraction) |
| Room                                 | `drift` (+ `sqlite3_flutter_libs`)       |
| WorkManager                          | `workmanager` (+ `connectivity_plus`)    |
| OkHttp / Gson                        | `dio` (+ `json_serializable`)            |
| Coil                                 | `cached_network_image`                   |
| RECORD_AUDIO / RecognitionService    | `speech_to_text` + `flutter_tts`         |

---

## Plan por fases

- **Fase 1 (HECHA):** esqueleto, tema, navegación, login, placeholders.
- **Fase 2 (HECHA):** Pescadex (85 especies del JSON, búsqueda + detalle) y Perfil.
- **Fase 3 (HECHA):** Crear parte (wizard) + Reportes (Firestore + estadísticas).
- **Identificar pez (HECHO):** foto (cámara/galería) + modelo .tflite offline
  (5 clases) y, alternativamente, análisis por foto con Gemini. Resultado
  enlazado a la Pescadex.
- **Chat Huka (HECHO):** chat de texto con Gemini + accesos a enlaces (mareas,
  vedas, viento, lunar). PENDIENTE: entrada por voz, TTS y análisis con ML Kit.
- **Contador (HECHO):** conteo en vivo, backup local y "guardar como parte".
- **Logros (HECHO):** 26 logros calculados desde tus partes, con filtros y detalle.
- **Torneos (núcleo HECHO):** crear, unirse por código, ranking, aceptar/rechazar
  solicitudes. PENDIENTE: motor de puntaje personalizado y carga de partes al torneo.
- **Fase 7:** Notificaciones (FCM), sync offline (WorkManager), pulido iOS y
  "Sign in with Apple", e íconos/splash.

Para cada fase, pedime: *"migrá la Fase X"* y la implemento sobre este esqueleto.

---

## Estructura del proyecto

```
juka_flutter/
├── pubspec.yaml
├── lib/
│   ├── main.dart                 # arranque + init Firebase
│   ├── firebase_options.dart     # PLACEHOLDER (lo genera flutterfire)
│   ├── app/
│   │   ├── app.dart              # MaterialApp.router
│   │   ├── theme.dart            # tema M3 (migrado de HukaTheme.kt)
│   │   └── router.dart           # rutas + guard de sesión (go_router)
│   ├── core/widgets/
│   │   └── placeholder_screen.dart
│   └── features/
│       ├── auth/                 # login Google/Apple + providers
│       ├── home/                 # Scaffold + menú lateral (9 entradas)
│       ├── pescadex/  parte/  contador/  chat/
│       ├── reportes/  logros/  torneos/  identificar/  perfil/
└── assets/
    └── models/                   # acá va modelo_nuevo.tflite
```
