import 'package:flutter/material.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:go_router/go_router.dart';

class AlterarPasswordScreen extends StatefulWidget {
  const AlterarPasswordScreen({super.key});

  @override
  State<AlterarPasswordScreen> createState() => _AlterarPasswordScreenState();
}

class _AlterarPasswordScreenState extends State<AlterarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordAtualController = TextEditingController();
  final _novaPasswordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  bool _verPasswordAtual = false;
  bool _verNovaPassword = false;
  bool _verConfirmarPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordAtualController.dispose();
    _novaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submeter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final resultado = await APIService.instance.alterarPassword(
      passwordAtual: _passwordAtualController.text.trim(),
      novaPassword: _novaPasswordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado.sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password alterada com sucesso.'),
          backgroundColor: AppConstants.corSucesso,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.erro ?? 'Erro ao alterar password.'),
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
        backgroundColor: AppConstants.corPrimaria,
        foregroundColor: Colors.white,
        title: const Text(
          'Alterar Password',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Password atual
              _buildCampo(
                controller: _passwordAtualController,
                label: 'Password atual',
                verPassword: _verPasswordAtual,
                onToggleVer: () =>
                    setState(() => _verPasswordAtual = !_verPasswordAtual),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obrigatório';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Nova password
              _buildCampo(
                controller: _novaPasswordController,
                label: 'Nova password',
                verPassword: _verNovaPassword,
                onToggleVer: () =>
                    setState(() => _verNovaPassword = !_verNovaPassword),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obrigatório';
                  if (v.length < 8) return 'Mínimo 8 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirmar nova password
              _buildCampo(
                controller: _confirmarPasswordController,
                label: 'Confirmar nova password',
                verPassword: _verConfirmarPassword,
                onToggleVer: () => setState(
                    () => _verConfirmarPassword = !_verConfirmarPassword),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obrigatório';
                  if (v != _novaPasswordController.text) {
                    return 'As passwords não coincidem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Botão guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submeter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.corPrimaria,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Guardar',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampo({
    required TextEditingController controller,
    required String label,
    required bool verPassword,
    required VoidCallback onToggleVer,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !verPassword,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppConstants.corPrimaria),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            verPassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggleVer,
        ),
      ),
    );
  }
}