import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'professional_registration_screen.dart';

class ClientRegistrationScreen extends StatefulWidget {
  const ClientRegistrationScreen({super.key});

  @override
  State<ClientRegistrationScreen> createState() =>
      _ClientRegistrationScreenState();
}

class _ClientRegistrationScreenState extends State<ClientRegistrationScreen> {
  final TextEditingController _identifierController = TextEditingController();

  Future<void> _signInWithGoogle() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Connexion Google désactivée pour le moment')),
    );
  }

  Future<void> _signInWithFacebook() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Connexion Facebook désactivée pour le moment')),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Barre de menu identique à l'écran professionnel
          _buildHeader(),

          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Bienvenue',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inscrivez-vous pour découvrir les meilleurs services de beauté',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'E-mail ou numéro de téléphone',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Entrez votre e-mail ou téléphone',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFFFB3D9), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bouton principal
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Inscription/connexion côté client
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB3D9),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        "S'inscrire / se connecter",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    "En vous inscrivant, vous acceptez nos\nConditions d'utilisation et notre Politique\nde confidentialité",
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 12, height: 1.3),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),
                  // Séparateur "ou"
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8))),
                      ),
                      const SizedBox(width: 8),
                      Text('ou', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8))),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  // Boutons sociaux
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
                  // Lien pro
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
                                  const ProfessionalRegistrationScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Inscrivez-vous ici',
                          style: TextStyle(
                              color: Color(0xFFE91E63),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Barre de menu identique à l'écran professionnel
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
}
