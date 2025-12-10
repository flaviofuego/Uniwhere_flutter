# Assets Directory

Esta carpeta contiene los recursos visuales de la aplicación.

## Estructura

```
assets/
├── icons/       # Íconos de categorías y UI
├── images/      # Imágenes de referencia para VPS
└── models/      # Modelos 3D (flechas, marcadores)
```

## Íconos Requeridos

Para una implementación completa, se necesitan los siguientes íconos:

### Categorías de Ubicaciones
- `bedroom.png` - Ícono de habitación (256x256)
- `kitchen.png` - Ícono de cocina (256x256)
- `bathroom.png` - Ícono de baño (256x256)
- `living_room.png` - Ícono de sala (256x256)
- `study.png` - Ícono de estudio/trabajo (256x256)
- `service.png` - Ícono genérico de servicio (256x256)
- `recreation.png` - Ícono de recreación (256x256)
- `work.png` - Ícono de trabajo (256x256)

### UI
- `app_icon.png` - Ícono de la aplicación (1024x1024)

## Modelos 3D

Para AR real, se necesitan modelos 3D simples:

- `arrow.obj` / `arrow.gltf` - Modelo de flecha direccional
- `marker.obj` / `marker.gltf` - Modelo de marcador de ubicación

## Notas

- Todos los íconos deben ser PNG con fondo transparente
- Los modelos 3D deben ser optimizados para mobile (<10KB cada uno)
- Las imágenes se pueden generar con herramientas como:
  - Canva (para íconos)
  - Blender (para modelos 3D)
  - Material Icons (Google)

## Licencias

Asegúrate de usar recursos con licencia apropiada o crear tus propios assets.
