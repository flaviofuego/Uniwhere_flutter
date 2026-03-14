import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../providers/settings_provider.dart';
import '../providers/navigation_provider.dart';

/// Pantalla de configuración de UNIwhere.
///
/// Permite al usuario:
///   - Cambiar la IP/URL del backend FastAPI
///   - Activar el modo debug (muestra coordenadas de pose en la pantalla AR)
///   - Ver información de la app
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  bool _testingConnection = false;
  String? _connectionResult;
  bool? _connectionOk;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _urlController = TextEditingController(text: settings.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// Guarda la URL del backend y notifica al NavigationProvider
  Future<void> _saveUrl() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) return;

    final settings = context.read<SettingsProvider>();
    await settings.setBaseUrl(newUrl);

    // Propagar el cambio al NavigationProvider
    if (mounted) {
      context.read<NavigationProvider>().updateBackendUrl(newUrl);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL del backend guardada')),
      );
    }
  }

  /// Prueba la conexión con el backend actual
  Future<void> _testConnection() async {
    if (_testingConnection) return;

    // Capturar referencias antes de cualquier await (evita uso de context async)
    final nav = context.read<NavigationProvider>();

    // Guardar primero la URL actual
    await _saveUrl();

    setState(() {
      _testingConnection = true;
      _connectionResult = null;
      _connectionOk = null;
    });

    try {
      await nav.checkConnection();

      if (!mounted) return;
      final ok = nav.connectionStatus == ConnectionStatus.connected;
      setState(() {
        _connectionOk = ok;
        _connectionResult = ok
            ? 'Conexión exitosa con el backend'
            : 'No se pudo conectar. Verifica IP y que el servidor esté activo.';
      });
    } finally {
      if (mounted) setState(() => _testingConnection = false);
    }
  }

  /// Restaura los ajustes a valores por defecto
  Future<void> _resetDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restaurar valores por defecto'),
        content: const Text(
            '¿Seguro que quieres restaurar todos los ajustes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final settings = context.read<SettingsProvider>();
      await settings.resetToDefaults();
      _urlController.text = AppConfig.defaultBaseUrl;
      setState(() {
        _connectionResult = null;
        _connectionOk = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajustes restaurados')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConfig.horizontalPadding),
        children: [
          // ==================================================================
          // SECCIÓN: BACKEND
          // ==================================================================
          _SectionHeader(title: 'Servidor Backend', icon: Icons.dns_rounded),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo URL del backend
                  const Text(
                    'URL del backend FastAPI',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ejemplo: http://192.168.1.10:8000',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),

                  // TextField con la URL
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.link_rounded),
                      hintText: AppConfig.defaultBaseUrl,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save_rounded),
                        onPressed: _saveUrl,
                        tooltip: 'Guardar URL',
                      ),
                    ),
                    onSubmitted: (_) => _saveUrl(),
                  ),

                  const SizedBox(height: 12),

                  // Botón de prueba de conexión
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _testingConnection ? null : _testConnection,
                      icon: _testingConnection
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.network_check_rounded),
                      label: Text(_testingConnection
                          ? 'Probando...'
                          : 'Probar conexión'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConfig.primaryColor,
                        side: const BorderSide(color: AppConfig.primaryColor),
                      ),
                    ),
                  ),

                  // Resultado de la prueba de conexión
                  if (_connectionResult != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (_connectionOk ?? false)
                            ? Colors.green.withValues(alpha:0.12)
                            : Colors.red.withValues(alpha:0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (_connectionOk ?? false)
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: (_connectionOk ?? false)
                                ? AppConfig.successColor
                                : AppConfig.errorColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _connectionResult!,
                              style: TextStyle(
                                color: (_connectionOk ?? false)
                                    ? AppConfig.successColor
                                    : AppConfig.errorColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ==================================================================
          // SECCIÓN: OPCIONES
          // ==================================================================
          _SectionHeader(title: 'Opciones', icon: Icons.tune_rounded),
          const SizedBox(height: 12),

          Card(
            child: Consumer<SettingsProvider>(
              builder: (context, settings, _) => SwitchListTile(
                title: const Text('Modo Debug'),
                subtitle: const Text(
                  'Muestra coordenadas de pose y nodo actual en la pantalla AR',
                ),
                value: settings.debugMode,
                activeThumbColor: AppConfig.primaryColor,
                secondary: const Icon(Icons.bug_report_rounded),
                onChanged: (v) => settings.setDebugMode(v),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ==================================================================
          // SECCIÓN: INFORMACIÓN DE LA APP
          // ==================================================================
          _SectionHeader(title: 'Acerca de', icon: Icons.info_outline_rounded),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.school_rounded,
                  title: 'Institución',
                  value: AppConfig.universityName,
                ),
                const Divider(height: 1, indent: 56),
                _InfoRow(
                  icon: Icons.tag_rounded,
                  title: 'Versión',
                  value: AppConfig.appVersion,
                ),
                const Divider(height: 1, indent: 56),
                _InfoRow(
                  icon: Icons.camera_rounded,
                  title: 'Sensor',
                  value: 'Intel RealSense D455',
                ),
                const Divider(height: 1, indent: 56),
                _InfoRow(
                  icon: Icons.psychology_rounded,
                  title: 'Localización',
                  value: 'hloc (SuperPoint + SuperGlue)',
                ),
                const Divider(height: 1, indent: 56),
                _InfoRow(
                  icon: Icons.api_rounded,
                  title: 'Backend',
                  value: 'FastAPI (Python)',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botón de restaurar valores por defecto
          TextButton.icon(
            onPressed: _resetDefaults,
            icon: const Icon(Icons.restore_rounded, color: Colors.grey),
            label: const Text(
              'Restaurar valores por defecto',
              style: TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ==============================================================================
// WIDGETS AUXILIARES
// ==============================================================================

/// Encabezado de sección con ícono y título
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppConfig.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppConfig.primaryColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Fila de información dentro de una Card
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600], size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
