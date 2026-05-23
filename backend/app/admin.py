from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import PerfilUsuario, ReporteSesion, Usuario


@admin.register(Usuario)
class UsuarioAdmin(BaseUserAdmin):
    list_display  = ["email", "nombre", "empresa", "edad", "is_active", "date_joined"]
    search_fields = ["email", "nombre", "empresa"]
    ordering      = ["-date_joined"]
    fieldsets = (
        (None,           {"fields": ("email", "password")}),
        ("Datos personales", {"fields": ("nombre", "fecha_nacimiento", "peso", "empresa")}),
        ("Permisos",     {"fields": ("is_active", "is_staff", "is_superuser", "groups")}),
    )
    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields":  ("email", "nombre", "fecha_nacimiento", "peso",
                        "empresa", "password1", "password2"),
        }),
    )


@admin.register(PerfilUsuario)
class PerfilAdmin(admin.ModelAdmin):
    list_display  = ["usuario", "cargo", "frecuencia_pausas", "nivel_actividad", "notificaciones"]
    search_fields = ["usuario__nombre", "usuario__email", "cargo"]


@admin.register(ReporteSesion)
class ReporteAdmin(admin.ModelAdmin):
    list_display  = ["usuario", "fecha", "nivel_energia", "dolor", "satisfaccion", "completo_rutina"]
    list_filter   = ["nivel_energia", "dolor", "completo_rutina"]
    search_fields = ["usuario__nombre", "usuario__email"]
    ordering      = ["-fecha"]
