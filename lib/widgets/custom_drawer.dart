import 'package:flutter/material.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  Widget _buildMenuItem(BuildContext context, String title, String routeName) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16, 
              color: Color.fromARGB(255, 32, 32, 32),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right, 
            size: 20, 
            color: Color.fromARGB(255, 32, 32, 32),
          ),
          onTap: () {
            Navigator.pop(context);
            if (routeName.isNotEmpty) {
              Navigator.pushReplacementNamed(context, routeName);
            }
          },
        ),
        const Divider(height: 1, color: Colors.black12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/icons/logo-softinsa.svg',
                    height: 45,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppConstants.corPrimaria),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ], 
              ),
            ),
            const Divider(height: 1, color: Colors.black12),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(context, 'Dashboard', AppConstants.routeDashboard),
                  _buildMenuItem(context, 'Os Meus Badges', AppConstants.routeMeusBadges),
                  _buildMenuItem(context, 'Os Meus Objetivos', AppConstants.routeObjetivos),
                  _buildMenuItem(context, 'Candidaturas', AppConstants.routeCandidaturas),
                  _buildMenuItem(context, 'Catálogo de Badges', AppConstants.routeCatalogo),
                  _buildMenuItem(context, 'Gamification', AppConstants.routeGamification),
                  _buildMenuItem(context, 'Notificações', AppConstants.routeNotificacoes),
                  _buildMenuItem(context, 'Definições', AppConstants.routeDefinicoes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}