import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFFE91E63);      // Rose principal
  static const Color primaryLight = Color(0xFFF8BBD9); // Rose clair
  static const Color primaryDark = Color(0xFFC2185B);  // Rose foncé
  
  // Couleurs secondaires
  static const Color secondary = Color(0xFFFF9800);    // Orange
  static const Color accent = Color(0xFF4CAF50);       // Vert
  
  // Couleurs de fond
  static const Color background = Color(0xFFFFFFFF);   // Blanc
  static const Color surface = Color(0xFFF5F5F5);     // Gris très clair
  static const Color card = Color(0xFFFFFFFF);        // Blanc pour les cartes
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFF212121);   // Noir principal
  static const Color textSecondary = Color(0xFF757575); // Gris moyen
  static const Color textLight = Color(0xFFBDBDBD);     // Gris clair
  
  // Couleurs d'état
  static const Color success = Color(0xFF4CAF50);       // Vert succès
  static const Color warning = Color(0xFFFF9800);       // Orange avertissement
  static const Color error = Color(0xFFF44336);         // Rouge erreur
  static const Color info = Color(0xFF2196F3);          // Bleu info
  
  // Couleurs spéciales
  static const Color admin = Color(0xFFFFD700);         // Jaune admin
  static const Color pending = Color(0xFFFFC107);       // Jaune en attente
  
  // Couleurs de gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
