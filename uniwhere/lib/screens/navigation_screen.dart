import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/room_location.dart';
import '../services/navigation_service.dart';
import '../services/vps_service.dart';
import '../utils/constants.dart';
import '../widgets/ar_info_card_widget.dart';
import '../widgets/ar_route_overlay.dart';
import '../widgets/debug_panel.dart';

/// Pantalla de navegación AR simplificada con flechas y línea de ruta.
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  RoomLocation? _selected;

  @override
  Widget build(BuildContext context) {
    final NavigationService nav = context.watch<NavigationService>();
    final VpsService vps = context.watch<VpsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Navegación'),
        backgroundColor: primaryBlue,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<RoomLocation>(
                    value: _selected,
                    decoration: const InputDecoration(
                      labelText: '¿A dónde quieres ir?',
                      prefixIcon: Icon(Icons.search),
                    ),
                    items: nav.locations
                        .map(
                          (RoomLocation loc) => DropdownMenuItem<RoomLocation>(
                            value: loc,
                            child: Text(loc.name),
                          ),
                        )
                        .toList(),
                    onChanged: (RoomLocation? value) {
                      setState(() => _selected = value);
                      if (value != null) {
                        nav.startNavigation(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Simular match VPS',
                  onPressed: _selected == null
                      ? null
                      : () {
                          if (_selected != null) {
                            vps.simulateReferenceDetection(_selected!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Posición actualizada (VPS simulado)')),
                            );
                          }
                        },
                  icon: const Icon(Icons.center_focus_strong),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: <Widget>[
                GestureDetector(
                  onLongPress: () => _openInfoCard(context),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Vista AR con flechas 3D y línea de ruta',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                if (nav.destination != null)
                  Positioned.fill(
                    child: ArRouteOverlay(
                      path: nav.currentPath,
                      arrowColor: nav.arrowColor,
                      recalibrating: nav.recalibrating,
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: DebugPanel(
                    navigationService: nav,
                    detectedPlanes: 3,
                    fps: 30,
                    trackingState: nav.recalibrating ? 'Recalibrando' : 'Tracking estable',
                  ),
                ),
              ],
            ),
          ),
          _BottomStatus(nav: nav),
        ],
      ),
    );
  }

  /// Muestra la ficha AR cuando el usuario mantiene la vista fija.
  Future<void> _openInfoCard(BuildContext context) async {
    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: ArInfoCardWidget(card: genericInfoCard),
      ),
    );
  }
}

class _BottomStatus extends StatelessWidget {
  const _BottomStatus({required this.nav});
  final NavigationService nav;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  nav.destination?.name ?? 'Sin destino',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Distancia: ${nav.distanceToDestination.toStringAsFixed(2)} m'),
                Text('Tiempo estimado: ${nav.currentPath?.estimatedTimeSeconds ?? 0} s'),
                if (nav.recalibrating) const Text('Recalibrando posición...', style: TextStyle(color: Colors.orange)),
                if (nav.hasArrived) const Text('Has llegado', style: TextStyle(color: Colors.green)),
              ],
            ),
          ),
          Column(
            children: <Widget>[
              ElevatedButton(
                onPressed: nav.destination == null ? null : nav.stopNavigation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Detener'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
