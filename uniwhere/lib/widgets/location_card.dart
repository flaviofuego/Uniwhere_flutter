import 'package:flutter/material.dart';
import '../models/room_location.dart';
import '../utils/constants.dart';

/// Widget de tarjeta para mostrar una ubicación
/// Usada en listas y búsquedas
class LocationCard extends StatelessWidget {
  final RoomLocation location;
  final VoidCallback? onTap;
  final VoidCallback? onNavigate;
  final bool showNavigateButton;

  const LocationCard({
    super.key,
    required this.location,
    this.onTap,
    this.onNavigate,
    this.showNavigateButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.defaultSpacing,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Ícono de categoría
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getCategoryColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: _getCategoryColor(),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  // Nombre y categoría
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCategoryDisplayName(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConstants.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón de navegación
                  if (showNavigateButton && onNavigate != null)
                    IconButton(
                      icon: const Icon(Icons.navigation),
                      color: AppConstants.primaryColor,
                      onPressed: onNavigate,
                      tooltip: 'Navegar aquí',
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultSpacing),
              // Descripción
              Text(
                location.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Tags
              if (location.tags.isNotEmpty) ...[
                const SizedBox(height: AppConstants.defaultSpacing),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: location.tags.take(3).map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (location.category) {
      case 'habitacion':
        return const Color(0xFFFF6B6B);
      case 'servicio':
        return const Color(0xFF4ECDC4);
      case 'recreacion':
        return AppConstants.primaryColor;
      case 'trabajo':
        return const Color(0xFFFFA07A);
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon() {
    switch (location.category) {
      case 'habitacion':
        return Icons.bed;
      case 'servicio':
        return Icons.bathroom;
      case 'recreacion':
        return Icons.weekend;
      case 'trabajo':
        return Icons.work;
      default:
        return Icons.location_on;
    }
  }

  String _getCategoryDisplayName() {
    switch (location.category) {
      case 'habitacion':
        return 'Habitación';
      case 'servicio':
        return 'Servicio';
      case 'recreacion':
        return 'Recreación';
      case 'trabajo':
        return 'Trabajo';
      default:
        return location.category;
    }
  }
}
