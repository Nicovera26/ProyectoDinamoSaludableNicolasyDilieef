from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import PerfilUsuario, ReporteSesion
from .models import Ejercicio, PerfilUsuario, ReporteSesion
from .serializers import (
    EjercicioSerializer, LoginSerializer, PerfilUsuarioSerializer,
    RegisterSerializer, ReporteSesionSerializer, UsuarioSerializer,
)


def _get_tokens(user):
    refresh = RefreshToken.for_user(user)
    return {"refresh": str(refresh), "access": str(refresh.access_token)}


# ── POST /api/auth/register/ ─────────────────────────────────────────────────

class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({"errors": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        user = serializer.save()
        return Response({
            "message": "Registro exitoso.",
            "user":    UsuarioSerializer(user).data,
            "tokens":  _get_tokens(user),
        }, status=status.HTTP_201_CREATED)


# ── POST /api/auth/login/ ────────────────────────────────────────────────────

class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({"errors": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        user = serializer.validated_data["user"]
        return Response({
            "message": "Inicio de sesión exitoso.",
            "user":    UsuarioSerializer(user).data,
            "tokens":  _get_tokens(user),
        }, status=status.HTTP_200_OK)


# ── POST /api/auth/logout/ ───────────────────────────────────────────────────

class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get("refresh")
        if not refresh_token:
            return Response({"error": "Se requiere el refresh token."}, status=status.HTTP_400_BAD_REQUEST)
        try:
            RefreshToken(refresh_token).blacklist()
            return Response({"message": "Sesión cerrada correctamente."}, status=status.HTTP_200_OK)
        except Exception:
            return Response({"error": "Token inválido o ya expirado."}, status=status.HTTP_400_BAD_REQUEST)


# ── GET | PATCH /api/auth/me/ ────────────────────────────────────────────────

class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UsuarioSerializer(request.user).data)

    def patch(self, request):
        """Actualiza nombre, peso, empresa del usuario base."""
        serializer = UsuarioSerializer(request.user, data=request.data, partial=True)
        if not serializer.is_valid():
            return Response({"errors": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response(serializer.data)


# ── GET | PATCH /api/perfil/ ─────────────────────────────────────────────────

class PerfilView(APIView):
    permission_classes = [IsAuthenticated]

    def _get_or_create_perfil(self, user):
        perfil, _ = PerfilUsuario.objects.get_or_create(usuario=user)
        return perfil

    def get(self, request):
        perfil = self._get_or_create_perfil(request.user)
        return Response(PerfilUsuarioSerializer(perfil).data)

    def patch(self, request):
        """
        Actualiza cargo, frecuencia_pausas, nivel_actividad, notificaciones.
        Espejo del botón 'Guardar perfil' en perfil_form.dart.
        """
        perfil = self._get_or_create_perfil(request.user)
        serializer = PerfilUsuarioSerializer(perfil, data=request.data, partial=True)
        if not serializer.is_valid():
            return Response({"errors": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response({
            "message": "Perfil actualizado correctamente.",
            "perfil":  serializer.data,
        })


# ── GET | POST /api/reportes/ ────────────────────────────────────────────────

class ReporteListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Lista todos los reportes del usuario autenticado."""
        reportes = ReporteSesion.objects.filter(usuario=request.user)
        serializer = ReporteSesionSerializer(reportes, many=True)
        return Response(serializer.data)

    def post(self, request):
        """
        Crea un nuevo reporte.
        Espejo del botón 'Guardar reporte' en reporte_form.dart.
        """
        serializer = ReporteSesionSerializer(
            data=request.data, context={"request": request}
        )
        if not serializer.is_valid():
            return Response({"errors": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        reporte = serializer.save()
        return Response({
            "message": "Reporte guardado correctamente.",
            "reporte": ReporteSesionSerializer(reporte).data,
        }, status=status.HTTP_201_CREATED)


# ── GET | DELETE /api/reportes/<id>/ ─────────────────────────────────────────

class ReporteDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def _get_reporte(self, pk, user):
        try:
            return ReporteSesion.objects.get(pk=pk, usuario=user)
        except ReporteSesion.DoesNotExist:
            return None

    def get(self, request, pk):
        reporte = self._get_reporte(pk, request.user)
        if not reporte:
            return Response({"error": "Reporte no encontrado."}, status=status.HTTP_404_NOT_FOUND)
        return Response(ReporteSesionSerializer(reporte).data)

    def delete(self, request, pk):
        reporte = self._get_reporte(pk, request.user)
        if not reporte:
            return Response({"error": "Reporte no encontrado."}, status=status.HTTP_404_NOT_FOUND)
        reporte.delete()
        return Response({"message": "Reporte eliminado."}, status=status.HTTP_204_NO_CONTENT)


# ── GET | POST /api/ejercicios/ ───────────────────────────────────────────────

class EjercicioListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Lista los ejercicios del usuario autenticado."""
        ejercicios = Ejercicio.objects.filter(usuario=request.user)
        return Response(EjercicioSerializer(ejercicios, many=True).data)

    def post(self, request):
        """Crea un nuevo ejercicio para el usuario autenticado."""
        serializer = EjercicioSerializer(data=request.data, context={'request': request})
        if not serializer.is_valid():
            return Response({'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        ejercicio = serializer.save()
        return Response({
            'message': 'Ejercicio creado correctamente.',
            'ejercicio': EjercicioSerializer(ejercicio).data,
        }, status=status.HTTP_201_CREATED)


# ── GET | PATCH | DELETE /api/ejercicios/<id>/ ────────────────────────────────

class EjercicioDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def _get_ejercicio(self, pk, user):
        try:
            return Ejercicio.objects.get(pk=pk, usuario=user)
        except Ejercicio.DoesNotExist:
            return None

    def get(self, request, pk):
        ejercicio = self._get_ejercicio(pk, request.user)
        if not ejercicio:
            return Response({'error': 'Ejercicio no encontrado.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(EjercicioSerializer(ejercicio).data)

    def patch(self, request, pk):
        """Edita nombre, descripción, duración o ícono del ejercicio."""
        ejercicio = self._get_ejercicio(pk, request.user)
        if not ejercicio:
            return Response({'error': 'Ejercicio no encontrado.'}, status=status.HTTP_404_NOT_FOUND)
        serializer = EjercicioSerializer(ejercicio, data=request.data, partial=True, context={'request': request})
        if not serializer.is_valid():
            return Response({'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response({
            'message': 'Ejercicio actualizado correctamente.',
            'ejercicio': serializer.data,
        })

    def delete(self, request, pk):
        ejercicio = self._get_ejercicio(pk, request.user)
        if not ejercicio:
            return Response({'error': 'Ejercicio no encontrado.'}, status=status.HTTP_404_NOT_FOUND)
        ejercicio.delete()
        return Response({'message': 'Ejercicio eliminado correctamente.'}, status=status.HTTP_204_NO_CONTENT)
