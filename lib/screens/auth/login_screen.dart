import 'package:flutter/material.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_logo.dart'; // Import do nosso novo logo!
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/providers/utilizador_provider.dart';

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
  bool _aceitaPolitica = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_aceitaPolitica) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tem de aceitar a Política de Privacidade para continuar.'),
          backgroundColor: AppConstants.corErro,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await APIService.instance.login(
      _emailController.text.trim(),
      _passwordController.text,
      manterSessao: _manterSessao,
    );

    if (mounted) setState(() => _isLoading = false);

    if (resultado.sucesso) {
      if (mounted) {
        if (!resultado.configuracaoCompleta) {
          ref.invalidate(utilizadorProvider);
          context.go(AppConstants.routeConfiguracaoInicial);
        } else {
          ref.invalidate(utilizadorProvider);
          context.go(AppConstants.routeDashboard);
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.erro ?? 'Erro desconhecido'),
            backgroundColor: AppConstants.corErro,
          ),
        );
      }
    }
  }
void _mostrarPoliticaPrivacidade(BuildContext context) async {
  final nav = Navigator.of(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  final texto = await APIService.instance.getPoliticaPrivacidade();
  if (!mounted) return;
  nav.pop();

  _mostrarDialogoPolitica(texto);
}

void _mostrarDialogoPolitica(String? texto) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Política de Privacidade e RGPD'),
      content: SingleChildScrollView(
        child: Text(
          texto ?? 'Não foi possível carregar a política de privacidade.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Fechar'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() => _aceitaPolitica = true);
            Navigator.pop(ctx);
          },
          child: const Text('Aceitar'),
        ),
      ],
    ),
  );
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
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Insira o seu email',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Por favor, insere o teu email';
                        if (!value.contains('@')) return 'Por favor, insira um email válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Insira a sua password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Por favor, insira a sua password';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Checkbox(
                          value: _manterSessao,
                          onChanged: (value) => setState(() => _manterSessao = value!),
                          activeColor: AppConstants.corPrimaria,
                        ),
                        const Expanded(child: Text('Manter sessão iniciada', style: TextStyle(fontSize: 12))),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _aceitaPolitica,
                          onChanged: (value) => setState(() => _aceitaPolitica = value!),
                          activeColor: AppConstants.corPrimaria,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                                children: [
                                  const TextSpan(text: 'Li e aceito a '),
                                  TextSpan(
                                    text: 'Política de Privacidade',
                                    style: const TextStyle(
                                      color: AppConstants.corPrimaria,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _mostrarPoliticaPrivacidade(context),
                                  ),
                                  const TextSpan(
                                    text: ' e autorizo o tratamento dos meus dados pessoais para efeitos de certificação profissional.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        context.push(AppConstants.routeRecuperarPassword);
                      },
                      child: const Text('Esqueci-me da password', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _fazerLogin,
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Entrar'),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    const Text('SOFTINSA', style: TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.bold))
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