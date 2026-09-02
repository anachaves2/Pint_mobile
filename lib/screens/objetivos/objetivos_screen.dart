import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/models/objetivo.dart';
import 'package:pint_mobile/providers/objetivos_provider.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';

/// Ecrãs 19 e 20 do protótipo (ObjetivosFinalizados / ObjetivosEmProgresso).
///
/// No protótipo são dois ecrãs separados. Aqui ficam como duas tabs do mesmo
/// ecrã: no telemóvel é mais natural alternar do que navegar para trás e para
/// a frente, e evita duplicar o cabeçalho e o RefreshIndicator.
class ObjetivosScreen extends ConsumerStatefulWidget {
  const ObjetivosScreen({super.key});

  @override
  ConsumerState<ObjetivosScreen> createState() => _ObjetivosScreenState();
}

class _ObjetivosScreenState extends ConsumerState<ObjetivosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    // Ao entrar no ecrã sincroniza em segundo plano — os dados do SQLite
    // aparecem logo e são substituídos quando a resposta chegar.
    _sincronizar();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _sincronizar() async {
    await APIService.instance.sincronizarObjetivos();
    if (mounted) ref.invalidate(objetivosProvider);
  }

  @override
  Widget build(BuildContext context) {
    final emProgresso = ref.watch(objetivosEmProgressoProvider);
    final finalizados = ref.watch(objetivosFinalizadosProvider);
    final estado = ref.watch(objetivosProvider);

    return Scaffold(
      backgroundColor: D.fundo,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: SvgPicture.asset('assets/icons/drawerprimario.svg',
                height: 20,
                colorFilter: const ColorFilter.mode(
                    AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(ref.t('mobile_dash_objetivos_titulo'), style: D.tituloPagina),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg',
                height: 24,
                colorFilter: const ColorFilter.mode(
                    AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => context.push(AppConstants.routeNotificacoes),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            margin: const EdgeInsets.fromLTRB(D.e4, 0, D.e4, D.e2),
            decoration: BoxDecoration(
              color: D.superficie,
              borderRadius: BorderRadius.circular(D.rSm),
              boxShadow: D.elev1,
            ),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                color: D.azul600,
                borderRadius: BorderRadius.circular(D.rSm),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: D.tinta30,
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: '${ref.t('mobile_cand_em_progresso')} (${emProgresso.length})'),
                Tab(text: '${ref.t('mobile_obj_finalizados')} (${finalizados.length})'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: D.azul600,
        onPressed: () => context.push('${AppConstants.routeObjetivos}/novo'),
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        label: Text(ref.t('mobile_obj_definir'),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
      body: estado.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppConstants.corPrimaria)),
        error: (err, _) => _Vazio(
          icone: Icons.cloud_off_outlined,
          titulo: ref.t('mobile_obj_erro_titulo'),
          texto: ref.t('mobile_obj_erro_texto'),
        ),
        data: (_) => TabBarView(
          controller: _tabs,
          children: [
            _Lista(
              objetivos: emProgresso,
              aoAtualizar: _sincronizar,
              vazio: _Vazio(
                icone: Icons.flag_outlined,
                titulo: ref.t('mobile_obj_vazio_progresso_titulo'),
                texto: ref.t('mobile_obj_vazio_progresso_texto'),
              ),
            ),
            _Lista(
              objetivos: finalizados,
              aoAtualizar: _sincronizar,
              vazio: _Vazio(
                icone: Icons.emoji_events_outlined,
                titulo: ref.t('mobile_obj_vazio_finalizados_titulo'),
                texto: ref.t('mobile_obj_vazio_finalizados_texto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Lista
// ─────────────────────────────────────────────────────────

class _Lista extends StatelessWidget {
  const _Lista({
    required this.objetivos,
    required this.aoAtualizar,
    required this.vazio,
  });

  final List<Objetivo> objetivos;
  final Future<void> Function() aoAtualizar;
  final Widget vazio;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppConstants.corPrimaria,
      onRefresh: aoAtualizar,
      child: objetivos.isEmpty
          // ListView (e não Center) para o pull-to-refresh continuar a funcionar
          ? ListView(children: [const SizedBox(height: 60), vazio])
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(D.e4, D.e3, D.e4, 96),
              itemCount: objetivos.length,
              separatorBuilder: (_, __) => const SizedBox(height: D.e3),
              itemBuilder: (_, i) => _CardObjetivo(objetivo: objetivos[i]),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Card de objetivo
// ─────────────────────────────────────────────────────────

class _CardObjetivo extends ConsumerWidget {
  const _CardObjetivo({required this.objetivo});

  final Objetivo objetivo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cor = D.corDoTipo(objetivo.idTipoObjetivo);
    final icone = D.iconeDoTipo(objetivo.idTipoObjetivo);
    final emCurso = objetivo.estado == 'Em Curso';

    return CardGradiente(
      padding: const EdgeInsets.all(D.e4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho: ícone do tipo + nome + estado ──
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(D.rSm),
                ),
                child: Icon(icone, size: 20, color: cor),
              ),
              const SizedBox(width: D.e3),
              Expanded(
                child: Text(objetivo.nomeTipoObjetivo,
                    style: D.tituloCard, maxLines: 2),
              ),
              const SizedBox(width: D.e2),
              _chipEstado(objetivo, ref),
            ],
          ),

          const SizedBox(height: D.e4),

          // ── Prazo ──
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 15, color: D.tinta30),
              const SizedBox(width: D.e1 + 2),
              Text('${ref.t('mobile_obj_definido_em')} ${_data(objetivo.dataInicio)}',
                  style: D.legenda),
              const Spacer(),
              Text('${ref.t('mobile_badges_expira_em')} ${_data(objetivo.dataFim)}', style: D.legenda),
            ],
          ),

          if (emCurso) ...[
            const SizedBox(height: D.e3),
            _BarraPrazo(objetivo: objetivo),
            const SizedBox(height: D.e4),
            Row(
              children: [
                Expanded(
                  child: _BotaoSecundario(
                    icone: Icons.edit_outlined,
                    texto: ref.t('mobile_obj_editar'),
                    onTap: () => _abrirEditar(context, ref, objetivo),
                  ),
                ),
                const SizedBox(width: D.e2),
                Expanded(
                  child: _BotaoSecundario(
                    icone: Icons.delete_outline,
                    texto: ref.t('mobile_obj_remover'),
                    cor: D.erro,
                    onTap: () => _confirmarRemover(context, ref, objetivo),
                  ),
                ),
              ],
            ),
          ] else if (objetivo.dataConclusao != null) ...[
            const SizedBox(height: D.e2),
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 15, color: D.tinta30),
                const SizedBox(width: D.e1 + 2),
                Text('${ref.t('mobile_obj_alcancado_em')} ${_data(objetivo.dataConclusao!)}',
                    style: D.legenda),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chipEstado(Objetivo o, WidgetRef ref) {
    if (o.estado == 'Em Curso') {
      if (o.ultrapassado) {
        return ChipEstado(
            texto: ref.t('mobile_badges_expirado'), cor: D.erro, corFundo: D.erroBg);
      }
      if (o.proximoDoPrazo) {
        return ChipEstado(
            texto: '${o.diasRestantes}d', cor: D.aviso, corFundo: D.avisoBg);
      }
      return ChipEstado(
          texto: ref.t('mobile_obj_em_curso'), cor: D.azul600, corFundo: D.azul100);
    }
    if (o.alcancado) {
      return ChipEstado(
          texto: ref.t('mobile_obj_alcancado'),
          cor: D.ok,
          corFundo: D.okBg,
          icone: Icons.check);
    }
    return ChipEstado(
        texto: ref.t('mobile_obj_nao_alcancado'), cor: D.erro, corFundo: D.erroBg);
  }

  // ── Ações ──

  void _abrirEditar(BuildContext context, WidgetRef ref, Objetivo o) async {
    final nova = await showDatePicker(
      context: context,
      initialDate: o.dataFim,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: ref.tr('mobile_obj_nova_data_limite'),
    );
    if (nova == null) return;

    final r = await APIService.instance.editarObjetivo(
      idObjetivo: o.id,
      dataInicio: o.dataInicio,
      dataFim: nova,
    );

    if (!context.mounted) return;
    if (r.sucesso) {
      await APIService.instance.sincronizarObjetivos();
      ref.invalidate(objetivosProvider);
      _aviso(context, ref.tr('mobile_obj_atualizado'), D.ok);
    } else {
      _aviso(context, r.erro ?? ref.tr('mobile_obj_erro_editar'), D.erro);
    }
  }

  void _confirmarRemover(
      BuildContext context, WidgetRef ref, Objetivo o) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: D.superficie,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(D.rLg)),
        title: Text(ref.tr('mobile_obj_remover_titulo'), style: D.tituloSeccao),
        content: Text('${ref.tr('mobile_obj_remover_confirmar')} "${o.nomeTipoObjetivo}"?',
            style: D.corpo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ref.tr('mobile_notif_nao'), style: const TextStyle(color: D.tinta50)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: D.erro),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ref.tr('mobile_obj_sim')),
          ),
        ],
      ),
    );

    if (confirmou != true || !context.mounted) return;

    final r = await APIService.instance.removerObjetivo(o.id);
    if (!context.mounted) return;

    if (r.sucesso) {
      await APIService.instance.sincronizarObjetivos();
      ref.invalidate(objetivosProvider);
      _aviso(context, ref.tr('mobile_obj_removido'), D.ok);
    } else {
      _aviso(context, r.erro ?? ref.tr('mobile_obj_erro_remover'), D.erro);
    }
  }

  void _aviso(BuildContext context, String texto, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: cor,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
    ));
  }
}

// ─────────────────────────────────────────────────────────
// Barra de prazo
// ─────────────────────────────────────────────────────────

/// Mostra quanto do prazo já passou (não o progresso real do objetivo,
/// que o backend ainda não devolve). Fica claro no rótulo.
class _BarraPrazo extends ConsumerWidget {
  const _BarraPrazo({required this.objetivo});

  final Objetivo objetivo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = objetivo.dataFim.difference(objetivo.dataInicio).inDays;
    final decorrido = DateTime.now().difference(objetivo.dataInicio).inDays;
    final fracao =
        total <= 0 ? 1.0 : (decorrido / total).clamp(0.0, 1.0).toDouble();

    final cor = objetivo.ultrapassado
        ? D.erro
        : objetivo.proximoDoPrazo
            ? D.aviso
            : D.azul600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fracao,
            minHeight: 7,
            backgroundColor: D.azul100,
            valueColor: AlwaysStoppedAnimation(cor),
          ),
        ),
        const SizedBox(height: D.e1 + 2),
        Text(
          objetivo.ultrapassado
              ? ref.t('mobile_obj_prazo_terminado')
              : '${ref.t('mobile_obj_termina_em')} ${objetivo.diasRestantes} ${objetivo.diasRestantes == 1 ? ref.t('mobile_obj_dia') : ref.t('mobile_obj_dias')}',
          style: D.legenda.copyWith(color: cor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Auxiliares
// ─────────────────────────────────────────────────────────

class _BotaoSecundario extends StatelessWidget {
  const _BotaoSecundario({
    required this.icone,
    required this.texto,
    required this.onTap,
    this.cor = D.azul600,
  });

  final IconData icone;
  final String texto;
  final VoidCallback onTap;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(D.rSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: D.e2 + 2),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(D.rSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 15, color: cor),
            const SizedBox(width: D.e1 + 2),
            Text(texto,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: cor)),
          ],
        ),
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio({
    required this.icone,
    required this.titulo,
    required this.texto,
  });

  final IconData icone;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: D.e6, vertical: D.e5),
      child: Column(
        children: [
          Icon(icone, size: 44, color: D.tinta30),
          const SizedBox(height: D.e4),
          Text(titulo, style: D.tituloCard, textAlign: TextAlign.center),
          const SizedBox(height: D.e2),
          Text(texto, style: D.legenda, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

String _data(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';