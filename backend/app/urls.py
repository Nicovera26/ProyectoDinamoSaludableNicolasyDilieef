from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    LoginView, LogoutView, MeView, PerfilView,
    RegisterView, ReporteDetailView, ReporteListCreateView,
    EjercicioListCreateView, EjercicioDetailView,
)

urlpatterns = [
    # Auth
    path('auth/register/',      RegisterView.as_view(),    name='auth-register'),
    path('auth/login/',         LoginView.as_view(),        name='auth-login'),
    path('auth/logout/',        LogoutView.as_view(),       name='auth-logout'),
    path('auth/me/',            MeView.as_view(),           name='auth-me'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),

    # Perfil
    path('perfil/',             PerfilView.as_view(),       name='perfil'),

    # Reportes
    path('reportes/',           ReporteListCreateView.as_view(),  name='reportes-list'),
    path('reportes/<int:pk>/',  ReporteDetailView.as_view(),      name='reportes-detail'),

    # Ejercicios personalizados
    path('ejercicios/',         EjercicioListCreateView.as_view(), name='ejercicios-list'),
    path('ejercicios/<int:pk>/',EjercicioDetailView.as_view(),     name='ejercicios-detail'),
]
