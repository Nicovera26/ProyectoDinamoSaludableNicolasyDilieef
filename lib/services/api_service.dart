
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl    = 'https://proyectodinamosaludablenicolasydilieef.onrender.com/api';
  static const String _keyAccess  = 'jwt_access';
  static const String _keyRefresh = 'jwt_refresh';
  static const String _keyUser    = 'user_data';
  static const _timeout = Duration(seconds: 10);


  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccess,  access);
    await prefs.setString(_keyRefresh, refresh);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccess);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefresh);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccess);
    await prefs.remove(_keyRefresh);
    await prefs.remove(_keyUser);
  }

  static Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }


  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }


  static Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }


  static Future<bool> _refreshToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      ).timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await saveTokens(data['access'], data['refresh'] ?? refresh);
        return true;
      }
    } catch (_) {}
    return false;
  }


  static Future<http.Response> _authedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var headers = await _authHeaders();
    var res = await request(headers);
    if (res.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        headers = await _authHeaders();
        res = await request(headers);
      }
    }
    return res;
  }


  static Future<ApiResponse> register({
    required String nombre,
    required String email,
    required String password,
    required String confirmPassword,
    required DateTime fechaNacimiento,
    required double peso,
    required String empresa,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre':           nombre.trim(),
          'email':            email.trim().toLowerCase(),
          'password':         password,
          'confirm_password': confirmPassword,
          'fecha_nacimiento': _formatDate(fechaNacimiento),
          'peso':             peso,
          'empresa':          empresa.trim(),
        }),
      ).timeout(_timeout);
      return _parse(res);
    } catch (e) {
      return _connectionError(e);
    }
  }

  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email':    email.trim().toLowerCase(),
          'password': password,
        }),
      ).timeout(_timeout);
      return _parse(res);
    } catch (e) {
      return _connectionError(e);
    }
  }

  static Future<ApiResponse> logout() async {
    try {
      final refresh = await getRefreshToken();
      final res = await _authedRequest(
        (h) => http.post(
          Uri.parse('$_baseUrl/auth/logout/'),
          headers: h,
          body: jsonEncode({'refresh': refresh}),
        ).timeout(_timeout),
      );
      await clearSession();
      return _parse(res);
    } catch (_) {
      await clearSession();
      return ApiResponse(
        success: true, statusCode: 200,
        data: {'message': 'Sesión cerrada.'},
      );
    }
  }

  static Future<ApiResponse> getMe() async {
    try {
      final res = await _authedRequest(
        (h) => http.get(
          Uri.parse('$_baseUrl/auth/me/'),
          headers: h,
        ).timeout(_timeout),
      );
      return _parse(res);
    } catch (e) {
      return _connectionError(e);
    }
  }

  /// Actualiza datos base del usuario (nombre, empresa)
  static Future<ApiResponse> updateMe(Map<String, dynamic> data) async {
    try {
      final res = await _authedRequest(
        (h) => http.patch(
          Uri.parse('$_baseUrl/auth/me/'),
          headers: h,
          body: jsonEncode(data),
        ).timeout(_timeout),
      );
      return _parse(res);
    } catch (e) {
      return _connectionError(e);
    }
  }


  static Future<ApiResponse> getPerfil() async {
    try {
      final res = await _authedRequest(
        (h) => http.get(
          Uri.parse('$_baseUrl/perfil/'),
          headers: h,
        ).timeout(_timeout),
      );
      return _parse(res);
    } catch (e) {
      return _connectionError(e);
    }
  }

  static Future<ApiResponse> updatePerfil(Map<String, dynamic> data) async {
    try {
      final res = await _authedRequest(
        (h) => http.patch(
          Uri.parse('$_baseUrl/perfil/'),
          headers: h,
          body: jsonEncode(data),
        ).timeout(_timeout),
      );
      return _parse(res);
    } catch (e) {
      return _connectionError(e);
    }
  }



  static Future<ApiResponse> getReportes() async {
    try {
      final res = await _authedRequest(
        (h) => http.get(
          Uri.parse('$_baseUrl/reportes/'),
          headers: h,
        ).timeout(_timeout),
      );
      return _parse(res);
    } catch (e) {
      return _connectionError(e);
    }
  }

  static Future<ApiResponse> crearReporte({
    required bool completoRutina,
    required String nivelEnergia,
    required String dolor,
    required int satisfaccion,
    String notas = '',
  }) async {
    try {
      final res = await _authedRequest(
        (h) => http.post(
          Uri.parse('$_baseUrl/reportes/'),
          headers: h,
          body: jsonEncode({
            'completo_rutina': completoRutina,
            'nivel_energia':   nivelEnergia,
            'dolor':           dolor,
            'satisfaccion':    satisfaccion,
            'notas':           notas,
          }),
        ).timeout(_timeout),
      );
      return _parse(res);
    } catch (e) {
      return _connectionError(e);
    }
  }


  static Future<ApiResponse> getEjercicios() async {
    try {
      final res = await _authedRequest(
        (h) => http.get(
          Uri.parse('$_baseUrl/ejercicios/'),
          headers: h,
        ).timeout(_timeout),
      );
      final body = jsonDecode(res.body);
      final ok   = res.statusCode >= 200 && res.statusCode < 300;
      if (body is List) {
        return ApiResponse(
          success: ok, statusCode: res.statusCode,
          data: {'ejercicios': body},
        );
      }
      return ApiResponse(
        success: ok, statusCode: res.statusCode,
        data: body as Map<String, dynamic>,
      );
    } catch (e) {
      return _connectionError(e);
    }
  }

  static Future<ApiResponse> crearEjercicio({
    required String nombre,
    required String descripcion,
    required int duracion,
    required String icono,
  }) async {
    try {
      final res = await _authedRequest(
        (h) => http.post(
          Uri.parse('$_baseUrl/ejercicios/'),
          headers: h,
          body: jsonEncode({
            'nombre':      nombre,
            'descripcion': descripcion,
            'duracion':    duracion,
            'icono':       icono,
          }),
        ).timeout(_timeout),
      );
      return _parse(res);
    } catch (e) {
      return _connectionError(e);
    }
  }

  static Future<ApiResponse> editarEjercicio(
      int id, Map<String, dynamic> data) async {
    try {
      final res = await _authedRequest(
        (h) => http.patch(
          Uri.parse('$_baseUrl/ejercicios/$id/'),
          headers: h,
          body: jsonEncode(data),
        ).timeout(_timeout),
      );
      return _parse(res);
    } catch (e) {
      return _connectionError(e);
    }
  }

  static Future<ApiResponse> eliminarEjercicio(int id) async {
    try {
      final res = await _authedRequest(
        (h) => http.delete(
          Uri.parse('$_baseUrl/ejercicios/$id/'),
          headers: h,
        ).timeout(_timeout),
      );
      if (res.statusCode == 204) {
        return ApiResponse(
          success: true, statusCode: 204,
          data: {'message': 'Eliminado.'},
        );
      }
      return _parse(res);
    } catch (e) {
      return _connectionError(e);
    }
  }


  static Future<ApiResponse> enviarContacto({
    required String nombre,
    required String email,
    required String mensaje,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/contacto/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre':  nombre.trim(),
          'email':   email.trim().toLowerCase(),
          'mensaje': mensaje.trim(),
        }),
      ).timeout(_timeout);
      return _parse(res);
    } catch (e) {
      return _connectionError(e);
    }
  }


  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static ApiResponse _parse(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final ok   = res.statusCode >= 200 && res.statusCode < 300;
      return ApiResponse(success: ok, statusCode: res.statusCode, data: body);
    } catch (_) {
      return ApiResponse(
        success: false, statusCode: res.statusCode,
        data: {'error': 'Error inesperado del servidor.'},
      );
    }
  }

  static ApiResponse _connectionError(Object e) {
    String msg = 'No se pudo conectar al servidor.';
    if (e.toString().contains('TimeoutException')) {
      msg = 'El servidor tardó demasiado. Verifica que Django esté corriendo.';
    } else if (e.toString().contains('SocketException')) {
      msg = 'Sin conexión. Verifica que el servidor esté activo.';
    }
    return ApiResponse(success: false, statusCode: 0, data: {'error': msg});
  }
}


class ApiResponse {
  final bool success;
  final int statusCode;
  final Map<String, dynamic> data;

  ApiResponse({
    required this.success,
    required this.statusCode,
    required this.data,
  });

  String get errorMessage {
    if (data.containsKey('errors')) {
      final errors = data['errors'] as Map<String, dynamic>;
      for (final entry in errors.entries) {
        final val = entry.value;
        if (val is List && val.isNotEmpty) return val.first.toString();
        if (val is String) return val;
      }
    }
    return data['error']?.toString() ??
        data['detail']?.toString() ??
        data['message']?.toString() ??
        'Error desconocido.';
  }
}
