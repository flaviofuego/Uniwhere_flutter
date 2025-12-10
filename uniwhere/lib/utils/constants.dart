import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../models/ar_info_card.dart';
import '../models/room_location.dart';

/// Colores de marca definidos en el enunciado.
const Color primaryBlue = Color(0xFF2196F3);
const Color darkGrey = Color(0xFF2C2C2C);

/// Límite máximo de ubicaciones permitidas en la demo.
const int maxLocations = 20;

/// Listado de categorías predefinidas para el formulario de calibración.
const List<String> roomCategories = <String>[
  'habitacion',
  'servicio',
  'recreacion',
  'trabajo',
];

/// Datos precargados para poder navegar sin calibrar primero.
final List<RoomLocation> demoLocations = <RoomLocation>[
  RoomLocation(
    id: 'sala',
    name: 'Sala',
    description: 'Punto de inicio y sala principal.',
    position: Vector3(0, 0, 0),
    category: 'recreacion',
    iconPath: 'assets/icons/placeholder.png',
    tags: const ['reuniones'],
    imageReference: 'sala_ref',
  ),
  RoomLocation(
    id: 'cocina',
    name: 'Cocina',
    description: 'Área de comida con electrodomésticos.',
    position: Vector3(3, 0, -2),
    category: 'servicio',
    iconPath: 'assets/icons/placeholder.png',
    tags: const ['comida', 'servicio'],
    imageReference: 'cocina_ref',
  ),
  RoomLocation(
    id: 'bano',
    name: 'Baño',
    description: 'Baño de visitas.',
    position: Vector3(-2, 0, 3),
    category: 'servicio',
    iconPath: 'assets/icons/placeholder.png',
    tags: const ['higiene'],
    imageReference: 'bano_ref',
  ),
  RoomLocation(
    id: 'master',
    name: 'Cuarto Principal',
    description: 'Dormitorio principal de la casa.',
    position: Vector3(4, 0, 4),
    category: 'habitacion',
    iconPath: 'assets/icons/placeholder.png',
    tags: const ['descanso'],
    imageReference: 'master_ref',
  ),
  RoomLocation(
    id: 'estudio',
    name: 'Estudio',
    description: 'Espacio de trabajo y lectura.',
    position: Vector3(-3, 0, -3),
    category: 'trabajo',
    iconPath: 'assets/icons/placeholder.png',
    tags: const ['trabajo'],
    imageReference: 'estudio_ref',
  ),
];

/// Ficha genérica usada cuando el usuario enfoca un punto de interés.
final ARInfoCard genericInfoCard = ARInfoCard(
  title: 'Punto de interés',
  content:
      'Ejemplo de panel AR. Aquí puedes mostrar datos curiosos o indicaciones para extenderlo a un campus universitario.',
  imageUrl: 'https://via.placeholder.com/300x180',
  features: const <String>[
    'Capacidad: 4 personas',
    'Horario: 24/7',
    'Conectividad WiFi',
  ],
);
