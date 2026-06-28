import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Formatos de fecha en español (para DateFormat con locale 'es').
  await initializeDateFormatting('es');

  // Inicializa Firebase (equivalente a la inicialización en HukaApplication.kt).
  // Genera firebase_options.dart con:  flutterfire configure
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ProviderScope = raíz de Riverpod. Todos los ViewModels/estados viven aquí.
  runApp(const ProviderScope(child: JukaApp()));
}
