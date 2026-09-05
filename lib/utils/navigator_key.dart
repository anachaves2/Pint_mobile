import 'package:flutter/material.dart';

// Chave global do Navigator — permite navegar a partir de sítios que não
// têm BuildContext (ex.: APIService, que corre em segundo plano e deteta a
// sessão expirada durante uma sincronização periódica). Fica num ficheiro
// à parte, sem outras dependências, para não criar um import circular
// entre main.dart/app_routes.dart e api_service.dart.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();