import 'package:flutter/material.dart';
import 'camera_screen.dart';
import '../forms/reporte_form.dart';
import '../forms/perfil_form.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  HOME SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  static const Color _primary = Color(0xFF0D6EFD);

  String _nombreUsuario = '';
  bool   _loadingUser   = true;

  late final List<Widget> _sections;

  @override
  void initState() {
    super.initState();
    _sections = [
      _DashboardSection(onGoToCamera: () => setState(() => _selectedIndex = 1)),
      const CameraScreen(),
      const _FormulariosSection(),
    ];
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final cached = await ApiService.getCachedUser();
    if (cached != null && mounted) {
      setState(() { _nombreUsuario = cached['nombre']?.toString() ?? ''; _loadingUser = false; });
    }
    final res = await ApiService.getMe();
    if (res.success && mounted) {
      await ApiService.saveUser(res.data);
      setState(() { _nombreUsuario = res.data['nombre']?.toString() ?? _nombreUsuario; _loadingUser = false; });
    } else if (mounted) {
      setState(() => _loadingUser = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Confirma que desea cerrar la sesión actual?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC3545)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.self_improvement_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pausas Activas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (!_loadingUser && _nombreUsuario.isNotEmpty)
              Text(_nombreUsuario, style: const TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis),
          ])),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded), tooltip: 'Cerrar sesión', onPressed: _logout),
        ],
        elevation: 0,
      ),
      body: _sections[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: _primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded, color: _primary), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.videocam_outlined),  selectedIcon: Icon(Icons.videocam_rounded,  color: _primary), label: 'Cámara'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment_rounded, color: _primary), label: 'Formularios'),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DASHBOARD — con CRUD de ejercicios
// ══════════════════════════════════════════════════════════════════════════════

class _DashboardSection extends StatefulWidget {
  final VoidCallback onGoToCamera;
  const _DashboardSection({required this.onGoToCamera});

  @override
  State<_DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<_DashboardSection> {
  static const Color _primary = Color(0xFF0D6EFD);
  static const Color _success = Color(0xFF198754);
  static const Color _warning = Color(0xFFFFC107);
  static const Color _danger  = Color(0xFFDC3545);

  List<Map<String, dynamic>> _ejercicios = [];
  bool _loadingEjercicios = true;

  // Iconos disponibles para selección
  static const Map<String, IconData> _iconosDisponibles = {
    'accessibility_new':    Icons.accessibility_new_rounded,
    'rotate_right':         Icons.rotate_right_rounded,
    'self_improvement':     Icons.self_improvement_rounded,
    'directions_walk':      Icons.directions_walk_rounded,
    'pan_tool':             Icons.pan_tool_rounded,
    'fitness_center':       Icons.fitness_center_rounded,
    'sports_gymnastics':    Icons.sports_gymnastics,
    'airline_seat_recline': Icons.airline_seat_recline_extra_rounded,
    'favorite':             Icons.favorite_rounded,
    'psychology':           Icons.psychology_rounded,
  };

  @override
  void initState() {
    super.initState();
    _cargarEjercicios();
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _cargarEjercicios() async {
    setState(() => _loadingEjercicios = true);
    final res = await ApiService.getEjercicios();
    if (res.success && mounted) {
      setState(() {
        _ejercicios = (res.data['ejercicios'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loadingEjercicios = false;
      });
    } else if (mounted) {
      setState(() => _loadingEjercicios = false);
    }
  }

  Future<void> _crearEjercicio(Map<String, dynamic> data) async {
    final res = await ApiService.crearEjercicio(
      nombre:      data['nombre'],
      descripcion: data['descripcion'],
      duracion:    data['duracion'],
      icono:       data['icono'],
    );
    if (res.success && mounted) {
      _mostrarSnack('Ejercicio creado correctamente.', _success);
      _cargarEjercicios();
    } else if (mounted) {
      _mostrarSnack(res.errorMessage, _danger);
    }
  }

  Future<void> _editarEjercicio(int id, Map<String, dynamic> data) async {
    final res = await ApiService.editarEjercicio(id, data);
    if (res.success && mounted) {
      _mostrarSnack('Ejercicio actualizado correctamente.', _success);
      _cargarEjercicios();
    } else if (mounted) {
      _mostrarSnack(res.errorMessage, _danger);
    }
  }

  Future<void> _eliminarEjercicio(int id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Eliminar ejercicio'),
        content: Text('¿Desea eliminar "$nombre"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final res = await ApiService.eliminarEjercicio(id);
    if (res.success && mounted) {
      _mostrarSnack('Ejercicio eliminado.', _success);
      _cargarEjercicios();
    } else if (mounted) {
      _mostrarSnack(res.errorMessage, _danger);
    }
  }

  void _mostrarSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Modal crear/editar ────────────────────────────────────────────────────

  void _showFormEjercicio({Map<String, dynamic>? ejercicio}) {
    final nombreCtrl = TextEditingController(text: ejercicio?['nombre'] ?? '');
    final descCtrl   = TextEditingController(text: ejercicio?['descripcion'] ?? '');
    final durCtrl    = TextEditingController(text: ejercicio?['duracion']?.toString() ?? '');
    String iconoSel  = ejercicio?['icono'] ?? 'accessibility_new';
    final formKey    = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(
                ejercicio == null ? 'Nuevo ejercicio' : 'Editar ejercicio',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 20),

              // Nombre
              _formLabel('Nombre del ejercicio'),
              const SizedBox(height: 6),
              TextFormField(
                controller: nombreCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Ej. Estiramiento cervical'),
                validator: (v) => (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
              ),
              const SizedBox(height: 14),

              // Descripción
              _formLabel('Descripción / instrucciones'),
              const SizedBox(height: 6),
              TextFormField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Describe cómo realizar el ejercicio...'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 14),

              // Duración
              _formLabel('Duración (minutos)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: durCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Ej. 5', suffixText: 'min'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1 || n > 120) return 'Entre 1 y 120 minutos';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Ícono
              _formLabel('Ícono'),
              const SizedBox(height: 8),
              Wrap(spacing: 10, runSpacing: 10,
                children: _iconosDisponibles.entries.map((e) {
                  final sel = e.key == iconoSel;
                  return GestureDetector(
                    onTap: () => setModal(() => iconoSel = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: sel ? _primary.withValues(alpha: 0.15) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? _primary : Colors.grey.shade300, width: sel ? 2 : 1),
                      ),
                      child: Icon(e.value, color: sel ? _primary : Colors.grey.shade500, size: 22),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final data = {
                    'nombre':      nombreCtrl.text.trim(),
                    'descripcion': descCtrl.text.trim(),
                    'duracion':    int.parse(durCtrl.text.trim()),
                    'icono':       iconoSel,
                  };
                  Navigator.pop(ctx);
                  if (ejercicio == null) {
                    _crearEjercicio(data);
                  } else {
                    _editarEjercicio(ejercicio['id'] as int, data);
                  }
                },
                child: Text(ejercicio == null ? 'Crear ejercicio' : 'Guardar cambios'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _formLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final completados = _ejercicios.where((e) => e['completado'] == true).length;
    final total       = _ejercicios.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        // Encabezado
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PROGRAMA DE BIENESTAR LABORAL',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _primary, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            const Text('Rutina de Pausas Activas',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 3),
            Text('Ingeniería de Software — Sesión diaria programada',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ])),
          FilledButton.icon(
            onPressed: widget.onGoToCamera,
            icon: const Icon(Icons.videocam_rounded, size: 15),
            label: const Text('Análisis postural'),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ]),

        const SizedBox(height: 16),

        // Aviso ergonómico
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _primary.withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: _primary, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'La exposición prolongada a pantallas incrementa el riesgo de lesiones musculoesqueléticas. '
              'Se recomienda realizar pausas activas cada 60 minutos.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.5),
            )),
          ]),
        ),

        const SizedBox(height: 16),

        // Progreso
        if (total > 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Text('Avance de la sesión',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                Text('$completados / $total', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? completados / total : 0,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                completados == total && total > 0
                    ? 'Rutina completada satisfactoriamente.'
                    : '${total - completados} actividad(es) pendiente(s) por completar.',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ]),
          ),

          const SizedBox(height: 12),

          Row(children: [
            _StatChip(label: 'Completadas', value: '$completados',         color: _success),
            const SizedBox(width: 8),
            _StatChip(label: 'Pendientes',  value: '${total - completados}', color: _warning),
            const SizedBox(width: 8),
            _StatChip(label: 'Total',       value: '$total',               color: _primary),
          ]),

          const SizedBox(height: 20),
        ],

        // Título + botón agregar
        Row(children: [
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mis Ejercicios',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              Text('Gestione su rutina personalizada de pausas activas.',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
          FilledButton.icon(
            onPressed: () => _showFormEjercicio(),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Agregar'),
            style: FilledButton.styleFrom(
              backgroundColor: _success,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Lista de ejercicios
        if (_loadingEjercicios)
          const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ))
        else if (_ejercicios.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(children: [
              Icon(Icons.fitness_center_rounded, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('No tiene ejercicios registrados.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Toque "Agregar" para crear su primera rutina personalizada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ]),
          )
        else
          ...List.generate(_ejercicios.length, (i) {
            final e    = _ejercicios[i];
            final icon = _iconosDisponibles[e['icono']] ?? Icons.fitness_center_rounded;
            final done = e['completado'] == true;
            final colors = [
              const Color(0xFF0D6EFD), const Color(0xFF198754),
              const Color(0xFF8B5CF6), const Color(0xFFF59E0B), const Color(0xFFEF4444),
            ];
            final color = colors[i % colors.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: done ? _success.withValues(alpha: 0.3) : Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                title: Text(e['nombre'] as String,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? Colors.grey.shade400 : const Color(0xFF1A1A2E),
                    )),
                subtitle: Row(children: [
                  Icon(Icons.schedule_outlined, size: 11, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text('${e['duracion']} min',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ]),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  // Checkbox completado
                  Checkbox(
                    value: done,
                    activeColor: _success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (_) => setState(() => _ejercicios[i]['completado'] = !done),
                  ),
                  // Editar
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: _primary,
                    tooltip: 'Editar',
                    onPressed: () => _showFormEjercicio(ejercicio: e),
                  ),
                  // Eliminar
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: _danger,
                    tooltip: 'Eliminar',
                    onPressed: () => _eliminarEjercicio(e['id'] as int, e['nombre'] as String),
                  ),
                ]),
                onTap: () => _showDetalle(context, e, icon, color),
              ),
            );
          }),
      ]),
    );
  }

  void _showDetalle(BuildContext ctx, Map<String, dynamic> e, IconData icon, Color color) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 52, height: 52,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e['nombre'] as String,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('${e['duracion']} minutos',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ])),
          ]),
          const SizedBox(height: 18),
          const Text('Instrucciones de ejecución',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Text(e['descripcion'] as String,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.6)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D6EFD),
                  side: const BorderSide(color: Color(0xFF0D6EFD)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () { Navigator.pop(ctx); _showFormEjercicio(ejercicio: e); },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Entendido'),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  FORMULARIOS
// ══════════════════════════════════════════════════════════════════════════════

class _FormulariosSection extends StatelessWidget {
  const _FormulariosSection();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Formularios',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 4),
        Text('Registro de información y reportes de sesión.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        _FormCard(
          icon: Icons.assignment_rounded, color: const Color(0xFF0D6EFD),
          title: 'Reporte de Sesión',
          subtitle: 'Registre los indicadores de bienestar de la sesión actual.',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReporteForm())),
        ),
        const SizedBox(height: 14),
        _FormCard(
          icon: Icons.manage_accounts_rounded, color: const Color(0xFF8B5CF6),
          title: 'Perfil de Usuario',
          subtitle: 'Actualice sus datos personales, laborales y preferencias.',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilForm())),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════════════════════

class _StatChip extends StatelessWidget {
  final String label, value; final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ]),
    ),
  );
}

class _FormCard extends StatelessWidget {
  final IconData icon; final Color color;
  final String title, subtitle; final VoidCallback onTap;
  const _FormCard({required this.icon, required this.color,
      required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(width: 50, height: 50,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 25)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.4)),
        ])),
        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
      ]),
    ),
  );
}
