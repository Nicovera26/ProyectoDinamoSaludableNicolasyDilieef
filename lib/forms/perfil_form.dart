import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PerfilForm extends StatefulWidget {
  const PerfilForm({super.key});

  @override
  State<PerfilForm> createState() => _PerfilFormState();
}

class _PerfilFormState extends State<PerfilForm> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController  = TextEditingController();
  final _emailController   = TextEditingController();
  final _edadController    = TextEditingController();
  final _cargoController   = TextEditingController();
  final _empresaController = TextEditingController();

  static const Color _primary = Color(0xFF0D6EFD);
  static const Color _purple  = Color(0xFF8B5CF6);

  String _frecuencia     = 'Cada 60 min';
  String _nivelActividad = 'Moderado';
  bool   _notificaciones = true;
  bool   _guardando      = false;
  bool   _cargando       = true;   // ← nuevo: estado de carga inicial
  String? _errorCarga;             // ← nuevo: mensaje si falla la carga

  final List<String> _frecuencias      = ['Cada 30 min', 'Cada 45 min', 'Cada 60 min', 'Cada 90 min'];
  final List<String> _nivelesActividad = ['Sedentario', 'Ligero', 'Moderado', 'Activo'];


  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _edadController.dispose();
    _cargoController.dispose();
    _empresaController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    setState(() { _cargando = true; _errorCarga = null; });

    // 1. Intentar caché local primero (respuesta instantánea)
    final cached = await ApiService.getCachedUser();
    if (cached != null && mounted) {
      _rellenarControllers(cached);
    }

    // 2. Traer datos frescos del backend
    final meRes = await ApiService.getMe();
    if (!mounted) return;

    if (meRes.success) {
      final user = meRes.data;
      _rellenarControllers(user);

      // Guardar en caché para próxima vez
      await ApiService.saveUser(user);

      // 3. Traer preferencias del perfil extendido
      final perfilRes = await ApiService.getPerfil();
      if (mounted && perfilRes.success) {
        final perfil = perfilRes.data;
        setState(() {
          _cargoController.text   = perfil['cargo']?.toString() ?? '';
          _frecuencia             = perfil['frecuencia_pausas']?.toString() ?? 'Cada 60 min';
          _nivelActividad         = perfil['nivel_actividad']?.toString() ?? 'Moderado';
          _notificaciones         = perfil['notificaciones'] as bool? ?? true;
        });
      }
    } else {
      setState(() => _errorCarga = meRes.errorMessage);
    }

    if (mounted) setState(() => _cargando = false);
  }

  void _rellenarControllers(Map<String, dynamic> user) {
    setState(() {
      _nombreController.text  = user['nombre']?.toString() ?? '';
      _emailController.text   = user['email']?.toString() ?? '';
      _edadController.text    = user['edad']?.toString() ?? '';
      _empresaController.text = user['empresa']?.toString() ?? '';
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    // Actualizar datos base del usuario (nombre, empresa)
    final meRes = await ApiService.updateMe({
      'nombre':  _nombreController.text.trim(),
      'empresa': _empresaController.text.trim(),
    });

    if (!mounted) return;

    if (!meRes.success) {
      setState(() => _guardando = false);
      _mostrarError(meRes.errorMessage);
      return;
    }

    final perfilRes = await ApiService.updatePerfil({
      'cargo':             _cargoController.text.trim(),
      'frecuencia_pausas': _frecuencia,
      'nivel_actividad':   _nivelActividad,
      'notificaciones':    _notificaciones,
    });

    if (!mounted) return;
    setState(() => _guardando = false);

    if (perfilRes.success) {
      // Actualizar caché con datos nuevos
      final updatedUser = meRes.data;
      await ApiService.saveUser(updatedUser);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Perfil actualizado correctamente'),
          ]),
          backgroundColor: _purple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      _mostrarError(perfilRes.errorMessage);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: const Color(0xFFDC3545),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        title: const Text('Perfil de Usuario',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        actions: [
          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: _cargando && _nombreController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorCarga != null && _nombreController.text.isEmpty
              ? _buildError()
              : _buildForm(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded,
              size: 56, color: Color(0xFFDC3545)),
          const SizedBox(height: 16),
          Text(_errorCarga!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _cargarDatosUsuario,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            style: FilledButton.styleFrom(backgroundColor: _purple),
          ),
        ]),
      ),
    );
  }


  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Avatar ──
            Center(
              child: Stack(children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: _purple.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _purple.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 48, color: _purple),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: _purple, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Datos personales ──
            _SectionTitle(
                title: 'Datos personales',
                icon: Icons.person_outline_rounded,
                color: _purple),
            const SizedBox(height: 12),

            _FormCard(child: Column(children: [
              _Campo(
                label: 'Nombre completo',
                controller: _nombreController,
                icon: Icons.person_outline_rounded,
                validator: (v) => v!.trim().isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 14),
              _Campo(
                label: 'Correo electrónico',
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: false, // el email no se puede cambiar
                validator: (v) {
                  if (v!.isEmpty) return 'Campo requerido';
                  if (!v.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _Campo(
                label: 'Edad',
                controller: _edadController,
                icon: Icons.cake_outlined,
                enabled: false, // calculada desde fecha de nacimiento
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
              ),
            ])),

            const SizedBox(height: 16),

            // ── Datos laborales ──
            _SectionTitle(
                title: 'Datos laborales',
                icon: Icons.work_outline_rounded,
                color: _primary),
            const SizedBox(height: 12),

            _FormCard(child: Column(children: [
              _Campo(
                label: 'Cargo',
                controller: _cargoController,
                icon: Icons.badge_outlined,
                validator: (v) => null, // opcional
              ),
              const SizedBox(height: 14),
              _Campo(
                label: 'Empresa',
                controller: _empresaController,
                icon: Icons.business_outlined,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Campo requerido' : null,
              ),
            ])),

            const SizedBox(height: 16),

            // ── Preferencias ──
            _SectionTitle(
                title: 'Preferencias',
                icon: Icons.settings_outlined,
                color: const Color(0xFF198754)),
            const SizedBox(height: 12),

            _FormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Frecuencia de pausas
                  const Text('Frecuencia de pausas',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _frecuencias.map((f) {
                      final sel = f == _frecuencia;
                      return GestureDetector(
                        onTap: () => setState(() => _frecuencia = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? _primary : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel ? _primary : Colors.grey.shade300),
                          ),
                          child: Text(f,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : Colors.grey.shade700)),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  const Text('Nivel de actividad física',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 10),
                  Row(
                    children: _nivelesActividad.map((n) {
                      final sel = n == _nivelActividad;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _nivelActividad = n),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 6),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFF198754)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: sel
                                      ? const Color(0xFF198754)
                                      : Colors.grey.shade300),
                            ),
                            child: Text(n,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? Colors.white
                                        : Colors.grey.shade600)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Notificaciones
                  Row(children: [
                    const Icon(Icons.notifications_outlined,
                        size: 20, color: Color(0xFF1A1A2E)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Notificaciones',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            Text('Recibir alertas de pausa activa',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ]),
                    ),
                    Switch(
                      value: _notificaciones,
                      activeColor: _primary,
                      onChanged: (v) =>
                          setState(() => _notificaciones = v),
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Botón guardar ──
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: _guardando
                  ? const SizedBox(
                      height: 22, width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Text('Guardar perfil'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}


class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionTitle(
      {required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;

  const _Campo({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E))),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        enabled: enabled,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF8B5CF6), width: 2)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    ]);
  }
}
