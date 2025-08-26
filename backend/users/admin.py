from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin
from .models import User, Client, Professional


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    list_display = ("username", "email", "first_name", "last_name", "is_staff")
    search_fields = ("username", "email", "first_name", "last_name")
    ordering = ("username",)


@admin.register(Client)
class ClientAdmin(admin.ModelAdmin):
    list_display = ("user", "phone_number", "created_at")
    search_fields = ("user__username", "user__email")


@admin.register(Professional)
class ProfessionalAdmin(admin.ModelAdmin):
    list_display = ("user", "business_name", "is_verified", "created_at")
    list_filter = ("is_verified",)
    search_fields = ("user__username", "user__email", "business_name")
# TODO: Enregistrer les modèles pour users
