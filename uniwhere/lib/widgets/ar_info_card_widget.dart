import 'package:flutter/material.dart';

import '../models/ar_info_card.dart';
import '../utils/constants.dart';

/// Panel flotante usado cuando el usuario mantiene el punto en foco.
class ArInfoCardWidget extends StatelessWidget {
  const ArInfoCardWidget({super.key, required this.card});

  final ARInfoCard card;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  card.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkGrey,
                  ),
                ),
                const Icon(Icons.info_outline, color: primaryBlue),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: card.imageUrl.startsWith('http')
                  ? Image.network(
                      card.imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? progress) {
                        if (progress == null) return child;
                        final double? percent =
                            progress.expectedTotalBytes != null && progress.expectedTotalBytes != 0
                                ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
                                : null;
                        return SizedBox(
                          height: 120,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: percent,
                              color: primaryBlue,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/room_placeholder.png',
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      card.imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 12),
            Text(card.content),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: card.features
                  .map(
                    (String feature) => Chip(
                      label: Text(feature),
                      backgroundColor: primaryBlue.withOpacity(0.1),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop('navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Navegar aquí'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop('close'),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
