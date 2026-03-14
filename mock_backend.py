"""
UNIwhere Mock Backend
=====================
Servidor FastAPI de simulación que imita exactamente el comportamiento del
backend real de localización indoor con COLMAP + SuperPoint + SuperGlue.

Simula un edificio universitario de un piso con pasillos y aulas típicas.
"""

import asyncio
import math
import random
import time
from typing import Optional

import networkx as nx
import numpy as np
import uvicorn
from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# =============================================================================
# MAPA DEL EDIFICIO - Grafo de navegación
# Coordenadas en metros, sistema de referencia COLMAP (Y hacia arriba)
# =============================================================================

NODES: dict[str, dict] = {
    "entrada_principal": {"x": 0.0,  "y": 0.0, "z": 0.0,  "label": "Entrada Principal"},
    "pasillo_a1":        {"x": 5.0,  "y": 0.0, "z": 0.0,  "label": "Pasillo A"},
    "pasillo_a2":        {"x": 10.0, "y": 0.0, "z": 0.0,  "label": "Pasillo A - Mitad"},
    "interseccion_1":    {"x": 15.0, "y": 0.0, "z": 0.0,  "label": "Intersección Principal"},
    "salon_101":         {"x": 15.0, "y": 0.0, "z": 5.0,  "label": "Salón 101"},
    "salon_102":         {"x": 15.0, "y": 0.0, "z": 10.0, "label": "Salón 102"},
    "salon_103":         {"x": 10.0, "y": 0.0, "z": 10.0, "label": "Salón 103"},
    "banos":             {"x": 20.0, "y": 0.0, "z": 0.0,  "label": "Baños"},
    "escaleras":         {"x": 25.0, "y": 0.0, "z": 0.0,  "label": "Escaleras"},
    "sala_espera":       {"x": 20.0, "y": 0.0, "z": 5.0,  "label": "Sala de Espera"},
    "biblioteca":        {"x": 25.0, "y": 0.0, "z": 5.0,  "label": "Biblioteca"},
    "cafeteria":         {"x": 25.0, "y": 0.0, "z": 10.0, "label": "Cafetería"},
}

EDGES: list[tuple[str, str, float]] = [
    ("entrada_principal", "pasillo_a1",     5.0),
    ("pasillo_a1",        "pasillo_a2",     5.0),
    ("pasillo_a2",        "interseccion_1", 5.0),
    ("interseccion_1",    "salon_101",      5.0),
    ("salon_101",         "salon_102",      5.0),
    ("salon_102",         "salon_103",      5.0),
    ("interseccion_1",    "banos",          5.0),
    ("banos",             "escaleras",      5.0),
    ("escaleras",         "sala_espera",    5.1),
    ("sala_espera",       "biblioteca",     5.0),
    ("biblioteca",        "cafeteria",      5.0),
]

# =============================================================================
# CONSTRUCCIÓN DEL GRAFO (NetworkX)
# =============================================================================

graph = nx.Graph()
for node_id, data in NODES.items():
    graph.add_node(node_id, **data)

for u, v, weight in EDGES:
    graph.add_edge(u, v, weight=weight)

# =============================================================================
# ESTADO INTERNO DE SIMULACIÓN DE LOCALIZACIÓN
# =============================================================================

class LocalizationState:
    """
    Mantiene la posición simulada del usuario en el edificio.
    Avanza 0.5 m por llamada en dirección al nodo destino más cercano.
    """

    def __init__(self):
        self.reset()

    def reset(self):
        self._current_node_index = 0
        self._node_sequence = list(NODES.keys())  # Recorre todos los nodos en orden
        node = NODES[self._node_sequence[0]]
        self.x: float = node["x"]
        self.y: float = node["y"]
        self.z: float = node["z"]

    def _nearest_node(self) -> str:
        min_dist = float("inf")
        nearest = self._node_sequence[0]
        for node_id, data in NODES.items():
            d = math.sqrt(
                (self.x - data["x"]) ** 2
                + (self.z - data["z"]) ** 2
            )
            if d < min_dist:
                min_dist = d
                nearest = node_id
        return nearest

    def advance(self) -> dict:
        """Avanza 0.5 m hacia el siguiente nodo de la secuencia."""
        target_id = self._node_sequence[
            min(self._current_node_index + 1, len(self._node_sequence) - 1)
        ]
        target = NODES[target_id]

        dx = target["x"] - self.x
        dz = target["z"] - self.z
        dist = math.sqrt(dx * dx + dz * dz)

        step = 0.5
        if dist < step:
            # Llegamos al nodo — avanzar al siguiente
            self.x = target["x"]
            self.z = target["z"]
            self._current_node_index = min(
                self._current_node_index + 1, len(self._node_sequence) - 1
            )
        else:
            self.x += (dx / dist) * step
            self.z += (dz / dist) * step

        # Ruido gaussiano (sigma = 0.05 m) para simular imprecisión real
        noise = np.random.normal(0, 0.05, 3)
        x_noisy = self.x + noise[0]
        z_noisy = self.z + noise[2]

        nearest = self._nearest_node()
        confidence = round(random.uniform(0.72, 0.97), 2)

        return {
            "pose": {
                "x":  round(x_noisy, 3),
                "y":  round(self.y, 3),
                "z":  round(z_noisy, 3),
                "qw": 1.0,
                "qx": 0.0,
                "qy": 0.0,
                "qz": 0.0,
            },
            "nearest_node": nearest,
            "confidence": confidence,
        }


_localization_state = LocalizationState()

# =============================================================================
# APLICACIÓN FASTAPI
# =============================================================================

app = FastAPI(
    title="UNIwhere Mock Backend",
    description="Servidor de simulación del backend de localización indoor UNIwhere.",
    version="1.0.0",
)

# CORS: la app Flutter necesita acceso desde cualquier origen
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --------------------------------------------------------------------------
# Middleware: logging + header X-Mock-Server
# --------------------------------------------------------------------------

@app.middleware("http")
async def log_and_tag(request: Request, call_next):
    ts = time.strftime("%H:%M:%S")
    print(f"[{ts}] {request.method} {request.url.path}"
          + (f"?{request.url.query}" if request.url.query else ""))
    response = await call_next(request)
    response.headers["X-Mock-Server"] = "true"
    return response


# =============================================================================
# ENDPOINT 1 — GET /health
# =============================================================================

@app.get("/health")
async def health():
    """Verificación de estado del servidor."""
    return {"status": "ok", "mock": True, "version": "1.0.0"}


# =============================================================================
# ENDPOINT 2 — GET /points_of_interest
# =============================================================================

@app.get("/points_of_interest")
async def points_of_interest():
    """
    Devuelve todos los nodos como lista directa.
    Cada item incluye 'id' y 'name' (campos que espera PointOfInterest.fromJson).
    """
    return [
        {
            "id":   node_id,
            "name": data["label"],
            "x":    data["x"],
            "y":    data["y"],
            "z":    data["z"],
        }
        for node_id, data in NODES.items()
    ]


# =============================================================================
# ENDPOINT 3 — POST /localize
# =============================================================================

@app.post("/localize")
async def localize(image: UploadFile = File(...)):
    """
    Recibe un frame JPEG y devuelve la pose simulada en el mapa.

    - 10 % de probabilidad de error 503 (zona sin textura) para probar
      el manejo de errores en la app.
    - Latencia simulada entre 150 ms y 400 ms.
    - Avanza 0.5 m por llamada en dirección al próximo nodo.
    """
    # Simular latencia realista del pipeline SuperPoint + SuperGlue
    await asyncio.sleep(random.uniform(0.15, 0.40))

    # 10 % de fallos de localización
    if random.random() < 0.10:
        return JSONResponse(
            status_code=503,
            content={"detail": "Localización fallida: zona sin textura suficiente"},
        )

    result = _localization_state.advance()
    return result


# =============================================================================
# ENDPOINT 4 — GET /route?origin=X&destination=Y
# =============================================================================

@app.get("/route")
async def route(origin: str, destination: str):
    """
    Calcula la ruta óptima entre dos nodos usando A* sobre el grafo NetworkX.
    Devuelve lista de waypoints con coordenadas, distancia total y tiempo estimado.
    """
    if origin not in NODES:
        raise HTTPException(
            status_code=404,
            detail=f"Nodo origen '{origin}' no existe en el mapa.",
        )
    if destination not in NODES:
        raise HTTPException(
            status_code=404,
            detail=f"Nodo destino '{destination}' no existe en el mapa.",
        )

    try:
        path: list[str] = nx.astar_path(
            graph,
            origin,
            destination,
            heuristic=_euclidean_heuristic,
            weight="weight",
        )
    except nx.NetworkXNoPath:
        raise HTTPException(
            status_code=404,
            detail=f"No existe ruta entre '{origin}' y '{destination}'.",
        )

    # Construir waypoints
    waypoints = []
    total_distance = 0.0
    prev_node: Optional[str] = None

    for node_id in path:
        data = NODES[node_id]
        waypoints.append({
            "node_id": node_id,
            "x":       data["x"],
            "y":       data["y"],
            "z":       data["z"],
            "label":   data["label"],
        })
        if prev_node is not None:
            total_distance += graph[prev_node][node_id]["weight"]
        prev_node = node_id

    # Velocidad de caminata ~1.4 m/s (igual que AppConfig.walkingSpeedMs)
    estimated_time = int(total_distance / 1.4)

    return {
        "waypoints":               waypoints,
        "total_distance":          round(total_distance, 2),
        "estimated_time_seconds":  estimated_time,
    }


# =============================================================================
# HEURÍSTICA A*
# =============================================================================

def _euclidean_heuristic(u: str, v: str) -> float:
    """Distancia euclidiana en el plano XZ (Y constante en un solo piso)."""
    nu, nv = NODES[u], NODES[v]
    return math.sqrt((nu["x"] - nv["x"]) ** 2 + (nu["z"] - nv["z"]) ** 2)


# =============================================================================
# ARRANQUE — imprime mapa en consola
# =============================================================================

def _print_map():
    print("\n" + "=" * 60)
    print("  UNIwhere Mock Backend  v1.0.0")
    print("=" * 60)
    print(f"\n  Nodos ({len(NODES)}):")
    for nid, d in NODES.items():
        print(f"    {nid:<22} ({d['x']:5.1f}, {d['y']:4.1f}, {d['z']:5.1f})  {d['label']}")
    print(f"\n  Edges ({len(EDGES)}):")
    for u, v, w in EDGES:
        print(f"    {u:<22} <-> {v:<22}  peso={w}")
    print("\n  Endpoints:")
    print("    GET  /health")
    print("    GET  /points_of_interest")
    print("    POST /localize           (multipart, campo 'image')")
    print("    GET  /route?origin=X&destination=Y")
    print("    GET  /docs               (Swagger UI)")
    print("\n" + "=" * 60 + "\n")


@app.on_event("startup")
async def startup_event():
    _print_map()


# =============================================================================
# EJECUCIÓN DIRECTA
# =============================================================================

if __name__ == "__main__":
    uvicorn.run("mock_backend:app", host="0.0.0.0", port=8000, reload=True)


# =============================================================================
# INSTRUCCIONES DE USO
# =============================================================================
# pip install -r requirements_mock.txt
# uvicorn mock_backend:app --reload --host 0.0.0.0 --port 8000
# Probar en: http://localhost:8000/docs
#
# Endpoints disponibles:
#   GET  /health                              → estado del servidor
#   GET  /points_of_interest                  → todos los nodos del mapa
#   POST /localize       (campo: image JPEG)  → pose simulada + nearest_node
#   GET  /route?origin=entrada_principal&destination=cafeteria  → ruta A*
#
# Para resetear la posición simulada, reinicia el servidor.
# La app Flutter debe apuntar a: http://<IP-de-tu-PC>:8000
# (en Settings de la app, cambiar la URL del backend)
