import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/room_location.dart';
import 'services/ar_service.dart';
import 'services/navigation_service.dart';
import 'services/storage_service.dart';
import 'services/vps_service.dart';
import 'services/permissions_service.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

/// Punto de entrada principal de la aplicación
/// AR Home Navigator Demo - Prototipo de navegación indoor con AR + VPS
void main() async {
  // Asegurar que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientación portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Inicializar Hive y registrar adaptadores ANTES de cualquier uso
  await Hive.initFlutter();
  
  // Registrar adaptador siempre (verificar con debug)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(RoomLocationAdapter());
    debugPrint('✅ RoomLocationAdapter registrado correctamente');
  } else {
    debugPrint('ℹ️ RoomLocationAdapter ya estaba registrado');
  }
  
  // Inicializar servicios
  final storageService = StorageService();
  await storageService.initialize();
  
  runApp(MyApp(storageService: storageService));
}

/// Widget raíz de la aplicación
class MyApp extends StatelessWidget {
  final StorageService storageService;

  const MyApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    // Usar MultiProvider para inyección de dependencias
    return MultiProvider(
      providers: [
        // Servicios singleton
        Provider<StorageService>.value(value: storageService),
        Provider<PermissionsService>(create: (_) => PermissionsService()),
        Provider<ARService>(create: (_) => ARService()),
        Provider<NavigationService>(create: (_) => NavigationService()),
        Provider<VPSService>(create: (_) => VPSService()),
      ],
      child: MaterialApp(
        title: 'AR Home Navigator',
        debugShowCheckedModeBanner: false,
        
        // Tema de la aplicación
        theme: ThemeData(
          // Colores principales
          primaryColor: AppConstants.primaryColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppConstants.primaryColor,
            primary: AppConstants.primaryColor,
            secondary: AppConstants.secondaryColor,
          ),
          
          // Tipografía
          fontFamily: 'Roboto',
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimaryColor,
            ),
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimaryColor,
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimaryColor,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              color: AppConstants.textPrimaryColor,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              color: AppConstants.textPrimaryColor,
            ),
          ),
          
          // Estilo de botones
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.buttonBorderRadius,
                ),
              ),
            ),
          ),
          
          // Estilo de tarjetas
          cardTheme: CardThemeData(
            elevation: AppConstants.cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.cardBorderRadius,
              ),
            ),
          ),
          
          // AppBar
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
          ),
          
          // Snackbar
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          // Input fields
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        
        // Pantalla inicial
        home: const HomeScreen(),
      ),
    );
  }
}
