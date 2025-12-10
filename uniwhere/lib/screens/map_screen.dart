import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/navigation_service.dart';
import '../utils/constants.dart';
import '../widgets/house_map.dart';

/// Mapa 2D cenital de la casa con ruta y ubicación actual.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationService nav = context.watch<NavigationService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa 2D'),
        backgroundColor: primaryBlue,
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.vrpano),
            tooltip: 'Cambiar a vista AR',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            HouseMap(
              locations: nav.locations,
              path: nav.currentPath,
              userPosition: nav.userPosition,
            ),
            const SizedBox(height: 12),
            Text(
              'Posición actual: x=${nav.userPosition.x.toStringAsFixed(2)}, '
              'y=${nav.userPosition.y.toStringAsFixed(2)}, '
              'z=${nav.userPosition.z.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: nav.locations
                    .map(
                      (location) => ListTile(
                        leading: const Icon(Icons.room_preferences),
                        title: Text(location.name),
                        subtitle: Text(location.description),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
