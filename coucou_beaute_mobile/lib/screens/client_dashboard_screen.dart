import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
// import removed: top_logo_app_bar not used here
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_base.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'onboarding_screen.dart';
import '../widgets/top_logo_app_bar.dart';
// calendar UI is now in professional detail screen

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0; // 0: Tous, 1..n categories
  final MapController _mapController = MapController();
  double _zoom = 11;
  final latlng.LatLng _fallbackCenter =
      const latlng.LatLng(36.4515, 10.7353); // Hammamet par défaut
  latlng.LatLng? _userCenter;
  // Center is the user's center only
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = 10;
  // Advanced filters
  double _priceMin = 0;
  double _priceMax = 300;
  double _minRating = 0;
  final Map<String, bool> _langs = {
    'Français': false,
    'Anglais': false,
    'Arabe': false,
  };

  // Categories loaded dynamically from backend
  List<String> _tabs = ['Tous'];
  Map<String, String> _labelToCode = {}; // 'Coiffure' -> 'hairdressing'
  double _globalPriceMin = 0;
  double _globalPriceMax = 300;
  // kept for potential future behavior tuning (currently unused)

  String? _codeToLabel(String? code) {
    if (code == null) return null;
    for (final entry in _labelToCode.entries) {
      if (entry.value == code) return entry.key;
    }
    return null;
  }

  // Professionals loaded from backend
  List<Map<String, dynamic>> _pros = [];
  // Client appointments
  List<Map<String, dynamic>> _myAppointments = [];
  // Keys for in-page navigation
  final GlobalKey _appointmentsKey = GlobalKey();

  // helper removed

  @override
  void initState() {
    super.initState();
    _restoreFilters();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCategories();
      await _initFromAuthProfile();
      if (_userCenter == null) {
        await _ensureLocation();
      }
      await _fetchProfessionals();
      await _fetchMyAppointments();
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        setState(
            () => _visibleCount = (_visibleCount + 10).clamp(0, _pros.length));
      }
    });
  }

  Future<void> _initFromAuthProfile() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final me = auth.me;
      final cp =
          me != null ? me['client_profile'] as Map<String, dynamic>? : null;
      final lat = (cp?['latitude']) as num?;
      final lng = (cp?['longitude']) as num?;
      if (lat != null && lng != null) {
        _userCenter = latlng.LatLng(lat.toDouble(), lng.toDouble());
        _mapController.move(_userCenter!, _zoom);
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _ensureLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium);
        if (_userCenter == null) {
          _userCenter = latlng.LatLng(pos.latitude, pos.longitude);
          _mapController.move(_userCenter!, _zoom);
          setState(() {});
        }
      }
    } catch (_) {}
  }

  Future<void> _restoreFilters() async {
    final sp = await SharedPreferences.getInstance();
    _searchController.text = sp.getString('client_search') ?? '';
    _selectedTab = sp.getInt('client_tab') ?? 0;
    setState(() {});
  }

  Future<void> _persistFilters() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('client_search', _searchController.text);
    await sp.setInt('client_tab', _selectedTab);
  }

  Future<void> _fetchMyAppointments() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.accessToken;
      if (token == null) return;
      final uri = Uri.parse('${apiBase()}/api/appointments/agenda/');
      // Reuse pro agenda when client is linked to a pro? Here we add a lightweight client list endpoint-like behavior.
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json'
      });
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final List items = body['results'] as List? ?? [];
        setState(() => _myAppointments = items
            .map<Map<String, dynamic>>(
                (e) => (e as Map).cast<String, dynamic>())
            .toList());
      }
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    try {
      final uri = Uri.parse('${apiBase()}/api/professionals/categories/');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final List cats = body['categories'] as List? ?? [];
        _labelToCode.clear();
        final labels = <String>[];
        for (final c in cats) {
          final m = (c as Map).cast<String, dynamic>();
          final label = (m['label']?.toString() ?? '').trim();
          final code = (m['code']?.toString() ?? '').trim();
          if (label.isNotEmpty && code.isNotEmpty) {
            labels.add(label);
            _labelToCode[label] = code;
          }
        }
        _tabs = ['Tous', ...labels];
        _globalPriceMin = (body['price_min'] as num?)?.toDouble() ?? 0;
        _globalPriceMax = (body['price_max'] as num?)?.toDouble() ?? 300;
        if (_priceMin == 0) _priceMin = _globalPriceMin;
        if (_priceMax == 300) _priceMax = _globalPriceMax;
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _fetchProfessionals() async {
    try {
      final categoryLabel = _selectedTab == 0 ? '' : _tabs[_selectedTab];
      final center = _userCenter ?? _fallbackCenter;
      final langs =
          _langs.entries.where((e) => e.value).map((e) => e.key).join(',');
      final qp = {
        if (categoryLabel.isNotEmpty)
          'category': _labelToCode[categoryLabel] ??
              _labelToCode[categoryLabel.toLowerCase()] ??
              'other',
        'page_size': '100',
        'center_lat': center.latitude.toString(),
        'center_lng': center.longitude.toString(),
        'within_km': '25',
        'price_min': _priceMin.round().toString(),
        'price_max': _priceMax.round().toString(),
        'min_rating': _minRating.toStringAsFixed(1),
        if (langs.isNotEmpty) 'langs': langs,
      };
      final qs = Uri(queryParameters: qp).query;
      final uri = Uri.parse('${apiBase()}/api/professionals/search/?$qs');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List data = body is Map<String, dynamic>
            ? (body['results'] as List? ?? [])
            : (body as List);
        _pros = data.map<Map<String, dynamic>>((e) {
          final m = e as Map<String, dynamic>;
          final extra = (m['extra'] as Map?) ?? {};
          final lat = (extra['latitude'] ?? m['latitude']) as num?;
          final lng = (extra['longitude'] ?? m['longitude']) as num?;
          final categoryCode = (extra['primary_service'] ?? '') as String?;
          final service = _codeToLabel(categoryCode) ??
              (m['business_name'] ?? 'Service') as String?;
          final langs = (extra['spoken_languages'] ?? []) as List?;
          return {
            'id': m['id'] ?? 0,
            'name': (m['business_name'] ?? 'Professionnelle') as String,
            'service': service ?? 'Service',
            'categoryCode': categoryCode,
            'rating': (extra['rating'] ?? 4.8) as num,
            'reviews': (extra['reviews'] ?? 0) as num,
            'price': (extra['price'] ?? 100) as num,
            'lat': lat?.toDouble(),
            'lng': lng?.toDouble(),
            'langs': (langs ?? ['Français']).cast<String>(),
            'distanceKm': ((extra['distance_km'] as num?) ?? 999).toDouble(),
            'extra': extra,
          };
        }).toList();
        _pros.sort((a, b) =>
            (a['distanceKm'] as num).compareTo((b['distanceKm'] as num)));
        if (!mounted) return;
        setState(() {
          _visibleCount = (_visibleCount).clamp(0, _pros.length);
        });
      }
    } catch (_) {
      setState(() {
        _pros = [];
      });
    }
  }

  // mapping handled via _labelToCode from backend

  // City picker helpers removed (not used)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = GoogleFonts.poppinsTextTheme(theme.textTheme);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: TopLogoAppBar(
        onMenuPressed: _openClientMenu,
        showBack: false,
      ),
      body: DefaultTextStyle(
        style: textTheme.bodyMedium!,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildCategoryTabs(),
              const SizedBox(height: 12),
              _buildMap(),
              const SizedBox(height: 16),
              _buildMyAppointments(),
              const SizedBox(height: 16),
              _buildNearbyHeader(),
              const SizedBox(height: 8),
              _buildInlineFiltersPanel(),
              const SizedBox(height: 12),
              ..._filteredPros().take(_visibleCount).map(_buildProCard),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      // Removed bottom floating filter button per request. Use the header button instead.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFFE91E63),
                side: const BorderSide(color: Color(0xFFE91E63)),
                shape: const StadiumBorder(),
              ),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              },
              label: const Text('Déconnexion'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyAppointments() {
    if (_myAppointments.isEmpty) {
      return Container(
        key: _appointmentsKey,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: const Text('Aucun rendez-vous'),
      );
    }
    return Container(
      key: _appointmentsKey,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mes rendez-vous',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final a in _myAppointments)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading:
                    const Icon(Icons.event_available, color: Color(0xFFE91E63)),
                title: Text(a['service_name'] ?? 'Service'),
                subtitle: Text('${a['start']} → ${a['end']} • ${a['status']}'),
                trailing: Text('${a['price'] ?? ''} DT',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  void _openClientMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.event_note_outlined,
                      color: Color(0xFFE91E63)),
                  title: const Text('Mes rendez-vous'),
                  onTap: () => Navigator.pop(context, 'appointments'),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFF4A90E2)),
                  title: const Text('Déconnexion'),
                  onTap: () => Navigator.pop(context, 'logout'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    if (choice == 'appointments') {
      _scrollToKey(_appointmentsKey);
    } else if (choice == 'logout') {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset =
        box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
    _scrollController.animateTo(
      _scrollController.offset + offset.dy - 100,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) {
          setState(() {});
          _persistFilters();
        },
        decoration: InputDecoration(
          hintText: 'Rechercher un service…',
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  // Booking state used previously (now removed)
  // Kept minimal placeholders to avoid refactor cost in helper functions
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _dayToSlots = {};
  // bool _loadingSlots = false; // not used after moving booking UI

  Future<void> _fetchSlotsForDay(DateTime day) async {
    final pro = _pros.isNotEmpty ? _pros.first : null;
    if (pro == null) return;
    final proId = pro['id'] as int?;
    if (proId == null) return;
    // no-op after moving booking UI
    final d =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse(
        '${apiBase()}/api/appointments/public/slots/?pro_id=$proId&date=$d');
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final List items = body['results'] as List? ?? [];
      final list = items
          .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
          .toList();
      final key = DateTime(day.year, day.month, day.day);
      setState(() => _dayToSlots[key] = list);
    }
    // no-op after moving booking UI
  }

  // booking slot list removed

  // booking submission handled in pro detail screen

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = i == _selectedTab;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedTab = i);
              _persistFilters();
              _fetchProfessionals();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFF6FA5)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _tabs[i],
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userCenter ?? _fallbackCenter,
                initialZoom: _zoom,
                onTap: null,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'coucou_beaute_mobile',
                ),
                MarkerLayer(
                    markers: _filteredPros()
                        .where((p) => p['lat'] != null && p['lng'] != null)
                        .take(30)
                        .map((p) => Marker(
                              point: latlng.LatLng(
                                  (p['lat'] as double), (p['lng'] as double)),
                              width: 36,
                              height: 36,
                              child: GestureDetector(
                                onTap: () => _openProfessionalDetail(p),
                                child: const Icon(Icons.location_on,
                                    color: Color(0xFFE91E63), size: 28),
                              ),
                            ))
                        .toList()),
                if (_userCenter != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _userCenter!,
                      width: 28,
                      height: 28,
                      child: const Icon(Icons.my_location,
                          color: Colors.blueAccent, size: 22),
                    )
                  ]),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                children: [
                  _zoomBtn(Icons.add, () {
                    final next =
                        (_mapController.camera.zoom + 1).clamp(2.0, 19.0);
                    _mapController.move(_mapController.camera.center, next);
                    setState(() => _zoom = next);
                  }),
                  const SizedBox(height: 6),
                  _zoomBtn(Icons.remove, () {
                    final next =
                        (_mapController.camera.zoom - 1).clamp(2.0, 19.0);
                    _mapController.move(_mapController.camera.center, next);
                    setState(() => _zoom = next);
                  }),
                  const SizedBox(height: 6),
                  _zoomBtn(Icons.my_location, () {
                    final c = _userCenter ?? _fallbackCenter;
                    _mapController.move(c, _zoom);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 18)),
      ),
    );
  }

  Widget _buildNearbyHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text('Professionnelles à proximité',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        TextButton(
          onPressed: _openFiltersModal,
          child: const Text('Filtres'),
        )
      ],
    );
  }

  Widget _buildInlineFiltersPanel() {
    final langs =
        _langs.entries.where((e) => e.value).map((e) => e.key).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Prix', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${_priceMin.round()} – ${_priceMax.round()} DT',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Langues',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(langs.isEmpty ? '—' : langs.join(', '),
                  style: const TextStyle(color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Note minimum',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < _minRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: const Color(0xFFFFC107),
                          size: 18,
                        )),
              )
            ],
          ),
        ],
      ),
    );
  }

  // removed unused active filters demo

  // chip helper removed

  Iterable<Map<String, dynamic>> _filteredPros() {
    final q = _searchController.text.toLowerCase();
    final filter = _selectedTab == 0 ? 'Tous' : _tabs[_selectedTab];
    return _pros.where((p) {
      final inSearch = q.isEmpty ||
          p['name'].toString().toLowerCase().contains(q) ||
          p['service'].toString().toLowerCase().contains(q);
      final inTab = filter == 'Tous' ||
          _codeToLabel(p['categoryCode'])?.toLowerCase() ==
              filter.toLowerCase();
      return inSearch && inTab;
    });
  }

  Widget _buildProCard(Map<String, dynamic> p) {
    return InkWell(
      onTap: () => _openProfessionalDetail(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundImage: AssetImage('assets/images/image.png'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(p['name'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700))),
                      Text('${(p['distanceKm'] as num).toStringAsFixed(1)} km',
                          style: const TextStyle(color: Colors.grey))
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(
                          5,
                          (i) => Icon(
                                i < ((p['rating'] as num).toDouble()).round()
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 16,
                                color: const Color(0xFFFFC107),
                              )),
                      const SizedBox(width: 6),
                      Text('(${p['reviews']})',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12))
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(p['service'],
                      style: const TextStyle(
                          color: Color(0xFFFF6FA5),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${p['price']} DT',
                style: const TextStyle(fontWeight: FontWeight.w800))
          ],
        ),
      ),
    );
  }

  void _openProfessionalDetail(Map<String, dynamic> p) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => _ProfessionalDetailScreen(data: p),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    ));
  }

  void _openFiltersModal() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        double minPrice = _priceMin;
        double maxPrice = _priceMax;
        double rating = _minRating;
        final langs = Map<String, bool>.from(_langs);
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 12),
          child: StatefulBuilder(builder: (context, setM) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtres avancés',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                const Text('Prix (DT)'),
                RangeSlider(
                  values: RangeValues(minPrice, maxPrice),
                  min: _globalPriceMin,
                  max: _globalPriceMax < _globalPriceMin
                      ? _globalPriceMin + 1
                      : _globalPriceMax,
                  divisions: 50,
                  onChanged: (v) => setM(() {
                    minPrice = v.start;
                    maxPrice = v.end;
                  }),
                ),
                const SizedBox(height: 8),
                const Text('Note minimum'),
                Slider(
                  value: rating,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: rating.toStringAsFixed(1),
                  onChanged: (v) => setM(() {
                    rating = v;
                  }),
                ),
                const SizedBox(height: 8),
                const Text('Langues'),
                Wrap(
                  spacing: 8,
                  children: langs.keys
                      .map((k) => FilterChip(
                            label: Text(k),
                            selected: langs[k]!,
                            onSelected: (v) => setM(() {
                              langs[k] = v;
                            }),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6FA5),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      setState(() {
                        _priceMin = minPrice;
                        _priceMax = maxPrice;
                        _minRating = rating;
                        _langs
                          ..clear()
                          ..addAll(langs);
                      });
                      Navigator.pop(context);
                      _fetchProfessionals();
                    },
                    child: const Text('Appliquer'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
        );
      },
    );
  }
}

class _ProfessionalDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProfessionalDetailScreen({required this.data});

  @override
  Widget build(BuildContext context) {
    final extra = (data['extra'] as Map?) ?? {};
    final services = (extra['services'] as List?) ?? [];
    final gallery = (extra['gallery'] as List?) ?? [];
    final bio = (extra['bio']?.toString() ?? '').trim();
    final city = (extra['city']?.toString() ?? '').trim();
    final rating = (extra['rating'] ?? 4.8) as num;
    final reviews = (extra['reviews'] ?? 0) as num;
    final address = (extra['address']?.toString() ?? '').trim();
    final days = (extra['working_days'] as List?)?.cast<String>() ?? [];
    final hours =
        (extra['working_hours'] as Map?)?.cast<String, dynamic>() ?? {};
    final insta = (extra['social_instagram']?.toString() ?? '').trim();
    final fb = (extra['social_facebook']?.toString() ?? '').trim();
    final tiktok = (extra['social_tiktok']?.toString() ?? '').trim();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text('Détail professionnelle',
            style: TextStyle(color: Colors.black87)),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6FA5),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () async {
                await _openBookingSheet(context, data);
              },
              child: const Text('Réserver un rendez-vous'),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bannière
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/images/image.png',
                height: 160, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          // Informations principales
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundImage: AssetImage('assets/images/image.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'] ?? 'Professionnelle',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                        '${(data['service'] ?? '-')}${city.isNotEmpty ? ' • $city' : ''}',
                        style: const TextStyle(color: Color(0xFFFF6FA5))),
                    const SizedBox(height: 6),
                    Row(children: [
                      ...List.generate(
                          5,
                          (i) => Icon(
                                i < rating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 16,
                                color: const Color(0xFFFFC107),
                              )),
                      const SizedBox(width: 6),
                      Text('($reviews avis)',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.message_outlined,
                      color: Color(0xFFFF6FA5))),
              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.call_outlined,
                      color: Color(0xFFFF6FA5))),
            ],
          ),
          const SizedBox(height: 16),
          // Réseaux sociaux (chips)
          if ([insta, fb, tiktok].any((e) => e.isNotEmpty)) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Wrap(spacing: 8, children: [
                if (insta.isNotEmpty)
                  _socialChip(Icons.camera_alt_outlined, 'Instagram'),
                if (fb.isNotEmpty)
                  _socialChip(Icons.facebook_outlined, 'Facebook'),
                if (tiktok.isNotEmpty)
                  _socialChip(Icons.music_note_outlined, 'TikTok'),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          // À propos
          const Text('À propos', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(bio.isEmpty ? 'Aucune description' : bio),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.place, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(address,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)))
            ])
          ],
          const SizedBox(height: 16),
          // Jours & horaires
          const Text('Jours et horaires',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (days.isNotEmpty)
            Wrap(
              spacing: 6,
              children: days
                  .map((d) => Chip(
                        label: Text(d),
                        backgroundColor: const Color(0xFFFFE5F0),
                        labelStyle: const TextStyle(color: Color(0xFFE91E63)),
                      ))
                  .toList(),
            ),
          if (hours.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('${hours['start'] ?? '—'} - ${hours['end'] ?? '—'}',
                style: const TextStyle(color: Colors.grey)),
          ],
          const SizedBox(height: 16),
          // Galerie
          const Text('Galerie', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (gallery.isEmpty)
            const Text('Aucune image')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gallery.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (_, i) {
                final src = gallery[i];
                Widget img;
                final s = src?.toString() ?? '';
                if (s.startsWith('http')) {
                  img = Image.network(s, fit: BoxFit.cover);
                } else {
                  img =
                      Image.asset('assets/images/image.png', fit: BoxFit.cover);
                }
                return ClipRRect(
                    borderRadius: BorderRadius.circular(12), child: img);
              },
            ),
          const SizedBox(height: 16),
          // Services et tarifs (design doux rose)
          const Text('Services et tarifs',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (services.isEmpty)
            const Text('Aucun service renseigné')
          else
            Column(
              children: services.map((s) {
                final m = s as Map<String, dynamic>;
                final name = (m['name'] ?? m['title'] ?? 'Service') as String;
                final duration = (m['duration'] ?? 60) as int;
                final price = (m['price'] ?? 100) as num;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('$duration min',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('${price} DT',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          // Avis clients (exemples stylés)
          const Text('Avis clients',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _reviewCard(
              'Marie L.',
              'Soin du visage parfait ! Sophie a su adapter les produits à ma peau sensible. Je recommande vivement.',
              5,
              'Il y a 2j'),
          _reviewCard(
              'Camille D.',
              'Très bonne manucure qui tient bien dans le temps. Petit bémol sur le temps d\'attente.',
              4,
              'Il y a 1sem'),
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                  onPressed: () {},
                  child: const Text('Voir tous les avis (124)'))),
          const SizedBox(height: 16),
          // Guide: réservez via le bouton en bas
          const Text('Réservation',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Choisissez une date et un créneau via le bouton en bas.'),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _reviewCard(String name, String comment, int stars, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
              backgroundImage: AssetImage('assets/images/image.png')),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(date,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < stars ? Icons.star : Icons.star_border,
                        size: 16,
                        color: const Color(0xFFFFC107),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Text(comment),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _socialChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: const Color(0xFFE91E63)),
      label: Text(label),
      backgroundColor: const Color(0xFFFFE5F0),
      labelStyle: const TextStyle(color: Color(0xFFE91E63)),
      shape: const StadiumBorder(),
    );
  }

  List<String> _generateHourlySlots(String start, String end) {
    // expected format HH:mm
    int toMinutes(String t) {
      final parts = t.split(':');
      if (parts.length != 2) return -1;
      final h = int.tryParse(parts[0]) ?? -1;
      final m = int.tryParse(parts[1]) ?? -1;
      if (h < 0 || m < 0) return -1;
      return h * 60 + m;
    }

    String toLabel(int mins) {
      final h = (mins ~/ 60).toString().padLeft(2, '0');
      final m = (mins % 60).toString().padLeft(2, '0');
      return '$h:$m';
    }

    final s = toMinutes(start);
    final e = toMinutes(end);
    if (s < 0 || e <= s) return [];
    final result = <String>[];
    for (int m = s; m <= e; m += 60) {
      result.add(toLabel(m));
    }
    return result;
  }
}

Future<void> _openBookingSheet(
    BuildContext context, Map<String, dynamic> pro) async {
  DateTime selectedDay = DateTime.now();
  DateTime? selectedStart;
  DateTime? selectedEnd;
  List<Map<String, dynamic>> slots = const [];
  bool loading = false;
  // Load services from professional extra data
  final extra = (pro['extra'] as Map?) ?? {};
  final List rawServices = (extra['services'] as List?) ?? [];
  final Set<int> selectedServiceIdxs = <int>{};
  bool inited = false;

  Future<void> loadSlots() async {
    loading = true;
    final d =
        '${selectedDay.year.toString().padLeft(4, '0')}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse(
        '${apiBase()}/api/appointments/public/slots/?pro_id=${pro['id']}&date=$d');
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final List items = body['results'] as List? ?? [];
      slots = items
          .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
          .toList();
    }
    loading = false;
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setM) {
        Future<void> refresh(DateTime d) async {
          if (!ctx.mounted) return;
          setM(() {
            selectedDay = d;
          });
          await loadSlots();
          if (!ctx.mounted) return;
          setM(() {});
        }

        // Initial load after first build
        if (!inited) {
          inited = true;
          Future.microtask(() async {
            if (!ctx.mounted) return;
            await refresh(selectedDay);
          });
        }

        return SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Réserver un rendez-vous',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (rawServices.isNotEmpty) ...[
                  const Text('Services'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < rawServices.length; i++)
                        Builder(builder: (_) {
                          final m =
                              (rawServices[i] as Map).cast<String, dynamic>();
                          final name =
                              (m['name'] ?? m['title'] ?? 'Service').toString();
                          final price = (m['price'] ?? 0).toString();
                          final selected = selectedServiceIdxs.contains(i);
                          return FilterChip(
                            label: Text('$name • $price DT'),
                            selected: selected,
                            onSelected: (v) => setM(() {
                              if (v) {
                                selectedServiceIdxs.add(i);
                              } else {
                                selectedServiceIdxs.remove(i);
                              }
                            }),
                            selectedColor: const Color(0xFFFFE5F0),
                            checkmarkColor: const Color(0xFFE91E63),
                          );
                        }),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  height: 360,
                  child: CalendarDatePicker(
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 180)),
                    initialDate: selectedDay,
                    onDateChanged: (d) => refresh(d),
                  ),
                ),
                if (loading)
                  const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator()),
                if (!loading)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slots.map((s) {
                      final status = (s['status'] ?? '').toString();
                      final start =
                          DateTime.tryParse(s['start']?.toString() ?? '');
                      final end = DateTime.tryParse(s['end']?.toString() ?? '');
                      final isAvailable = status != 'confirmed';
                      Color color;
                      switch (status) {
                        case 'pending':
                          color = const Color(0xFFFFC107);
                          break;
                        case 'confirmed':
                          color = const Color(0xFFE53935);
                          break;
                        default:
                          color = const Color(0xFF4CAF50);
                      }
                      final label = start != null
                          ? '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}'
                          : '—';
                      final selected =
                          selectedStart == start && selectedEnd == end;
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: isAvailable && start != null && end != null
                            ? (v) => setM(() {
                                  selectedStart = start;
                                  selectedEnd = end;
                                })
                            : null,
                        selectedColor: const Color(0xFFFFE5F0),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: color),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6FA5),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: (selectedStart != null &&
                            selectedEnd != null &&
                            (rawServices.isEmpty ||
                                selectedServiceIdxs.isNotEmpty))
                        ? () async {
                            final auth = Provider.of<AuthProvider>(context,
                                listen: false);
                            // Aggregate chosen services
                            String serviceName;
                            num totalPrice;
                            if (selectedServiceIdxs.isNotEmpty) {
                              final names = <String>[];
                              num sum = 0;
                              for (final i in selectedServiceIdxs) {
                                final m = (rawServices[i] as Map)
                                    .cast<String, dynamic>();
                                names.add((m['name'] ?? m['title'] ?? 'Service')
                                    .toString());
                                final p = m['price'];
                                if (p is num) {
                                  sum += p;
                                } else {
                                  sum +=
                                      num.tryParse(p?.toString() ?? '0') ?? 0;
                                }
                              }
                              serviceName = names.join(' + ');
                              totalPrice = sum;
                            } else {
                              serviceName =
                                  (pro['service'] ?? 'Service').toString();
                              totalPrice = (pro['price'] ?? 0) as num;
                            }
                            final resp = await auth.bookAppointment(
                              proId: pro['id'] as int,
                              serviceName: serviceName,
                              price: totalPrice,
                              start: selectedStart!,
                              end: selectedEnd!,
                            );
                            if (resp['ok'] == true) {
                              if (context.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Réservation envoyée – en attente de confirmation')),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                      content: Text('Erreur de réservation')));
                            }
                          }
                        : null,
                    child: const Text('Valider la réservation'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      });
    },
  );
}
