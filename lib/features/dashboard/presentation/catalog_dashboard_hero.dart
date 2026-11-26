import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/catalog_palette.dart';

class CatalogDashboardHero extends StatelessWidget {
  const CatalogDashboardHero({this.onCreateCampaign, super.key});

  final VoidCallback? onCreateCampaign;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF4F6FF), Color(0xFFD9E2FF)],
        ),
        border: Border.fromBorderSide(
          BorderSide(color: CatalogPalette.outline),
        ),
        boxShadow: [BoxShadow(color: Color(0xFFC1CBEF), offset: Offset(3, 3))],
      ),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final roomy = width >= 530;
            final widePadding = width >= 740;
            final showArtwork =
                width >= 250 && MediaQuery.textScalerOf(context).scale(14) < 22;
            final horizontal = widePadding ? 30.0 : (roomy ? 21.0 : 14.0);
            final titleSize = widePadding ? 46.0 : (roomy ? 39.0 : 28.0);

            return CustomPaint(
              painter: const _CatalogDots(),
              child: Stack(
                children: [
                  if (showArtwork)
                    Positioned(
                      right: roomy ? 22 : 5,
                      top: 0,
                      bottom: 0,
                      width: math.min(width * (roomy ? .36 : .33), 250),
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: Opacity(
                            opacity: roomy ? 1 : .27,
                            child: const FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: 220,
                                height: 154,
                                child: CustomPaint(painter: _CatalogDisc()),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontal,
                      vertical: roomy ? 18 : 14,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: roomy && showArtwork
                            ? (width - 2 * horizontal) * .62
                            : width - 2 * horizontal,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen de la organización actual',
                            style: type.labelMedium?.copyWith(
                              color: CatalogPalette.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Semantics(
                            header: true,
                            child: Text(
                              'Encuentra a tu próximo cliente',
                              style: type.headlineLarge?.copyWith(
                                fontSize: titleSize,
                                height: 1,
                                letterSpacing: -titleSize * .05,
                                fontWeight: FontWeight.w800,
                                color: CatalogPalette.cobaltDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Consulta tus campañas y da seguimiento a tus prospectos.',
                            style: type.bodySmall?.copyWith(
                              color: CatalogPalette.muted,
                            ),
                          ),
                          if (onCreateCampaign != null) ...[
                            const SizedBox(height: 11),
                            FilledButton.icon(
                              onPressed: onCreateCampaign,
                              icon: const Icon(Icons.add),
                              label: const Text('Crear campaña'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CatalogDots extends CustomPainter {
  const _CatalogDots();

  @override
  void paint(Canvas canvas, Size size) {
    final dots = Paint()..color = const Color(0x406376BF);
    for (var y = 5.0; y < size.height; y += 8) {
      for (var x = 5.0; x < size.width; x += 8) {
        canvas.drawCircle(Offset(x, y), .74, dots);
      }
    }
  }

  @override
  bool shouldRepaint(_CatalogDots oldDelegate) => false;
}

class _CatalogDisc extends CustomPainter {
  const _CatalogDisc();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = size.center(Offset.zero);
    final caseArea = Rect.fromCenter(
      center: Offset.zero,
      width: 167,
      height: 113,
    );
    canvas.save();
    canvas.translate(center.dx - 11, center.dy + 5);
    canvas.rotate(.14);
    canvas.drawRect(
      caseArea.shift(const Offset(5, 5)),
      paint..color = const Color(0x637584C2),
    );
    canvas.drawRect(caseArea, paint..color = const Color(0xFFEFF5FF));
    for (var y = caseArea.top + 17; y < caseArea.bottom; y += 14) {
      canvas.drawRect(
        Rect.fromLTRB(
          caseArea.left,
          y,
          caseArea.right,
          math.min(y + 7, caseArea.bottom),
        ),
        paint..color = const Color(0xFFD8EAFB),
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(caseArea.left, caseArea.top, caseArea.width, 15),
      paint..color = CatalogPalette.cobalt,
    );
    canvas.drawRect(
      caseArea,
      Paint()
        ..color = CatalogPalette.cobalt
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7,
    );
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx + 14, center.dy - 8);
    canvas.rotate(-.38);
    canvas.scale(1, .88);
    final disc = Rect.fromCircle(center: Offset.zero, radius: 59);
    canvas.drawCircle(
      const Offset(3, 5),
      59,
      paint..color = const Color(0x64485FBB),
    );
    canvas.drawCircle(
      Offset.zero,
      59,
      paint
        ..shader = const SweepGradient(
          colors: [
            Color(0xFF90A5F4),
            Color(0xFFECFFC5),
            Color(0xFF6B85DA),
            Color(0xFFF9FBFF),
            Color(0xFFDFF287),
            Color(0xFF8CA5F4),
            Color(0xFF90A5F4),
          ],
        ).createShader(disc),
    );
    final groove = Paint()
      ..color = const Color(0x393B61A0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .75;
    for (var radius = 14.0; radius <= 59; radius += 5) {
      canvas.drawCircle(Offset.zero, radius, groove);
    }
    paint.shader = null;
    canvas.drawCircle(Offset.zero, 9, paint..color = CatalogPalette.surface);
    canvas.drawCircle(Offset.zero, 5.8, paint..color = CatalogPalette.cobalt);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CatalogDisc oldDelegate) => false;
}
