import 'package:flutter/material.dart';
import 'package:pint_mobile/utils/design.dart';

// Saudações do enunciado (bónus) — equivalente ao components/Saudacao.jsx da web:
//   - "Bem-vindo!"               → primeiro acesso de sempre        (modal, uma vez)
//   - "Seja bem-vindo novamente" → após 15+ dias sem entrar         (modal, uma vez)
//   - "Bom dia/tarde/noite"      → restantes situações              (banner no dashboard)
//
// O banner horário já está no dashboard_screen.dart. Este ficheiro trata da
// saudação de EVENTO, que aparece num diálogo uma única vez por sessão.

class SaudacaoEvento {
  SaudacaoEvento._();

  // Flag em memória: garante que o modal só aparece uma vez por sessão da
  // app, mesmo que se navegue várias vezes para o dashboard. Equivale ao
  // sessionStorage usado na web. É reposta no logout (ver limpar()).
  static bool _jaMostrou = false;

  // Guarda o diálogo em curso, para que a celebração de marcos possa
  // esperar por ele e os dois não se sobreponham no ecrã.
  static Future<void>? _emCurso;
  static Future<void> get concluida => _emCurso ?? Future.value();

  static void limpar() {
    _jaMostrou = false;
    _emCurso = null;
  }

  /// Decide qual a saudação de evento a mostrar — ou null se nenhuma.
  static String? _mensagemPara({
    required bool primeiroAcesso,
    required DateTime? ultimoLoginAnterior,
  }) {
    if (primeiroAcesso) return 'Bem-vindo!';

    if (ultimoLoginAnterior != null) {
      final dias = DateTime.now().difference(ultimoLoginAnterior).inDays;
      if (dias >= 15) return 'Seja bem-vindo novamente!';
    }

    return null;
  }

  /// Mostra o diálogo, se houver motivo e ainda não tiver sido mostrado.
  static Future<void> mostrarSeNecessario(
    BuildContext context, {
    required String nome,
    required bool primeiroAcesso,
    required DateTime? ultimoLoginAnterior,
  }) async {
    if (_jaMostrou) return;

    final mensagem = _mensagemPara(
      primeiroAcesso: primeiroAcesso,
      ultimoLoginAnterior: ultimoLoginAnterior,
    );
    if (mensagem == null) return;

    _jaMostrou = true;
    if (!context.mounted) return;

    final primeiroNome = nome.split(' ').first;
    final ehPrimeiroAcesso = primeiroAcesso;

    _emCurso = showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rLg)),
        child: Padding(
          padding: const EdgeInsets.all(D.e5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: D.azul100, shape: BoxShape.circle),
                child: Icon(
                  ehPrimeiroAcesso ? Icons.celebration_outlined : Icons.waving_hand_outlined,
                  size: 36,
                  color: D.azul600,
                ),
              ),
              const SizedBox(height: D.e4),
              Text(mensagem,
                  textAlign: TextAlign.center,
                  style: D.tituloSeccao.copyWith(fontSize: 20, color: D.azul600)),
              const SizedBox(height: D.e2),
              Text(
                ehPrimeiroAcesso
                    ? 'Olá $primeiroNome! Esta é a tua plataforma de badges. '
                        'Explora o catálogo e candidata-te ao teu primeiro badge.'
                    : 'Que bom ver-te por cá outra vez, $primeiroNome. '
                        'Vê o que há de novo no catálogo desde a tua última visita.',
                textAlign: TextAlign.center,
                style: D.corpo.copyWith(height: 1.5),
              ),
              const SizedBox(height: D.e5),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: D.azul600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: D.e3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
                  ),
                  child: const Text('Vamos lá', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await _emCurso;
  }
}