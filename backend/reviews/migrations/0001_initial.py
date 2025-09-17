# Generated manually

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import django.core.validators


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('users', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Review',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('rating', models.PositiveIntegerField(choices=[(1, '1 étoile'), (2, '2 étoiles'), (3, '3 étoiles'), (4, '4 étoiles'), (5, '5 étoiles')], validators=[django.core.validators.MinValueValidator(1), django.core.validators.MaxValueValidator(5)], verbose_name='Note')),
                ('comment', models.TextField(blank=True, max_length=1000, null=True, verbose_name='Commentaire')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Date de création')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Date de modification')),
                ('is_verified', models.BooleanField(default=False, verbose_name='Avis vérifié')),
                ('is_public', models.BooleanField(default=True, verbose_name='Public')),
                ('client', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='reviews_given', to=settings.AUTH_USER_MODEL, verbose_name='Client')),
                ('professional', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='reviews_received', to='users.professional', verbose_name='Professionnel')),
            ],
            options={
                'verbose_name': 'Avis',
                'verbose_name_plural': 'Avis',
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='ReviewImage',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('image', models.ImageField(upload_to='reviews/images/%Y/%m/%d/', verbose_name='Image')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Date de création')),
                ('review', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='images', to='reviews.review', verbose_name='Avis')),
            ],
            options={
                'verbose_name': 'Image d\'avis',
                'verbose_name_plural': 'Images d\'avis',
            },
        ),
        migrations.AlterUniqueTogether(
            name='review',
            unique_together={('client', 'professional')},
        ),
    ]