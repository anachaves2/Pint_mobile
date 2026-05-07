import 'package:flutter/material.dart';
// O import abaixo não está a ser usado (ainda) neste ficheiro, por isso podemos removê-lo para ter o código mais limpo.
// import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';

class DashboardScreen extends StatefulWidget{
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder( 
          builder: (context) {
            return IconButton(
              icon: SvgPicture.asset(
                'assets/icons/drawer.svg',
                height: 20,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn),
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          }
        ),
        title: const Text(
          'DASHBOARD',
          style: TextStyle(
            color: AppConstants.corPrimaria,
            fontSize: 20,
            fontWeight: FontWeight.bold, 
          ),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/notificacoesprimaria.svg', 
              height: 24,
              colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn),
            ),
            onPressed: () {
              //Colocar o widget do ecrã de notificações
            },
          ),
        ],
      ),
    );
  }
}