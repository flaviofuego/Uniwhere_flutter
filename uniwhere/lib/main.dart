import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'providers/navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'services/backend_service.dart';
import 'screens/splash_screen.dart';

/// Punto de entrada de UNIwhere
/// Inicializa providers y lanza la aplicación
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forzar orientación vertical en pantallas de navegación AR
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cargar configuraciones guardadas antes de iniciar la app
  final settings = SettingsProvider();
  await settings.load();

  runApp(UniwhereApp(settings: settings));
}

/// Widget raíz de la aplicación
class UniwhereApp extends StatelessWidget {
  final SettingsProvider settings;

  const UniwhereApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    // Crear el BackendService con la URL guardada en settings
    final backendService = BackendService(baseUrl: settings.baseUrl);

    return MultiProvider(
      providers: [
        // Settings: accesible desde cualquier pantalla
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),

        // NavigationProvider: estado central de navegación
        ChangeNotifierProvider<NavigationProvider>(
          create: (_) => NavigationProvider(backendService: backendService),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          // Sincronizar URL del backend cuando cambia en settings
          final navProvider =
              Provider.of<NavigationProvider>(context, listen: false);
          navProvider.updateBackendUrl(settingsProvider.baseUrl);

          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,

            // ==================================================================
            // TEMA - Material Design 3 con colores universitarios
            // ==================================================================
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppConfig.primaryColor,
                primary: AppConfig.primaryColor,
                onPrimary: AppConfig.onPrimaryColor,
                surface: AppConfig.surfaceColor,
              ),

              // AppBar con el color universitario
              appBarTheme: const AppBarTheme(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),

              // Botones elevados con el color primario
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConfig.borderRadius),
                  ),
                ),
              ),

              // Cards con bordes redondeados
              cardTheme: CardThemeData(
                elevation: AppConfig.cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConfig.borderRadius),
                ),
              ),

              // Campos de texto
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),

              // Snackbars flotantes
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Pantalla inicial: SplashScreen
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
