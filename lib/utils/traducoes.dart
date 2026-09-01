// utils/traducoes.dart
// Dicionário de traduções do mobile — equivalente ao translations.jsx da Web.
// Cada chave existe nos 3 idiomas. Se faltar uma chave num idioma, cai para
// PT; se faltar em PT também, mostra a própria chave (nunca rebenta).
//
// Convenção de nomenclatura das chaves: 'mobile_<ecrã>_<elemento>'.
// Chaves partilhadas entre vários ecrãs (botões, estados genéricos) usam só
// 'mobile_geral_<algo>', sem prefixo de ecrã.

class Traducoes {
  Traducoes._();

  static const Map<String, Map<String, String>> mapa = {
    'pt': {
      // ── Geral / partilhado ──────────────────────────────────────
      'mobile_geral_a_carregar': 'A carregar...',
      'mobile_geral_cancelar': 'Cancelar',
      'mobile_geral_guardar': 'Guardar',
      'mobile_geral_guardar_alteracoes': 'Guardar Alterações',
      'mobile_geral_confirmar': 'Confirmar',
      'mobile_geral_erro_desconhecido': 'Erro desconhecido',
      'mobile_geral_sem_ligacao': 'Sem ligação ao servidor.',
      'mobile_geral_ver_tudo': 'Ver Tudo',
      'mobile_geral_procurar': 'Procurar...',
      'mobile_geral_requisitos': 'Requisitos',

      // ── Login ────────────────────────────────────────────────────
      'mobile_login_email_label': 'Email',
      'mobile_login_email_hint': 'Insira o seu email',
      'mobile_login_email_obrigatorio': 'Por favor, insere o teu email',
      'mobile_login_email_invalido': 'Por favor, insira um email válido',
      'mobile_login_password_label': 'Password',
      'mobile_login_password_hint': 'Insira a sua password',
      'mobile_login_password_obrigatoria': 'Por favor, insira a sua password',
      'mobile_login_manter_sessao': 'Manter sessão iniciada',
      'mobile_login_esqueci_password': 'Esqueci-me da password',
      'mobile_login_entrar': 'Entrar',

      // ── Dashboard ────────────────────────────────────────────────
      'mobile_dash_titulo': 'DASHBOARD',
      'mobile_dash_bom_dia': 'Bom dia',
      'mobile_dash_boa_tarde': 'Boa tarde',
      'mobile_dash_boa_noite': 'Boa noite',
      'mobile_dash_resumo_atividade': 'RESUMO DA MINHA ATIVIDADE',
      'mobile_dash_pedidos_pendentes': 'Pedidos\nPendentes',
      'mobile_dash_badges_conquistados': 'Badges\nConquistados',
      'mobile_dash_badges_especiais': 'Badges\nEspeciais',
      'mobile_dash_objetivos_alcancados': 'Objetivos\nAlcançados',
      'mobile_dash_objetivos_titulo': 'OBJETIVOS',
      'mobile_dash_objetivos_erro': 'Não foi possível carregar os objetivos.',
      'mobile_dash_objetivos_progresso_lp': 'Progresso na Learning Path',
      'mobile_dash_objetivos_em_progresso': 'Objetivos em progresso',
      'mobile_dash_objetivos_sem_curso': 'Sem objetivos em curso.',
      'mobile_dash_gamification_titulo': 'GAMIFICATION',
      'mobile_dash_ranking_vazio': 'Ainda sem ranking disponível.',
      'mobile_dash_desempenho_titulo': 'O teu desempenho',
      'mobile_dash_badges_recomendados_titulo': 'BADGES RECOMENDADOS',
      'mobile_dash_badges_recomendados_erro': 'Não foi possível carregar as recomendações.',
      'mobile_dash_badges_recomendados_vazio': 'Já conquistaste todos os badges!',
      'mobile_dash_ranking_titulo': 'Ranking',
      'mobile_ola': 'Olá',
      'mobile_geral_tentar_novamente': 'Tentar novamente',
      'mobile_geral_procura_hint': 'Procura...',

      // ── PIN de recuperação de password ──────────────────────────
      'mobile_pin_insira_5_digitos': 'Insira os 5 dígitos.',
      'mobile_pin_titulo': 'Introduza o código:',
      'mobile_pin_subtitulo': 'Insira o código de 5 dígitos enviado para o seu email.',
      'mobile_pin_verificar': 'Verificar',

      // ── Ranking ──────────────────────────────────────────────────
      'mobile_ranking_titulo': 'RANKING',
      'mobile_ranking_erro': 'Não foi possível carregar o ranking.',
      'mobile_ranking_pesquisar_hint': 'Procurar consultor',
      'mobile_ranking_vazio': 'Nenhum consultor encontrado.',
      'mobile_ranking_pts': 'pts',
      'mobile_ranking_pontos': 'Pontos',

      // ── RGPD ─────────────────────────────────────────────────────
      'mobile_rgpd_erro_aceitar': 'Não foi possível registar a aceitação.',
      'mobile_rgpd_subtitulo': 'Antes de continuar, precisamos que confirmes que leste e aceitas a nossa Política de Privacidade.',
      'mobile_rgpd_indisponivel': 'Política de privacidade não disponível de momento.',
      'mobile_rgpd_aceitar_btn': 'Li e aceito a Política de Privacidade',
      'mobile_rgpd_sair_btn': 'Sair sem aceitar',

      // ── Configuração inicial ─────────────────────────────────────
      'mobile_config_inicial_seleciona_area': 'Seleciona a tua área para continuar.',
      'mobile_config_inicial_erro_guardar': 'Erro ao guardar. Tenta novamente.',
      'mobile_config_inicial_bemvindo': 'Bem-vindo!',
      'mobile_config_inicial_subtitulo': 'Escolhe a tua área para personalizarmos a tua experiência.',
      'mobile_config_inicial_continuar': 'Continuar',

      // ── Catálogo de badges ───────────────────────────────────────
      'mobile_catalogo_vazio': 'Nenhum badge encontrado.',
      'mobile_catalogo_titulo': 'CATÁLOGO',
      'mobile_catalogo_procurar_hint': 'Procura...',
      'mobile_catalogo_todas_areas': 'Todas as áreas',
      'mobile_catalogo_obtido': 'Obtido',

      // ── Trocar password (primeiro acesso) ───────────────────────
      'mobile_trocar_pass_erro': 'Erro ao alterar a password.',
      'mobile_trocar_pass_titulo': 'Define a tua nova palavra-passe',
      'mobile_trocar_pass_subtitulo': 'Por razões de segurança, tens de trocar a password temporária antes de continuar.',
      'mobile_trocar_pass_nova_label': 'Nova palavra-passe*',
      'mobile_trocar_pass_nova_hint': 'Mínimo 8 caracteres',
      'mobile_trocar_pass_nova_obrigatoria': 'Insere a nova palavra-passe',
      'mobile_trocar_pass_min_caracteres': 'A password deve ter pelo menos 8 caracteres.',
      'mobile_trocar_pass_repetir_label': 'Repete a palavra-passe*',
      'mobile_trocar_pass_repetir_obrigatoria': 'Repete a palavra-passe',
      'mobile_trocar_pass_nao_coincidem': 'As passwords não coincidem.',
      'mobile_trocar_pass_botao': 'Trocar password',

      // ── Badges (geral / expirados) ──────────────────────────────
      'mobile_badges_erro_carregar': 'Erro ao carregar badges',
      'mobile_badges_titulo': 'BADGES',
      'mobile_badges_nenhum_encontrado': 'Nenhum badge encontrado',
      'mobile_badges_sem_expirados': 'Não tens badges expirados',
      'mobile_badges_service_line': 'Service Line',
      'mobile_badges_area': 'Área',
      'mobile_badges_conquistado_em': 'Conquistado em:',
      'mobile_badges_expirou_em': 'Expirou em:',
      'mobile_badges_renovar': 'Renovar',
      'mobile_badges_expirado': 'Expirado',

      // ── Candidaturas a decorrer ──────────────────────────────────
      'mobile_cand_sem_encontradas': 'Sem candidaturas encontradas.',
      'mobile_cand_decorrer_titulo': 'A DECORRER',
      'mobile_cand_pesquisar_badge_hint': 'Pesquisar badge...',
      'mobile_cand_nivel_todos': 'Nível: Todos',
      'mobile_cand_tab_todos': 'Todos',
      'mobile_cand_tab_aguardar': 'A Aguardar',
      'mobile_cand_tab_corrigir': 'A Corrigir',
    },
    'en': {
      // ── Geral / partilhado ──────────────────────────────────────
      'mobile_geral_a_carregar': 'Loading...',
      'mobile_geral_cancelar': 'Cancel',
      'mobile_geral_guardar': 'Save',
      'mobile_geral_guardar_alteracoes': 'Save Changes',
      'mobile_geral_confirmar': 'Confirm',
      'mobile_geral_erro_desconhecido': 'Unknown error',
      'mobile_geral_sem_ligacao': 'No connection to the server.',
      'mobile_geral_ver_tudo': 'See All',
      'mobile_geral_procurar': 'Search...',
      'mobile_geral_requisitos': 'Requirements',

      // ── Login ────────────────────────────────────────────────────
      'mobile_login_email_label': 'Email',
      'mobile_login_email_hint': 'Enter your email',
      'mobile_login_email_obrigatorio': 'Please enter your email',
      'mobile_login_email_invalido': 'Please enter a valid email',
      'mobile_login_password_label': 'Password',
      'mobile_login_password_hint': 'Enter your password',
      'mobile_login_password_obrigatoria': 'Please enter your password',
      'mobile_login_manter_sessao': 'Keep me signed in',
      'mobile_login_esqueci_password': 'Forgot my password',
      'mobile_login_entrar': 'Log in',

      // ── Dashboard ────────────────────────────────────────────────
      'mobile_dash_titulo': 'DASHBOARD',
      'mobile_dash_bom_dia': 'Good morning',
      'mobile_dash_boa_tarde': 'Good afternoon',
      'mobile_dash_boa_noite': 'Good evening',
      'mobile_dash_resumo_atividade': 'SUMMARY OF MY ACTIVITY',
      'mobile_dash_pedidos_pendentes': 'Pending\nRequests',
      'mobile_dash_badges_conquistados': 'Badges\nEarned',
      'mobile_dash_badges_especiais': 'Special\nBadges',
      'mobile_dash_objetivos_alcancados': 'Goals\nAchieved',
      'mobile_dash_objetivos_titulo': 'GOALS',
      'mobile_dash_objetivos_erro': 'Could not load your goals.',
      'mobile_dash_objetivos_progresso_lp': 'Learning Path progress',
      'mobile_dash_objetivos_em_progresso': 'Goals in progress',
      'mobile_dash_objetivos_sem_curso': 'No goals in progress.',
      'mobile_dash_gamification_titulo': 'GAMIFICATION',
      'mobile_dash_ranking_vazio': 'No ranking available yet.',
      'mobile_dash_desempenho_titulo': 'Your performance',
      'mobile_dash_badges_recomendados_titulo': 'RECOMMENDED BADGES',
      'mobile_dash_badges_recomendados_erro': 'Could not load recommendations.',
      'mobile_dash_badges_recomendados_vazio': 'You have earned all badges!',
      'mobile_dash_ranking_titulo': 'Ranking',
      'mobile_ola': 'Hi',
      'mobile_geral_tentar_novamente': 'Try again',
      'mobile_geral_procura_hint': 'Search...',

      // ── PIN de recuperação de password ──────────────────────────
      'mobile_pin_insira_5_digitos': 'Enter the 5 digits.',
      'mobile_pin_titulo': 'Enter the code:',
      'mobile_pin_subtitulo': 'Enter the 5-digit code sent to your email.',
      'mobile_pin_verificar': 'Verify',

      // ── Ranking ──────────────────────────────────────────────────
      'mobile_ranking_titulo': 'RANKING',
      'mobile_ranking_erro': 'Could not load the ranking.',
      'mobile_ranking_pesquisar_hint': 'Search consultant',
      'mobile_ranking_vazio': 'No consultant found.',
      'mobile_ranking_pts': 'pts',
      'mobile_ranking_pontos': 'Points',

      // ── RGPD ─────────────────────────────────────────────────────
      'mobile_rgpd_erro_aceitar': 'Could not register your acceptance.',
      'mobile_rgpd_subtitulo': 'Before continuing, we need you to confirm that you have read and accept our Privacy Policy.',
      'mobile_rgpd_indisponivel': 'Privacy policy currently unavailable.',
      'mobile_rgpd_aceitar_btn': 'I have read and accept the Privacy Policy',
      'mobile_rgpd_sair_btn': 'Log out without accepting',

      // ── Configuração inicial ─────────────────────────────────────
      'mobile_config_inicial_seleciona_area': 'Select your area to continue.',
      'mobile_config_inicial_erro_guardar': 'Error saving. Please try again.',
      'mobile_config_inicial_bemvindo': 'Welcome!',
      'mobile_config_inicial_subtitulo': 'Choose your area so we can personalize your experience.',
      'mobile_config_inicial_continuar': 'Continue',

      // ── Catálogo de badges ───────────────────────────────────────
      'mobile_catalogo_vazio': 'No badge found.',
      'mobile_catalogo_titulo': 'CATALOG',
      'mobile_catalogo_procurar_hint': 'Search...',
      'mobile_catalogo_todas_areas': 'All areas',
      'mobile_catalogo_obtido': 'Earned',

      // ── Trocar password (primeiro acesso) ───────────────────────
      'mobile_trocar_pass_erro': 'Error changing the password.',
      'mobile_trocar_pass_titulo': 'Set your new password',
      'mobile_trocar_pass_subtitulo': 'For security reasons, you need to change the temporary password before continuing.',
      'mobile_trocar_pass_nova_label': 'New password*',
      'mobile_trocar_pass_nova_hint': 'Minimum 8 characters',
      'mobile_trocar_pass_nova_obrigatoria': 'Enter the new password',
      'mobile_trocar_pass_min_caracteres': 'The password must be at least 8 characters long.',
      'mobile_trocar_pass_repetir_label': 'Repeat the password*',
      'mobile_trocar_pass_repetir_obrigatoria': 'Repeat the password',
      'mobile_trocar_pass_nao_coincidem': 'Passwords do not match.',
      'mobile_trocar_pass_botao': 'Change password',

      // ── Badges (geral / expirados) ──────────────────────────────
      'mobile_badges_erro_carregar': 'Error loading badges',
      'mobile_badges_titulo': 'BADGES',
      'mobile_badges_nenhum_encontrado': 'No badge found',
      'mobile_badges_sem_expirados': 'You have no expired badges',
      'mobile_badges_service_line': 'Service Line',
      'mobile_badges_area': 'Area',
      'mobile_badges_conquistado_em': 'Earned on:',
      'mobile_badges_expirou_em': 'Expired on:',
      'mobile_badges_renovar': 'Renew',
      'mobile_badges_expirado': 'Expired',

      // ── Candidaturas a decorrer ──────────────────────────────────
      'mobile_cand_sem_encontradas': 'No applications found.',
      'mobile_cand_decorrer_titulo': 'IN PROGRESS',
      'mobile_cand_pesquisar_badge_hint': 'Search badge...',
      'mobile_cand_nivel_todos': 'Level: All',
      'mobile_cand_tab_todos': 'All',
      'mobile_cand_tab_aguardar': 'Pending',
      'mobile_cand_tab_corrigir': 'To Fix',
    },
    'es': {
      // ── Geral / partilhado ──────────────────────────────────────
      'mobile_geral_a_carregar': 'Cargando...',
      'mobile_geral_cancelar': 'Cancelar',
      'mobile_geral_guardar': 'Guardar',
      'mobile_geral_guardar_alteracoes': 'Guardar Cambios',
      'mobile_geral_confirmar': 'Confirmar',
      'mobile_geral_erro_desconhecido': 'Error desconocido',
      'mobile_geral_sem_ligacao': 'Sin conexión al servidor.',
      'mobile_geral_ver_tudo': 'Ver Todo',
      'mobile_geral_procurar': 'Buscar...',
      'mobile_geral_requisitos': 'Requisitos',

      // ── Login ────────────────────────────────────────────────────
      'mobile_login_email_label': 'Email',
      'mobile_login_email_hint': 'Introduce tu email',
      'mobile_login_email_obrigatorio': 'Por favor, introduce tu email',
      'mobile_login_email_invalido': 'Por favor, introduce un email válido',
      'mobile_login_password_label': 'Contraseña',
      'mobile_login_password_hint': 'Introduce tu contraseña',
      'mobile_login_password_obrigatoria': 'Por favor, introduce tu contraseña',
      'mobile_login_manter_sessao': 'Mantener sesión iniciada',
      'mobile_login_esqueci_password': 'Olvidé mi contraseña',
      'mobile_login_entrar': 'Entrar',

      // ── Dashboard ────────────────────────────────────────────────
      'mobile_dash_titulo': 'PANEL',
      'mobile_dash_bom_dia': 'Buenos días',
      'mobile_dash_boa_tarde': 'Buenas tardes',
      'mobile_dash_boa_noite': 'Buenas noches',
      'mobile_dash_resumo_atividade': 'RESUMEN DE MI ACTIVIDAD',
      'mobile_dash_pedidos_pendentes': 'Solicitudes\nPendientes',
      'mobile_dash_badges_conquistados': 'Badges\nConseguidos',
      'mobile_dash_badges_especiais': 'Badges\nEspeciales',
      'mobile_dash_objetivos_alcancados': 'Objetivos\nAlcanzados',
      'mobile_dash_objetivos_titulo': 'OBJETIVOS',
      'mobile_dash_objetivos_erro': 'No se pudieron cargar los objetivos.',
      'mobile_dash_objetivos_progresso_lp': 'Progreso en el Learning Path',
      'mobile_dash_objetivos_em_progresso': 'Objetivos en curso',
      'mobile_dash_objetivos_sem_curso': 'Sin objetivos en curso.',
      'mobile_dash_gamification_titulo': 'GAMIFICATION',
      'mobile_dash_ranking_vazio': 'Aún no hay ranking disponible.',
      'mobile_dash_desempenho_titulo': 'Tu rendimiento',
      'mobile_dash_badges_recomendados_titulo': 'BADGES RECOMENDADOS',
      'mobile_dash_badges_recomendados_erro': 'No se pudieron cargar las recomendaciones.',
      'mobile_dash_badges_recomendados_vazio': '¡Ya has conseguido todos los badges!',
      'mobile_dash_ranking_titulo': 'Ranking',
      'mobile_ola': 'Hola',
      'mobile_geral_tentar_novamente': 'Intentar de nuevo',
      'mobile_geral_procura_hint': 'Buscar...',

      // ── PIN de recuperación de contraseña ───────────────────────
      'mobile_pin_insira_5_digitos': 'Introduce los 5 dígitos.',
      'mobile_pin_titulo': 'Introduce el código:',
      'mobile_pin_subtitulo': 'Introduce el código de 5 dígitos enviado a tu email.',
      'mobile_pin_verificar': 'Verificar',

      // ── Ranking ──────────────────────────────────────────────────
      'mobile_ranking_titulo': 'RANKING',
      'mobile_ranking_erro': 'No se pudo cargar el ranking.',
      'mobile_ranking_pesquisar_hint': 'Buscar consultor',
      'mobile_ranking_vazio': 'Ningún consultor encontrado.',
      'mobile_ranking_pts': 'pts',
      'mobile_ranking_pontos': 'Puntos',

      // ── RGPD ─────────────────────────────────────────────────────
      'mobile_rgpd_erro_aceitar': 'No se pudo registrar la aceptación.',
      'mobile_rgpd_subtitulo': 'Antes de continuar, necesitamos que confirmes que has leído y aceptas nuestra Política de Privacidad.',
      'mobile_rgpd_indisponivel': 'Política de privacidad no disponible en este momento.',
      'mobile_rgpd_aceitar_btn': 'He leído y acepto la Política de Privacidad',
      'mobile_rgpd_sair_btn': 'Salir sin aceptar',

      // ── Configuración inicial ────────────────────────────────────
      'mobile_config_inicial_seleciona_area': 'Selecciona tu área para continuar.',
      'mobile_config_inicial_erro_guardar': 'Error al guardar. Inténtalo de nuevo.',
      'mobile_config_inicial_bemvindo': '¡Bienvenido!',
      'mobile_config_inicial_subtitulo': 'Elige tu área para personalizar tu experiencia.',
      'mobile_config_inicial_continuar': 'Continuar',

      // ── Catálogo de badges ───────────────────────────────────────
      'mobile_catalogo_vazio': 'No se encontró ningún badge.',
      'mobile_catalogo_titulo': 'CATÁLOGO',
      'mobile_catalogo_procurar_hint': 'Buscar...',
      'mobile_catalogo_todas_areas': 'Todas las áreas',
      'mobile_catalogo_obtido': 'Conseguido',

      // ── Cambiar contraseña (primer acceso) ──────────────────────
      'mobile_trocar_pass_erro': 'Error al cambiar la contraseña.',
      'mobile_trocar_pass_titulo': 'Define tu nueva contraseña',
      'mobile_trocar_pass_subtitulo': 'Por razones de seguridad, debes cambiar la contraseña temporal antes de continuar.',
      'mobile_trocar_pass_nova_label': 'Nueva contraseña*',
      'mobile_trocar_pass_nova_hint': 'Mínimo 8 caracteres',
      'mobile_trocar_pass_nova_obrigatoria': 'Introduce la nueva contraseña',
      'mobile_trocar_pass_min_caracteres': 'La contraseña debe tener al menos 8 caracteres.',
      'mobile_trocar_pass_repetir_label': 'Repite la contraseña*',
      'mobile_trocar_pass_repetir_obrigatoria': 'Repite la contraseña',
      'mobile_trocar_pass_nao_coincidem': 'Las contraseñas no coinciden.',
      'mobile_trocar_pass_botao': 'Cambiar contraseña',

      // ── Badges (general / expirados) ────────────────────────────
      'mobile_badges_erro_carregar': 'Error al cargar los badges',
      'mobile_badges_titulo': 'BADGES',
      'mobile_badges_nenhum_encontrado': 'Ningún badge encontrado',
      'mobile_badges_sem_expirados': 'No tienes badges caducados',
      'mobile_badges_service_line': 'Service Line',
      'mobile_badges_area': 'Área',
      'mobile_badges_conquistado_em': 'Conseguido el:',
      'mobile_badges_expirou_em': 'Caducó el:',
      'mobile_badges_renovar': 'Renovar',
      'mobile_badges_expirado': 'Caducado',

      // ── Solicitudes en curso ─────────────────────────────────────
      'mobile_cand_sem_encontradas': 'No se encontraron solicitudes.',
      'mobile_cand_decorrer_titulo': 'EN CURSO',
      'mobile_cand_pesquisar_badge_hint': 'Buscar badge...',
      'mobile_cand_nivel_todos': 'Nivel: Todos',
      'mobile_cand_tab_todos': 'Todos',
      'mobile_cand_tab_aguardar': 'Pendientes',
      'mobile_cand_tab_corrigir': 'Por Corregir',
    },
  };

  /// Traduz [chave] para [idioma]. Cai para PT se faltar no idioma pedido, e
  /// devolve a própria chave (nunca um ecrã em branco) se faltar em PT também.
  static String t(String idioma, String chave) {
    return mapa[idioma]?[chave] ?? mapa['pt']?[chave] ?? chave;
  }
}