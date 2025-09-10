# Modèles pour l'app appointments
# Système de prise de rendez-vous

from django.db import models
from django.conf import settings
from users.models import Professional, Client

class Appointment(models.Model):
    """Rendez-vous planifié entre un client et un professionnel."""

    STATUS_CHOICES = (
        ("pending", "En attente"),
        ("confirmed", "Confirmé"),
        ("cancelled", "Annulé"),
        ("completed", "Terminé"),
    )

    professional = models.ForeignKey(Professional, on_delete=models.CASCADE, related_name="appointments")
    client = models.ForeignKey(Client, on_delete=models.SET_NULL, null=True, blank=True, related_name="appointments")
    service_name = models.CharField(max_length=255)
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    start = models.DateTimeField()
    end = models.DateTimeField()
    status = models.CharField(max_length=16, choices=STATUS_CHOICES, default="pending")
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=["professional", "start"]),
            models.Index(fields=["professional", "status"]),
        ]

    def __str__(self):
        return f"Appt {self.service_name} {self.start} - {self.professional_id}"


class Notification(models.Model):
    """Notification simple à destination d'un professionnel."""

    professional = models.ForeignKey(Professional, on_delete=models.CASCADE, related_name="notifications")
    title = models.CharField(max_length=255)
    body = models.TextField(blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Notif {self.title} -> {self.professional_id}"
