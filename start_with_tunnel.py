"""
UNIwhere — Lanzador con túnel Cloudflare
=========================================
Arranca el mock backend (uvicorn) y un Quick Tunnel de Cloudflare en paralelo.
Cuando el túnel esté listo imprime la URL pública y un QR code para escanear
con el teléfono y pegarla directamente en la app (Configuración → URL Backend).

Uso:
    python start_with_tunnel.py

Requisitos:
    1. cloudflared instalado y en PATH  →  https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/
       Windows rápido:  winget install Cloudflare.cloudflared
    2. pip install -r requirements_mock.txt
"""

import os
import re
import shutil
import subprocess
import sys
import threading
import time

# ---------------------------------------------------------------------------
# Colores ANSI (funcionan en Windows 10+ con terminal moderno)
# ---------------------------------------------------------------------------
RESET  = "\033[0m"
BOLD   = "\033[1m"
GREEN  = "\033[92m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
RED    = "\033[91m"
BLUE   = "\033[94m"


def _color(text: str, *codes: str) -> str:
    return "".join(codes) + text + RESET


# ---------------------------------------------------------------------------
# Verificar dependencias
# ---------------------------------------------------------------------------

def check_cloudflared() -> str:
    """
    Devuelve la ruta al ejecutable cloudflared.
    Busca en PATH y también en los directorios habituales de winget en Windows,
    ya que winget no añade el ejecutable al PATH automáticamente.
    """
    # 1. Buscar en PATH (caso ideal)
    path = shutil.which("cloudflared")
    if path:
        return path

    # 2. Buscar en ubicaciones típicas de winget / instalación manual en Windows
    if sys.platform == "win32":
        local_app = os.environ.get("LOCALAPPDATA", "")
        program_files = os.environ.get("ProgramFiles", "C:\\Program Files")
        program_files_x86 = os.environ.get("ProgramFiles(x86)", "C:\\Program Files (x86)")

        search_roots = [
            # winget instala aquí con el patrón Cloudflare.cloudflared_*
            os.path.join(local_app, "Microsoft", "WinGet", "Packages"),
            os.path.join(local_app, "Microsoft", "WinGet", "Links"),
            os.path.join(program_files, "Cloudflare"),
            os.path.join(program_files, "cloudflared"),
            os.path.join(program_files_x86, "Cloudflare"),
            os.path.join(program_files_x86, "cloudflared"),
            "C:\\ProgramData\\chocolatey\\bin",
            "C:\\tools\\cloudflared",
        ]

        for root in search_roots:
            if not os.path.isdir(root):
                continue
            for dirpath, _dirs, files in os.walk(root):
                for fname in files:
                    if fname.lower() in ("cloudflared.exe", "cloudflared"):
                        found = os.path.join(dirpath, fname)
                        print(_color(f"  ✓ cloudflared encontrado en:\n    {found}", GREEN))
                        print(_color("    (tip: agrega esa carpeta al PATH para evitar este mensaje)\n", "\033[90m"))
                        return found

    print(_color("\n  ✗ cloudflared no encontrado.\n", RED, BOLD))
    print("  Instálalo con UNO de estos métodos y vuelve a ejecutar:\n")
    print(_color("  Windows (winget):", YELLOW))
    print("    winget install Cloudflare.cloudflared\n")
    print(_color("  Windows (manual):", YELLOW))
    print("    Descarga el .exe desde:")
    print("    https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/")
    print("    Cópialo a C:\\Windows\\System32\\ o agrégalo al PATH.\n")
    print(_color("  macOS (brew):", YELLOW))
    print("    brew install cloudflared\n")
    print(_color("  Linux:", YELLOW))
    print("    Ver https://pkg.cloudflare.com/\n")
    sys.exit(1)


def check_uvicorn():
    """Verifica que uvicorn y el mock_backend sean accesibles."""
    if not shutil.which("uvicorn") and not _has_module("uvicorn"):
        print(_color("\n  ✗ uvicorn no encontrado. Ejecuta:", RED, BOLD))
        print("    pip install -r requirements_mock.txt\n")
        sys.exit(1)

    if not os.path.isfile(os.path.join(os.path.dirname(__file__), "mock_backend.py")):
        print(_color("\n  ✗ mock_backend.py no encontrado en el directorio actual.\n", RED, BOLD))
        sys.exit(1)


def _has_module(name: str) -> bool:
    import importlib.util
    return importlib.util.find_spec(name) is not None


# ---------------------------------------------------------------------------
# QR code en terminal
# ---------------------------------------------------------------------------

def print_qr(url: str):
    try:
        import qrcode
        qr = qrcode.QRCode(border=1)
        qr.add_data(url)
        qr.make(fit=True)
        print()
        qr.print_ascii(invert=True)
        print()
    except ImportError:
        print(_color("  (instala 'qrcode' para ver el QR: pip install qrcode)\n", YELLOW))


# ---------------------------------------------------------------------------
# Parsear URL del túnel desde la salida de cloudflared
# ---------------------------------------------------------------------------

TUNNEL_URL_RE = re.compile(r"https://[a-zA-Z0-9\-]+\.trycloudflare\.com")


def _read_tunnel_url(proc: subprocess.Popen, url_found: threading.Event, result: list):
    """Lee stderr de cloudflared línea por línea buscando la URL del túnel."""
    assert proc.stderr is not None
    for raw_line in proc.stderr:
        line = raw_line.decode(errors="replace").strip()
        if line:
            # Mostrar logs de cloudflared en gris tenue
            print(_color(f"  [cloudflared] {line}", "\033[90m"))
        match = TUNNEL_URL_RE.search(line)
        if match and not url_found.is_set():
            result.append(match.group(0))
            url_found.set()


# ---------------------------------------------------------------------------
# Banner de inicio
# ---------------------------------------------------------------------------

def print_banner():
    print(_color("\n" + "=" * 62, CYAN))
    print(_color("  UNIwhere Mock Backend  +  Cloudflare Quick Tunnel", CYAN, BOLD))
    print(_color("=" * 62 + "\n", CYAN))


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    # Habilitar códigos ANSI en Windows
    if sys.platform == "win32":
        os.system("")

    print_banner()
    check_uvicorn()
    cloudflared_bin = check_cloudflared()

    # ------------------------------------------------------------------
    # 1. Arrancar uvicorn en un subproceso
    # ------------------------------------------------------------------
    backend_dir = os.path.dirname(os.path.abspath(__file__))
    uvicorn_cmd = [
        sys.executable, "-m", "uvicorn",
        "mock_backend:app",
        "--host", "127.0.0.1",
        "--port", "8000",
    ]

    print(_color("  ▶ Iniciando mock backend (uvicorn)...", BLUE))
    uvicorn_proc = subprocess.Popen(
        uvicorn_cmd,
        cwd=backend_dir,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    # Dar tiempo a uvicorn para que empiece a escuchar
    time.sleep(2.0)

    if uvicorn_proc.poll() is not None:
        print(_color("  ✗ uvicorn terminó inesperadamente.\n", RED, BOLD))
        sys.exit(1)

    print(_color("  ✓ Backend escuchando en http://localhost:8000\n", GREEN))

    # ------------------------------------------------------------------
    # 2. Arrancar cloudflared quick tunnel
    # ------------------------------------------------------------------
    tunnel_cmd = [cloudflared_bin, "tunnel", "--url", "http://localhost:8000"]

    print(_color("  ▶ Creando Quick Tunnel (sin cuenta, temporal)...\n", BLUE))
    tunnel_proc = subprocess.Popen(
        tunnel_cmd,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
    )

    url_found   = threading.Event()
    tunnel_url  = []

    reader_thread = threading.Thread(
        target=_read_tunnel_url,
        args=(tunnel_proc, url_found, tunnel_url),
        daemon=True,
    )
    reader_thread.start()

    # Esperar hasta 30 s a que aparezca la URL
    if not url_found.wait(timeout=30):
        print(_color("\n  ✗ Tiempo de espera agotado buscando la URL del túnel.", RED, BOLD))
        print("    Verifica tu conexión a Internet y que cloudflared funcione.\n")
        uvicorn_proc.terminate()
        tunnel_proc.terminate()
        sys.exit(1)

    public_url = tunnel_url[0]

    # ------------------------------------------------------------------
    # 3. Mostrar resultado
    # ------------------------------------------------------------------
    print()
    print(_color("=" * 62, GREEN))
    print(_color("  ✓ Túnel activo", GREEN, BOLD))
    print(_color("=" * 62, GREEN))
    print()
    print(_color(f"  URL pública:  {public_url}", CYAN, BOLD))
    print()
    print("  → Copia esta URL en la app UNIwhere:")
    print(_color("    Configuración  ▸  URL del Backend", YELLOW))
    print()
    print_qr(public_url)
    print(_color("  Escanea el QR con la cámara del teléfono o cópiala manualmente.", YELLOW))
    print()
    print(_color("  Endpoints disponibles:", BOLD))
    print(f"    GET  {public_url}/health")
    print(f"    GET  {public_url}/points_of_interest")
    print(f"    POST {public_url}/localize")
    print(f"    GET  {public_url}/route?origin=entrada_principal&destination=cafeteria")
    print(f"    GET  {public_url}/docs   (Swagger UI)")
    print()
    print(_color("  Nota: Quick Tunnels son temporales (~24 h). La URL cambia", "\033[90m"))
    print(_color("        cada vez que reinicias este script.", "\033[90m"))
    print()
    print(_color("  Presiona Ctrl+C para detener todo.", YELLOW, BOLD))
    print(_color("=" * 62 + "\n", GREEN))

    # ------------------------------------------------------------------
    # 4. Esperar a Ctrl+C y limpiar
    # ------------------------------------------------------------------
    try:
        uvicorn_proc.wait()
    except KeyboardInterrupt:
        pass
    finally:
        print(_color("\n  Deteniendo servicios...", YELLOW))
        tunnel_proc.terminate()
        uvicorn_proc.terminate()
        try:
            tunnel_proc.wait(timeout=5)
            uvicorn_proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            tunnel_proc.kill()
            uvicorn_proc.kill()
        print(_color("  ✓ Todo detenido correctamente.\n", GREEN))


if __name__ == "__main__":
    main()
