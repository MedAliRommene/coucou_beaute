import os
import django
from django.test import Client


def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'coucou_beaute.settings')
    django.setup()

    from users.models import Professional
    from users.views_api import calculate_distance

    print('=== Diagnostics: Professionals & Coordinates ===')
    pros = Professional.objects.select_related('user').all()
    print(f'Total professionals: {pros.count()}')
    with_extra = 0
    with_coords = 0
    for p in pros:
        extra = getattr(p, 'extra', None)
        if extra:
            with_extra += 1
            lat = getattr(extra, 'latitude', None)
            lng = getattr(extra, 'longitude', None)
            if lat is not None and lng is not None:
                with_coords += 1
            print(f'- pro#{p.id} {p.business_name or p.user.get_full_name() or p.user.email} | extra: {bool(extra)} | lat: {lat} lng: {lng} | city: {getattr(extra, "city", "")}')
        else:
            print(f'- pro#{p.id} {p.business_name or p.user.get_full_name() or p.user.email} | extra: False')

    print(f'With extra: {with_extra}, with coords: {with_coords}')

    # Call the public API endpoint the dashboard uses
    c = Client()
    params = {
        'center_lat': '36.4515',
        'center_lng': '10.7353',
        'within_km': '50',
        'price_min': '0',
        'price_max': '300',
        'min_rating': '0',
        'category': '',
        'search': ''
    }
    resp = c.get('/api/api/professionals/simple/', params)
    print('HTTP status:', resp.status_code)
    try:
        data = resp.json()
    except Exception:
        print(resp.content[:500])
        return

    print('count:', data.get('count'))
    debug = data.get('debug', {})
    print('debug:', debug)
    for r in data.get('results', [])[:10]:
        print({
            'id': r.get('id'),
            'name': r.get('name'),
            'lat': r.get('lat'),
            'lng': r.get('lng'),
            'distanceKm': r.get('distanceKm'),
            'city': r.get('city'),
            'price': r.get('price'),
        })

    # Verify distance computation locally for first result with coords
    first = next((x for x in data.get('results', []) if x.get('lat') is not None and x.get('lng') is not None), None)
    if first:
        d = calculate_distance(36.4515, 10.7353, float(first['lat']), float(first['lng']))
        print('recomputed distanceKm:', round(d, 1))


if __name__ == '__main__':
    main()


