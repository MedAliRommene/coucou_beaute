from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.conf import settings
from django.utils import timezone
from threading import Thread
import logging

from .models import Appointment, Notification

logger = logging.getLogger(__name__)

def send_email_async(subject, message, from_email, recipient_list, html_message=None):
    """Send email in a separate thread to avoid blocking"""
    def send():
        try:
            send_mail(
                subject=subject,
                message=message,
                from_email=from_email,
                recipient_list=recipient_list,
                html_message=html_message,
                fail_silently=False
            )
            logger.info(f"Email sent successfully to {recipient_list}")
        except Exception as e:
            logger.error(f"Failed to send email to {recipient_list}: {str(e)}")
    
    Thread(target=send).start()

@receiver(post_save, sender=Appointment)
def appointment_created_handler(sender, instance, created, **kwargs):
    """Handle appointment creation"""
    if created:
        # Create notification for professional with detailed client info
        client_info = "Client"
        client_contact = ""
        if instance.client and instance.client.user:
            client_info = instance.client.user.get_full_name() or instance.client.user.username
            client_contact = f" ({instance.client.user.email})"
            if hasattr(instance.client, 'phone_number') and instance.client.phone_number:
                client_contact += f" - Tél: {instance.client.phone_number}"
        
        Notification.objects.create(
            professional=instance.professional,
            title="Nouvelle demande de rendez-vous",
            body=f"Demande de {client_info}{client_contact} pour le {instance.start.strftime('%d/%m/%Y à %H:%M')} - Service: {instance.service_name} ({instance.price} DT)"
        )
        
        # Send email notification to professional
        if instance.professional.user.email:
            subject = "Nouvelle demande de rendez-vous - Coucou Beauté"
            context = {
                'professional': instance.professional,
                'appointment': instance,
                'client_name': instance.client.user.get_full_name() if instance.client else 'Client',
                'service': instance.service_name,
                'date': instance.start.strftime('%d/%m/%Y'),
                'time': instance.start.strftime('%H:%M'),
                'site_url': getattr(settings, 'SITE_URL', 'http://127.0.0.1:8000')
            }
            
            html_message = render_to_string('appointments/emails/new_appointment_request.html', context)
            plain_message = f"""
Bonjour {instance.professional.user.get_full_name()},

Vous avez reçu une nouvelle demande de rendez-vous :

Client: {context['client_name']}
Service: {instance.service_name}
Date: {context['date']} à {context['time']}
Prix: {instance.price} DT

Connectez-vous à votre dashboard pour accepter ou refuser cette demande.

Cordialement,
L'équipe Coucou Beauté
            """
            
            send_email_async(
                subject=subject,
                message=plain_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[instance.professional.user.email],
                html_message=html_message
            )

@receiver(pre_save, sender=Appointment)
def appointment_status_changed_handler(sender, instance, **kwargs):
    """Handle appointment status changes"""
    if instance.pk:  # Only for existing appointments
        try:
            old_instance = Appointment.objects.get(pk=instance.pk)
            
            # Check if status changed
            if old_instance.status != instance.status:
                
                if instance.status == 'confirmed':
                    # Appointment confirmed by professional
                    
                    # Create notification for professional (confirmation feedback)
                    Notification.objects.create(
                        professional=instance.professional,
                        title="Rendez-vous confirmé",
                        body=f"Vous avez confirmé le rendez-vous avec {instance.client.user.get_full_name() if instance.client else 'Client'} pour le {instance.start.strftime('%d/%m/%Y à %H:%M')} - Service: {instance.service_name}"
                    )
                    
                    # Create notification for client (will need separate view to display this)
                    if instance.client:
                        # For now, create in professional's notification but we'll expand this later
                        pass
                    
                    # Send confirmation email to client
                    if instance.client and instance.client.user.email:
                        subject = "Confirmation de rendez-vous - Coucou Beauté"
                        context = {
                            'client': instance.client,
                            'appointment': instance,
                            'professional': instance.professional,
                            'service': instance.service_name,
                            'date': instance.start.strftime('%d/%m/%Y'),
                            'time': instance.start.strftime('%H:%M'),
                            'site_url': getattr(settings, 'SITE_URL', 'http://127.0.0.1:8000')
                        }
                        
                        html_message = render_to_string('appointments/emails/appointment_confirmed.html', context)
                        plain_message = f"""
Bonjour {instance.client.user.get_full_name()},

Votre rendez-vous a été confirmé !

Professionnel: {instance.professional.user.get_full_name()}
Service: {instance.service_name}
Date: {context['date']} à {context['time']}
Prix: {instance.price} DT
Adresse: {instance.professional.extra.address if instance.professional.extra else 'À confirmer'}

Nous vous rappelons de vous présenter à l'heure.

Cordialement,
L'équipe Coucou Beauté
                        """
                        
                        send_email_async(
                            subject=subject,
                            message=plain_message,
                            from_email=settings.DEFAULT_FROM_EMAIL,
                            recipient_list=[instance.client.user.email],
                            html_message=html_message
                        )
                
                elif instance.status == 'cancelled':
                    # Appointment cancelled
                    
                    # Determine who cancelled (professional or client)
                    canceller = "le professionnel" if hasattr(instance, '_cancelled_by_pro') else "vous"
                    
                    # Create notification for the other party
                    if instance.client:
                        Notification.objects.create(
                            professional=instance.professional,
                            title="Rendez-vous annulé",
                            body=f"Le rendez-vous du {instance.start.strftime('%d/%m/%Y à %H:%M')} a été annulé par {canceller} - Service: {instance.service_name}"
                        )
                    
                    # Send cancellation email
                    email_recipient = None
                    recipient_name = ""
                    
                    if hasattr(instance, '_cancelled_by_pro') and instance.client:
                        # Professional cancelled, notify client
                        email_recipient = instance.client.user.email
                        recipient_name = instance.client.user.get_full_name()
                    elif instance.professional.user.email:
                        # Client cancelled, notify professional
                        email_recipient = instance.professional.user.email
                        recipient_name = instance.professional.user.get_full_name()
                    
                    if email_recipient:
                        subject = "Annulation de rendez-vous - Coucou Beauté"
                        plain_message = f"""
Bonjour {recipient_name},

Le rendez-vous suivant a été annulé :

Date: {instance.start.strftime('%d/%m/%Y à %H:%M')}
Service: {instance.service_name}

N'hésitez pas à reprendre un nouveau rendez-vous si nécessaire.

Cordialement,
L'équipe Coucou Beauté
                        """
                        
                        send_email_async(
                            subject=subject,
                            message=plain_message,
                            from_email=settings.DEFAULT_FROM_EMAIL,
                            recipient_list=[email_recipient]
                        )
                        
        except Appointment.DoesNotExist:
            pass  # New appointment
        except Exception as e:
            logger.error(f"Error in appointment status change handler: {str(e)}")
