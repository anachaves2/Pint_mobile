import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/providers/utilizador_provider.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:go_router/go_router.dart';

// ECRÃ ACEITAR RGPD
// Equivalente ao AceitarRgpd.jsx da web: aparece DEPOIS do login, sempre que
// aceitouRgpd vier false (nunca aceitou, ou revogou nas Definições).
//
// Antes, no mobile, isto era uma checkbox no próprio formulário de login —
// o que não registava nada na base de dados, apenas bloqueava o botão.
// Agora o consentimento é mesmo persistido via PUT /perfil/rgpd.

class AceitarRgpdScreen extends ConsumerStatefulWidget {
  const AceitarRgpdScreen({super.key});

  @override
  ConsumerState<AceitarRgpdScreen> createState() => _AceitarRgpdScreenState();
}

class _AceitarRgpdScreenState extends ConsumerState<AceitarRgpdScreen> {
  String? _conteudo;
  bool _aCarregar = true;
  bool _aGuardar = false;
  String? _erro;
  String _primeiroNome = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final texto = await APIService.instance.getPoliticaPrivacidade();
    final utilizador = await DatabaseService.instance.getUser();
    if (!mounted) return;
    setState(() {
      _conteudo = texto;
      _primeiroNome = utilizador?.nome.split(' ').first ?? '';
      _aCarregar = false;
    });
  }

  Future<void> _aceitar() async {
    setState(() {
      _aGuardar = true;
      _erro = null;
    });

    final resultado = await APIService.instance.atualizarConsentimentoRgpd(true);
    if (!mounted) return;
    setState(() => _aGuardar = false);

    if (!resultado.sucesso) {
      setState(() => _erro = resultado.erro ?? 'Não foi possível registar a aceitação.');
      return;
    }

    ref.invalidate(utilizadorProvider);

    // Se ainda não escolheu a área, passa pela configuração inicial
    final utilizador = await DatabaseService.instance.getUser();
    if (!mounted) return;

    if (utilizador?.idArea == null) {
      context.go(AppConstants.routeConfiguracaoInicial);
    } else {
      context.go(AppConstants.routeDashboard);
    }
  }

  Future<void> _sairSemAceitar() async {
    await APIService.instance.logout();
    if (mounted) context.go(AppConstants.routeLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: D.fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: D.e5, vertical: D.e5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _primeiroNome.isEmpty ? 'Olá' : 'Olá, $_primeiroNome',
                style: D.tituloSeccao.copyWith(fontSize: 22, color: D.azul600),
              ),
              const SizedBox(height: D.e2),
              Text(
                'Antes de continuar, precisamos que confirmes que leste e aceitas a nossa Política de Privacidade.',
                style: D.legenda.copyWith(height: 1.5),
              ),
              const SizedBox(height: D.e4),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(D.e4),
                  decoration: BoxDecoration(color: D.fundoAlt, borderRadius: BorderRadius.circular(D.rLg)),
                  child: _aCarregar
                      ? const Center(child: CircularProgressIndicator(color: D.azul600))
                      : SingleChildScrollView(
                          child: Text(
                            _conteudo ?? 'Política de privacidade não disponível de momento.',
                            style: D.corpo.copyWith(height: 1.7),
                          ),
                        ),
                ),
              ),

              if (_erro != null) ...[
                const SizedBox(height: D.e3),
                Container(
                  padding: const EdgeInsets.all(D.e3),
                  decoration: BoxDecoration(color: D.erroBg, borderRadius: BorderRadius.circular(D.rSm)),
                  child: Text(_erro!, style: const TextStyle(color: D.erro, fontSize: 13)),
                ),
              ],

              const SizedBox(height: D.e4),
              ElevatedButton(
                onPressed: (_aGuardar || _aCarregar) ? null : _aceitar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: D.azul600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: D.fundoAlt,
                  padding: const EdgeInsets.symmetric(vertical: D.e3 + 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
                ),
                child: _aGuardar
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Li e aceito a Política de Privacidade',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              const SizedBox(height: D.e2),
              OutlinedButton(
                onPressed: _aGuardar ? null : _sairSemAceitar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: D.tinta50,
                  side: const BorderSide(color: D.tinta30),
                  padding: const EdgeInsets.symmetric(vertical: D.e3 + 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
                ),
                child: const Text('Sair sem aceitar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}