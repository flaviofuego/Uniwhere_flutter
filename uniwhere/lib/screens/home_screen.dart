import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room_location.dart';
import '../services/storage_service.dart';
import '../services/permissions_service.dart';
import '../widgets/location_card.dart';
import '../utils/constants.dart';
import 'calibration_screen.dart';
import 'navigation_screen.dart';
import 'map_screen.dart';

/// Pantalla de inicio de la aplicación
/// Muestra opciones principales y lista de ubicaciones
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late StorageService _storageService;
  late PermissionsService _permissionsService;
  List<RoomLocation> _locations = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _storageService = context.read<StorageService>();
    _permissionsService = context.read<PermissionsService>();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    
    try {
      final locations = _storageService.getAllLocations();
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar ubicaciones: $e')),
        );
      }
    }
  }

  Future<void> _checkPermissionsAndNavigate(Widget screen) async {
    final hasPermissions = await _permissionsService.hasAllPermissions();
    
    if (!hasPermissions) {
      final granted = await _permissionsService.requestAllPermissions();
      
      if (!granted['camera']!) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se requiere permiso de cámara para AR'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  List<RoomLocation> get _filteredLocations {
    if (_searchQuery.isEmpty) return _locations;
    
    return _locations.where((location) {
      return location.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          location.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          location.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Home Navigator'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Botón de mapa
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
            tooltip: 'Ver Mapa 2D',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppConstants.primaryColor,
                  AppConstants.primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    // Búsqueda
                    TextField(
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: '¿A dónde quieres ir?',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.buttonBorderRadius,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.defaultPadding),
                    
                    // Botones principales
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _checkPermissionsAndNavigate(
                                const CalibrationScreen(),
                              );
                            },
                            icon: const Icon(Icons.location_searching),
                            label: const Text('Calibración'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppConstants.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.buttonBorderRadius,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.defaultSpacing),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _locations.isEmpty
                                ? null
                                : () {
                                    _checkPermissionsAndNavigate(
                                      const NavigationScreen(),
                                    );
                                  },
                            icon: const Icon(Icons.navigation),
                            label: const Text('Navegación'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppConstants.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.buttonBorderRadius,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Lista de ubicaciones
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLocations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No hay ubicaciones guardadas'
                                  : 'No se encontraron resultados',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Usa el modo calibración para mapear tu casa',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLocations,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            top: AppConstants.defaultSpacing,
                            bottom: 80, // Espacio para el FAB
                          ),
                          itemCount: _filteredLocations.length,
                          itemBuilder: (context, index) {
                            final location = _filteredLocations[index];
                            return LocationCard(
                              location: location,
                              onTap: () {
                                _showLocationDetails(location);
                              },
                              onNavigate: () {
                                _startNavigationTo(location);
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _checkPermissionsAndNavigate(const CalibrationScreen());
        },
        icon: const Icon(Icons.add_location),
        label: const Text('Nueva Ubicación'),
        backgroundColor: AppConstants.primaryColor,
      ),
    );
  }

  void _showLocationDetails(RoomLocation location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      location.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      location.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: location.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _startNavigationTo(location);
                        },
                        icon: const Icon(Icons.navigation),
                        label: const Text('Navegar aquí'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.buttonBorderRadius,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _startNavigationTo(RoomLocation location) {
    _checkPermissionsAndNavigate(
      NavigationScreen(destination: location),
    );
  }
}
