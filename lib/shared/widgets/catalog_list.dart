import 'package:flutter/material.dart';

import '../../core/theme/catalog_palette.dart';

enum CatalogTagTone { neutral, positive, paused, info, error }

class CatalogTag extends StatelessWidget {
  const CatalogTag(this.label, {this.tone = CatalogTagTone.neutral, super.key});

  final String label;
  final CatalogTagTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, text) = switch (tone) {
      CatalogTagTone.neutral => (CatalogPalette.soft, CatalogPalette.muted),
      CatalogTagTone.positive => (
        const Color(0xFFE5F3D4),
        const Color(0xFF2F5024),
      ),
      CatalogTagTone.paused => (
        const Color(0xFFFFF0C6),
        const Color(0xFF635019),
      ),
      CatalogTagTone.info => (CatalogPalette.rail, CatalogPalette.link),
      CatalogTagTone.error => (
        CatalogPalette.errorSurface,
        CatalogPalette.error,
      ),
    };
    return ColoredBox(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class CatalogRecord {
  const CatalogRecord({
    required this.title,
    required this.cells,
    required this.open,
    this.description,
  });

  final String title;
  final String? description;
  final List<Widget> cells;
  final VoidCallback open;
}

class CatalogList extends StatelessWidget {
  const CatalogList({
    required this.titleLabel,
    required this.columns,
    required this.records,
    this.windowTitle,
    this.actionLabel,
    super.key,
  });

  final String titleLabel;
  final List<String> columns;
  final List<CatalogRecord> records;
  final String? windowTitle;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final showColumns =
            constraints.maxWidth >= (270 + columns.length * 95) * scale;
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: CatalogPalette.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Material(
              color: CatalogPalette.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (windowTitle case final heading?)
                    ColoredBox(
                      color: CatalogPalette.header,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Semantics(
                          header: true,
                          child: Text(
                            heading,
                            style: text.titleSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (showColumns)
                    ColoredBox(
                      color: CatalogPalette.soft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: _columns(
                          leading: _heading(titleLabel, text),
                          values: [
                            for (final label in columns) _heading(label, text),
                          ],
                          action: const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  for (var i = 0; i < records.length; i++) ...[
                    if (i > 0 || showColumns) const Divider(height: 1),
                    _record(records[i], text, showColumns),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _heading(String value, TextTheme text) => Semantics(
    header: true,
    child: Text(
      value,
      style: text.labelMedium?.copyWith(color: CatalogPalette.muted),
    ),
  );

  Widget _columns({
    required Widget leading,
    required List<Widget> values,
    required Widget action,
  }) => Row(
    children: [
      Expanded(flex: 4, child: leading),
      for (final value in values)
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 10),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: value,
            ),
          ),
        ),
      if (actionLabel != null)
        Expanded(
          flex: 2,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: action,
          ),
        )
      else
        SizedBox(width: 20, child: action),
    ],
  );

  Widget _record(CatalogRecord row, TextTheme text, bool showColumns) {
    final leading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.title,
          style: text.titleSmall?.copyWith(color: CatalogPalette.link),
        ),
        if (row.description case final description? when description.isNotEmpty)
          Text(
            description,
            style: text.bodySmall?.copyWith(color: CatalogPalette.muted),
          ),
      ],
    );
    final action = actionLabel == null
        ? const Icon(Icons.chevron_right, size: 18, color: CatalogPalette.link)
        : Text(
            actionLabel!,
            textAlign: TextAlign.end,
            style: text.labelMedium?.copyWith(color: CatalogPalette.link),
          );
    final values = [
      for (var index = 0; index < columns.length; index++)
        Semantics(label: columns[index], child: row.cells[index]),
    ];
    return InkWell(
      onTap: row.open,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: showColumns
              ? _columns(leading: leading, values: values, action: action)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: leading),
                        if (actionLabel == null) action,
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [...values, if (actionLabel != null) action],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
