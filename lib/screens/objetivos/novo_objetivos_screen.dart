import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/models/tipo_objetivo.dart';
import 'package:pint_mobile/providers/objetivos_provider.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';

/// Ecrãs 22, 23 e 26 do protótipo (NovoObjetivoTipo / NovoObjetivoNormal /
/// NovoObjetivoDefinido).
///
/// No protótipo são três ecrãs. Aqui é um só, em dois passos, com o terceiro
/// (confirmação) resolvido por diálogo — poupa duas rotas e mantém o contexto
/// do que o utilizador escolheu sempre visível.
class NovoObjetivoScreen extends ConsumerStatefulWidget {
  const NovoObjetivoScreen({super.key});

  @override
  ConsumerState<NovoObjetivoScreen> createState() => _NovoObjetivoScreenState();
}

class _NovoObjetivoScreenState extends ConsumerState<NovoObjetivoScreen> {
  TipoObjetivo? _tipo;
  DateTime? _dataFim;
  bool _aGuardar = false;
  String? _erro;

  @override
  Widget build(BuildContext context) {
    final tipos = ref.watch(tiposObjetivoProvider);

    return Scaffold(
      backgroundColor: D.fundo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppConstants.corPrimaria),
          // Se já escolheu tipo, o "voltar" recua um passo em vez de sair
          onPressed: () {
            if (_tipo != null) {
              setState(() {
                _tipo = null;
                _dataFim = null;
                _erro = null;
              });
            } else {
              context.pop();
            }
          },
        ),
        title: Text(ref.t('mobile_novo_obj_titulo'), style: D.tituloPagina),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg',
                height: 24,
                colorFilter: const ColorFilter.mode(
                    AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => context.push(AppConstants.routeNotificacoes),
          ),
        ],
      ),
      body: tipos.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppConstants.corPrimaria)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(D.e6),
            child: Text(ref.t('mobile_novo_obj_erro_tipos'),
                style: D.legenda, textAlign: TextAlign.center),
          ),
        ),
        data: (lista) =>
            _tipo == null ? _passoTipo(lista) : _passoData(),
      ),
    );
  }

  // ── Passo 1: escolher o tipo ────────────────────────────

  Widget _passoTipo(List<TipoObjetivo> tipos) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(D.e4, D.e2, D.e4, D.e6),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: D.e4),
          child: Text(ref.t('mobile_novo_obj_pergunta_tipo'),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: D.azul600)),
        ),
        ...tipos.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: D.e3),
              child: CardSimples(
                onTap: () => setState(() => _tipo = t),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: D.corDoTipo(t.id).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(D.rSm),
                      ),
                      child: Icon(D.iconeDoTipo(t.id),
                          size: 21, color: D.corDoTipo(t.id)),
                    ),
                    const SizedBox(width: D.e3),
                    Expanded(child: Text(t.nome, style: D.tituloCard)),
                    const Icon(Icons.chevron_right, color: D.tinta30),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  // ── Passo 2: escolher a data limite ─────────────────────

  Widget _passoData() {
    final t = _tipo!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(D.e4, D.e2, D.e4, D.e6),
      children: [
        CardGradiente(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: D.corDoTipo(t.id).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(D.rSm),
                    ),
                    child: Icon(D.iconeDoTipo(t.id),
                        size: 21, color: D.corDoTipo(t.id)),
                  ),
                  const SizedBox(width: D.e3),
                  Expanded(child: Text(t.nome, style: D.tituloCard)),
                ],
              ),
              if (t.descricao != null && t.descricao!.isNotEmpty) ...[
                const SizedBox(height: D.e3),
                Text(t.descricao!, style: D.legenda),
              ],
            ],
          ),
        ),
        const SizedBox(height: D.e5),
        Text(ref.t('mobile_novo_obj_ate_quando'), style: D.etiqueta),
        const SizedBox(height: D.e2),
        CardSimples(
          onTap: _escolherData,
          padding: const EdgeInsets.symmetric(
              horizontal: D.e4, vertical: D.e3 + 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _dataFim == null
                      ? ref.t('mobile_novo_obj_data_placeholder')
                      : _formatar(_dataFim!),
                  style: _dataFim == null
                      ? D.corpo.copyWith(color: D.tinta30)
                      : D.corpo.copyWith(
                          color: D.tinta, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.calendar_today_outlined,
                  size: 18, color: D.azul600),
            ],
          ),
        ),
        if (_erro != null) ...[
          const SizedBox(height: D.e3),
          Container(
            padding: const EdgeInsets.all(D.e3),
            decoration: BoxDecoration(
              color: D.erroBg,
              borderRadius: BorderRadius.circular(D.rSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: D.erro),
                const SizedBox(width: D.e2),
                Expanded(
                  child: Text(_erro!,
                      style: const TextStyle(fontSize: 13, color: D.erro)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: D.e6),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _aGuardar ? null : () => context.pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: D.e3 + 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(D.rSm)),
                ),
                child: Text(ref.t('mobile_geral_cancelar'),
                    style: const TextStyle(color: D.tinta50, fontSize: 14)),
              ),
            ),
            const SizedBox(width: D.e3),
            Expanded(
              child: FilledButton(
                onPressed: _aGuardar ? null : _guardar,
                style: FilledButton.styleFrom(
                  backgroundColor: D.azul600,
                  padding: const EdgeInsets.symmetric(vertical: D.e3 + 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(D.rSm)),
                ),
                child: _aGuardar
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(ref.t('mobile_geral_guardar'),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Ações ───────────────────────────────────────────────

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? hoje.add(const Duration(days: 90)),
      firstDate: hoje.add(const Duration(days: 1)),
      lastDate: hoje.add(const Duration(days: 365 * 3)),
      helpText: ref.tr('mobile_novo_obj_data_help'),
    );
    if (escolhida != null) {
      setState(() {
        _dataFim = escolhida;
        _erro = null;
      });
    }
  }

  Future<void> _guardar() async {
    if (_dataFim == null) {
      setState(() => _erro = ref.tr('mobile_novo_obj_escolhe_data'));
      return;
    }

    setState(() {
      _aGuardar = true;
      _erro = null;
    });

    final r = await APIService.instance.criarObjetivo(
      idTipoObjetivo: _tipo!.id,
      dataInicio: DateTime.now(),
      dataFim: _dataFim!,
    );

    if (!mounted) return;

    if (!r.sucesso) {
      setState(() {
        _aGuardar = false;
        _erro = r.erro ?? ref.tr('mobile_novo_obj_erro_criar');
      });
      return;
    }

    // O criarObjetivo já sincroniza; basta invalidar para os ecrãs atualizarem
    ref.invalidate(objetivosProvider);

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(D.e5),
          decoration: BoxDecoration(
            color: D.superficie,
            borderRadius: BorderRadius.circular(D.rLg),
            boxShadow: D.elev3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                    color: D.okBg, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 28, color: D.ok),
              ),
              const SizedBox(height: D.e4),
              Text(ref.tr('mobile_novo_obj_sucesso_titulo'),
                  style: D.tituloSeccao, textAlign: TextAlign.center),
              const SizedBox(height: D.e2),
              Text('${ref.tr('mobile_novo_obj_sucesso_ate')} ${_formatar(_dataFim!)} ${ref.tr('mobile_novo_obj_sucesso_conquistar')}',
                  style: D.legenda, textAlign: TextAlign.center),
              const SizedBox(height: D.e5),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: D.azul600,
                    padding: const EdgeInsets.symmetric(vertical: D.e3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(D.rSm)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(ref.tr('mobile_novo_obj_continuar')),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (mounted) context.pop();
  }

  String _formatar(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
}