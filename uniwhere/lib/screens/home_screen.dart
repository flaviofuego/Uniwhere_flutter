import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../config.dart';
import '../models/point_of_interest.dart';
import '../providers/navigation_provider.dart';
import 'ar_navigation_screen.dart';
import 'settings_screen.dart';

/// Pantalla principal de UNIwhere.
/// Muestra:
///   - Lista de puntos de interés del campus (desde /points_of_interest)
///   - Barra de búsqueda para filtrar destinos
///   - Botón "Navegar" que lleva a la pantalla AR
///   - Indicador de conexión con el backend
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PointOfInterest? _selectedPoi;

  @override
  void initState() {
    super.initState();
    // Cargar POIs y verificar conexión al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) => _initScreen());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Carga inicial: verificar conexión y cargar puntos de interés
  Future<void> _initScreen() async {
    final nav = context.read<NavigationProvider>();
    await nav.checkConnection();
    await nav.loadPointsOfInterest();
  }

  /// Filtra la lista de POIs según la búsqueda del usuario
  List<PointOfInterest> _filteredPois(List<PointOfInterest> pois) {
    if (_searchQuery.isEmpty) return pois;
    final q = _searchQuery.toLowerCase();
    return pois.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.description?.toLowerCase().contains(q) ?? false) ||
          (p.building?.toLowerCase().contains(q) ?? false) ||
          (p.category?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  /// Navega a la pantalla AR con el destino seleccionado
  void _startNavigation(PointOfInterest poi) {
    final nav = context.read<NavigationProvider>();
    nav.selectDestination(poi);
    nav.startNavigation();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ARNavigationScreen(),
      ),
    ).then((_) {
      // Al volver, limpiar estado de navegación
      nav.stopNavigation();
      setState(() => _selectedPoi = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.surfaceColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _selectedPoi != null ? _buildNavFab() : null,
    );
  }

  // ============================================================================
  // APP BAR
  // ============================================================================

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('UNIwhere'),
      actions: [
        // Indicador de conexión al backend
        Consumer<NavigationProvider>(
          builder: (_, nav, __) => _ConnectionDot(status: nav.connectionStatus),
        ),
        // Botón de configuración
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          tooltip: 'Configuración',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ).then((_) => _initScreen()), // Recargar al volver de settings
        ),
      ],
    );
  }

  // ============================================================================
  // CUERPO PRINCIPAL
  // ============================================================================

  Widget _buildBody() {
    return Consumer<NavigationProvider>(
      builder: (context, nav, _) {
        return Column(
          children: [
            // Header con descripción y barra de búsqueda
            _buildHeader(),
            // Lista de POIs o estados de carga/error
            Expanded(child: _buildPoiContent(nav)),
          ],
        );
      },
    );
  }

  // ============================================================================
  // HEADER CON BUSCADOR
  // ============================================================================

  Widget _buildHeader() {
    return Container(
      color: AppConfig.primaryColor,
      padding: const EdgeInsets.fromLTRB(
        AppConfig.horizontalPadding,
        0,
        AppConfig.horizontalPadding,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtítulo
          Text(
            '¿A dónde vas hoy?',
            style: TextStyle(
              color: Colors.white.withValues(alpha:0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          // Barra de búsqueda
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Buscar: aula, biblioteca, laboratorio...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // CONTENIDO DE LA LISTA DE POIs
  // ============================================================================

  Widget _buildPoiContent(NavigationProvider nav) {
    // Estado: cargando
    if (nav.loadingPois) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinKitFadingCircle(color: AppConfig.primaryColor, size: 48),
            const SizedBox(height: 16),
            const Text('Cargando destinos...', style: TextStyle(fontSize: 14)),
          ],
        ),
      );
    }

    // Estado: error de conexión
    if (nav.poisError != null) {
      return _buildErrorView(nav.poisError!);
    }

    // Estado: sin datos
    if (nav.pois.isEmpty) {
      return _buildEmptyView();
    }

    // Lista filtrada de POIs
    final filtered = _filteredPois(nav.pois);
    if (filtered.isEmpty) {
      return _buildNoResultsView();
    }

    return RefreshIndicator(
      color: AppConfig.primaryColor,
      onRefresh: () => nav.loadPointsOfInterest(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConfig.horizontalPadding),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _PoiCard(
          poi: filtered[i],
          isSelected: _selectedPoi?.id == filtered[i].id,
          onTap: () => setState(() {
            _selectedPoi =
                _selectedPoi?.id == filtered[i].id ? null : filtered[i];
          }),
          onNavigate: () => _startNavigation(filtered[i]),
        ),
      ),
    );
  }

  // ============================================================================
  // ESTADOS VACÍOS / ERROR
  // ============================================================================

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifica tu conexión WiFi y que el backend esté activo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initScreen,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No hay destinos disponibles.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _initScreen,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Recargar'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Sin resultados para "$_searchQuery"',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // FAB DE NAVEGACIÓN
  // ============================================================================

  Widget _buildNavFab() {
    return FloatingActionButton.extended(
      onPressed: () => _startNavigation(_selectedPoi!),
      backgroundColor: AppConfig.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.navigation_rounded),
      label: Text(
        'Navegar a ${_selectedPoi!.name}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ==============================================================================
// WIDGET: TARJETA DE PUNTO DE INTERÉS
// ==============================================================================

class _PoiCard extends StatelessWidget {
  final PointOfInterest poi;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onNavigate;

  const _PoiCard({
    required this.poi,
    required this.isSelected,
    required this.onTap,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: isSelected ? 5 : AppConfig.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          side: isSelected
              ? const BorderSide(color: AppConfig.primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Ícono de categoría
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppConfig.primaryColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      poi.categoryIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Información del POI
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (poi.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          poi.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (poi.description != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          poi.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Botón navegar (solo si está seleccionado)
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation_rounded),
                    color: AppConfig.primaryColor,
                    tooltip: 'Ir a ${poi.name}',
                    style: IconButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor.withValues(alpha:0.1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// WIDGET: INDICADOR DE CONEXIÓN
// ==============================================================================

/// Punto de color en el AppBar que indica el estado de conexión al backend
class _ConnectionDot extends StatelessWidget {
  final ConnectionStatus status;

  const _ConnectionDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      ConnectionStatus.connected => (Colors.greenAccent, 'Backend conectado'),
      ConnectionStatus.disconnected => (Colors.redAccent, 'Sin conexión con backend'),
      ConnectionStatus.unknown => (Colors.grey, 'Verificando conexión...'),
    };

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: label,
        child: Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha:0.5), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
