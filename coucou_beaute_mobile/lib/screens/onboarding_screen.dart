import 'package:flutter/material.dart';
import 'professional_registration_screen.dart';
import 'client_registration_screen.dart';
import 'pro_dashboard_screen.dart';
import 'client_dashboard_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? selectedRole;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // 🔝 En-tête (Header)
              _buildHeader(),

              // 📝 Titre + Slogan
              _buildTitleAndSlogan(),

              // 👩‍🦰 Image principale
              _buildMainImage(),

              // Espace entre l'image et la phrase "Je suis..."
              const SizedBox(height: 24),

              // ⚪ Section Choix Utilisateur
              _buildUserChoiceSection(),

              // 📧 Connexion rapide
              _buildQuickLoginSection(),

              // 🔻 Bas de l'écran
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  // 🔝 En-tête (Header)
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo centré et plus grand sans cercle
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE5F0), // Rose très clair
                  Color(0xFFE8F4FD), // Bleu très clair
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB3D9).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo coucou beaute.png',
              height: 120, // Logo plus grand et attirant
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(height: 20), // Plus d'espace après le logo
      ],
    );
  }

  // 📝 Titre + Slogan
  Widget _buildTitleAndSlogan() {
    return Column(
      children: [
        // Sous-titre seulement
        Text(
          'Votre beauté à portée de main',
          style: TextStyle(
            color: Colors.grey[600], // Gris clair
            fontSize: 14, // Taille réduite pour économiser l'espace
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16), // Espacement réduit
      ],
    );
  }

  // 👩‍🦰 Image principale
  Widget _buildMainImage() {
    return Container(
      width: double.infinity,
      height: 200, // Taille réduite de l'image
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20), // Bordures plus arrondies
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.1), // Ombre simple et professionnelle
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/image.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // ⚪ Section Choix Utilisateur
  Widget _buildUserChoiceSection() {
    return Column(
      children: [
        // Titre "Je suis..."
        const Text(
          'Je suis...',
          style: TextStyle(
            color: Colors.black87, // Noir foncé
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12), // Espacement réduit

        // Bouton Cliente avec hover effect
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 6), // Margin réduit
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedRole = 'client';
                  });
                  // TODO: Navigation vers l'espace client
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedRole == 'client'
                      ? const Color(0xFFFFB3D9) // Rose clair quand sélectionné
                      : const Color(0xFFE8E8E8), // Gris clair par défaut
                  foregroundColor: selectedRole == 'client'
                      ? Colors.white // Blanc quand sélectionné
                      : Colors.grey[600], // Gris quand non sélectionné
                  shape: const StadiumBorder(), // Forme arrondie complète
                  minimumSize:
                      const Size(double.infinity, 45), // Hauteur réduite
                  elevation: selectedRole == 'client'
                      ? 6
                      : 2, // Élévation quand sélectionné
                  shadowColor: const Color(0xFFFFB3D9).withOpacity(0.3),
                ),
                child: Text(
                  'Cliente',
                  style: TextStyle(
                    color: selectedRole == 'client'
                        ? Colors.white // Blanc quand sélectionné
                        : Colors.grey[600], // Gris quand non sélectionné
                    fontSize: 16,
                    fontWeight: selectedRole == 'client'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bouton Professionnelle avec hover effect
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 6), // Margin réduit
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedRole = 'professional';
                  });
                  // TODO: Navigation vers l'espace professionnel
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedRole == 'professional'
                      ? const Color(
                          0xFFFFB3D9) // Rose clair quand sélectionné (identique à Cliente)
                      : const Color(0xFFE8E8E8), // Gris clair par défaut
                  foregroundColor: selectedRole == 'professional'
                      ? Colors
                          .white // Blanc quand sélectionné (identique à Cliente)
                      : Colors.grey[600], // Gris quand non sélectionné
                  shape: const StadiumBorder(), // Forme arrondie complète
                  minimumSize:
                      const Size(double.infinity, 45), // Hauteur réduite
                  elevation: selectedRole == 'professional'
                      ? 6
                      : 2, // Élévation identique à Cliente
                  shadowColor: const Color(0xFFFFB3D9).withOpacity(0.3),
                ),
                child: Text(
                  'Professionnelle',
                  style: TextStyle(
                    color: selectedRole == 'professional'
                        ? Colors
                            .white // Blanc quand sélectionné (identique à Cliente)
                        : Colors.grey[600], // Gris quand non sélectionné
                    fontSize: 16,
                    fontWeight: selectedRole == 'professional'
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 📧 Connexion rapide
  Widget _buildQuickLoginSection() {
    return Column(
      children: [
        // Petit texte "Connexion rapide avec" centré
        Center(
          child: Text(
            'Connexion rapide avec',
            style: TextStyle(
              color: Colors.grey[600], // Gris
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(height: 12), // Espacement réduit

        // Champ Email avec couleur claire et professionnelle
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.email,
              color: selectedRole != null
                  ? const Color(
                      0xFFFFB3D9) // Rose clair quand un rôle est choisi
                  : Colors.grey[400], // Gris clair par défaut
            ),
            hintText: 'Votre email',
            hintStyle: TextStyle(
              color: Colors.grey[400], // Gris clair pour le hint
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: selectedRole != null
                    ? const Color(
                        0xFFFFB3D9) // Rose clair quand un rôle est choisi
                    : Colors.grey[300]!, // Gris clair par défaut
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFFFB3D9), width: 2), // Rose clair au focus
            ),
            filled: true,
            fillColor: selectedRole != null
                ? const Color(0xFFFFB3D9).withOpacity(
                    0.05) // Fond rose très clair quand un rôle est choisi
                : Colors.grey[50], // Gris très clair par défaut
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12, // Padding réduit
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 8), // Espacement réduit entre champs

        // Champ Mot de passe avec visibilité
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock,
              color: selectedRole != null
                  ? const Color(0xFFFFB3D9)
                  : Colors.grey[400],
            ),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: selectedRole != null
                      ? const Color(0xFFFFB3D9)
                      : Colors.grey[400]),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            hintText: 'Mot de passe',
            hintStyle: TextStyle(
              color: Colors.grey[400],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: selectedRole != null
                    ? const Color(0xFFFFB3D9)
                    : Colors.grey[300]!,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFFFFB3D9), width: 2),
            ),
            filled: true,
            fillColor: selectedRole != null
                ? const Color(0xFFFFB3D9).withOpacity(0.05)
                : Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Bouton Connecter
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _attemptLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB3D9),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              minimumSize: const Size(double.infinity, 48),
              elevation: 6,
              shadowColor: const Color(0xFFFFB3D9).withOpacity(0.4),
            ),
            child: const Text(
              'Connecter',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  // 🔻 Bas de l'écran
  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16), // Padding pour le bas
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Nouveau sur Coucou Beauté? ',
            style: TextStyle(
              color: Colors.grey[600], // Gris
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigation vers l'inscription selon le rôle choisi
              if (selectedRole == 'professional') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ProfessionalRegistrationScreen(),
                  ),
                );
              } else if (selectedRole == 'client') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientRegistrationScreen(),
                  ),
                );
              } else {
                // Aucun rôle sélectionné
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez d\'abord choisir votre rôle'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor:
                  const Color(0xFFE91E63), // Rose plus sombre et professionnel
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
            ),
            child: const Text(
              'S\'inscrire',
              style: TextStyle(
                color: Color(0xFFE91E63), // Rose plus sombre et professionnel
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isValidEmail(String v) {
    return RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(v);
  }

  void _attemptLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Veuillez saisir un email valide"),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Mot de passe trop court (min 8 caractères)"),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    _loginToApi(email, password);
  }

  Future<void> _loginToApi(String email, String password) async {
    try {
      String _baseApi() {
        const env = String.fromEnvironment('API_BASE');
        if (env.isNotEmpty) return env;
        if (Platform.isAndroid)
          return 'http://10.0.2.2:8000'; // Android emulator -> host
        return 'http://127.0.0.1:8000'; // iOS simulator/desktop
      }

      final uri = Uri.parse('${_baseApi()}/api/auth/login/');
      final client = HttpClient();
      final req = await client.postUrl(uri);
      final payload = jsonEncode({
        "email": email,
        "password": password,
        "expected_role": selectedRole == 'professional'
            ? 'professional'
            : (selectedRole == 'client' ? 'client' : null),
      });
      req.headers.set(
          HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.contentLength = utf8.encode(payload).length;
      req.write(payload);
      final res = await req.close().timeout(const Duration(seconds: 15));
      final body = await res.transform(const Utf8Decoder()).join();
      if (res.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        final role = (data['role'] as String?) ?? 'user';
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Connecté'),
          backgroundColor: Colors.green,
        ));
        if (!context.mounted) return;
        if (role == 'professional') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProDashboardScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ClientDashboardScreen()),
          );
        }
      } else {
        String message = 'Échec de connexion';
        try {
          final err = jsonDecode(body) as Map<String, dynamic>;
          message = (err['detail'] as String?) ?? err.values.first.toString();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ));
      }
    } on SocketException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Connexion refusée. Assurez-vous que le serveur Django tourne et utilisez une URL accessible (10.0.2.2 pour Android émulateur, IP locale sur appareil).'),
        backgroundColor: Colors.redAccent,
      ));
    } on TimeoutException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Délai dépassé. Vérifiez votre connexion réseau.'),
        backgroundColor: Colors.redAccent,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur réseau: $e'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }
}
