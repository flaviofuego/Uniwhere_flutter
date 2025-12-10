import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math_64.dart';

import '../models/room_location.dart';
import '../services/navigation_service.dart';
import '../utils/constants.dart';
import '../widgets/location_tile.dart';

/// Pantalla de calibración donde el usuario marca puntos de interés.
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  @override
  Widget build(BuildContext context) {
    final NavigationService nav = context.watch<NavigationService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Calibración'),
        backgroundColor: primaryBlue,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddLocationSheet(context, nav),
        label: const Text('Marcar punto actual'),
        icon: const Icon(Icons.add_location_alt),
        backgroundColor: primaryBlue,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                Text(
                  'Camina por la casa y marca puntos de interés',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text('El origen (0,0,0) es el primer punto que guardes.'),
              ],
            ),
          ),
          // Placeholder de vista AR; en producción se conecta con ar_flutter_plugin.
          Container(
            height: 220,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Vista AR (detectar planos y tomar referencias)',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Puntos guardados',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check),
                  label: const Text('Finalizar calibración'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: nav.locations.length,
              itemBuilder: (BuildContext _, int index) {
                return LocationTile(location: nav.locations[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Despliega un formulario simple para crear nuevas ubicaciones.
  Future<void> _openAddLocationSheet(
    BuildContext context,
    NavigationService nav,
  ) async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();
    final TextEditingController refCtrl = TextEditingController();
    String category = roomCategories.first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Nuevo punto de interés',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre de la ubicación'),
              ),
              DropdownButtonFormField<String>(
                value: category,
                items: roomCategories
                    .map((String c) => DropdownMenuItem<String>(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (String? value) => category = value ?? category,
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de imagen de referencia (VPS)',
                  suffixIcon: Icon(Icons.photo_camera_outlined),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final RoomLocation newLocation = RoomLocation(
                    id: const Uuid().v4(),
                    name: nameCtrl.text.isEmpty ? 'Punto ${nav.locations.length + 1}' : nameCtrl.text,
                    description: descCtrl.text.isEmpty ? 'Punto creado durante la calibración' : descCtrl.text,
                    position: nav.locations.isEmpty
                        ? Vector3.zero()
                        : nav.userPosition + Vector3(0.5 * nav.locations.length, 0, 0.3 * nav.locations.length),
                    category: category,
                    iconPath: 'assets/icons/placeholder.png',
                    tags: const <String>['custom'],
                    imageReference: refCtrl.text.isEmpty ? null : refCtrl.text,
                  );
                  nav.addLocation(newLocation);
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Guardar'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
