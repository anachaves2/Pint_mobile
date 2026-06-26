import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import 'package:pint_mobile/utils/constants.dart';

// Widget reutilizável do logo: usado no login, landing page e outros ecrãs de auth
class CustomLogo extends StatelessWidget {
  // Permite ajustar a altura do logo SVG conforme o ecrã onde é usado
  final double svgHeight;
  const CustomLogo({
    super.key,
    this.svgHeight = 50.0, 
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, 
      children: [
        // Nome da app em duas cores: "Badge" em azul primário e "Boost" em azul secundário
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 36, 
              fontWeight: FontWeight.bold, 
              fontFamily: 'Roboto',
            ),
            children: [
              TextSpan(
                text: 'Badge', 
                style: TextStyle(color: AppConstants.corPrimaria),
              ),
              TextSpan(
                text: 'Boost', 
                style: TextStyle(color: AppConstants.corSecundaria),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Logo da Softinsa em formato SVG: escalável sem perda de qualidade
        SvgPicture.asset( 
          'assets/icons/logo-softinsa.svg',
          height: svgHeight, 
        ), 
      ],
    );
  }
}

