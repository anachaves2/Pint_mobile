import 'package:flutter/material.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_logo.dart';
import 'package:go_router/go_router.dart'; 

class LandingPageScreen extends StatelessWidget {
  const LandingPageScreen({super.key});

  Widget _buildDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const CustomLogo(), // O widget isolado a ser chamado
              const SizedBox(height: 40),
              // Simulação dos 3 pontinhos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(AppConstants.corPrimaria),
                  const SizedBox(width: 8),
                  _buildDot(AppConstants.corPrimaria),
                  const SizedBox(width: 8),
                  _buildDot(AppConstants.corPrimaria),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navega corretamente para o ecrã de login
                    context.push(AppConstants.routeLogin);
                  },
                  child: const Text('Início'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}