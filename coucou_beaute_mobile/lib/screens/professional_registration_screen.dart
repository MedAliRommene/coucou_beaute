import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  final TextEditingController _salonNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedCategory;
  String? _selectedServiceType;
  bool _isSubscriptionActive = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Password strength state
  bool _pwHasMinLen = false;
  bool _pwHasUpper = false;
  bool _pwHasLower = false;
  bool _pwHasDigit = false;
  bool _pwHasSpecial = false;
  double _pwStrength = 0.0;

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

  String? _profilePhotoUrl;
  String? _idDocumentUrl;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _salonNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  String get _apiBaseUrl =>
      Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000';

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email.trim());
  }

  bool _validatePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(digits);
  }

  String? _mapCategoryToCode(String? label) {
    switch (label) {
      case 'Coiffure':
        return 'hairdressing';
      case 'Esthétique':
      case 'Soins du visage':
        return 'esthetics';
      case 'Manucure':
        return 'manicure';
      case 'Massage':
        return 'massage';
      case 'Autres':
        return 'other';
      default:
        return null;
    }
  }

  String? _mapServiceTypeToCode(String? label) {
    switch (label) {
      case 'Je me déplace':
        return 'mobile';
      case 'Je reçois chez moi':
        return 'home';
      case "J'ai un salon":
        return 'salon';
      default:
        return null;
    }
  }

  List<String> _selectedLanguagesCodes() {
    final List<String> result = [];
    _languages.forEach((k, v) {
      if (v) {
        if (k == 'Français') result.add('french');
        if (k == 'Arabe') result.add('arabic');
        if (k == 'Anglais') result.add('english');
      }
    });
    return result;
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
            icon: const Icon(
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
          const Icon(
            Icons.menu,
            color: Color(0xFF4A90E2), // Bleu vif exact
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
          prefixIcon: const Icon(Icons.email, color: Colors.pink),
        ),

        const SizedBox(height: 12),

        // Téléphone
        _buildTextField(
          controller: _telephoneController,
          hint: '+216 XX XXX XXX',
          prefixIcon: const Icon(Icons.phone, color: Colors.pink),
        ),

        const SizedBox(height: 12),

        // Mot de passe
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          onChanged: _onPasswordChanged,
          decoration: InputDecoration(
            hintText: 'Mot de passe',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.lock, color: Colors.pink),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.pink, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),

        const SizedBox(height: 8),
        _buildPasswordStrength(),

        const SizedBox(height: 12),

        // Confirmer mot de passe
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            hintText: 'Confirmer le mot de passe',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.pink),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscureConfirm ? Icons.visibility : Icons.visibility_off),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.pink, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
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
          borderSide: const BorderSide(color: Colors.pink, width: 2),
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
              child: const Icon(
                Icons.person,
                color: Colors.pink,
                size: 40,
              ),
            ),

            const SizedBox(width: 16),

            // Bouton Télécharger style pill
            Expanded(
              child: ElevatedButton(
                onPressed: _pickProfilePhoto,
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
        if (_profilePhotoUrl != null) ...[
          const SizedBox(height: 8),
          Text('Image sélectionnée',
              style: TextStyle(color: Colors.green[700], fontSize: 12)),
        ],
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
                const Icon(
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
                  onPressed: _pickIdDocument,
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
        if (_idDocumentUrl != null) ...[
          const SizedBox(height: 8),
          Text('Document attaché',
              style: TextStyle(color: Colors.green[700], fontSize: 12)),
        ],
      ],
    );
  }

  // 📂 Catégorie d'activité
  Widget _buildActivityCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
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
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFFFFB3D9),
                size: 20,
              ),
            ),
            items: [..._categories, 'Autres'].map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(
                  category,
                  style: const TextStyle(
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
            style: const TextStyle(
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
        if (_selectedServiceType == "J'ai un salon") ...[
          const SizedBox(height: 12),
          _buildTextField(
            controller: _salonNameController,
            hint: 'Nom de votre salon',
            prefixIcon: const Icon(Icons.business, color: Colors.pink),
          ),
        ],
      ],
    );
  }

  // 🏠 Adresse
  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
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
                              ? const Icon(
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
                child: const Text(
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
        onPressed: _canValidate() && !_isSubmitting ? _submitApplication : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canValidate()
              ? Colors.pinkAccent
              : Colors.pinkAccent.withOpacity(0.3),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        child: Text(
          _isSubmitting ? 'Envoi en cours...' : 'Valider inscription',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Vérifier si le formulaire peut être validé
  bool _canValidate() {
    return _getValidationErrors().isEmpty;
  }

  List<String> _getValidationErrors() {
    final List<String> errors = [];
    if (_prenomController.text.trim().isEmpty) errors.add('Prénom manquant');
    if (_nomController.text.trim().isEmpty) errors.add('Nom manquant');
    if (_emailController.text.trim().isEmpty) {
      errors.add('Email manquant');
    } else if (!_validateEmail(_emailController.text)) {
      errors.add('Email invalide');
    }
    if (_telephoneController.text.trim().isEmpty) {
      errors.add('Numéro de téléphone manquant');
    } else if (!_validatePhone(_telephoneController.text)) {
      errors.add('Numéro de téléphone invalide');
    }
    if (_passwordController.text.isEmpty) {
      errors.add('Mot de passe manquant');
    } else if (_passwordController.text.length < 8) {
      errors.add('Mot de passe trop court (min 8 caractères)');
    }
    if (_confirmPasswordController.text.isEmpty) {
      errors.add('Confirmation du mot de passe manquante');
    } else if (_passwordController.text != _confirmPasswordController.text) {
      errors.add('Les mots de passe ne correspondent pas');
    }
    if (_selectedCategory == null) errors.add("Catégorie d'activité manquante");
    if (_selectedServiceType == null) errors.add('Type de prestation manquant');
    if (_selectedServiceType == "J'ai un salon" &&
        _salonNameController.text.trim().isEmpty) {
      errors.add('Nom du salon manquant');
    }
    if (_adresseController.text.trim().isEmpty) {
      errors.add('Adresse professionnelle manquante');
    }
    if (_profilePhotoUrl == null) errors.add('Photo de profil manquante');
    if (_idDocumentUrl == null) errors.add("Pièce d'identité manquante");
    return errors;
  }

  Future<void> _submitApplication() async {
    FocusScope.of(context).unfocus();
    final scaffold = ScaffoldMessenger.of(context);
    final errors = _getValidationErrors();
    if (errors.isNotEmpty) {
      scaffold.showSnackBar(SnackBar(content: Text(errors.join(' • '))));
      return;
    }

    // Assure lat/lng via géocodage si nécessaire
    if (_lastLat == null || _lastLng == null) {
      try {
        final locs =
            await geo.locationFromAddress(_adresseController.text.trim());
        if (locs.isNotEmpty) {
          _lastLat = locs.first.latitude;
          _lastLng = locs.first.longitude;
        }
      } catch (_) {}
    }

    final categoryCode = _mapCategoryToCode(_selectedCategory);
    final serviceCode = _mapServiceTypeToCode(_selectedServiceType);
    final payload = {
      'first_name': _prenomController.text.trim(),
      'last_name': _nomController.text.trim(),
      'email': _emailController.text.trim(),
      'phone_number': _telephoneController.text.trim(),
      'activity_category': categoryCode,
      'service_type': serviceCode,
      'spoken_languages': _selectedLanguagesCodes(),
      'address': _adresseController.text.trim(),
      'latitude': _lastLat,
      'longitude': _lastLng,
      'profile_photo': _profilePhotoUrl ?? '',
      'id_document': _idDocumentUrl ?? '',
      'subscription_active': _isSubscriptionActive,
      'salon_name': _salonNameController.text.trim(),
      'password': _passwordController.text,
    };

    setState(() => _isSubmitting = true);
    try {
      final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20)));
      final res = await dio.post('$_apiBaseUrl/api/applications/professionals/',
          data: payload);
      if (res.statusCode == 201) {
        scaffold.showSnackBar(const SnackBar(
            content: Text(
                'Demande envoyée avec succès. Vous serez notifié après validation.')));
        Navigator.pop(context);
      } else {
        scaffold
            .showSnackBar(SnackBar(content: Text('Erreur: ${res.statusCode}')));
      }
    } on DioException catch (e) {
      String msg = 'Échec de l\'envoi. Vérifiez vos informations.';
      if (e.response?.data is Map) {
        final Map data = e.response!.data as Map;
        final Map<String, String> labels = {
          'first_name': 'Prénom',
          'last_name': 'Nom',
          'email': 'Email',
          'phone_number': 'Téléphone',
          'activity_category': "Catégorie d'activité",
          'service_type': 'Type de prestation',
          'spoken_languages': 'Langues parlées',
          'address': 'Adresse professionnelle',
          'latitude': 'Latitude',
          'longitude': 'Longitude',
          'profile_photo': 'Photo de profil',
          'id_document': "Pièce d'identité",
          'subscription_active': 'Abonnement',
          'salon_name': 'Nom du salon',
          'password': 'Mot de passe',
        };
        final parts = <String>[];
        data.forEach((key, value) {
          final label = labels[key] ?? key;
          String firstError;
          if (value is List && value.isNotEmpty) {
            firstError = value.first.toString();
          } else {
            firstError = value.toString();
          }
          parts.add('$label: $firstError');
        });
        if (parts.isNotEmpty) {
          msg = parts.join(' • ');
        }
      }
      scaffold.showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      scaffold.showSnackBar(const SnackBar(content: Text('Erreur réseau.')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (picked == null) return;
    await _uploadFile(picked,
        kind: 'profile_photo', onUrl: (u) => _profilePhotoUrl = u);
  }

  Future<void> _pickIdDocument() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 2000, imageQuality: 85);
    if (picked == null) return;
    await _uploadFile(picked,
        kind: 'id_document', onUrl: (u) => _idDocumentUrl = u);
  }

  Future<void> _uploadFile(XFile file,
      {required String kind, required void Function(String url) onUrl}) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final dio = Dio();
      final form = FormData.fromMap({
        'kind': kind,
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
      });
      final res =
          await dio.post('$_apiBaseUrl/api/applications/upload/', data: form);
      final url = res.data['url'] as String?;
      if (url != null) {
        setState(() => onUrl(url));
      } else {
        scaffold.showSnackBar(
            const SnackBar(content: Text('Échec du téléversement.')));
      }
    } catch (_) {
      scaffold.showSnackBar(
          const SnackBar(content: Text('Échec du téléversement.')));
    }
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

  // === Password strength helpers ===
  void _onPasswordChanged(String value) {
    final hasMinLen = value.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasLower = RegExp(r'[a-z]').hasMatch(value);
    final hasDigit = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value);
    final checks = [hasMinLen, hasUpper, hasLower, hasDigit, hasSpecial];
    final satisfied = checks.where((e) => e).length;
    // Strength between 0 and 1
    final strength = (satisfied / checks.length).clamp(0.0, 1.0);
    setState(() {
      _pwHasMinLen = hasMinLen;
      _pwHasUpper = hasUpper;
      _pwHasLower = hasLower;
      _pwHasDigit = hasDigit;
      _pwHasSpecial = hasSpecial;
      _pwStrength = strength;
    });
  }

  Widget _buildPasswordStrength() {
    Color barColor;
    if (_pwStrength >= 0.8) {
      barColor = Colors.green;
    } else if (_pwStrength >= 0.6) {
      barColor = Colors.lightGreen;
    } else if (_pwStrength >= 0.4) {
      barColor = Colors.orange;
    } else if (_pwStrength > 0) {
      barColor = Colors.redAccent;
    } else {
      barColor = Colors.grey.shade300;
    }

    Widget criteriaRow(String text, bool ok) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16, color: ok ? Colors.green : Colors.grey),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _pwStrength == 0 ? null : _pwStrength,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            color: barColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            criteriaRow('≥ 8 caractères', _pwHasMinLen),
            criteriaRow('Majuscule', _pwHasUpper),
            criteriaRow('Minuscule', _pwHasLower),
            criteriaRow('Chiffre', _pwHasDigit),
            criteriaRow('Caractère spécial', _pwHasSpecial),
          ],
        )
      ],
    );
  }
}
