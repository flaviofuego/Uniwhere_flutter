import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Panel de navegación que muestra distancia, tiempo y destino
/// Se muestra en la parte inferior durante la navegación AR
class NavigationPanel extends StatelessWidget {
  final String destinationName;
  final double distance;
  final int estimatedTimeSeconds;
  final VoidCallback? onStop;
  final bool isOffRoute;

  const NavigationPanel({
    super.key,
    required this.destinationName,
    required this.distance,
    required this.estimatedTimeSeconds,
    this.onStop,
    this.isOffRoute = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.cardBorderRadius * 2),
          topRight: Radius.circular(AppConstants.cardBorderRadius * 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de arrastre
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Alerta si está fuera de ruta
            if (isOffRoute)
              Container(
                margin: const EdgeInsets.only(bottom: AppConstants.defaultSpacing),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: AppConstants.defaultSpacing,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppConstants.warningColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppConstants.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Te has desviado de la ruta',
                        style: TextStyle(
                          color: AppConstants.warningColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Destino
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppConstants.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: AppConstants.defaultSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Navegando hacia',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.textSecondaryColor,
                        ),
                      ),
                      Text(
                        destinationName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Botón de detener
                if (onStop != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onStop,
                    tooltip: 'Detener navegación',
                  ),
              ],
            ),
            
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Distancia y tiempo
            Row(
              children: [
                // Distancia
                Expanded(
                  child: _InfoBox(
                    icon: Icons.straighten,
                    label: 'Distancia',
                    value: AppConstants.formatDistance(distance),
                    color: AppConstants.getArrowColorByDistance(distance),
                  ),
                ),
                const SizedBox(width: AppConstants.defaultSpacing),
                // Tiempo
                Expanded(
                  child: _InfoBox(
                    icon: Icons.access_time,
                    label: 'Tiempo',
                    value: AppConstants.formatTime(estimatedTimeSeconds),
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget auxiliar para mostrar información en caja
class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppConstants.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
