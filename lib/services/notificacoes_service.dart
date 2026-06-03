import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Handler para quando a app está EM BACKGROUND ou FECHADA e chega uma notificação.
// Tem de estar FORA da classe e marcado com @pragma — é assim que o Firebase exige.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Mensagem recebida em background: ${message.messageId}');
}

// Singleton — única instância partilhada por toda a app
class NotificacoesService {
  static final NotificacoesService instance = NotificacoesService._();
  NotificacoesService._();

  // Referência para o Firebase Cloud Messaging
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Referência para mostrar notificações locais (popups na barra do telemóvel)
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Canal de notificação Android — define a importância (vai estourar som, vibrar, etc.)
  // O nome 'high_importance_channel' tem de ser IGUAL ao que pusemos no AndroidManifest.xml
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notificações BadgeBoost',
    description: 'Notificações sobre candidaturas e badges.',
    importance: Importance.max,
  );

  // ─────────────────────────────────────────────────────────────
  // Método principal — chama-se UMA VEZ no main.dart ao arrancar a app
  // ─────────────────────────────────────────────────────────────
  Future<void> inicializar() async {
    // 1. Pede permissão ao utilizador (Android 13+ exige isto explicitamente)
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Permissão de notificações: ${settings.authorizationStatus}');

    // 2. Configura as notificações locais (para mostrar popups quando app está aberta)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // 3. Cria o canal de notificação no Android (define som, vibração, importância)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Regista o handler para mensagens recebidas em background (app fechada)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Ouve mensagens recebidas quando a app está em PRIMEIRO PLANO (aberta)
    FirebaseMessaging.onMessage.listen(_mostrarNotificacao);

    // 6. Obtém o token FCM deste dispositivo — vai aparecer na consola
    final token = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');

    //7. Subsvcreve o tópico "todos", recomendado pelo professor.
    //Permite enviar uma notificação para todos os dispositivos ao mesmo tempo, em vez de termos de saber o token de cada um.
    await _firebaseMessaging.subscribeToTopic('todos'); 
    debugPrint('Subscreveu ao tópico "todos"');
  }

  // ─────────────────────────────────────────────────────────────
  // Quando a app está aberta, o Android NÃO mostra a notificação automaticamente.
  // Por isso temos de a mostrar nós próprios usando flutter_local_notifications.
  // ─────────────────────────────────────────────────────────────
  void _mostrarNotificacao(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'Sem título',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Método auxiliar — devolve o token FCM atual do dispositivo.
  // Vamos usar isto mais tarde para enviar o token ao backend.
  // ─────────────────────────────────────────────────────────────
  Future<String?> getToken() => _firebaseMessaging.getToken();
}