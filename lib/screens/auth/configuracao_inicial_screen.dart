import 'package:flutter/material.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:go_router/go_router.dart';

class ConfiguracaoInicialScreen extends StatefulWidget {
  const ConfiguracaoInicialScreen({super.key});

  @override
  State<ConfiguracaoInicialScreen> createState() =>
      _ConfiguracaoInicialScreenState();
}

class _ConfiguracaoInicialScreenState
    extends State<ConfiguracaoInicialScreen> {
  List<Map<String, dynamic>> _areas = [];
  int? _areaSelecionada;
  String? _nomeAreaSelecionada;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _carregarAreas();
  }

  Future<void> _carregarAreas() async {
    final areas = await APIService.instance.getAreas();
    if (mounted) setState(() { _areas = areas; _isLoading = false; });
  }

  Future<void> _guardar() async {
    if (_areaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona a tua área para continuar.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final sucesso = await APIService.instance.configuracaoInicial(
      idArea: _areaSelecionada!,
      nomeArea: _nomeAreaSelecionada!,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (sucesso) {
      context.go(AppConstants.routeDashboard);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao guardar. Tenta novamente.'),
          backgroundColor: AppConstants.corErro,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppConstants.corPrimaria))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    const Text('Bem-vindo!',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.corPrimaria)),
                    const SizedBox(height: 8),
                    const Text(
                        'Escolhe a tua área para personalizarmos a tua experiência.',
                        style:
                            TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 32),
                    Expanded(
                      child: ListView(
                        children: _areas
                            .map((area) => RadioListTile<int>(
                                  title: Text(area['nome'] as String),
                                  value: area['id'] as int,
                                  groupValue: _areaSelecionada,
                                  activeColor: AppConstants.corPrimaria,
                                  onChanged: (val) => setState(() {
                                    _areaSelecionada = val;
                                    _nomeAreaSelecionada = area['nome'] as String;
                                  }),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _guardar,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Continuar'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }
}