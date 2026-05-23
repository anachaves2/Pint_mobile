import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pint_mobile/models/consultor.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';

class Perfil extends StatefulWidget {
  const Perfil({super.key});

  @override
  State<Perfil> createState() => _PerfilState();
}

class _PerfilState extends State<Perfil> {
  Consultor? _consultor;
  bool _isLoading = true;

  // Cores Softinsa
  static const Color _azulPrimario = AppConstants.corPrimaria;
  static const Color _azulClaro = Color(0xFFE8F0FB);
  static const Color _cinzaTexto = Color(0xFF555555);
  static const Color _cinzaClaro = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    // Carrega os dados do consultor da base de dados local (SQLite)
    // Estes dados são guardados no login pelo DatabaseService
    final consultor = await DatabaseService.instance.getUser();

    if (mounted) {
      setState(() {
        _consultor = consultor;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _azulPrimario))
          : _consultor == null
              ? const Center(child: Text('Erro ao carregar perfil'))
              : _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: SvgPicture.asset(
            'assets/icons/drawerprimario.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppConstants.corPrimaria,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
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
          onPressed: () {
            Navigator.pushNamed(context, '/notificacoes');
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildFotoPerfil(),
          const SizedBox(height: 12),
          _buildNomeECargo(),
          const SizedBox(height: 12),
          _buildRankingEPontos(),
          const SizedBox(height: 28),
          _buildSecaoInformacoes(),
          const SizedBox(height: 12),
          _buildMembroDesde(),
          const SizedBox(height: 32),
          _buildBotaoDefinicoes(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFotoPerfil() {
    return CircleAvatar(
      radius: 48,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: _consultor!.urlFoto != null
          ? NetworkImage(_consultor!.urlFoto!)
          : null,
      child: _consultor!.urlFoto == null
          ? const Icon(Icons.person, size: 48, color: Colors.grey)
          : null,
    );
  }

  Widget _buildNomeECargo() {
    return Column(
      children: [
        Text(
          _consultor!.nome,
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

  Widget _buildRankingEPontos() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildChip(
          icon: Icons.emoji_events_outlined,
          label:
              '${_consultor!.posicaoRanking != null ? '${_consultor!.posicaoRanking}ª' : '--'} Posição',
          cor: _azulPrimario,
        ),
        const SizedBox(width: 12),
        _buildChip(
          icon: Icons.star_outline,
          label:
              '${_consultor!.totalPontos ?? 0} Pontos',
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

  Widget _buildSecaoInformacoes() {
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
              _buildLinhaInfo(
                icon: Icons.email_outlined,
                texto: _consultor!.email,
              ),
              _buildDivisor(),
              _buildLinhaInfo(
                icon: Icons.phone_outlined,
                texto: _consultor!.telefone ?? 'Sem telefone',
                vazio: _consultor!.telefone == null,
              ),
              _buildDivisor(),
              _buildLinhaInfo(
                icon: Icons.link,
                texto: _consultor!.urlLinkedin ?? 'Sem LinkedIn',
                vazio: _consultor!.urlLinkedin == null,
                isLink: _consultor!.urlLinkedin != null,
              ),
              _buildDivisor(),
              _buildLinhaInfo(
                icon: Icons.language,
                texto: 'www.softinsa.pt/galeria-publico/${_consultor!.nome.toLowerCase().replaceAll(' ', '-')}',
                isLink: true,
              ),
              _buildDivisor(),
              _buildLinhaInfo(
                icon: Icons.work_outline,
                texto: 'Área: ${_consultor!.nomeArea}',
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
          Icon(icon, size: 18, color: vazio ? Colors.grey.shade400 : _azulPrimario),
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

  Widget _buildMembroDesde() {
    final data = _consultor!.dataMembro;
    final dataFormatada =
        '${data.day.toString().padLeft(2, '0')}-${data.month.toString().padLeft(2, '0')}-${data.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          'Membro desde: $dataFormatada',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoDefinicoes() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/definicoes');
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _azulPrimario),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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