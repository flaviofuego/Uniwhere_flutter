import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'screens/home_screen.dart';
import 'services/navigation_service.dart';
import 'services/vps_service.dart';
import 'utils/constants.dart';

/// Punto de entrada de la demo AR + VPS.
/// Aquí se inyectan los servicios de navegación y posicionamiento simulado.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<NavigationService>(
          create: (_) => NavigationService(),
        ),
        ChangeNotifierProvider<VpsService>(
          create: (BuildContext context) => VpsService(
            context.read<NavigationService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'AR Home Navigator Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F9FC),
          fontFamily: 'Roboto',
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
