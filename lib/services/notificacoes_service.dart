import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ═══════════════════════════════════════════════════════════════════════════
// O Firebase Cloud Messaging permite enviar notificações do servidor
// para os dispositivos dos utilizadores, mesmo com a app fechada.
//
// Fluxo:
//   Backend → Firebase → Dispositivo → NotificacoesService → Utilizador
//
// Há 3 estados possíveis da app quando chega uma notificação:
//   1. App ABERTA (foreground)  → _mostrarNotificacao() trata
//   2. App em BACKGROUND        → Firebase mostra automaticamente
//   3. App FECHADA              → _firebaseMessagingBackgroundHandler trata
// ═══════════════════════════════════════════════════════════════════════════

// Handler para mensagens recebidas quando a app está FECHADA ou em BACKGROUND.
//
// IMPORTANTE: Tem de estar FORA da classe e ao nível global do ficheiro.
// O @pragma('vm:entry-point') é obrigatório — garante que o Dart não remove
// esta função durante a compilação em modo release (tree-shaking).
// Sem este pragma, as notificações em background não funcionariam.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Mensagem recebida em background: ${message.messageId}');
}

// Padrão Singleton — garante que existe UMA única instância deste serviço
// em toda a aplicação. Evita inicializações duplicadas do Firebase.
//
// Uso: NotificacoesService.instance.inicializar()
class NotificacoesService {
  static final NotificacoesService instance = NotificacoesService._();
  NotificacoesService._();

  // FirebaseMessaging —> responsável por:
  //   - Pedir permissões ao utilizador
  //   - Obter o token FCM do dispositivo
  //   - Subscrever tópicos
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // FlutterLocalNotificationsPlugin — responsável por mostrar notificações
  // locais (popups na barra de estado) quando a app está em PRIMEIRO PLANO.
  // O Android não mostra notificações FCM automaticamente quando a app está aberta,
  // por isso precisamos deste plugin para as mostrar manualmente.
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Canal de notificação Android (obrigatório para Android 8+).
  // Define nome, descrição e importância (som, vibração, prioridade).
  // O ID 'high_importance_channel' TEM de ser igual ao definido
  // no AndroidManifest.xml — senão as notificações não aparecem.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notificações BadgeBoost',
    description: 'Notificações sobre candidaturas e badges.',
    importance: Importance.max,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // inicializar() —> chamado UMA VEZ no main.dart antes de runApp().
  //
  // Segue as fases obrigatórias para configurar push notifications:
  //   1. Pedir permissão ao utilizador
  //   2. Configurar notificações locais
  //   3. Criar canal Android
  //   4. Registar handler para background
  //   5. Ouvir mensagens em foreground
  //   6. Obter token FCM do dispositivo
  //   7. Subscrever tópico 'todos'
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> inicializar() async {

    // FASE 1: Pedir permissão ao utilizador.
    // No Android 13+ (API 33+) é obrigatório pedir permissão explicitamente.
    // Sem esta permissão, as notificações não aparecem no dispositivo.
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,  // mostrar notificação
      badge: true,  // mostrar número no ícone da app
      sound: true,  // reproduzir som
    );
    debugPrint('Permissão de notificações: ${settings.authorizationStatus}');

    // FASE 2: Configurar o plugin de notificações locais.
    // Usa o ícone da app (@mipmap/ic_launcher) como ícone das notificações.
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // FASE 3: Criar o canal de notificação Android.
    // Necessário para Android 8.0+ (Oreo). Define as características
    // das notificações: som, vibração, importância visual.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // FASE 4: Registar o handler para mensagens em background/app fechada.
    // Quando a app está fechada e chega uma notificação, o Firebase
    // chama esta função num isolate separado.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // FASE 5: Ouvir mensagens quando a app está em PRIMEIRO PLANO.
    // O Firebase NÃO mostra a notificação automaticamente neste caso —
    // temos de a mostrar manualmente com _mostrarNotificacao().
    FirebaseMessaging.onMessage.listen(_mostrarNotificacao);

    // FASE 6: Obter o token FCM único deste dispositivo.
    // Este token identifica o dispositivo no Firebase e pode ser enviado
    // ao backend para notificações direcionadas a um utilizador específico.
    final token = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');

    // FASE 7: Subscrever o tópico 'todos'.
    // Os tópicos permitem enviar uma notificação para TODOS os dispositivos
    // subscritos de uma só vez, sem precisar de conhecer o token de cada um.
    // O professor recomendou usar 'todos' com t minúsculo.
    // Uso no Firebase Console: enviar para o tópico 'todos'
    await _firebaseMessaging.subscribeToTopic('todos');
    debugPrint('Subscreveu ao tópico "todos"');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // _mostrarNotificacao() -> chamado quando a app está em PRIMEIRO PLANO.
  //
  // O Firebase não mostra notificações automaticamente quando a app está aberta.
  // Este método usa o FlutterLocalNotificationsPlugin para mostrar
  // a notificação manualmente na barra de estado do dispositivo.
  // ─────────────────────────────────────────────────────────────────────────
  void _mostrarNotificacao(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return; // mensagem de dados sem notificação visual

    _localNotifications.show(
      notification.hashCode,           // ID único da notificação
      notification.title ?? 'Sem título',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,                  // tem de corresponder ao canal criado acima
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,   // mostra no topo do ecrã
          priority: Priority.high,      // interrompe o utilizador
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // Devolve o token FCM atual do dispositivo.
  // Útil para enviar o token ao backend após o login.
  Future<String?> getToken() => _firebaseMessaging.getToken();
}