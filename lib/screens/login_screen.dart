import 'package:flutter/material.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controlador para alternar entre a Landing Page (0) e o Login (1)
  final PageController _pageController = PageController();

  // Controladores de texto para ler o que o utilizador escreve
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Chave do formulário para podermos validar os campos
  final _formKey = GlobalKey<FormState>();

  // Variáveis de estado
  bool _obscurePassword = true; // Para esconder/mostrar a password com o olho
  bool _manterSessao = false; // Checkbox de manter sessão
  bool _aceitaPolitica = false; // Checkbox da política de privacidade
  bool _isLoading = false; // Para mostrar um indicador de carregamento durante a chamada à API

  @override
  void dispose() {
    // Limpar os controladores quando o ecrã for destruído para libertar memória
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- FUNÇÃO DE LOGIN ---
  Future<void> _fazerLogin() async {
    // 1. Valida se os campos de texto estão preenchidos corretamente (isto ativa as bordas vermelhas)
    if (!_formKey.currentState!.validate()) {
      return; // Para aqui se houver erros
    }

    // 2. Valida se aceitou a política de privacidade
    if (!_aceitaPolitica) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tem de aceitar a Política de Privacidade para continuar.'),
          backgroundColor: AppConstants.corErro,
        ),
      );
      return;
    }

    // 3. Mostra o loading
    setState(() {
      _isLoading = true;
    });

    // 4. Chama a API
    final resultado = await APIService.instance.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    // 5. Esconde o loading
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    // 6. Trata o resultado
    if (resultado.sucesso) {
      if (mounted) {
        // Se ainda não configurou a área, vai para a configuração inicial, senão vai para o Dashboard
        if (!resultado.configuracaoCompleta) {
          Navigator.pushReplacementNamed(context, AppConstants.routeConfiguracaoInicial);
        } else {
          Navigator.pushReplacementNamed(context, AppConstants.routeDashboard);
        }
      }
    } else {
      // Mostra o erro devolvido pela API (ex: credenciais inválidas)
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

  // --- WIDGET DO LOGO (Reutilizável) ---
  Widget _buildLogo() {
    return Column(
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
            children: [
              TextSpan(text: 'Badge', style: TextStyle(color: AppConstants.corPrimaria)),
              TextSpan(text: 'Boost', style: TextStyle(color: AppConstants.corSecundaria)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'by\nSOFTINSA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppConstants.corPrimaria,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // --- ECRÃ 01: LANDING PAGE ---
  Widget _buildLandingPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          _buildLogo(),
          const SizedBox(height: 40),
          // Simulação dos 3 pontinhos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(AppConstants.corPrimaria),
              const SizedBox(width: 8),
              _buildDot(AppConstants.corPrimaria),
              const SizedBox(width: 8),
              _buildDot(AppConstants.corPrimaria),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Desliza para o formulário de login (página 1)
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Início'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // --- ECRÃ 02: FORMULÁRIO DE LOGIN ---
  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: SingleChildScrollView( // Permite fazer scroll se o teclado cobrir o ecrã
          child: Form(
            key: _formKey, // Essencial para a validação a vermelho
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 40),
                
                // Campo de Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Insere o teu email',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insere o teu email'; // Vai ficar vermelho se falhar
                    }
                    if (!value.contains('@')) {
                      return 'Por favor, insere um email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo de Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Insere a tua password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insere a tua password'; // Vai ficar vermelho se falhar
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Checkboxes
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
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text(
                          'Li e aceito a Política de Privacidade e autorizo o tratamento dos meus dados pessoais para efeitos de certificação profissional.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Esqueci-me da password
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppConstants.routeRecuperarPassword);
                  },
                  child: const Text(
                    'Esqueci-me da password',
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // Botão Entrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _fazerLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Entrar'),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Pequeno logo no fundo
                const Text(
                  'SOFTINSA',
                  style: TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Impede o utilizador de deslizar com o dedo
          children: [
            _buildLandingPage(),
            _buildLoginForm(),
          ],
        ),
      ),
    );
  }
}

