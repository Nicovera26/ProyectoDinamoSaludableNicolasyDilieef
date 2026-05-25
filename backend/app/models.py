from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.utils import timezone


class UsuarioManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("El correo electrónico es obligatorio.")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("nombre", "Admin")
        extra_fields.setdefault("fecha_nacimiento", timezone.now().date())
        extra_fields.setdefault("peso", 70.0)
        extra_fields.setdefault("empresa", "Admin")
        return self.create_user(email, password, **extra_fields)


class Usuario(AbstractBaseUser, PermissionsMixin):
    email            = models.EmailField(unique=True)
    nombre           = models.CharField(max_length=150)
    fecha_nacimiento = models.DateField()
    peso             = models.FloatField(validators=[MinValueValidator(20), MaxValueValidator(300)])
    empresa          = models.CharField(max_length=200)

    is_active   = models.BooleanField(default=True)
    is_staff    = models.BooleanField(default=False)
    date_joined = models.DateTimeField(default=timezone.now)

    objects = UsuarioManager()

    USERNAME_FIELD  = "email"
    REQUIRED_FIELDS = []

    class Meta:
        verbose_name        = "Usuario"
        verbose_name_plural = "Usuarios"
        ordering            = ["-date_joined"]

    def __str__(self):
        return f"{self.nombre} <{self.email}>"

    @property
    def edad(self):
        hoy  = timezone.now().date()
        edad = hoy.year - self.fecha_nacimiento.year
        if (hoy.month, hoy.day) < (self.fecha_nacimiento.month, self.fecha_nacimiento.day):
            edad -= 1
        return edad


class FRECUENCIA(models.TextChoices):
    MIN_30 = "Cada 30 min", "Cada 30 min"
    MIN_45 = "Cada 45 min", "Cada 45 min"
    MIN_60 = "Cada 60 min", "Cada 60 min"
    MIN_90 = "Cada 90 min", "Cada 90 min"


class NIVEL_ACTIVIDAD(models.TextChoices):
    SEDENTARIO = "Sedentario", "Sedentario"
    LIGERO     = "Ligero",     "Ligero"
    MODERADO   = "Moderado",   "Moderado"
    ACTIVO     = "Activo",     "Activo"


class PerfilUsuario(models.Model):
    usuario = models.OneToOneField(
        Usuario, on_delete=models.CASCADE, related_name="perfil"
    )
    cargo             = models.CharField(max_length=150, blank=True, default="")
    frecuencia_pausas = models.CharField(
        max_length=20, choices=FRECUENCIA.choices, default=FRECUENCIA.MIN_60
    )
    nivel_actividad   = models.CharField(
        max_length=20, choices=NIVEL_ACTIVIDAD.choices, default=NIVEL_ACTIVIDAD.MODERADO
    )
    notificaciones    = models.BooleanField(default=True)
    updated_at        = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name        = "Perfil de usuario"
        verbose_name_plural = "Perfiles de usuario"

    def __str__(self):
        return f"Perfil de {self.usuario.nombre}"



class NIVEL_ENERGIA(models.TextChoices):
    MUY_BAJO  = "Muy bajo",  "Muy bajo"
    BAJO      = "Bajo",      "Bajo"
    NORMAL    = "Normal",    "Normal"
    BUENO     = "Bueno",     "Bueno"
    EXCELENTE = "Excelente", "Excelente"


class NIVEL_DOLOR(models.TextChoices):
    NINGUNO  = "Ninguno",  "Ninguno"
    LEVE     = "Leve",     "Leve"
    MODERADO = "Moderado", "Moderado"
    FUERTE   = "Fuerte",   "Fuerte"


class ReporteSesion(models.Model):
    usuario         = models.ForeignKey(
        Usuario, on_delete=models.CASCADE, related_name="reportes"
    )
    completo_rutina = models.BooleanField(default=True)
    nivel_energia   = models.CharField(
        max_length=20, choices=NIVEL_ENERGIA.choices, default=NIVEL_ENERGIA.BUENO
    )
    dolor           = models.CharField(
        max_length=20, choices=NIVEL_DOLOR.choices, default=NIVEL_DOLOR.NINGUNO
    )
    satisfaccion    = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)], default=4
    )
    notas           = models.TextField(blank=True, default="")
    fecha           = models.DateTimeField(default=timezone.now)

    class Meta:
        verbose_name        = "Reporte de sesión"
        verbose_name_plural = "Reportes de sesión"
        ordering            = ["-fecha"]

    def __str__(self):
        return f"Reporte {self.fecha.date()} — {self.usuario.nombre}"


class Ejercicio(models.Model):
    """
    Ejercicio personalizado por usuario.
    Cada usuario gestiona su propia lista desde Flutter.
    """
    ICONOS = [
        ('accessibility_new',    'Estiramiento'),
        ('rotate_right',         'Rotación'),
        ('self_improvement',     'Relajación'),
        ('directions_walk',      'Caminata'),
        ('pan_tool',             'Muñecas'),
        ('fitness_center',       'Fuerza'),
        ('sports_gymnastics',    'Gimnasia'),
        ('airline_seat_recline', 'Postura'),
        ('favorite',             'Bienestar'),
        ('psychology',           'Mental'),
    ]

    usuario     = models.ForeignKey(
        Usuario, on_delete=models.CASCADE, related_name='ejercicios'
    )
    nombre      = models.CharField(max_length=150)
    descripcion = models.TextField()
    duracion    = models.PositiveSmallIntegerField(help_text='Duración en minutos')
    icono       = models.CharField(max_length=50, choices=ICONOS, default='accessibility_new')
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name        = 'Ejercicio'
        verbose_name_plural = 'Ejercicios'
        ordering            = ['-created_at']

    def __str__(self):
        return f'{self.nombre} — {self.usuario.nombre}'
