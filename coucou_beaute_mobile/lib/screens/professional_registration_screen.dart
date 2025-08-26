import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class ProfessionalRegistrationScreen extends StatefulWidget {
  const ProfessionalRegistrationScreen({super.key});

  @override
  State<ProfessionalRegistrationScreen> createState() =>
      _ProfessionalRegistrationScreenState();
}

class _ProfessionalRegistrationScreenState
    extends State<ProfessionalRegistrationScreen> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();

  String? _selectedCategory;
  String? _selectedServiceType;
  bool _isSubscriptionActive = false;

  // Etat intelligent pour l'adresse
  Timer? _addressDebounce;
  String _addressStatus = '';
  geo.Placemark? _resolvedPlacemark;
  double? _lastLat;
  double? _lastLng;

  final List<String> _categories = [
    'Coiffure',
    'Maquillage',
    'Manucure',
    'Soins du visage',
    'Massage'
  ];
  final List<String> _serviceTypes = [
    'Je me déplace',
    'Je reçois chez moi',
    'J\'ai un salon'
  ];

  final Map<String, bool> _languages = {
    'Français': false,
    'Arabe': false,
    'Anglais': false,
  };

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 🔝 En-tête en haut
          _buildHeader(),

          // 📱 Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre "Inscription Professionnelle" (défile avec le contenu)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'Inscription Professionnelle',
                      style: TextStyle(
                        color: Colors.pink[700],
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // 📝 Description (défile avec le contenu)
                  _buildDescription(),

                  // 📑 Champs du formulaire
                  _buildFormFields(),

                  const SizedBox(height: 24),

                  // 👤 Photo de profil
                  _buildProfilePhotoSection(),

                  const SizedBox(height: 24),

                  // 🪪 Pièce d'identité
                  _buildIdDocumentSection(),

                  const SizedBox(height: 24),

                  // 📂 Catégorie d'activité
                  _buildActivityCategorySection(),

                  const SizedBox(height: 24),

                  // ⚙️ Type de prestation
                  _buildServiceTypeSection(),

                  const SizedBox(height: 24),

                  // 🏠 Adresse
                  _buildAddressSection(),

                  const SizedBox(height: 24),

                  // 🌍 Langues parlées
                  _buildLanguagesSection(),

                  const SizedBox(height: 24),

                  // 💳 Abonnement Professionnel
                  _buildSubscriptionSection(),

                  const SizedBox(height: 32),

                  // ✅ Bouton final
                  _buildValidationButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔝 En-tête en haut
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color:
            const Color(0xFFFFB3D9), // Rose clair synchronisé avec onboarding
        // Suppression des coins arrondis pour un look rectangulaire
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
          // Flèche de retour à gauche
          IconButton(
            onPressed: () {
              Navigator.pop(context); // Retour à l'onboarding screen
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),

          // Logo centré indépendamment des icônes gauche/droite
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/logo2.png',
                height: 50, // Taille optimale : claire mais pas trop grande
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Menu Burger (droite) en bleu vif
          Icon(
            Icons.menu,
            color: const Color(0xFF4A90E2), // Bleu vif exact
            size: 28,
          ),
        ],
      ),
    );
  }

  // 📝 Description seulement (sans redondance du titre)
  Widget _buildDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Text(
        'Complétez votre profil pour rejoindre notre communauté de professionnels de beauté',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 16,
          height: 1.4,
        ),
        textAlign: TextAlign.start,
      ),
    );
  }

  // 📑 Champs du formulaire
  Widget _buildFormFields() {
    return Column(
      children: [
        // Nom
        _buildTextField(
          controller: _nomController,
          hint: 'Votre nom',
        ),

        const SizedBox(height: 12),

        // Prénom
        _buildTextField(
          controller: _prenomController,
          hint: 'Votre prénom',
        ),

        const SizedBox(height: 12),

        // Email
        _buildTextField(
          controller: _emailController,
          hint: 'votre.email@exemple.com',
          prefixIcon: Icon(Icons.email, color: Colors.pink),
        ),

        const SizedBox(height: 12),

        // Téléphone
        _buildTextField(
          controller: _telephoneController,
          hint: '+216 XX XXX XXX',
          prefixIcon: Icon(Icons.phone, color: Colors.pink),
        ),
      ],
    );
  }

  // Champ de texte réutilisable
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    Widget? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.pink, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  // 👤 Photo de profil
  Widget _buildProfilePhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo de profil',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Icône cercle rose
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.pink,
                size: 40,
              ),
            ),

            const SizedBox(width: 16),

            // Bouton Télécharger style pill
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implémenter la logique de téléchargement
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  side: const BorderSide(color: Colors.black12),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
                child: const Text(
                  'Télécharger',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 🪪 Pièce d'identité
  Widget _buildIdDocumentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pièce d\'identité',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Carte en pointillés gris avec fond rose clair
        DottedBorder(
          color: Colors.grey[300]!,
          strokeWidth: 1.5,
          dashPattern: const [6, 4],
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.badge_outlined,
                  color: Colors.pink,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'Format JPG ou PDF (max 5MB)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implémenter la logique de téléchargement
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: Colors.black12),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  child: const Text(
                    'Télécharger',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 📂 Catégorie d'activité
  Widget _buildActivityCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie d\'activité',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Dropdown simple et moderne
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB3D9).withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: const Color(0xFFFFB3D9).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              hintText: 'Sélectionnez une catégorie',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              suffixIcon: Icon(
                Icons.keyboard_arrow_down,
                color: const Color(0xFFFFB3D9),
                size: 20,
              ),
            ),
            items: ['Coiffure', 'Esthétique', 'Manucure', 'Massage', 'Autres']
                .map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(
                  category,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
            },
            dropdownColor: Colors.white,
            icon: const SizedBox.shrink(), // Cache l'icône par défaut
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ⚙️ Type de prestation
  Widget _buildServiceTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de prestation',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _serviceTypes.map((String type) {
            return RadioListTile<String>(
              title: Text(type),
              value: type,
              groupValue: _selectedServiceType,
              onChanged: (String? value) {
                setState(() {
                  _selectedServiceType = value;
                });
              },
              activeColor: Colors.pink,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
        ),
      ],
    );
  }

  // 🏠 Adresse
  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adresse professionnelle',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Champ adresse professionnelle moderne et compact
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB3D9).withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: const Color(0xFFFFB3D9).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _adresseController,
            maxLines: 3, // Réduit de 4 à 3 lignes
            textInputAction: TextInputAction.newline,
            onChanged: _onAddressChangedDebounced,
            decoration: InputDecoration(
              hintText:
                  '📍 Votre adresse professionnelle complète\nExemple: 123 Rue de la Beauté, 1000 Tunis, Tunisie',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB3D9), Color(0xFFFFC0E1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB3D9).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Utiliser ma position',
                    icon: const Icon(Icons.my_location, color: Colors.pink),
                    onPressed: _useMyLocation,
                  ),
                  IconButton(
                    tooltip: 'Ouvrir dans Google Maps',
                    icon: const Icon(Icons.map_outlined, color: Colors.pink),
                    onPressed: _openInMaps,
                  ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            ),
          ),
        ),
        if (_addressStatus.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _addressStatus,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // 🌍 Langues parlées
  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Langues parlées',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Options de langues avec style comme sur l'image
        Row(
          children: _languages.entries.map((entry) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _languages[entry.key] = !entry.value;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.pink[200]!,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Radio button personnalisé (seul élément qui change)
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: entry.value ? Colors.pink : Colors.white,
                            border: Border.all(
                              color: Colors.pink,
                              width: 1.5,
                            ),
                          ),
                          child: entry.value
                              ? Icon(
                                  Icons.check,
                                  size: 10,
                                  color: Colors.white,
                                )
                              : null,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          entry.key,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 💳 Abonnement Professionnel
  Widget _buildSubscriptionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Abonnement Professionnel',
            style: TextStyle(
              color: Colors.pink[700],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Accédez à tous les avantages pour seulement 30 Dinars/mois',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 16),

          // Statut
          Row(
            children: [
              Text(
                'Statut',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                _isSubscriptionActive ? 'Actif' : 'Désactivé',
                style: TextStyle(
                  color:
                      _isSubscriptionActive ? Colors.green : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: _isSubscriptionActive,
                onChanged: (bool value) {
                  setState(() {
                    _isSubscriptionActive = value;
                  });
                },
                activeColor: Colors.pink,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Prix et bouton Payer
          Row(
            children: [
              Text(
                '30 DT/mois',
                style: TextStyle(
                  color: Colors.pink[700],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implémenter la logique de paiement
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[100],
                  foregroundColor: Colors.pink[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Payer',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Bouton final
  Widget _buildValidationButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _canValidate()
            ? () {
                // TODO: Implémenter la validation de l'inscription
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canValidate()
              ? Colors.pinkAccent
              : Colors.pinkAccent.withOpacity(0.3),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        child: Text(
          'Valider inscription',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Vérifier si le formulaire peut être validé
  bool _canValidate() {
    return _nomController.text.isNotEmpty &&
        _prenomController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _telephoneController.text.isNotEmpty &&
        _adresseController.text.isNotEmpty &&
        _selectedCategory != null &&
        _selectedServiceType != null;
  }

  void _onAddressChangedDebounced(String value) {
    _addressDebounce?.cancel();
    setState(() {
      _addressStatus = 'Validation de l\'adresse...';
    });
    _addressDebounce = Timer(const Duration(milliseconds: 700), () async {
      await _reverseGeocodeFromInput(value);
    });
  }

  Future<void> _reverseGeocodeFromInput(String raw) async {
    if (raw.trim().isEmpty) {
      setState(() {
        _addressStatus = '';
        _resolvedPlacemark = null;
        _lastLat = null;
        _lastLng = null;
      });
      return;
    }
    try {
      final List<geo.Location> locations = await geo.locationFromAddress(raw);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final List<geo.Placemark> placemarks =
            await geo.placemarkFromCoordinates(
          loc.latitude,
          loc.longitude,
        );
        setState(() {
          _resolvedPlacemark = placemarks.isNotEmpty ? placemarks.first : null;
          _lastLat = loc.latitude;
          _lastLng = loc.longitude;
          _addressStatus = _resolvedPlacemark != null
              ? 'Adresse reconnue: '
                  '${_resolvedPlacemark!.street ?? ''}, '
                  '${_resolvedPlacemark!.locality ?? ''}'
              : 'Adresse introuvable';
        });
      } else {
        setState(() {
          _addressStatus = 'Adresse introuvable';
          _resolvedPlacemark = null;
          _lastLat = null;
          _lastLng = null;
        });
      }
    } catch (_) {
      setState(() {
        _addressStatus = 'Adresse introuvable';
        _resolvedPlacemark = null;
        _lastLat = null;
        _lastLng = null;
      });
    }
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _addressStatus = 'Récupération de votre position...';
    });
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      setState(() {
        _addressStatus = 'Autorisez l\'accès à la localisation';
      });
      return;
    }
    final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium);
    final List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      final composed = [
        if ((p.street ?? '').isNotEmpty) p.street,
        if ((p.postalCode ?? '').isNotEmpty) p.postalCode,
        if ((p.locality ?? '').isNotEmpty) p.locality,
        if ((p.country ?? '').isNotEmpty) p.country,
      ].whereType<String>().join(', ');
      _adresseController.text = composed;
      setState(() {
        _resolvedPlacemark = p;
        _lastLat = pos.latitude;
        _lastLng = pos.longitude;
        _addressStatus = 'Adresse détectée automatiquement';
      });
    } else {
      setState(() {
        _addressStatus = 'Adresse introuvable';
      });
    }
  }

  Future<void> _openInMaps() async {
    String? url;
    if (_lastLat != null && _lastLng != null) {
      url =
          'https://www.google.com/maps/search/?api=1&query=${_lastLat!},${_lastLng!}';
    } else {
      final q = _adresseController.text.trim();
      if (q.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Entrez une adresse ou utilisez ma position.')),
        );
        return;
      }
      url =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}';
    }
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir Google Maps.')),
      );
    }
  }
}
