import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Pantalla de login (equivalente a ui/auth/LoginScreen.kt).
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(authControllerProvider);
    final isLoading = controller.isLoading;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎣', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text('Huka', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Tu compañero de pesca inteligente',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Tarjeta de error (persistente, como en la app original).
              if (controller.hasError && !isLoading)
                Card(
                  color: scheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline,
                            color: scheme.onErrorContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('No se pudo iniciar sesión',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: scheme.onErrorContainer)),
                              const SizedBox(height: 4),
                              Text(
                                _mensajeError(controller.error),
                                style:
                                    TextStyle(color: scheme.onErrorContainer),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Botón de Google con estado de carga.
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle(),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(
                      isLoading ? 'Iniciando...' : 'Continuar con Google'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Traduce errores técnicos comunes a un mensaje claro.
  String _mensajeError(Object? error) {
    final s = error?.toString() ?? '';
    if (s.contains('network') || s.contains('Network')) {
      return 'Revisá tu conexión a internet e intentá de nuevo.';
    }
    if (s.contains('canceled') || s.contains('cancel')) {
      return 'Cancelaste el inicio de sesión.';
    }
    // ApiException: 10 = SHA-1 / configuración de Google mal cargada.
    if (s.contains('10') && s.contains('ApiException')) {
      return 'Hay un problema de configuración con Google. '
          'Verificá la huella SHA-1 en Firebase.';
    }
    return 'Ocurrió un error. Intentá de nuevo en un momento.';
  }
}
