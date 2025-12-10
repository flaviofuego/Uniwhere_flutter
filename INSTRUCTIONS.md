# Guía Rápida de Uso - AR Wayfinding

## 📱 Pasos para Probar la Aplicación

### 1. Primera Configuración

Cuando abras la aplicación por primera vez:

1. Se te pedirán permisos de **Cámara** y **Ubicación**
2. **Acepta ambos permisos** (son necesarios para el funcionamiento)
3. Si no aparece el diálogo de permisos, ve a Configuración > Aplicaciones > AR Wayfinding > Permisos

### 2. Pantalla Principal

En la pantalla principal verás:

- **Tarjeta de bienvenida** con instrucciones
- **Lista de destinos disponibles**:
  - 🍳 Cocina
  - 🪑 Sala de Estar
  - 🛏️ Dormitorio
  - 🚿 Baño
  - 🚪 Entrada

### 3. Iniciar Navegación

1. **Toca un destino** de la lista (se resaltará en azul)
2. **Presiona el botón "Iniciar Navegación AR"**
3. La vista de cámara se abrirá automáticamente

### 4. Usar la Vista AR

En la vista de navegación AR verás:

#### Elementos en Pantalla:

1. **Vista de Cámara**: Fondo en tiempo real
2. **Marcador del Destino** (parte superior):
   - Icono del lugar
   - Nombre del destino
   - Distancia en metros
   - Solo aparece si el destino está en tu campo de visión

3. **Flecha de Navegación** (centro-inferior):
   - Apunta hacia el destino
   - Rota según tu orientación
   - Color azul con borde blanco

4. **Panel de Información** (parte inferior):
   - 📍 Nombre del destino
   - 📏 Distancia actual
   - 🧭 Ángulo de dirección
   - Instrucción de navegación en texto

### 5. Cómo Navegar

1. **Sostén el teléfono verticalmente** frente a ti
2. **Rota tu cuerpo** lentamente hasta que la flecha apunte hacia adelante
3. **Camina en esa dirección**
4. La aplicación actualizará:
   - La distancia conforme te acerques
   - El ángulo mientras te mueves
   - Las instrucciones de navegación

#### Instrucciones que verás:

- "Continúa recto" → Sigue adelante
- "Gira ligeramente a la derecha/izquierda" → Pequeño ajuste
- "Gira a la derecha/izquierda" → Giro de 90°
- "Gira fuertemente" → Giro amplio
- "Da la vuelta" → Gira 180°

## 🏠 Configuración para Pruebas en Casa

### Método Rápido (Sin Modificar Código)

1. **Ubícate en el centro de tu casa/habitación**
2. **Imagina que estás en el punto (0,0)**
3. **Selecciona cualquier destino** y camina
4. La aplicación te mostrará la dirección relativa

### Método Avanzado (Personalizar Coordenadas)

Si quieres coordenadas precisas para tu espacio:

1. **Mide tu espacio**:
   - Usa una cinta métrica
   - Anota las distancias entre habitaciones

2. **Edita el archivo** `lib/models/waypoint_data.dart`

3. **Ajusta las coordenadas**:
```dart
Waypoint(
  id: '1',
  name: 'Cocina',
  latitude: 0.0,    // Distancia Este-Oeste en metros
  longitude: 5.0,   // Distancia Norte-Sur en metros
  altitude: 0.0,    // Altura (para multi-piso)
),
```

4. **Sistema de coordenadas**:
   - Centro de tu casa = (0, 0)
   - `latitude`: positivo = este, negativo = oeste
   - `longitude`: positivo = norte, negativo = sur
   - `altitude`: altura en metros (para escaleras/pisos)

### Ejemplo de Mapeo:

```
        Norte (longitude +)
            ↑
    Cocina (0, 5)
            |
Sala (-3,0) • Centro (0,0) → Este (latitude +)
            |
         Baño (5, 0)
            |
         Entrada (0, -5)
```

## 🎯 Tips para Mejor Precisión

### Hardware:

1. **Usa en dispositivo físico** (no emulador)
2. **Dispositivo con buenos sensores** (mejor con giroscopio)
3. **Área bien iluminada** para mejor tracking de cámara

### Calibración:

1. **Calibra la brújula**:
   - Antes de usar, mueve el teléfono haciendo un "8" en el aire
   - Esto mejora la precisión del magnetómetro

2. **Evita interferencias**:
   - Aléjate de objetos metálicos grandes
   - No uses cerca de electrodomésticos
   - Los imanes pueden afectar la brújula

3. **Posición del dispositivo**:
   - Sostenlo verticalmente
   - Mantén una posición estable
   - No lo muevas bruscamente

## 🐛 Problemas Comunes

### "No se encontró ninguna cámara"

**Solución**:
- Verifica que diste permiso de cámara
- Reinicia la aplicación
- Verifica en configuración del sistema

### "Los sensores no responden"

**Solución**:
- Calibra la brújula (movimiento en 8)
- Reinicia el dispositivo
- Algunos dispositivos tienen sensores de baja calidad

### "La navegación no es precisa"

**Solución**:
- Ajusta las coordenadas manualmente
- Calibra los sensores
- Prueba en un área más amplia
- Este es un sistema de demostración, no GPS real

### "La flecha apunta en dirección incorrecta"

**Solución**:
- Calibra la brújula
- Aléjate de objetos metálicos
- Verifica que el magnetómetro funcione
- Prueba reiniciando la aplicación

## 📊 Limitaciones Actuales

Esta es una **versión de demostración** con las siguientes limitaciones:

1. **Coordenadas relativas**: No usa GPS real, usa un sistema de coordenadas simple
2. **Sin mapas**: No hay visualización de mapas o planos
3. **Precisión limitada**: Depende de los sensores del dispositivo
4. **Un solo piso**: No hay soporte real para múltiples niveles
5. **Sin obstáculos**: No detecta paredes u objetos

Para un sistema de producción, considera:
- Integración con GPS/GNSS
- Mapas de interiores
- Beacons Bluetooth
- Sistemas VPS (Visual Positioning System)

## 🎓 Aprendiendo del Código

### Archivos Clave:

- **`main.dart`**: Punto de entrada, manejo de permisos
- **`home_screen.dart`**: Selección de destinos
- **`ar_view_screen.dart`**: Lógica de navegación y sensores
- **`ar_overlay.dart`**: Visualización AR (flecha y marcadores)
- **`waypoint.dart`**: Modelo de datos
- **`waypoint_data.dart`**: Datos de ejemplo (modifica aquí)

### Conceptos Utilizados:

- **Cámara API**: Acceso a cámara en tiempo real
- **Sensores**: Magnetómetro, acelerómetro
- **CustomPainter**: Dibujo de gráficos AR
- **Trigonometría**: Cálculo de ángulos y distancias
- **Permisos**: Sistema de permisos Android/iOS

## 📞 ¿Necesitas Ayuda?

Si tienes problemas:

1. Lee las secciones de "Problemas Comunes"
2. Verifica los logs de la aplicación
3. Abre un issue en GitHub con:
   - Descripción del problema
   - Modelo de dispositivo
   - Capturas de pantalla
   - Logs si es posible

---

**¡Disfruta probando tu sistema de navegación AR!** 🚀
