import 'package:flutter/material.dart';
import 'package:pint_mobile/utils/design.dart';

/// Card com "borda" de gradiente — o elemento assinatura do design,
/// igual ao StatCard da web (serviceline/Gamification.jsx).
///
/// A borda é conseguida com um Container exterior que tem o gradiente
/// e 1px de padding; o Container interior branco tapa o meio, deixando
/// só o gradiente visível na margem.
///
/// Usar com critério: cards de estatística e destaques sim, listas não.
/// Se tudo tiver borda de gradiente, deixa de destacar seja o que for.
class CardGradiente extends StatelessWidget {
  const CardGradiente({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(D.e4),
    this.onTap,
    this.espessura = 1.0,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double espessura;

  @override
  Widget build(BuildContext context) {
    final conteudo = Container(
      padding: EdgeInsets.all(espessura),
      decoration: BoxDecoration(
        gradient: D.gradMarca,
        borderRadius: BorderRadius.circular(D.rMd),
        boxShadow: D.elev2,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: D.superficie,
          borderRadius: BorderRadius.circular(D.rMd - espessura),
        ),
        child: child,
      ),
    );

    if (onTap == null) return conteudo;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(D.rMd),
      child: conteudo,
    );
  }
}

/// Card simples, sem gradiente, para listas e conteúdo corrente.
/// Separa-se do fundo por elevação, não por borda.
class CardSimples extends StatelessWidget {
  const CardSimples({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(D.e4),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final conteudo = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: D.superficie,
        borderRadius: BorderRadius.circular(D.rMd),
        boxShadow: D.elev1,
      ),
      child: child,
    );

    if (onTap == null) return conteudo;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(D.rMd),
      child: conteudo,
    );
  }
}

/// Etiqueta de estado (Alcançado / Não Alcançado / Em curso).
/// Fundo suave + texto forte, sem borda.
class ChipEstado extends StatelessWidget {
  const ChipEstado({
    super.key,
    required this.texto,
    required this.cor,
    required this.corFundo,
    this.icone,
  });

  final String texto;
  final Color cor;
  final Color corFundo;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: D.e3, vertical: D.e1 + 1),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 13, color: cor),
            const SizedBox(width: D.e1 + 2),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}