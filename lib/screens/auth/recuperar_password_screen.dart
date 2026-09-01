import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';
import 'package:go_router/go_router.dart';

class RecuperarPasswordScreen extends ConsumerStatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  ConsumerState<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends ConsumerState<RecuperarPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  //Envia o email à API, se existir, a PI envia um PIN para o email
  Future<void> _enviarPin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    // Chama a API que construíste
    final resultado = await APIService.instance.recuperarPassword(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resultado.sucesso) {
      // Passa o email como argumento para o ecrã seguinte via go_router
      context.push(
        AppConstants.routeRedefinirPassword1,
        extra: email, 
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.erro ?? ref.tr('mobile_recuperar_erro_enviar')),
          backgroundColor: AppConstants.corErro,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Ícone de voltar (a setinha para a esquerda do protótipo)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                
                // Título
                Text(
                  ref.t('mobile_recuperar_titulo'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.corPrimaria,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Texto de instrução
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info, color: Colors.grey, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ref.t('mobile_recuperar_instrucao'),
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Campo de Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: ref.t('mobile_login_email_label'),
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return ref.tr('mobile_recuperar_email_obrigatorio');
                    if (!value.contains('@')) return ref.tr('mobile_recuperar_email_invalido');
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botão Enviar
                SizedBox(
                  width: 200, // Largura aproximada do protótipo
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _enviarPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.corPrimaria,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            ref.t('mobile_recuperar_enviar'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Logo no fundo
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Text(
                        'SOFT',
                        style: TextStyle(
                          color: AppConstants.corPrimaria,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'INSA',
                        style: TextStyle(
                          color: AppConstants.corSecundaria, // Azul claro para o INSA
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}