import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_logo.dart';
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';

class LandingPageScreen extends ConsumerWidget {
  const LandingPageScreen({super.key});

  //Widget auxilicar para desenhar pontos decorativos
  Widget _buildDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  child: Text(ref.t('mobile_landing_inicio')),
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