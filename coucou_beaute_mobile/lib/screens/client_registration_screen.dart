import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../providers/auth_provider.dart';
import 'professional_registration_screen.dart';
import 'client_dashboard_screen.dart';

class ClientRegistrationScreen extends StatefulWidget {
  const ClientRegistrationScreen({super.key});

  @override
  State<ClientRegistrationScreen> createState() =>
      _ClientRegistrationScreenState();
}

class _ClientRegistrationScreenState extends State<ClientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscure = true;
  double? _lat;
  double? _lng;
  final _mapController = MapController();
  double _zoom = 13;
  static const latlng.LatLng _nabeulCenter = latlng.LatLng(36.4515, 10.7353);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'E-mail requis';
    final re = RegExp(r'^.+@.+\..+');
    if (!re.hasMatch(value)) return 'E-mail invalide';
    return null;
  }

  String? _validatePhone(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return null; // optional
    final re = RegExp(r'^\+?[0-9]{8,15}');
    if (!re.hasMatch(value)) return 'Format invalide (ex: +216XXXXXXXX)';
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.length < 6) return 'Au moins 6 caractères';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final payload = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'phone_number': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      if (_lat != null) 'latitude': _lat,
      if (_lng != null) 'longitude': _lng,
    };
    final auth = context.read<AuthProvider>();
    final result = await auth.registerClient(payload);
    setState(() => _isSubmitting = false);
    if (result['ok'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inscription réussie. Bienvenue !')));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ClientDashboardScreen()),
          (route) => false,
        );
      }
    } else {
      final data = result['data'] as Map<String, dynamic>?;
      final msg = data?['detail']?.toString() ??
          data?.values.firstOrNull?.toString() ??
          'Erreur lors de l\'inscription';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Créer un compte client',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Profitez d\'une expérience personnalisée et réservez vos soins en quelques clics',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[700], height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(
                          child: _textField(
                              label: 'Prénom',
                              controller: _firstNameController,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Requis'
                                  : null)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _textField(
                              label: 'Nom',
                              controller: _lastNameController,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Requis'
                                  : null)),
                    ]),
                    const SizedBox(height: 12),
                    _textField(
                        label: 'E-mail',
                        controller: _emailController,
                        keyboard: TextInputType.emailAddress,
                        validator: _validateEmail),
                    const SizedBox(height: 12),
                    _textField(
                        label: 'Téléphone',
                        controller: _phoneController,
                        keyboard: TextInputType.phone,
                        validator: _validatePhone),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: _passwordField(
                              label: 'Mot de passe',
                              controller: _passwordController)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _passwordField(
                              label: 'Confirmer le mot de passe',
                              controller: _confirmPasswordController,
                              validator: _validateConfirm)),
                    ]),
                    const SizedBox(height: 12),
                    _textField(
                        label: 'Adresse',
                        controller: _addressController,
                        maxLines: 2),
                    const SizedBox(height: 12),
                    _textField(label: 'Ville', controller: _cityController),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Touchez la carte pour choisir votre position, ou déplacez le marqueur.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOsmMap(),
                    if (_lat != null && _lng != null) ...[
                      const SizedBox(height: 8),
                      Text(
                          'Coordonnées: ${"${(_lat!).toStringAsFixed(5)}, ${(_lng!).toStringAsFixed(5)}"}',
                          style: TextStyle(color: Colors.grey[700]))
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB3D9),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Créer mon compte',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8)))),
                      const SizedBox(width: 8),
                      Text('ou', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8)))),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const FaIcon(FontAwesomeIcons.google,
                            size: 18, color: Colors.white),
                        label: const Text('Continuer avec Google',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4285F4),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _signInWithFacebook,
                        icon: const FaIcon(FontAwesomeIcons.facebookF,
                            size: 18, color: Colors.white),
                        label: const Text('Continuer avec Facebook',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Vous êtes une professionnelle ? ',
                            style: TextStyle(color: Colors.grey[700])),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ProfessionalRegistrationScreen()));
                          },
                          child: const Text('Inscrivez-vous ici',
                              style: TextStyle(
                                  color: Color(0xFFE91E63),
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Connexion Google désactivée pour le moment')));
  }

  Future<void> _signInWithFacebook() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Connexion Facebook désactivée pour le moment')));
  }

  Widget _textField(
      {required String label,
      required TextEditingController controller,
      String? Function(String?)? validator,
      int maxLines = 1,
      TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800])),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: 'Entrez $label'.toLowerCase(),
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFFFB3D9), width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _passwordField(
      {required String label,
      required TextEditingController controller,
      String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800])),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: _obscure,
          validator: validator ?? _validatePassword,
          decoration: InputDecoration(
            hintText: 'Entrez $label'.toLowerCase(),
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFFFB3D9), width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600]),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB3D9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFB3D9).withOpacity(0.8),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/logo2.png',
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const Icon(Icons.menu, color: Color(0xFF4A90E2), size: 28),
        ],
      ),
    );
  }

  Widget _buildOsmMap() {
    final center = latlng.LatLng(
        _lat ?? _nabeulCenter.latitude, _lng ?? _nabeulCenter.longitude);
    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: _zoom,
                onTap: (tapPosition, point) async {
                  await _updateFromLatLng(point);
                  _mapController.move(point, _mapController.camera.zoom);
                },
                onMapEvent: (event) {
                  _zoom = _mapController.camera.zoom;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'coucou_beaute_mobile',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: latlng.LatLng(center.latitude, center.longitude),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on,
                        color: Color(0xFFE91E63), size: 36),
                  ),
                ]),
              ],
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Column(
                children: [
                  _zoomButton(
                      icon: Icons.add,
                      onTap: () {
                        final next =
                            (_mapController.camera.zoom + 1).clamp(2.0, 19.0);
                        _mapController.move(_mapController.camera.center, next);
                        setState(() => _zoom = next);
                      }),
                  const SizedBox(height: 6),
                  _zoomButton(
                      icon: Icons.remove,
                      onTap: () {
                        final next =
                            (_mapController.camera.zoom - 1).clamp(2.0, 19.0);
                        _mapController.move(_mapController.camera.center, next);
                        setState(() => _zoom = next);
                      }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoomButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: Colors.black87)),
      ),
    );
  }

  Future<void> _updateFromLatLng(dynamic pos) async {
    // Accept google_maps_flutter LatLng or latlong2 LatLng
    final double lat =
        pos is latlng.LatLng ? pos.latitude : (pos.latitude as double);
    final double lng =
        pos is latlng.LatLng ? pos.longitude : (pos.longitude as double);
    _lat = lat;
    _lng = lng;
    try {
      final placemarks = await geo.placemarkFromCoordinates(_lat!, _lng!);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _addressController.text = [p.street, p.subLocality, p.locality]
            .where((e) => (e ?? '').isNotEmpty)
            .join(', ');
        _cityController.text = p.locality ?? _cityController.text;
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }
}
