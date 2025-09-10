import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../widgets/top_logo_app_bar.dart';

class ProFirstAccessOnboarding extends StatefulWidget {
  const ProFirstAccessOnboarding({super.key});

  @override
  State<ProFirstAccessOnboarding> createState() =>
      _ProFirstAccessOnboardingState();
}

class _ProFirstAccessOnboardingState extends State<ProFirstAccessOnboarding> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();

  final List<_ServiceInput> _services = [
    _ServiceInput(
        name: TextEditingController(),
        durationMin: TextEditingController(),
        price: TextEditingController()),
  ];

  File? _profileImageFile;
  final List<File> _galleryFiles = [];

  // Disponibilités
  final List<String> _timeOptions = _generateHalfHourTimes();
  String _startTime = '09:00';
  String _endTime = '18:00';
  final Set<String> _selectedDays = <String>{}; // mon,tue,wed,thu,fri,sat,sun

  @override
  void dispose() {
    _fullNameController.dispose();
    _specialtyController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _tiktokController.dispose();
    for (final s in _services) {
      s.name.dispose();
      s.durationMin.dispose();
      s.price.dispose();
    }
    super.dispose();
  }

  static List<String> _generateHalfHourTimes() {
    final List<String> result = [];
    for (int h = 0; h < 24; h++) {
      final hh = h.toString().padLeft(2, '0');
      result.add('$hh:00');
      result.add('$hh:30');
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Charger les données pour pré-remplir si disponibles
    final me = context.watch<AuthProvider>().me;
    final hint =
        me != null ? me['application_hint'] as Map<String, dynamic>? : null;
    final prof =
        me != null ? me['professional_profile'] as Map<String, dynamic>? : null;
    final extra = prof != null ? prof['extra'] as Map<String, dynamic>? : null;
    _prefillOnce(hint, extra);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TopLogoAppBar(
        showBack: true,
        onMenuPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu à venir')),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Bienvenue ! Complétez votre profil'),
              _profileSection(),
              const SizedBox(height: 16),
              _sectionTitle('Disponibilités'),
              _availabilitySection(),
              const SizedBox(height: 16),
              _sectionTitle('À propos de moi'),
              _aboutSection(),
              const SizedBox(height: 16),
              _sectionTitle('Réseaux sociaux'),
              _socialLinksSection(),
              const SizedBox(height: 16),
              _sectionTitle('Galerie (optionnel)'),
              _gallerySection(),
              const SizedBox(height: 16),
              _sectionTitle('Services proposés & Tarifs'),
              _servicesSection(),
              const SizedBox(height: 24),
              _submitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  bool _prefilled = false;
  void _prefillOnce(Map<String, dynamic>? hint, Map<String, dynamic>? extra) {
    if (_prefilled) return;
    _prefilled = true;
    if (hint == null) return;
    _fullNameController.text = [
      hint['first_name'] ?? '',
      hint['last_name'] ?? ''
    ].where((e) => (e as String).isNotEmpty).join(' ').trim();
    _specialtyController.text = _specialtyController.text.isEmpty
        ? _activityCodeToLabel(hint['activity_category'] as String?)
        : _specialtyController.text;
    _cityController.text = _cityController.text.isEmpty
        ? (hint['address'] ?? '')
        : _cityController.text;
    _bioController.text = _bioController.text;
    // Services not provided by hint; keep empty.

    // Pré-remplir depuis les extras existants si présents
    if (extra != null) {
      final bio = (extra['bio'] as String?) ?? '';
      final city = (extra['city'] as String?) ?? '';
      final ig = (extra['social_instagram'] as String?) ?? '';
      final fb = (extra['social_facebook'] as String?) ?? '';
      final tk = (extra['social_tiktok'] as String?) ?? '';
      _bioController.text =
          _bioController.text.isEmpty ? bio : _bioController.text;
      _cityController.text =
          _cityController.text.isEmpty ? city : _cityController.text;
      _instagramController.text = ig;
      _facebookController.text = fb;
      _tiktokController.text = tk;

      final services = (extra['services'] as List?)?.cast<dynamic>() ?? [];
      if (services.isNotEmpty) {
        // Nettoyer existants
        for (final s in _services) {
          s.name.dispose();
          s.durationMin.dispose();
          s.price.dispose();
        }
        _services.clear();
        for (final item in services) {
          final map = (item as Map).cast<String, dynamic>();
          _services.add(_ServiceInput(
            name: TextEditingController(text: (map['name'] ?? '').toString()),
            durationMin: TextEditingController(
                text: (map['duration_min'] ?? '').toString()),
            price: TextEditingController(text: (map['price'] ?? '').toString()),
          ));
        }
      }

      final days = (extra['working_days'] as List?)?.cast<String>() ?? [];
      _selectedDays.addAll(days);
      final wh =
          (extra['working_hours'] as Map?)?.cast<String, dynamic>() ?? {};
      _startTime = (wh['start'] as String?) ?? _startTime;
      _endTime = (wh['end'] as String?) ?? _endTime;
    }
  }

  String _activityCodeToLabel(String? code) {
    switch (code) {
      case 'hairdressing':
        return 'Coiffure';
      case 'makeup':
        return 'Maquillage';
      case 'manicure':
        return 'Manucure';
      case 'esthetics':
        return 'Esthétique';
      case 'massage':
        return 'Massage';
      default:
        return '';
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _profileSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _glassBoxDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pickProfileImage,
            child: CircleAvatar(
              radius: 36,
              backgroundImage: _profileImageFile != null
                  ? FileImage(_profileImageFile!)
                  : null,
              child: _profileImageFile == null
                  ? const Icon(Icons.camera_alt, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                ),
                TextField(
                  controller: _specialtyController,
                  decoration: const InputDecoration(labelText: 'Spécialité'),
                ),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'Ville'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _availabilitySection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _glassBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Jours de travail',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _dayChip('Lun', 'mon'),
              _dayChip('Mar', 'tue'),
              _dayChip('Mer', 'wed'),
              _dayChip('Jeu', 'thu'),
              _dayChip('Ven', 'fri'),
              _dayChip('Sam', 'sat'),
              _dayChip('Dim', 'sun'),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Créneaux horaires',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _startTime,
                  items: _timeOptions
                      .map((t) => DropdownMenuItem<String>(
                          value: t, child: Text('Début $t')))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _startTime = v ?? _startTime),
                  decoration: const InputDecoration(labelText: 'Début'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _endTime,
                  items: _timeOptions
                      .map((t) => DropdownMenuItem<String>(
                          value: t, child: Text('Fin $t')))
                      .toList(),
                  onChanged: (v) => setState(() => _endTime = v ?? _endTime),
                  decoration: const InputDecoration(labelText: 'Fin'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Les jours non sélectionnés sont considérés comme congés.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _dayChip(String label, String code) {
    final selected = _selectedDays.contains(code);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          if (selected) {
            _selectedDays.remove(code);
          } else {
            _selectedDays.add(code);
          }
        });
      },
      selectedColor: const Color(0xFFFFB3D9),
      backgroundColor: const Color(0xFFFFE5F0),
      labelStyle:
          TextStyle(color: selected ? Colors.white : const Color(0xFFE91E63)),
    );
  }

  Widget _aboutSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _glassBoxDecoration(),
      child: TextField(
        controller: _bioController,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'Présentez-vous (formation, approche, diplômes...)',
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  Widget _gallerySection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _glassBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _addPhotoTile(),
              for (int i = 0; i < _galleryFiles.length; i++) _galleryThumb(i),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialLinksSection() {
    InputDecoration deco(IconData icon, String hint) {
      return InputDecoration(
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE5F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFE91E63), size: 18),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: const Color(0xFFFFB3D9).withOpacity(0.5)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE91E63), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _glassBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Réseaux sociaux (optionnel)',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _instagramController,
            decoration: deco(
                FontAwesomeIcons.instagram, 'Lien Instagram (https://...)'),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _facebookController,
            decoration:
                deco(FontAwesomeIcons.facebook, 'Lien Facebook (https://...)'),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tiktokController,
            decoration:
                deco(FontAwesomeIcons.tiktok, 'Lien TikTok (https://...)'),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  Widget _addPhotoTile() {
    return GestureDetector(
      onTap: _pickGalleryImages,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add_a_photo, color: Color(0xFFE91E63)),
      ),
    );
  }

  Widget _galleryThumb(int index) {
    final file = _galleryFiles[index];
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 84, height: 84, fit: BoxFit.cover),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => setState(() => _galleryFiles.removeAt(index)),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        )
      ],
    );
  }

  Widget _servicesSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _glassBoxDecoration(),
      child: Column(
        children: [
          for (int i = 0; i < _services.length; i++) _serviceRow(i),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _services.add(_ServiceInput(
                    name: TextEditingController(),
                    durationMin: TextEditingController(),
                    price: TextEditingController(),
                  ));
                });
              },
              icon: const Icon(Icons.add, color: Color(0xFFE91E63)),
              label: const Text('Ajouter un service'),
            ),
          )
        ],
      ),
    );
  }

  Widget _serviceRow(int index) {
    final s = _services[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: TextField(
                controller: s.name,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Service',
                  prefixIcon: const Icon(Icons.design_services_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: s.durationMin,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Durée',
                  suffixText: 'min',
                  prefixIcon: const Icon(Icons.schedule_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: s.price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]'))
                ],
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Prix',
                  suffixText: 'DT',
                  prefixIcon: const Icon(Icons.attach_money_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Supprimer',
              onPressed: () {
                if (_services.length == 1) return;
                setState(() {
                  final removed = _services.removeAt(index);
                  removed.name.dispose();
                  removed.durationMin.dispose();
                  removed.price.dispose();
                });
              },
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            )
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Valider mon profil'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  bool _isValidUrl(String v) {
    if (v.trim().isEmpty) return true;
    final uri = Uri.tryParse(v.trim());
    return uri != null && (uri.isScheme("https") || uri.isScheme("http"));
  }

  Future<void> _submit() async {
    final errors = <String>[];
    if (_fullNameController.text.trim().isEmpty) {
      errors.add('Nom complet requis');
    }
    if (_specialtyController.text.trim().isEmpty) {
      errors.add('Spécialité requise');
    }
    if (_cityController.text.trim().isEmpty) errors.add('Ville requise');
    if (_selectedDays.isEmpty) {
      errors.add('Choisissez au moins un jour de travail');
    }
    final hasService = _services.any(
        (s) => s.name.text.trim().isNotEmpty && s.price.text.trim().isNotEmpty);
    if (!hasService) errors.add('Ajoutez au moins un service avec un prix');
    if (!_isValidUrl(_instagramController.text)) {
      errors.add('Lien Instagram invalide');
    }
    if (!_isValidUrl(_facebookController.text)) {
      errors.add('Lien Facebook invalide');
    }
    if (!_isValidUrl(_tiktokController.text)) {
      errors.add('Lien TikTok invalide');
    }

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errors.join(' • ')),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    // Convert gallery to base64 for storage
    final List<String> galleryBase64 = [];
    for (final f in _galleryFiles) {
      final bytes = await f.readAsBytes();
      final b64 = base64Encode(bytes);
      const mime = 'image/jpeg';
      galleryBase64.add('data:$mime;base64,$b64');
    }

    final extras = {
      'bio': _bioController.text.trim(),
      'city': _cityController.text.trim(),
      'social_instagram': _instagramController.text.trim(),
      'social_facebook': _facebookController.text.trim(),
      'social_tiktok': _tiktokController.text.trim(),
      'services': _services
          .where((s) => s.name.text.trim().isNotEmpty)
          .map((s) => {
                'name': s.name.text.trim(),
                'duration_min': int.tryParse(s.durationMin.text.trim()) ?? 0,
                'price': double.tryParse(s.price.text.trim()) ?? 0,
              })
          .toList(),
      'working_days': _selectedDays.toList(),
      'working_hours': {'start': _startTime, 'end': _endTime},
      'gallery': galleryBase64,
    };

    final auth = context.read<AuthProvider>();
    final ok = await auth.saveProfessionalExtras(extras);
    if (ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Profil enregistré. Redirection vers le tableau de bord...'),
        backgroundColor: Colors.green,
      ));
      Navigator.of(context).pop(true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Échec de l\'enregistrement du profil'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _profileImageFile = File(picked.path);
      });
    }
  }

  Future<void> _pickGalleryImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      setState(() {
        _galleryFiles.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  BoxDecoration _glassBoxDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.6),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6)),
      ],
      border: Border.all(color: const Color(0xFFFFB3D9).withOpacity(0.4)),
    );
  }
}

class _ServiceInput {
  final TextEditingController name;
  final TextEditingController durationMin;
  final TextEditingController price;
  _ServiceInput(
      {required this.name, required this.durationMin, required this.price});
}
