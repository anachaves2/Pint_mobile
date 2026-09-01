import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/providers/utilizador_provider.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/custom_logo.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';
import 'package:go_router/go_router.dart';

// ECRÃ TROCAR PASSWORD — PRIMEIRO ACESSO
// Equivalente ao TrocarPasswordPrimeiroAcesso.jsx da web. Obrigatório para
// contas criadas pelo Admin que ainda nunca fizeram login (a API marca
// primeiroAcesso = true enquanto ultimoLogin for null).
//
// Não tem forma de sair sem trocar — é intencional, tal como na web.

class TrocarPasswordPrimeiroAcesso extends ConsumerStatefulWidget {
  const TrocarPasswordPrimeiroAcesso({super.key});

  @override
  ConsumerState<TrocarPasswordPrimeiroAcesso> createState() => _TrocarPasswordPrimeiroAcessoState();
}

class _TrocarPasswordPrimeiroAcessoState extends ConsumerState<TrocarPasswordPrimeiroAcesso> {
  final _formKey = GlobalKey<FormState>();
  final _novaController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _obscureNova = true;
  bool _obscureConfirmar = true;
  bool _isLoading = false;
  String? _erro;

  @override
  void dispose() {
    _novaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _submeter() async {
    setState(() => _erro = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final resultado = await APIService.instance.trocarPasswordPrimeiroAcesso(_novaController.text);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!resultado.sucesso) {
      setState(() => _erro = resultado.erro ?? ref.tr('mobile_trocar_pass_erro'));
      return;
    }

    ref.invalidate(utilizadorProvider);

    // Mesma ordem da web: RGPD a seguir (se ainda não aceite), senão
    // configuração inicial / dashboard.
    final utilizador = await DatabaseService.instance.getUser();
    if (!mounted) return;

    if (utilizador != null && !utilizador.aceitouRgpd) {
      context.go(AppConstants.routeAceitarRgpd);
    } else if (utilizador?.idArea == null) {
      context.go(AppConstants.routeConfiguracaoInicial);
    } else {
      context.go(AppConstants.routeDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: D.fundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: D.e6, vertical: D.e5),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CustomLogo(),
                  const SizedBox(height: D.e6),

                  Text(ref.t('mobile_trocar_pass_titulo'),
                      style: D.tituloSeccao.copyWith(fontSize: 20, color: D.azul600)),
                  const SizedBox(height: D.e2),
                  Text(
                    ref.t('mobile_trocar_pass_subtitulo'),
                    style: D.legenda.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: D.e5),

                  TextFormField(
                    controller: _novaController,
                    obscureText: _obscureNova,
                    decoration: InputDecoration(
                      labelText: ref.t('mobile_trocar_pass_nova_label'),
                      hintText: ref.t('mobile_trocar_pass_nova_hint'),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNova ? Icons.visibility : Icons.visibility_off, color: D.tinta30),
                        onPressed: () => setState(() => _obscureNova = !_obscureNova),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return ref.tr('mobile_trocar_pass_nova_obrigatoria');
                      if (v.length < 8) return ref.tr('mobile_trocar_pass_min_caracteres');
                      return null;
                    },
                  ),
                  const SizedBox(height: D.e4),

                  TextFormField(
                    controller: _confirmarController,
                    obscureText: _obscureConfirmar,
                    decoration: InputDecoration(
                      labelText: ref.t('mobile_trocar_pass_repetir_label'),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmar ? Icons.visibility : Icons.visibility_off, color: D.tinta30),
                        onPressed: () => setState(() => _obscureConfirmar = !_obscureConfirmar),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return ref.tr('mobile_trocar_pass_repetir_obrigatoria');
                      if (v != _novaController.text) return ref.tr('mobile_trocar_pass_nao_coincidem');
                      return null;
                    },
                  ),

                  if (_erro != null) ...[
                    const SizedBox(height: D.e3),
                    Container(
                      padding: const EdgeInsets.all(D.e3),
                      decoration: BoxDecoration(color: D.erroBg, borderRadius: BorderRadius.circular(D.rSm)),
                      child: Text(_erro!, style: const TextStyle(color: D.erro, fontSize: 13)),
                    ),
                  ],

                  const SizedBox(height: D.e5),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submeter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: D.azul600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: D.e3 + 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(ref.t('mobile_trocar_pass_botao'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}