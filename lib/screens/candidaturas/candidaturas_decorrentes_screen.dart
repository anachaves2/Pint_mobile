import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/screens/candidaturas/candidaturas_screen.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/providers/candidatura_provider.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

class CandidaturasADecorrer extends ConsumerStatefulWidget {
  const CandidaturasADecorrer({super.key});

  @override
  ConsumerState<CandidaturasADecorrer> createState() => _CandidaturasADecorrerState();
}

class _CandidaturasADecorrerState extends ConsumerState<CandidaturasADecorrer> {

  @override
  void initState() {
    super.initState();
    atualizadorDados.stream.listen((_) {
      ref.invalidate(candidaturasProvider);
    });
  }

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
          builder: (ctx) => IconButton(
            icon: SvgPicture.asset('assets/icons/drawerprimario.svg', height: 20,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Candidaturas',
            style: TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg', height: 24,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => context.push(AppConstants.routeNotificacoes),
          ),
        ],
      ),
      // Riverpod: observa o provider e reconstrói automaticamente quando os dados mudam
      body: ref.watch(candidaturasProvider).when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppConstants.corPrimaria)),
        error: (err, _) => Center(child: Text('Erro: $err')),
        data: (todas) {
          // Filtra apenas as candidaturas que ainda não estão concluídas
          final emProgresso = todas.where((c) => !c.estaConcluida).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left, color: AppConstants.corPrimaria),
                    ),
                    const Text('Candidaturas a decorrer',
                        style: TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.black12),
              Expanded(
                child: RefreshIndicator(
                  color: AppConstants.corPrimaria,
                  // Sincroniza com a API e invalida o provider para actualizar a lista
                  onRefresh: () async {
                    await APIService.instance.sincronizarCandidaturas();
                    ref.invalidate(candidaturasProvider);
                  },
                  child: emProgresso.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 80),
                          Center(child: Column(children: [
                            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
                            SizedBox(height: 10),
                            Text('Não tens candidaturas em curso.',
                                style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ])),
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: emProgresso.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                          itemBuilder: (context, i) => CardCandidatura(
                            candidatura: emProgresso[i],
                            onTap: () => context.push(
                              AppConstants.routeDetalheCandidatura,
                              extra: emProgresso[i].numCandidatura,
                            ).then((_) => ref.invalidate(candidaturasProvider)),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}