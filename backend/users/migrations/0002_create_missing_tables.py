from django.db import migrations


CREATE_PRO_APPLICATION = r"""
CREATE TABLE IF NOT EXISTS users_professionalapplication (
    id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(150) NOT NULL,
    last_name VARCHAR(150) NOT NULL,
    email VARCHAR(254) NOT NULL,
    phone_number VARCHAR(32) NOT NULL,
    activity_category VARCHAR(32) NOT NULL,
    service_type VARCHAR(16) NOT NULL,
    spoken_languages JSONB NOT NULL DEFAULT '[]'::jsonb,
    address TEXT NOT NULL,
    latitude DOUBLE PRECISION NULL,
    longitude DOUBLE PRECISION NULL,
    profile_photo VARCHAR(512) NOT NULL DEFAULT '',
    id_document VARCHAR(512) NOT NULL DEFAULT '',
    subscription_active BOOLEAN NOT NULL DEFAULT FALSE,
    is_processed BOOLEAN NOT NULL DEFAULT FALSE,
    is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    processed_at TIMESTAMP WITH TIME ZONE NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    processed_by_id BIGINT NULL REFERENCES users_user(id) ON DELETE SET NULL
);
"""

CREATE_CLIENT = r"""
CREATE TABLE IF NOT EXISTS users_client (
    id BIGSERIAL PRIMARY KEY,
    phone_number VARCHAR(32) NOT NULL DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    user_id BIGINT NOT NULL UNIQUE REFERENCES users_user(id) ON DELETE CASCADE
);
"""

CREATE_PROFESSIONAL = r"""
CREATE TABLE IF NOT EXISTS users_professional (
    id BIGSERIAL PRIMARY KEY,
    business_name VARCHAR(255) NOT NULL DEFAULT '',
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    user_id BIGINT NOT NULL UNIQUE REFERENCES users_user(id) ON DELETE CASCADE
);
"""


class Migration(migrations.Migration):
    dependencies = [
        ("users", "0001_initial"),
    ]

    operations = [
        migrations.RunSQL(CREATE_PRO_APPLICATION, reverse_sql="DROP TABLE IF EXISTS users_professionalapplication CASCADE;"),
        migrations.RunSQL(CREATE_CLIENT, reverse_sql="DROP TABLE IF EXISTS users_client CASCADE;"),
        migrations.RunSQL(CREATE_PROFESSIONAL, reverse_sql="DROP TABLE IF EXISTS users_professional CASCADE;"),
    ]


