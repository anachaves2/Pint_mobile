import 'package:flutter/material.dart';
import 'package:pint_mobile/utils/constants.dart';

class CustomLogo extends StatelessWidget {
  const CustomLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
            children: [
              TextSpan(text: 'Badge', style: TextStyle(color: AppConstants.corPrimaria)),
              TextSpan(text: 'Boost', style: TextStyle(color: AppConstants.corSecundaria)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'by\nSOFTINSA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppConstants.corPrimaria,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}