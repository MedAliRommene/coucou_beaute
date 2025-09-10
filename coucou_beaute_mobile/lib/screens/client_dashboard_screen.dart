import 'package:flutter/material.dart';

class ClientDashboardScreen extends StatelessWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Espace Client')),
      body: const Center(
        child: Text('Bienvenue dans votre espace client'),
      ),
    );
  }
}
