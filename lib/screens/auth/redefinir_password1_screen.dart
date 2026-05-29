import 'package:flutter/material.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';

class RedefinirPassword1Screen extends StatefulWidget {
  const RedefinirPassword1Screen({super.key});

  @override
  State<RedefinirPassword1Screen> createState() => _RedefinirPassword1ScreenState();
}

class _RedefinirPassword1ScreenState extends State<RedefinirPassword1Screen> {
  // Alterado para 6 controladores
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  Future<void> _verificarPin(String email) async {
    final codigo = _controllers.map((c) => c.text).join();
    if (codigo.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insira os 6 dígitos.'), backgroundColor: AppConstants.corErro));
      return;
    }

    setState(() => _isLoading = true);
    // Usa o TEU método que já existia na API!
    final resultado = await APIService.instance.verificarCodigo(email, codigo);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resultado.tokenReset != null) {
      // Passa o token_reset para o ecrã seguinte em vez do PIN
      Navigator.pushNamed(
        context, 
        AppConstants.routeRedefinirPassword2,
        arguments: resultado.tokenReset, 
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resultado.erro ?? 'Erro'), backgroundColor: AppConstants.corErro));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
              const Text('Introduza o código:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConstants.corPrimaria)),
              const SizedBox(height: 16),
              Text('Insira o código de 6 dígitos enviado para o seu email.', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
              const SizedBox(height: 32),
              
              // Alterado para 6 quadradinhos mais estreitos para caberem no ecrã
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45, 
                    height: 55,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _verificarPin(email),
                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.corPrimaria, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verificar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}