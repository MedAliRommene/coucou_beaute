from datetime import datetime, timedelta

from django.utils.dateparse import parse_datetime
from django.db.models import Count
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from django.core.mail import send_mail
from django.conf import settings
import threading
from rest_framework import status
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.authentication import SessionAuthentication

from .models import Appointment, Notification
from django.utils import timezone as tz
from django.utils.dateparse import parse_date
from django.db.models import Count as DjangoCount


def _get_professional_from_user(user):
    return getattr(user, "professional_profile", None)


@api_view(["GET"])  # /api/appointments/agenda/?from=...&to=...
@permission_classes([IsAuthenticated])
@authentication_classes([JWTAuthentication])
def agenda(request):
    pro = _get_professional_from_user(request.user)
    if not pro:
        return Response({"detail": "Profil professionnel requis"}, status=status.HTTP_403_FORBIDDEN)
    start_str = request.query_params.get("from")
    end_str = request.query_params.get("to")
    qs = Appointment.objects.filter(professional=pro)
    if start_str:
        start_dt = parse_datetime(start_str)
        if start_dt:
            qs = qs.filter(start__gte=start_dt)
    if end_str:
        end_dt = parse_datetime(end_str)
        if end_dt:
            qs = qs.filter(end__lte=end_dt)
    qs = qs.order_by("start")[:500]
    data = []
    for a in qs:
        client_name = ""
        client_email = ""
        client_phone = ""
        try:
            if a.client is not None:
                user = getattr(a.client, "user", None)
                if user is not None:
                    client_name = (user.first_name or "").strip() + (" " + (user.last_name or "").strip() if (user.last_name or "").strip() else "")
                    client_email = user.email or ""
                client_phone = getattr(a.client, "phone_number", "") or ""
        except Exception:
            pass
        data.append({
            "id": a.id,
            "service_name": a.service_name,
            "price": float(a.price),
            "start": a.start.isoformat(),
            "end": a.end.isoformat(),
            "status": a.status,
            "client_name": client_name.strip(),
            "client_email": client_email,
            "client_phone": client_phone,
        })
    return Response({"results": data})


@api_view(["GET"])  # /api/appointments/agenda/day/?pro_id=&date=YYYY-MM-DD
@permission_classes([IsAuthenticated])
@authentication_classes([JWTAuthentication, SessionAuthentication])
def agenda_day(request):
    """Return all appointments for a given professional on a specific day.

    Intended for the admin dashboard daily calendar. Requires authentication
    (session auth for admin or JWT if used). Returns a flat list of events
    with client info and status.
    """
    pro_id = request.query_params.get("pro_id")
    date_str = request.query_params.get("date")
    if not pro_id or not date_str:
        return Response({"detail": "pro_id et date requis"}, status=status.HTTP_400_BAD_REQUEST)

    day = parse_date(date_str)
    if not day:
        return Response({"detail": "date invalide"}, status=status.HTTP_400_BAD_REQUEST)

    # Build day range [start, end)
    day_start_naive = datetime(day.year, day.month, day.day)
    day_start = tz.make_aware(day_start_naive, tz.get_current_timezone()) if tz.is_naive(day_start_naive) else day_start_naive
    day_end = day_start + timedelta(days=1)

    qs = (
        Appointment.objects.filter(
            professional_id=int(pro_id), start__lt=day_end, end__gt=day_start
        )
        .order_by("start")
    )

    data = []
    for a in qs:
        client_name = ""
        client_email = ""
        client_phone = ""
        try:
            if a.client is not None:
                user = getattr(a.client, "user", None)
                if user is not None:
                    client_name = (user.first_name or "").strip() + (
                        " " + (user.last_name or "").strip()
                        if (user.last_name or "").strip()
                        else ""
                    )
                    client_email = user.email or ""
                client_phone = getattr(a.client, "phone_number", "") or ""
        except Exception:
            pass
        data.append(
            {
                "id": a.id,
                "service_name": a.service_name,
                "price": float(a.price),
                "start": a.start.isoformat(),
                "end": a.end.isoformat(),
                "status": a.status,
                "client_name": client_name.strip(),
                "client_email": client_email,
                "client_phone": client_phone,
            }
        )

    return Response({"results": data})


@api_view(["GET"])  # /api/appointments/analytics/overview/?pro_id=&from=&to=
@permission_classes([IsAuthenticated])
@authentication_classes([JWTAuthentication, SessionAuthentication])
def analytics_overview(request):
    """Return lightweight analytics for a professional: weekly reservations and service distribution.

    - Optional query params `from` and `to` (ISO date YYYY-MM-DD). Defaults to last 7 days.
    - Returns counts by weekday (Mon..Sun) and service_name distribution (last 90 days if no range).
    """
    pro_id = request.query_params.get("pro_id")
    if not pro_id:
        return Response({"detail": "pro_id requis"}, status=status.HTTP_400_BAD_REQUEST)

    # Date range
    from_str = request.query_params.get("from")
    to_str = request.query_params.get("to")
    if from_str:
        d_from = parse_date(from_str)
    else:
        d_from = tz.now().date() - timedelta(days=6)
    if to_str:
        d_to = parse_date(to_str)
    else:
        d_to = tz.now().date()
    if not d_from or not d_to:
        return Response({"detail": "Dates invalides"}, status=status.HTTP_400_BAD_REQUEST)

    start_dt_naive = datetime(d_from.year, d_from.month, d_from.day)
    start_dt = tz.make_aware(start_dt_naive, tz.get_current_timezone()) if tz.is_naive(start_dt_naive) else start_dt_naive
    end_dt_naive = datetime(d_to.year, d_to.month, d_to.day) + timedelta(days=1)
    end_dt = tz.make_aware(end_dt_naive, tz.get_current_timezone()) if tz.is_naive(end_dt_naive) else end_dt_naive

    qs = Appointment.objects.filter(professional_id=int(pro_id), start__lt=end_dt, end__gte=start_dt)
    # Weekly reservations Mon..Sun
    week = [0, 0, 0, 0, 0, 0, 0]  # Mon..Sun
    status_counts = {"pending": 0, "confirmed": 0, "cancelled": 0, "completed": 0}
    revenue_by_day = {}  # YYYY-MM-DD -> float
    hourly = [0] * 24  # 0..23
    trend = []  # list of {date, count}

    # Prepare date iteration for trend
    iter_day = d_from
    while iter_day <= d_to:
        trend.append({"date": iter_day.isoformat(), "count": 0})
        iter_day += timedelta(days=1)

    trend_index = {item["date"]: i for i, item in enumerate(trend)}

    for a in qs:
        try:
            idx = a.start.astimezone(tz.get_current_timezone()).weekday()
            if 0 <= idx <= 6:
                week[idx] += 1
            # status
            if a.status in status_counts:
                status_counts[a.status] += 1
            # revenue by day (use confirmed/completed only)
            if a.status in ("confirmed", "completed"):
                day_key = a.start.date().isoformat()
                revenue_by_day[day_key] = float(revenue_by_day.get(day_key, 0.0) + float(a.price or 0))
            # hourly distribution (start hour)
            h = a.start.astimezone(tz.get_current_timezone()).hour
            if 0 <= h <= 23:
                hourly[h] += 1
            # trend per day
            dk = a.start.date().isoformat()
            if dk in trend_index:
                trend[trend_index[dk]]["count"] += 1
        except Exception:
            pass

    # Service distribution last 90 days within range
    dist_start = tz.now() - timedelta(days=90)
    dist_qs = Appointment.objects.filter(professional_id=int(pro_id), start__gte=dist_start)
    service_counts = {}
    for a in dist_qs.only("service_name"):
        key = (a.service_name or "Service").strip() or "Service"
        service_counts[key] = service_counts.get(key, 0) + 1
    services = sorted(
        ({"label": k, "value": v} for k, v in service_counts.items()),
        key=lambda x: -x["value"],
    )[:8]

    # Normalize revenue series for the given range
    revenue_series = []
    iter_day = d_from
    while iter_day <= d_to:
        key = iter_day.isoformat()
        revenue_series.append({"date": key, "value": float(revenue_by_day.get(key, 0.0))})
        iter_day += timedelta(days=1)

    # Aggregated KPIs
    revenue_total = float(sum(x["value"] for x in revenue_series))
    reservations_total = int(qs.count())

    # Retention: proportion of clients in range who had an appointment before the range start
    unique_client_ids = list(
        qs.filter(client_id__isnull=False).values_list("client_id", flat=True).distinct()
    )
    returning_clients = 0
    if unique_client_ids:
        earlier_ids = (
            Appointment.objects.filter(
                professional_id=int(pro_id), client_id__in=unique_client_ids, start__lt=start_dt
            )
            .values_list("client_id", flat=True)
            .distinct()
        )
        returning_clients = len(list(earlier_ids))
    retention_rate = float(returning_clients / len(unique_client_ids)) if unique_client_ids else 0.0

    # Margin estimate
    margin_rate = getattr(settings, "ANALYTICS_MARGIN_RATE", 0.35)
    margin_value = float(revenue_total * margin_rate)
    margin_pct = float(round(margin_rate * 100.0, 1))

    # Previous period comparison
    period_days = (d_to - d_from).days + 1
    prev_d_to = d_from - timedelta(days=1)
    prev_d_from = prev_d_to - timedelta(days=period_days - 1)
    prev_start_naive = datetime(prev_d_from.year, prev_d_from.month, prev_d_from.day)
    prev_start = tz.make_aware(prev_start_naive, tz.get_current_timezone()) if tz.is_naive(prev_start_naive) else prev_start_naive
    prev_end_naive = datetime(prev_d_to.year, prev_d_to.month, prev_d_to.day) + timedelta(days=1)
    prev_end = tz.make_aware(prev_end_naive, tz.get_current_timezone()) if tz.is_naive(prev_end_naive) else prev_end_naive
    qs_prev = Appointment.objects.filter(professional_id=int(pro_id), start__lt=prev_end, end__gte=prev_start)
    revenue_prev_total = 0.0
    for a in qs_prev.only("status", "price", "start"):
        if a.status in ("confirmed", "completed"):
            try:
                revenue_prev_total += float(a.price or 0)
            except Exception:
                pass
    reservations_prev_total = int(qs_prev.count())

    # City/location counts (by client city for appointments in range)
    city_rows = (
        qs.values("client__city").annotate(c=DjangoCount("id")).order_by("-c")
    )
    geo_city_counts = [{"label": (row["client__city"] or "Inconnu"), "value": int(row["c"])} for row in city_rows]

    return Response({
        "reservations_by_weekday": week,  # [Mon..Sun]
        "services_distribution": services,
        "status_breakdown": status_counts,
        "trend_daily": trend,
        "hourly_distribution": hourly,
        "revenue_daily": revenue_series,
        "geo_city_counts": geo_city_counts,
        "summary": {
            "revenue_total": revenue_total,
            "reservations_total": reservations_total,
            "retention_rate": retention_rate,
            "margin_pct": margin_pct,
            "margin_value": margin_value,
            "previous": {
                "revenue_total": float(revenue_prev_total),
                "reservations_total": reservations_prev_total,
            },
        },
    })

@api_view(["GET"])  # /api/appointments/kpis/
@permission_classes([IsAuthenticated])
@authentication_classes([JWTAuthentication])
def kpis(request):
    pro = _get_professional_from_user(request.user)
    if not pro:
        return Response({"detail": "Profil professionnel requis"}, status=status.HTTP_403_FORBIDDEN)
    total_visits = Appointment.objects.filter(professional=pro, status__in=["confirmed", "completed"]).count()
    total_reservations = Appointment.objects.filter(professional=pro).count()
    pending = Appointment.objects.filter(professional=pro, status="pending").count()
    confirmed = Appointment.objects.filter(professional=pro, status="confirmed").count()
    cancelled = Appointment.objects.filter(professional=pro, status="cancelled").count()
    completed = Appointment.objects.filter(professional=pro, status="completed").count()
    return Response({
        "visits": total_visits,
        "reservations": total_reservations,
        "by_status": {
            "pending": pending,
            "confirmed": confirmed,
            "cancelled": cancelled,
            "completed": completed,
        }
    })


@api_view(["GET"])  # /api/appointments/notifications/
@permission_classes([IsAuthenticated])
@authentication_classes([JWTAuthentication])
def notifications(request):
    pro = _get_professional_from_user(request.user)
    if not pro:
        return Response({"detail": "Profil professionnel requis"}, status=status.HTTP_403_FORBIDDEN)
    qs = Notification.objects.filter(professional=pro)[:50]
    data = [
        {
            "id": n.id,
            "title": n.title,
            "body": n.body,
            "is_read": n.is_read,
            "created_at": n.created_at.isoformat(),
        }
        for n in qs
    ]
    return Response({"results": data})


@api_view(["GET"])  # /api/appointments/notifications/unread_count/
@permission_classes([IsAuthenticated])
@authentication_classes([JWTAuthentication])
def notifications_unread_count(request):
    pro = _get_professional_from_user(request.user)
    if not pro:
        return Response({"detail": "Profil professionnel requis"}, status=status.HTTP_403_FORBIDDEN)
    count = Notification.objects.filter(professional=pro, is_read=False).count()
    return Response({"unread": count})


@api_view(["POST"])  # {ids:[...]}
@permission_classes([IsAuthenticated])
@authentication_classes([JWTAuthentication])
def notifications_mark_read(request):
    pro = _get_professional_from_user(request.user)
    if not pro:
        return Response({"detail": "Profil professionnel requis"}, status=status.HTTP_403_FORBIDDEN)
    ids = request.data.get("ids") or []
    Notification.objects.filter(professional=pro, id__in=ids).update(is_read=True)
    return Response({"ok": True})


@api_view(["POST"])  # create appointment
@permission_classes([IsAuthenticated])
@authentication_classes([JWTAuthentication])
def create_appointment(request):
    pro = _get_professional_from_user(request.user)
    if not pro:
        return Response({"detail": "Profil professionnel requis"}, status=status.HTTP_403_FORBIDDEN)
    body = request.data or {}
    try:
        start = parse_datetime(body.get("start"))
        end = parse_datetime(body.get("end"))
        if not start or not end:
            return Response({"detail": "start/end invalides"}, status=status.HTTP_400_BAD_REQUEST)
        appt = Appointment.objects.create(
            professional=pro,
            service_name=body.get("service_name") or "Service",
            price=body.get("price") or 0,
            start=start,
            end=end,
            status=body.get("status") or "pending",
            notes=body.get("notes") or "",
        )
        return Response({"id": appt.id}, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(["PATCH"])  # update appointment
@permission_classes([IsAuthenticated])
@authentication_classes([JWTAuthentication])
def update_appointment(request, pk: int):
    pro = _get_professional_from_user(request.user)
    if not pro:
        return Response({"detail": "Profil professionnel requis"}, status=status.HTTP_403_FORBIDDEN)
    try:
        appt = Appointment.objects.get(id=pk, professional=pro)
    except Appointment.DoesNotExist:
        return Response({"detail": "Rendez-vous introuvable"}, status=status.HTTP_404_NOT_FOUND)
    body = request.data or {}
    old_status = appt.status
    if "service_name" in body:
        appt.service_name = body.get("service_name") or appt.service_name
    if "price" in body:
        appt.price = body.get("price") or appt.price
    if "start" in body:
        dt = parse_datetime(body.get("start"))
        if dt:
            appt.start = dt
    if "end" in body:
        dt = parse_datetime(body.get("end"))
        if dt:
            appt.end = dt
    if "status" in body:
        appt.status = body.get("status") or appt.status
    if "notes" in body:
        appt.notes = body.get("notes") or appt.notes
    appt.save()
    # Notify client via email on status change
    try:
        if appt.client and appt.client.user and appt.client.user.email:
            new_status = appt.status
            if new_status != old_status and new_status in ["confirmed", "cancelled"]:
                subject = (
                    "Votre rendez-vous est confirmé" if new_status == "confirmed" else "Votre rendez-vous est annulé"
                )
                message = (
                    f"Bonjour {appt.client.user.first_name or ''},\n\n"
                    f"Votre rendez-vous '{appt.service_name}' du {appt.start.strftime('%d/%m/%Y %H:%M')} a été {('confirmé' if new_status=='confirmed' else 'annulé')} par le centre.\n\n"
                    "Merci d'utiliser COUCOU BEAUTÉ."
                )
                from_addr = getattr(settings, 'DEFAULT_FROM_EMAIL', 'no-reply@coucou-beaute.local')
                recipient = [appt.client.user.email]
                threading.Thread(target=send_mail, args=(subject, message, from_addr, recipient), kwargs={"fail_silently": True}).start()
    except Exception:
        pass
    return Response({"ok": True})


@api_view(["POST"])  # seed demo data
@permission_classes([IsAuthenticated])
@authentication_classes([JWTAuthentication])
def seed_demo(request):
    from datetime import timedelta
    pro = _get_professional_from_user(request.user)
    if not pro:
        return Response({"detail": "Profil professionnel requis"}, status=status.HTTP_403_FORBIDDEN)
    now = datetime.utcnow()
    created = []
    for i, name in enumerate(["Soin du visage", "Manicure + Pédicure", "Épilation visage", "Massage"]):
        start = now.replace(microsecond=0) + timedelta(hours=2*i)
        end = start + timedelta(minutes=60 + i*30)
        a = Appointment.objects.create(
            professional=pro,
            service_name=name,
            price=60 + i*10,
            start=start,
            end=end,
            status=["confirmed", "pending", "completed", "cancelled"][i % 4],
        )
        created.append(a.id)
    Notification.objects.create(professional=pro, title="Nouvelles réservations", body="4 rendez-vous créés")
    return Response({"created": created})

# Vues pour l'app appointments
# Système de prise de rendez-vous

from django.shortcuts import render
from django.http import JsonResponse

# TODO: Implémenter les vues
# def booking():
# def scheduling():
# def calendar_views():

# ------------------ Public/Client Booking ------------------
@api_view(["GET"])  # /api/appointments/public/slots/?pro_id=&date=YYYY-MM-DD
@permission_classes([AllowAny])
def public_slots(request):
    """Return computed slots for a professional for a given date.

    - Uses ProfessionalProfileExtra.working_days (list of 'mon'..'sun')
      and working_hours {start: '09:00', end: '18:00'} if available.
    - Generates 60min slots and marks each slot as:
      'confirmed' if overlaps a confirmed appointment,
      'pending' if overlaps a pending appointment,
      'available' otherwise.
    """
    from django.utils.dateparse import parse_date
    from users.models import Professional
    from datetime import datetime, timedelta

    pro_id = request.GET.get("pro_id")
    if not pro_id:
        return Response({"detail": "pro_id requis"}, status=status.HTTP_400_BAD_REQUEST)
    try:
        pro = Professional.objects.get(id=int(pro_id), is_verified=True)
    except Exception:
        return Response({"detail": "Professionnel introuvable"}, status=status.HTTP_404_NOT_FOUND)

    date_str = request.GET.get("date")
    day = parse_date(date_str) if date_str else None
    if not day:
        day = datetime.utcnow().date()

    # Read availability from extras if present
    start_label = "09:00"
    end_label = "18:00"
    allowed_days = {"mon", "tue", "wed", "thu", "fri"}
    try:
        e = pro.extra
        wh = getattr(e, "working_hours", {}) or {}
        wd = getattr(e, "working_days", []) or []
        if isinstance(wh, dict):
            start_label = (wh.get("start") or start_label).strip()
            end_label = (wh.get("end") or end_label).strip()
        if isinstance(wd, list) and wd:
            allowed_days = set([str(x).lower()[:3] for x in wd])
    except Exception:
        pass

    weekday_code = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"][day.weekday()]
    if weekday_code not in allowed_days:
        return Response({"results": []})

    def to_minutes(hhmm: str) -> int:
        try:
            parts = hhmm.split(":")
            return int(parts[0]) * 60 + int(parts[1])
        except Exception:
            return 9 * 60

    start_m = to_minutes(start_label)
    end_m = to_minutes(end_label)
    if end_m <= start_m:
        end_m = start_m + 60

    # Build a timezone-aware day start/end using project timezone
    day_start_naive = datetime(day.year, day.month, day.day)
    day_start = tz.make_aware(day_start_naive, tz.get_current_timezone()) if tz.is_naive(day_start_naive) else day_start_naive
    # Existing appts for overlap checks
    existing = list(
        Appointment.objects.filter(
            professional=pro, start__lt=day_start + timedelta(minutes=end_m), end__gt=day_start + timedelta(minutes=start_m)
        ).only("start", "end", "status")
    )

    def overlaps(s1, e1, s2, e2) -> bool:
        # Ensure all datetimes are timezone-aware in the same zone
        if tz.is_naive(s1):
            s1 = tz.make_aware(s1, tz.get_current_timezone())
        if tz.is_naive(e1):
            e1 = tz.make_aware(e1, tz.get_current_timezone())
        if tz.is_naive(s2):
            s2 = tz.make_aware(s2, tz.get_current_timezone())
        if tz.is_naive(e2):
            e2 = tz.make_aware(e2, tz.get_current_timezone())
        return s1 < e2 and s2 < e1

    results = []
    step = 60
    cur = start_m
    while cur < end_m:
        s = day_start + timedelta(minutes=cur)
        e = day_start + timedelta(minutes=min(cur + step, end_m))
        slot_status = "available"
        for a in existing:
            if overlaps(s, e, a.start, a.end):
                if a.status == "confirmed":
                    slot_status = "confirmed"
                    break
                elif a.status == "pending":
                    slot_status = "pending"
        results.append({
            "start": s.isoformat(),
            "end": e.isoformat(),
            "status": slot_status,
        })
        cur += step

    return Response({"results": results})


@api_view(["POST"])  # /api/appointments/client/book/
@permission_classes([IsAuthenticated])
@authentication_classes([JWTAuthentication])
def client_book(request):
    """Client creates a pending reservation for a professional.
    Body: {pro_id, service_name, price, start, end}
    """
    from users.models import Professional
    user = request.user
    pro_id = request.data.get("pro_id")
    try:
        pro = Professional.objects.get(id=int(pro_id), is_verified=True)
    except Exception:
        return Response({"detail": "Professionnel introuvable"}, status=status.HTTP_404_NOT_FOUND)
    try:
        start = parse_datetime(request.data.get("start"))
        end = parse_datetime(request.data.get("end"))
        if not start or not end:
            return Response({"detail": "start/end invalides"}, status=status.HTTP_400_BAD_REQUEST)
        # attach client if exists
        client = getattr(user, "client_profile", None)
        appt = Appointment.objects.create(
            professional=pro,
            client=client,
            service_name=request.data.get("service_name") or "Service",
            price=request.data.get("price") or 0,
            start=start,
            end=end,
            status="pending",
            notes=f"Réservé par {user.email}",
        )
        Notification.objects.create(
            professional=pro,
            title="Nouvelle demande de réservation",
            body=f"{user.email} a demandé {appt.service_name}",
        )
        return Response({"id": appt.id, "status": appt.status}, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
