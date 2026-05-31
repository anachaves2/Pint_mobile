import 'package:flutter/material.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:go_router/go_router.dart';

class RedefinirPassword2Screen extends StatefulWidget {
  const RedefinirPassword2Screen({super.key});

  @override
  State<RedefinirPassword2Screen> createState() => _RedefinirPassword2ScreenState();
}

class _RedefinirPassword2ScreenState extends State<RedefinirPassword2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _novaPasswordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();
  bool _verPassword = false;
  bool _verConfirmacao = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _novaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  // MÉTODO DO POPUP
  void _mostrarPopupSucesso() {
    showDialog(
      context: context,
      barrierDismissible: false, // Impede que o utilizador feche o popup ao clicar fora
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Ajusta o tamanho ao conteúdo
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.corSucesso.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppConstants.corSucesso, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sucesso!', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.corPrimaria),
              ),
              const SizedBox(height: 8),
              Text(
                'A sua password foi redefinida com sucesso.', 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // vai para o Login
                    context.go(AppConstants.routeLogin);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.corPrimaria,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Voltar ao Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _redefinir(String tokenReset) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final resultado = await APIService.instance.redefinirPassword(tokenReset, _novaPasswordController.text);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resultado.sucesso) {
      // EM VEZ DE NAVEGAR, MOSTRA O POPUP!
      _mostrarPopupSucesso();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resultado.erro ?? 'Erro'), backgroundColor: AppConstants.corErro));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenReset = GoRouterState.of(context).uri.queryParameters['token'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              children: [
                const Spacer(flex: 1),
                const Text('Redefinir password:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConstants.corPrimaria)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _novaPasswordController,
                  obscureText: !_verPassword,
                  decoration: InputDecoration(
                    hintText: 'Nova password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: IconButton(
                      icon: Icon(_verPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _verPassword = !_verPassword),
                    ),
                  ),
                  validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmarPasswordController,
                  obscureText: !_verConfirmacao,
                  decoration: InputDecoration(
                    hintText: 'Confirmar password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: IconButton(
                      icon: Icon(_verConfirmacao ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _verConfirmacao = !_verConfirmacao),
                    ),
                  ),
                  validator: (v) => v != _novaPasswordController.text ? 'As passwords não coincidem' : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _redefinir(tokenReset),
                    style: ElevatedButton.styleFrom(backgroundColor: AppConstants.corPrimaria, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Redefinir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}