import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import 'package:pint_mobile/utils/constants.dart';

class CustomLogo extends StatelessWidget {
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
        SvgPicture.asset( 
          'assets/icons/logo-softinsa.svg',
          height: svgHeight, 
        ), 
      ],
    );
  }
}

