import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/navigation_service.dart';
import '../utils/constants.dart';
import '../widgets/location_tile.dart';
import 'map_screen.dart';
import 'navigation_screen.dart';
import 'calibration_screen.dart';

/// Pantalla inicial con accesos a los modos solicitados.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationService nav = context.watch<NavigationService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Home Navigator Demo'),
        backgroundColor: primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Selecciona un modo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _PrimaryButton(
                  label: 'Modo Calibración',
                  icon: Icons.build,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CalibrationScreen(),
                    ),
                  ),
                ),
                _PrimaryButton(
                  label: 'Modo Navegación',
                  icon: Icons.navigation_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NavigationScreen(),
                    ),
                  ),
                ),
                _PrimaryButton(
                  label: 'Ver Mapa 2D',
                  icon: Icons.map,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MapScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Ubicaciones guardadas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: nav.locations.length,
                itemBuilder: (BuildContext _, int index) {
                  final location = nav.locations[index];
                  return LocationTile(
                    location: location,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NavigationScreen(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      onPressed: onPressed,
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
