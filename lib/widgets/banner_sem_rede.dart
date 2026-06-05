import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// connectivity_plus — Aula 11
// Widget que envolve toda a app e mostra um banner vermelho
// quando o telemóvel não tem ligação à internet.
// Como a app é offline-first (SQLite), continua a funcionar —
// apenas avisamos o utilizador que está a ver dados guardados.
class BannerSemRede extends StatefulWidget {
  // Recebe o ecrã filho (a app inteira) como parâmetro
  final Widget child;
  const BannerSemRede({super.key, required this.child});

  @override
  State<BannerSemRede> createState() => _BannerSemRedeState();
}

class _BannerSemRedeState extends State<BannerSemRede> {
  // true = sem rede, false = com rede
  bool _semRede = false;

  // StreamSubscription — fica à escuta de mudanças de conectividade
  // em tempo real (Aula 9 — StreamSubscription)
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();

    // Verifica o estado da rede quando o widget arranca
    _verificar();

    // Subscreve ao stream de mudanças de conectividade
    // Sempre que a rede muda (WiFi → sem rede, etc.) este listener dispara
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      // results é uma lista — verificamos se TODOS os resultados são "none"
      final semRede = results.every((r) => r == ConnectivityResult.none);
      if (mounted) setState(() => _semRede = semRede);
    });
  }

  @override
  void dispose() {
    // Cancela a subscrição quando o widget é destruído (boa prática)
    _sub?.cancel();
    super.dispose();
  }

  // Verifica o estado actual da rede (chamado no initState)
  Future<void> _verificar() async {
    final results = await Connectivity().checkConnectivity();
    final semRede = results.every((r) => r == ConnectivityResult.none);
    if (mounted) setState(() => _semRede = semRede);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mostra o banner vermelho apenas quando não há rede
        if (_semRede)
          Container(
            width: double.infinity,
            color: Colors.red[700],
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Sem ligação à internet — a mostrar dados guardados',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        // O ecrã filho ocupa o resto do espaço disponível
        Expanded(child: widget.child),
      ],
    );
  }
}