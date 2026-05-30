import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/services/api_service.dart';
 
class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});
 
  Widget _buildMenuItem(BuildContext context, String title, String routeName, {VoidCallback? onTapOverride}) {
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
          onTap: onTapOverride ?? () {
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
 
Future<void> _terminarSessao(BuildContext context) async {
    // 1. Mostrar o popup PRIMEIRO, enquanto o Drawer e o context estão válidos
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminar sessão'),
        content: const Text('Pretende terminar a sua sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // Retorna false
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), // Retorna true
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.corPrimaria,
            ),
            child: const Text('Terminar sessão', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    // Se a pessoa cancelou (clicou fora ou no botão Cancelar), não fazemos mais nada.
    if (confirmar != true) return;

    // 2. Se confirmou, executamos o logout
    await APIService.instance.logout();

    // 3. Verificamos se o context ainda está montado (boa prática no Flutter!) e navegamos
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppConstants.routeLanding,
        (route) => false,
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // CABEÇALHO
            Container(
              color: Colors.white, 
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/icons/logo-softinsa.svg',
                    height: 45,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color.fromARGB(255, 0, 0, 0)), 
                    onPressed: () => Navigator.pop(context),
                  ),
                ], 
              ),
            ),
            const Divider(height: 1, color: Colors.black12),
 
            // LISTA DE ITENS
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
                  _buildMenuItem(context, 'O Meu Perfil', AppConstants.routePerfil),
 
                  // LOGOUT
                  _buildMenuItem(
                    context,
                    'Terminar Sessão',
                    '',
                    onTapOverride: () => _terminarSessao(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 