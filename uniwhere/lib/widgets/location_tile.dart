import 'package:flutter/material.dart';

import '../models/room_location.dart';
import '../utils/constants.dart';

/// Item reutilizable para mostrar ubicaciones guardadas.
class LocationTile extends StatelessWidget {
  const LocationTile({
    super.key,
    required this.location,
    this.onTap,
    this.onLongPress,
  });

  final RoomLocation location;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryBlue.withOpacity(0.15),
          child: const Icon(Icons.place, color: primaryBlue),
        ),
        title: Text(location.name),
        subtitle: Text(location.description),
        trailing: Text(location.category),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
