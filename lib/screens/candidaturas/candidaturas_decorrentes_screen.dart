import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pint_mobile/models/candidatura_badge.dart';
import 'package:pint_mobile/screens/candidaturas/candidaturas_screen.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

class CandidaturasADecorrer extends StatefulWidget {
  const CandidaturasADecorrer({super.key});

  @override
  State<CandidaturasADecorrer> createState() => _CandidaturasADecorrerState();
}

class _CandidaturasADecorrerState extends State<CandidaturasADecorrer> {
  List<CandidaturaBadge> _candidaturas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
    atualizadorDados.stream.listen((_) => _carregar());
  }

  Future<void> _carregar() async {
    final todas = await DatabaseService.instance.getCandidaturas();
    if (mounted) setState(() { _candidaturas = todas.where((c) => !c.estaConcluida).toList(); _isLoading = false; });
  }

  Future<void> _refresh() async {
    await APIService.instance.sincronizarCandidaturas();
    await _carregar();
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
      body: Column(
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.corPrimaria))
                : RefreshIndicator(
                    color: AppConstants.corPrimaria,
                    onRefresh: _refresh,
                    child: _candidaturas.isEmpty
                        ? ListView(children: const [
                            SizedBox(height: 80),
                            Center(child: Column(children: [
                              Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('Não tens candidaturas em curso.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            ])),
                          ])
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _candidaturas.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) => CardCandidatura(
                              candidatura: _candidaturas[i],
                              onTap: () => context.push(AppConstants.routeDetalheCandidatura, extra: _candidaturas[i].numCandidatura).then((_) => _refresh()),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}