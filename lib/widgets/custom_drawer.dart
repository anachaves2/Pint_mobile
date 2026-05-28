import 'package:flutter/material.dart';
import 'package:pint_mobile/utils/constants.dart'; // Mantém as tuas constantes
import 'package:flutter_svg/flutter_svg.dart'; // Mantém o SVG do logo

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  // Mantemos o teu método original, preservando o estilo (fontes, cores, chevrons)
  Widget _buildMenuItem(BuildContext context, String title, String routeName, {IconData? leadingIcon}) {
    return Column(
      children: [
        ListTile(
          // Mantemos o estilo de texto do teu print
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16, 
              color: Color.fromARGB(255, 32, 32, 32),
            ),
          ),
          // Mantemos o chevron right do teu print
          trailing: const Icon(
            Icons.chevron_right, 
            size: 20, 
            color: Color.fromARGB(255, 32, 32, 32),
          ),
          onTap: () {
            Navigator.pop(context); // Fecha o Drawer
            if (routeName.isNotEmpty) {
              // Navega para a nova rota, substituindo a atual
              Navigator.pushReplacementNamed(context, routeName);
            }
          },
        ),
        // Mantemos os divisores
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
            // CABEÇALHO BRANCO (Visual de image_fc54a1.png)
            Container(
              color: Colors.white, // <--- ALTERAÇÃO: FUNDO BRANCO NO CABEÇALHO
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Mantemos o teu SVG do logo colorido (sem filtros)
                  SvgPicture.asset(
                    'assets/icons/logo-softinsa.svg',
                    height: 45,
                  ),
                  // Mantemos o teu botão de fechar ('X')
                  IconButton(
                    icon: const Icon(Icons.close, color: Color.fromARGB(255, 0, 0, 0)), // <--- ALTERAÇÃO: 'X' AZUL/TEAL (aproximado do logo)
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ], 
              ),
            ),
            const Divider(height: 1, color: Colors.black12),

            // LISTA DE ITENS (Onde adicionamos as novidades no final, com o visual branco)
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Lista Original (Mantém tudo o que já tinhas)
                  _buildMenuItem(context, 'Dashboard', AppConstants.routeDashboard),
                  _buildMenuItem(context, 'Os Meus Badges', AppConstants.routeMeusBadges),
                  _buildMenuItem(context, 'Os Meus Objetivos', AppConstants.routeObjetivos),
                  _buildMenuItem(context, 'Candidaturas', AppConstants.routeCandidaturas),
                  _buildMenuItem(context, 'Catálogo de Badges', AppConstants.routeCatalogo),
                  _buildMenuItem(context, 'Gamification', AppConstants.routeGamification),
                  _buildMenuItem(context, 'Notificações', AppConstants.routeNotificacoes),
                  _buildMenuItem(context, 'Definições', AppConstants.routeDefinicoes),

                  // ---> NOVIDADES: Inseridas no final da lista, com o mesmo estilo branco <---
                  
                  // Item para ir para o Perfil do Consultor
                  _buildMenuItem(context, 'O Meu Perfil', AppConstants.routePerfil),
                  
                  // Item para fazer Logout e voltar ao Login/Landing
                  _buildMenuItem(context, 'Terminar Sessão', AppConstants.routeLogin),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}