import 'package:flutter/material.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/custom_logo.dart'; // Import do nosso novo logo!
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/providers/utilizador_provider.dart';
import 'package:pint_mobile/services/notificacoes_service.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';

//Utiliza Riverpod - ConsumerStatefulWidget
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _manterSessao = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //Valida o formulário, chama a API e navega para o Dashboard ou Configuração Inicial
  // Encaminhamento pós-login, pela mesma ordem da web (Login.jsx):
  //   1. primeiroAcesso  -> trocar a password temporária
  //   2. !aceitouRgpd    -> aceitar a Política de Privacidade
  //   3. sem área/config -> configuração inicial
  //   4. caso contrário  -> dashboard
  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final resultado = await APIService.instance.login(
      _emailController.text.trim(),
      _passwordController.text,
      manterSessao: _manterSessao,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!resultado.sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.erro ?? ref.tr('mobile_geral_erro_desconhecido')),
          backgroundColor: AppConstants.corErro,
        ),
      );
      return;
    }

    // Força o provider a recarregar os dados do novo utilizador autenticado
    ref.invalidate(utilizadorProvider);

    // Regista o token FCM deste dispositivo no backend — "best effort", não
    // bloqueia nem afeta o resto do login se falhar (ex.: sem permissão de
    // notificações, ou Firebase ainda não inicializado neste dispositivo).
    final fcmToken = await NotificacoesService.instance.getToken();
    if (fcmToken != null) {
      APIService.instance.enviarTokenFcm(fcmToken);
    }

    if (resultado.primeiroAcesso) {
      context.go(AppConstants.routeTrocarPasswordPrimeiroAcesso);
      return;
    }

    if (!resultado.aceitouRgpd) {
      context.go(AppConstants.routeAceitarRgpd);
      return;
    }

    // Só a partir daqui vale a pena sincronizar — nos casos acima o
    // utilizador ainda não tem acesso ao resto da app.
    APIService.instance.sincronizarTodos();
    APIService.instance.iniciarSincronizacaoPeriodica(
      const Duration(minutes: AppConstants.intervalSincronizacaoMinutos),
    );

    context.go(resultado.configuracaoCompleta
        ? AppConstants.routeDashboard
        : AppConstants.routeConfiguracaoInicial);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Adicionamos uma AppBar invisível só para ter a "setinha" de voltar atrás!
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.corPrimaria),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CustomLogo(), // O widget isolado a ser chamado
                    const SizedBox(height: 40),
                    
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: ref.t('mobile_login_email_label'),
                        hintText: ref.t('mobile_login_email_hint'),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return ref.tr('mobile_login_email_obrigatorio');
                        if (!value.contains('@')) return ref.tr('mobile_login_email_invalido');
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: ref.t('mobile_login_password_label'),
                        hintText: ref.t('mobile_login_password_hint'),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return ref.tr('mobile_login_password_obrigatoria');
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        //Se marcado, guarda o token nas SharedPreferences para manter a sessão
                        Checkbox(
                          value: _manterSessao,
                          onChanged: (value) => setState(() => _manterSessao = value!),
                          activeColor: AppConstants.corPrimaria,
                        ),
                        Expanded(child: Text(ref.t('mobile_login_manter_sessao'), style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        context.push(AppConstants.routeRecuperarPassword);
                      },
                      child: Text(ref.t('mobile_login_esqueci_password'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _fazerLogin,
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(ref.t('mobile_login_entrar')),
                      ),
                    ),
                    const SizedBox(height: D.e5),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}