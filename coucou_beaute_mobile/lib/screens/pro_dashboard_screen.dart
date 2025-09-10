import 'package:flutter/material.dart';
// Replaced TopLogoAppBar with a single modern AppBar
import 'pro_first_access_onboarding.dart';
import 'onboarding_screen.dart';
import '../widgets/top_logo_app_bar.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_base.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
// responsive_builder not directly referenced in code after LayoutBuilder usage
import 'package:badges/badges.dart' as badges;
import 'package:url_launcher/url_launcher.dart';

class ProDashboardScreen extends StatefulWidget {
  const ProDashboardScreen({super.key});

  @override
  State<ProDashboardScreen> createState() => _ProDashboardScreenState();
}

class _ProDashboardScreenState extends State<ProDashboardScreen> {
  bool _needsFirstAccess = true; // TODO: read from storage/API when available
  Map<String, dynamic>? _kpis;
  List<dynamic> _agenda = const [];
  List<dynamic> _notifications = const [];
  int _unreadCount = 0;
  Map<DateTime, List<dynamic>> _events = {};

  @override
  void initState() {
    super.initState();
    // In a real app, fetch profile completeness here.
    _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopLogoAppBar(
        onMenuPressed: () => _openSettingsMenu(context),
        actions: [
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: 2, end: 2),
            showBadge: _unreadCount > 0,
            badgeStyle: const badges.BadgeStyle(badgeColor: Color(0xFFE91E63)),
            badgeContent: Text('$_unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 10)),
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded,
                  color: Color(0xFF4A90E2)),
              onPressed: () {
                // Scroll to notifications section if needed
              },
            ),
          )
        ],
        showBack: false,
      ),
      body: _needsFirstAccess
          ? _buildFirstAccessPrompt(context)
          : _buildDashboardContent(context),
    );
  }

  void _openSettingsMenu(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Modifier mon profil'),
                onTap: () => Navigator.of(ctx).pop('edit_profile'),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Déconnexion'),
                onTap: () => Navigator.of(ctx).pop('logout'),
              ),
            ],
          ),
        );
      },
    );
    if (choice == 'edit_profile') {
      final done = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const ProFirstAccessOnboarding()),
      );
      if (done == true) {
        if (mounted) setState(() {});
      }
    } else if (choice == 'logout') {
      final auth = context.read<AuthProvider>();
      await auth.logout();
      if (!mounted) return;
      // Close sheet first
      Navigator.of(context).pop();
      // Route to onboarding (auth gate would also do this, but go explicit)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildFirstAccessPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bienvenue ! Pour activer votre profil, complétez les étapes de configuration.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final done = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                      builder: (_) => const ProFirstAccessOnboarding()),
                );
                if (done == true) {
                  setState(() => _needsFirstAccess = false);
                }
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Commencer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                minimumSize: const Size(200, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final me = auth.me;
    final user = me?['user'] as Map<String, dynamic>?;
    final prof = me?['professional_profile'] as Map<String, dynamic>?;
    // If extras exist, we consider first access complete
    if (_needsFirstAccess && auth.hasProExtras) {
      Future.microtask(() => setState(() => _needsFirstAccess = false));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour ${user?['first_name'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (prof != null)
                      Row(children: [
                        Expanded(
                          child: Text('Centre: ${prof['business_name'] ?? '—'}',
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (prof['is_verified'] == true)
                                ? const Color(0xFFE6F6EF)
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(children: [
                            Icon(
                              (prof['is_verified'] == true)
                                  ? Icons.verified_rounded
                                  : Icons.hourglass_top_rounded,
                              size: 16,
                              color: (prof['is_verified'] == true)
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFEF6C00),
                            ),
                            const SizedBox(width: 6),
                            Text(
                                prof['is_verified'] == true
                                    ? 'Vérifié'
                                    : 'En attente',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: (prof['is_verified'] == true)
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFEF6C00))),
                          ]),
                        ),
                      ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildKpiGrid(),
          const SizedBox(height: 16),
          _pendingAppointmentsSection(),
          const SizedBox(height: 16),
          _buildCalendarSection(),
          const SizedBox(height: 16),
          _periodCharts(),
          const SizedBox(height: 16),
          _notificationsSection(),
          const SizedBox(height: 16),
          _recentActivitiesSection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon,
      {Color? color, required Widget chart}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
        border: Border.all(color: const Color(0xFFFFB3D9).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                const Color(0xFFFFB3D9),
                (color ?? const Color(0xFFFFE5F0))
              ]),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Icon(icon, color: const Color(0xFFE91E63)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.black87)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333))),
                const SizedBox(height: 6),
                SizedBox(height: 30, child: chart),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    final k = _kpis ?? const {};
    final by = (k['by_status'] as Map?) ?? const {};
    return LayoutBuilder(builder: (context, constraints) {
      final isTablet = constraints.maxWidth >= 700;
      final columns = isTablet ? 4 : 2;
      final itemWidth = (constraints.maxWidth - (12 * (columns - 1))) / columns;
      final cards = <Widget>[
        _kpiCard(
            'Vues du profil', '${k['visits'] ?? 0}', Icons.visibility_outlined,
            color: const Color(0xFFFFE5F0),
            chart:
                _miniLineChart(const [2, 3, 4, 3, 5], const Color(0xFFE91E63))),
        _kpiCard('Réservations', '${k['reservations'] ?? 0}',
            Icons.event_available_outlined,
            color: const Color(0xFFCDE7FF),
            chart:
                _miniBarChart(const [1, 2, 2, 3, 4], const Color(0xFF4A90E2))),
        _kpiCard(
            'En attente', '${by['pending'] ?? 0}', Icons.hourglass_top_outlined,
            color: const Color(0xFFFFF0CC),
            chart:
                _miniLineChart(const [1, 1, 2, 1, 2], const Color(0xFFEF6C00))),
        _kpiCard('Revenus', '— DT', Icons.paid_outlined,
            color: const Color(0xFFDDF7E3),
            chart:
                _miniBarChart(const [3, 4, 5, 6, 7], const Color(0xFF2E7D32))),
      ];
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children:
            cards.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
      );
    });
  }

  Widget _miniLineChart(List<double> values, Color color) {
    return LineChart(LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          color: color,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          spots: [
            for (int i = 0; i < values.length; i++)
              FlSpot(i.toDouble(), values[i])
          ],
        )
      ],
      minY: 0,
    ));
  }

  Widget _miniBarChart(List<double> values, Color color) {
    return BarChart(BarChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: [
        for (int i = 0; i < values.length; i++)
          BarChartGroupData(x: i, barRods: [
            BarChartRodData(
                toY: values[i],
                color: color,
                width: 6,
                borderRadius: BorderRadius.circular(2))
          ])
      ],
      alignment: BarChartAlignment.spaceBetween,
      maxY: (values.reduce((a, b) => a > b ? a : b)) + 1,
    ));
  }

  // removed unused legacy _agendaSection

  Widget _periodCharts() {
    return DefaultTabController(
      length: 3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
          border: Border.all(color: const Color(0xFFFFB3D9).withOpacity(0.4)),
        ),
        child: Column(
          children: [
            const TabBar(
              labelColor: Color(0xFFE91E63),
              unselectedLabelColor: Colors.black54,
              tabs: [
                Tab(text: 'Jour'),
                Tab(text: 'Semaine'),
                Tab(text: 'Mois'),
              ],
            ),
            SizedBox(
              height: 200,
              child: TabBarView(children: [
                _chartForPeriod('day'),
                _chartForPeriod('week'),
                _chartForPeriod('month'),
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget _chartForPeriod(String period) {
    List<double> values;
    if (period == 'day') {
      values = _countPerHour();
    } else if (period == 'week') {
      values = _countPerLastDays(7);
    } else {
      values = _countPerLastDays(30);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: LineChart(LineChartData(
        backgroundColor: Colors.white,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (values.isEmpty
              ? 1
              : (values.reduce((a, b) => a > b ? a : b) / 3 + 1).clamp(1, 5)),
          getDrawingHorizontalLine: (v) =>
              FlLine(color: const Color(0xFFF1F1F1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            gradient: const LinearGradient(
                colors: [Color(0xFFFF6FA5), Color(0xFFE91E63)]),
            barWidth: 4,
            dotData: const FlDotData(show: false),
            spots: [
              for (int i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i])
            ],
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6FA5).withOpacity(0.25),
                  const Color(0xFFE91E63).withOpacity(0.05)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          )
        ],
        minY: 0,
      )),
    );
  }

  List<double> _countPerHour() {
    final today = DateTime.now();
    final hours = List<double>.filled(12, 0); // 8..19 approx
    for (final a in _agenda) {
      final startStr = (a['start']?.toString() ?? '');
      final dt = DateTime.tryParse(startStr);
      if (dt != null &&
          dt.year == today.year &&
          dt.month == today.month &&
          dt.day == today.day) {
        final idx = (dt.hour - 8).clamp(0, 11);
        hours[idx] = hours[idx] + 1;
      }
    }
    return hours;
  }

  List<double> _countPerLastDays(int days) {
    final now = DateTime.now();
    final buckets = List<double>.filled(days, 0);
    for (final a in _agenda) {
      final dt = DateTime.tryParse(a['start']?.toString() ?? '');
      if (dt != null) {
        final diff = now.difference(DateTime(dt.year, dt.month, dt.day)).inDays;
        if (diff >= 0 && diff < days) {
          final idx = days - 1 - diff;
          buckets[idx] = buckets[idx] + 1;
        }
      }
    }
    return buckets;
  }

  Widget _buildCalendarSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
        border: Border.all(color: const Color(0xFFFFB3D9).withOpacity(0.4)),
      ),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: DateTime.now(),
        eventLoader: (d) => _events[d] ?? const [],
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
              color: const Color(0xFFFFE5F0),
              borderRadius: BorderRadius.circular(8)),
          selectedDecoration: BoxDecoration(
              color: const Color(0xFFE91E63),
              borderRadius: BorderRadius.circular(8)),
          markerDecoration: const BoxDecoration(
              color: Color(0xFFE91E63), shape: BoxShape.circle),
        ),
        headerStyle:
            const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      ),
    );
  }

  Widget _pendingAppointmentsSection() {
    final pending =
        _agenda.where((a) => (a['status'] ?? '') == 'pending').toList();
    if (pending.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
        border: Border.all(color: const Color(0xFFFFB3D9).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rendez-vous en attente',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...pending.map((a) {
            final dtStart = DateTime.tryParse((a['start'] ?? '').toString());
            final dtEnd = DateTime.tryParse((a['end'] ?? '').toString());
            final dateLabel = (dtStart != null)
                ? '${dtStart.day.toString().padLeft(2, '0')}/${dtStart.month.toString().padLeft(2, '0')} • ${dtStart.hour.toString().padLeft(2, '0')}:${dtStart.minute.toString().padLeft(2, '0')}'
                : '${a['start'] ?? ''}';
            final clientName = (a['client_name'] ?? '').toString();
            final clientEmail = (a['client_email'] ?? '').toString();
            final clientPhone = (a['client_phone'] ?? '').toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
                border:
                    Border.all(color: const Color(0xFFFFB3D9).withOpacity(0.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                colors: [Color(0xFFFFB3D9), Color(0xFFFFE5F0)]),
                          ),
                          child: const Icon(Icons.schedule,
                              color: Color(0xFFE91E63)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a['service_name'] ?? 'Service',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                  dtEnd != null
                                      ? '$dateLabel → ${dtEnd.hour.toString().padLeft(2, '0')}:${dtEnd.minute.toString().padLeft(2, '0')}'
                                      : '${a['start']} → ${a['end']}',
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 18, color: Colors.black54),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(
                              clientName.isEmpty ? 'Client' : clientName,
                              overflow: TextOverflow.ellipsis)),
                    ]),
                    if (clientEmail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.email_outlined,
                            size: 18, color: Colors.black54),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(clientEmail,
                                overflow: TextOverflow.ellipsis)),
                      ])
                    ],
                    if (clientPhone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.phone_outlined,
                            size: 18, color: Colors.black54),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(clientPhone,
                                overflow: TextOverflow.ellipsis)),
                      ])
                    ],
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateStatus(a['id'], 'cancelled'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE53935),
                              side: const BorderSide(color: Color(0xFFE53935)),
                              shape: const StadiumBorder()),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateStatus(a['id'], 'confirmed'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder()),
                          child: const Text('Confirmer'),
                        ),
                      ),
                    ])
                  ],
                ),
              ),
            );
          })
        ],
      ),
    );
  }

  // legacy list views removed

  // status change action removed in this iteration

  Widget _notificationsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
        border: Border.all(color: const Color(0xFFFFB3D9).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_none_rounded,
                  color: Color(0xFFE91E63)),
              const SizedBox(width: 8),
              const Text('Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              badges.Badge(
                showBadge: _unreadCount > 0,
                badgeStyle:
                    const badges.BadgeStyle(badgeColor: Color(0xFFE91E63)),
                badgeContent: Text('$_unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
                child: const SizedBox(width: 1, height: 1),
              )
            ],
          ),
          const SizedBox(height: 8),
          for (final n in _notifications)
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(n['title'] ?? ''),
              subtitle: Text(n['body'] ?? ''),
              trailing:
                  Text((n['created_at'] ?? '').toString().substring(0, 16)),
            ),
          if (_notifications.isEmpty) const Text('Aucune notification'),
        ],
      ),
    );
  }

  Widget _recentActivitiesSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
        border: Border.all(color: const Color(0xFFFFB3D9).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dernières activités',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final a in _agenda.take(10))
            ListTile(
              leading: const Icon(Icons.event_note_outlined,
                  color: Color(0xFFE91E63)),
              title: Text(a['service_name'] ?? 'Service'),
              subtitle: Text('${a['start']} → ${a['end']} • ${a['status']}'),
              trailing: Text('${a['price'] ?? ''} DT'),
            ),
          if (_agenda.isEmpty) const Text('Aucune activité récente'),
        ],
      ),
    );
  }

  Future<void> _refreshAll() async {
    final auth = context.read<AuthProvider>();
    final token = auth.accessToken;
    if (token == null) return;
    final base = apiBase();
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json'
    };
    try {
      final kpiRes = await http.get(Uri.parse('$base/api/appointments/kpis/'),
          headers: headers);
      final agendaRes = await http
          .get(Uri.parse('$base/api/appointments/agenda/'), headers: headers);
      final notRes = await http.get(
          Uri.parse('$base/api/appointments/notifications/'),
          headers: headers);
      if (kpiRes.statusCode == 200)
        _kpis = jsonDecode(kpiRes.body) as Map<String, dynamic>;
      if (agendaRes.statusCode == 200)
        _agenda =
            (jsonDecode(agendaRes.body)['results'] as List).cast<dynamic>();
      if (notRes.statusCode == 200) {
        _notifications =
            (jsonDecode(notRes.body)['results'] as List).cast<dynamic>();
        _unreadCount = _notifications.length;
      }
    } catch (_) {}
    _rebuildEvents();
    if (mounted) setState(() {});
  }

  void _rebuildEvents() {
    final map = <DateTime, List<dynamic>>{};
    for (final a in _agenda) {
      final dt = DateTime.tryParse(a['start']?.toString() ?? '');
      if (dt != null &&
          (a['status'] == 'confirmed' || a['status'] == 'completed')) {
        final day = DateTime(dt.year, dt.month, dt.day);
        (map[day] ??= []).add(a);
      }
    }
    _events = map;
  }

  Future<void> _updateStatus(dynamic id, String status) async {
    final auth = context.read<AuthProvider>();
    final token = auth.accessToken;
    if (token == null) return;
    final base = apiBase();
    try {
      await http.patch(
        Uri.parse('$base/api/appointments/update/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'status': status}),
      );
    } catch (_) {}
    await _refreshAll();
  }
}
