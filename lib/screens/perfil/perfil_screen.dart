import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/consultor.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/providers/utilizador_provider.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

// Ecrã do Perfil
// Mostra os dados pessoais do consultor autenticado.
//
// MIGRAÇÃO SQLITE → RIVERPOD:
//   Antes: initState() chamava DatabaseService.instance.getUser()
//   Agora:  ref.watch(utilizadorProvider) devolve o AsyncValue<Consultor?>
//   O widget é ConsumerWidget para ter acesso ao WidgetRef (ref).

class Perfil extends ConsumerWidget {
  const Perfil({super.key});

  static const Color _azulPrimario = AppConstants.corPrimaria;
  static const Color _azulClaro = Color(0xFFE8F0FB);
  static const Color _cinzaTexto = Color(0xFF555555);
  static const Color _cinzaClaro = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch reage automaticamente a qualquer mudança no provider.
    // AsyncValue tem 3 estados: loading / data / error — tratamos os 3 abaixo.
    final consultorAsync = ref.watch(utilizadorProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(),
      appBar: _buildAppBar(context),
      body: consultorAsync.when(
        // Estado de carregamento — mostra o spinner
        loading: () => const Center(
          child: CircularProgressIndicator(color: _azulPrimario),
        ),
        // Estado de erro — mostra mensagem e botão para tentar novamente
        error: (err, _) => _buildErro(context, ref),
        // Estado com dados — mostra o perfil (ou erro se o consultor for null)
        data: (consultor) {
          if (consultor == null) return _buildErro(context, ref);
          return RefreshIndicator(
            color: _azulPrimario,
            // Pull to refresh: sincroniza com a API e atualiza o provider
            onRefresh: () async {
              await APIService.instance.sincronizarTodos();
              // Invalida o cache do provider → chama build() novamente → relê do SQLite
              ref.invalidate(utilizadorProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildFotoPerfil(consultor),
                  const SizedBox(height: 12),
                  _buildNomeECargo(consultor),
                  const SizedBox(height: 12),
                  _buildRankingEPontos(consultor),
                  const SizedBox(height: 28),
                  _buildSecaoInformacoes(consultor),
                  const SizedBox(height: 12),
                  _buildMembroDesde(consultor),
                  const SizedBox(height: 32),
                  _buildBotaoDefinicoes(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  // ─── AppBar ───────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: SvgPicture.asset(
            'assets/icons/drawerprimario.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppConstants.corPrimaria,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: const Text(
        'PERFIL',
        style: TextStyle(
          color: _azulPrimario,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.2,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            'assets/icons/notificacoesprimaria.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppConstants.corPrimaria,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => context.push(AppConstants.routeNotificacoes),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }

  // ─── Ecrã de erro ─────────────────────────────────────────────────────────

  Widget _buildErro(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.grey.shade300, size: 64),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar perfil',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            // ref.invalidate força o provider a reconstruir-se
            onPressed: () => ref.invalidate(utilizadorProvider),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  // ─── Widgets de conteúdo ──────────────────────────────────────────────────

  Widget _buildFotoPerfil(Consultor consultor) {
    return CircleAvatar(
      radius: 48,
      backgroundColor: Colors.grey.shade300,
      backgroundImage:
          consultor.urlFoto != null ? NetworkImage(consultor.urlFoto!) : null,
      child: consultor.urlFoto == null
          ? const Icon(Icons.person, size: 48, color: Colors.grey)
          : null,
    );
  }

  Widget _buildNomeECargo(Consultor consultor) {
    return Column(
      children: [
        Text(
          consultor.nome,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _azulClaro,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'CONSULTOR',
            style: TextStyle(
              fontSize: 11,
              color: _azulPrimario,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingEPontos(Consultor consultor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildChip(
          icon: Icons.emoji_events_outlined,
          label: consultor.posicaoRanking != null
              ? '${consultor.posicaoRanking}ª Posição'
              : '-- Posição',
          cor: _azulPrimario,
        ),
        const SizedBox(width: 12),
        _buildChip(
          icon: Icons.star_outline,
          label: '${consultor.totalPontos ?? 0} Pontos',
          cor: const Color(0xFFF5A623),
        ),
      ],
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: cor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
        color: cor.withValues(alpha: 0.07),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoInformacoes(Consultor consultor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INFORMAÇÕES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _cinzaTexto,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _cinzaClaro,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildLinhaInfo(icon: Icons.email_outlined, texto: consultor.email),
              _buildDivisor(),
              _buildLinhaInfo(
                icon: Icons.phone_outlined,
                texto: consultor.telefone ?? 'Sem telefone',
                vazio: consultor.telefone == null,
              ),
              _buildDivisor(),
              _buildLinhaInfo(
                icon: Icons.link,
                texto: consultor.urlLinkedin ?? 'Sem LinkedIn',
                vazio: consultor.urlLinkedin == null,
                isLink: consultor.urlLinkedin != null,
              ),
              _buildDivisor(),
              _buildLinhaInfo(
                icon: Icons.language,
                texto:
                    'www.softinsa.pt/galeria-publico/${consultor.nome.toLowerCase().replaceAll(' ', '-')}',
                isLink: true,
              ),
              _buildDivisor(),
              _buildLinhaInfo(
                icon: Icons.work_outline,
                texto: 'Área: ${consultor.nomeArea}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinhaInfo({
    required IconData icon,
    required String texto,
    bool vazio = false,
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: vazio ? Colors.grey.shade400 : _azulPrimario,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                color: vazio
                    ? Colors.grey.shade400
                    : isLink
                        ? _azulPrimario
                        : Colors.black87,
                decoration: isLink ? TextDecoration.underline : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivisor() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildMembroDesde(Consultor consultor) {
    final data = consultor.dataMembro;
    final dataFormatada =
        '${data.day.toString().padLeft(2, '0')}-${data.month.toString().padLeft(2, '0')}-${data.year}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          'Membro desde: $dataFormatada',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBotaoDefinicoes(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => context.push(AppConstants.routeDefinicoes),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _azulPrimario),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text(
          'DEFINIÇÕES',
          style: TextStyle(
            color: _azulPrimario,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}