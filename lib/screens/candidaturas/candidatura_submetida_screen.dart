import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

class CandidaturaSubmetida extends StatelessWidget {
  const CandidaturaSubmetida({super.key});

  @override
  Widget build(BuildContext context) {
    final numCandidatura = GoRouterState.of(context).extra as int?;

    return Scaffold(
      backgroundColor: D.fundo,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: SvgPicture.asset('assets/icons/drawerprimario.svg', height: 20,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('CANDIDATURAS', style: D.tituloPagina),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg', height: 24,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => context.push(AppConstants.routeNotificacoes),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: D.e6, vertical: D.e6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(color: D.okBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline, size: 56, color: D.ok),
              ),
              const SizedBox(height: D.e5),
              Text('Novo pedido submetido!', style: D.tituloSeccao.copyWith(fontSize: 22), textAlign: TextAlign.center),
              const SizedBox(height: D.e2),
              Text(
                'A tua candidatura foi submetida com sucesso e encontra-se agora em validação pelo Talent Manager.',
                style: D.corpo.copyWith(color: D.tinta30, height: 1.5),
                textAlign: TextAlign.center,
              ),
              if (numCandidatura != null) ...[
                const SizedBox(height: D.e3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: D.e3, vertical: D.e2 + 2),
                  decoration: BoxDecoration(color: D.fundoAlt, borderRadius: BorderRadius.circular(D.rMd)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 16, color: D.tinta30),
                      const SizedBox(width: 6),
                      Text('Candidatura Nº $numCandidatura', style: D.legenda.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: D.e6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(AppConstants.routeCandidaturas),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: D.azul600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: D.e3 + 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
                  ),
                  child: const Text('Ver Candidaturas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
              const SizedBox(height: D.e2 + 2),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(AppConstants.routeNovaCandidatura),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: D.azul600,
                    side: const BorderSide(color: D.azul600),
                    padding: const EdgeInsets.symmetric(vertical: D.e3 + 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
                  ),
                  child: const Text('Nova Candidatura', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}