import re
from datetime import date

from django.contrib.auth import authenticate
from rest_framework import serializers

from .models import (
    FRECUENCIA, NIVEL_ACTIVIDAD, NIVEL_DOLOR, NIVEL_ENERGIA,
    Ejercicio, PerfilUsuario, ReporteSesion, Usuario,
)


# ── Helpers de validación (espejo de auth_bloc.dart) ─────────────────────────

def validar_nombre(value):
    value = value.strip()
    if len(value) < 3:
        raise serializers.ValidationError("Nombre muy corto (mínimo 3 caracteres).")
    if not re.match(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$', value):
        raise serializers.ValidationError("Solo se permiten letras.")
    return value


def validar_password_strength(value):
    if len(value) < 6:
        raise serializers.ValidationError("Mínimo 6 caracteres.")
    if not re.search(r'[A-Z]', value):
        raise serializers.ValidationError("Debe incluir al menos una mayúscula.")
    if not re.search(r'\d', value):
        raise serializers.ValidationError("Debe incluir al menos un número.")
    return value


def calcular_edad(fecha_nacimiento: date) -> int:
    hoy  = date.today()
    edad = hoy.year - fecha_nacimiento.year
    if (hoy.month, hoy.day) < (fecha_nacimiento.month, fecha_nacimiento.day):
        edad -= 1
    return edad


# ── Register ──────────────────────────────────────────────────────────────────

class RegisterSerializer(serializers.ModelSerializer):
    password         = serializers.CharField(write_only=True, min_length=6)
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        model  = Usuario
        fields = ["nombre", "fecha_nacimiento", "peso", "empresa",
                  "email", "password", "confirm_password"]

    def validate_nombre(self, value):
        return validar_nombre(value)

    def validate_password(self, value):
        return validar_password_strength(value)

    def validate_peso(self, value):
        if value < 20 or value > 300:
            raise serializers.ValidationError("Peso inválido (20–300 kg).")
        return value

    def validate_fecha_nacimiento(self, value):
        edad = calcular_edad(value)
        if edad < 5 or edad > 110:
            raise serializers.ValidationError("Edad inválida (5–110 años).")
        return value

    def validate(self, attrs):
        if attrs["password"] != attrs["confirm_password"]:
            raise serializers.ValidationError(
                {"confirm_password": "Las contraseñas no coinciden."})
        return attrs

    def create(self, validated_data):
        validated_data.pop("confirm_password")
        password = validated_data.pop("password")
        user = Usuario(**validated_data)
        user.set_password(password)
        user.save()
        # Crear perfil extendido automáticamente
        PerfilUsuario.objects.create(usuario=user)
        return user


# ── Login ─────────────────────────────────────────────────────────────────────

class LoginSerializer(serializers.Serializer):
    email    = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        email = attrs.get("email", "").strip().lower()
        user  = authenticate(username=email, password=attrs.get("password", ""))
        if user is None:
            raise serializers.ValidationError("Correo o contraseña incorrectos.")
        if not user.is_active:
            raise serializers.ValidationError("Esta cuenta está desactivada.")
        attrs["user"] = user
        return attrs


# ── Perfil extendido (perfil_form.dart) ──────────────────────────────────────

class PerfilUsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model  = PerfilUsuario
        fields = ["cargo", "frecuencia_pausas", "nivel_actividad", "notificaciones", "updated_at"]
        read_only_fields = ["updated_at"]

    def validate_frecuencia_pausas(self, value):
        opciones = [c[0] for c in FRECUENCIA.choices]
        if value not in opciones:
            raise serializers.ValidationError(f"Opciones válidas: {opciones}")
        return value

    def validate_nivel_actividad(self, value):
        opciones = [c[0] for c in NIVEL_ACTIVIDAD.choices]
        if value not in opciones:
            raise serializers.ValidationError(f"Opciones válidas: {opciones}")
        return value


# ── Usuario completo (GET /me) ────────────────────────────────────────────────

class UsuarioSerializer(serializers.ModelSerializer):
    edad   = serializers.IntegerField(read_only=True)
    perfil = PerfilUsuarioSerializer(read_only=True)

    class Meta:
        model  = Usuario
        fields = ["id", "email", "nombre", "fecha_nacimiento", "edad",
                  "peso", "empresa", "perfil", "date_joined"]
        read_only_fields = ["id", "email", "date_joined", "edad"]


# ── Reporte de sesión (reporte_form.dart) ─────────────────────────────────────

class ReporteSesionSerializer(serializers.ModelSerializer):
    usuario = serializers.StringRelatedField(read_only=True)

    class Meta:
        model  = ReporteSesion
        fields = ["id", "usuario", "completo_rutina", "nivel_energia",
                  "dolor", "satisfaccion", "notas", "fecha"]
        read_only_fields = ["id", "usuario", "fecha"]

    def validate_nivel_energia(self, value):
        opciones = [c[0] for c in NIVEL_ENERGIA.choices]
        if value not in opciones:
            raise serializers.ValidationError(f"Opciones válidas: {opciones}")
        return value

    def validate_dolor(self, value):
        opciones = [c[0] for c in NIVEL_DOLOR.choices]
        if value not in opciones:
            raise serializers.ValidationError(f"Opciones válidas: {opciones}")
        return value

    def validate_satisfaccion(self, value):
        if not (1 <= value <= 5):
            raise serializers.ValidationError("La satisfacción debe estar entre 1 y 5.")
        return value

    def create(self, validated_data):
        # El usuario viene del contexto (request.user), no del body
        validated_data["usuario"] = self.context["request"].user
        return super().create(validated_data)


# ── Ejercicio personalizado ───────────────────────────────────────────────────

class EjercicioSerializer(serializers.ModelSerializer):
    usuario = serializers.StringRelatedField(read_only=True)

    class Meta:
        model  = Ejercicio
        fields = ['id', 'usuario', 'nombre', 'descripcion', 'duracion', 'icono', 'created_at', 'updated_at']
        read_only_fields = ['id', 'usuario', 'created_at', 'updated_at']

    def validate_nombre(self, value):
        if len(value.strip()) < 3:
            raise serializers.ValidationError('El nombre debe tener al menos 3 caracteres.')
        return value.strip()

    def validate_duracion(self, value):
        if value < 1 or value > 120:
            raise serializers.ValidationError('La duración debe estar entre 1 y 120 minutos.')
        return value

    def create(self, validated_data):
        validated_data['usuario'] = self.context['request'].user
        return super().create(validated_data)
