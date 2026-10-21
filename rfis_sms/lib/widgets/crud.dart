import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import 'common.dart';
import 'record_form.dart';

/// Text shown for a stored value: choice labels are translated and dates are
/// shown as dd/MM/yyyy.
String displayValue(BuildContext context, FieldDef f, String raw) {
  if (raw.isEmpty) return '-';
  if (f.type == FieldType.date) return fmtDate(raw);
  if (f.type == FieldType.choice) {
    for (final o in f.options) {
      if (o.value == raw) return context.tr(o.ar, o.en);
    }
  }
  return raw;
}

/// An extra button shown in a record's detail sheet.
class RowAction {
  const RowAction({
    required this.ar,
    required this.en,
    required this.icon,
    required this.onTap,
  });

  final String ar;
  final String en;
  final IconData icon;
  final void Function(BuildContext context, Rec rec) onTap;
}

/// Describes one list/add/edit/delete screen backed by a table in AppState.
class CrudConfig {
  CrudConfig({
    required this.table,
    required this.titleAr,
    required this.titleEn,
    required this.icon,
    required this.fields,
    required this.titleKey,
    this.subtitleKeys = const <String>[],
    this.filterKey,
    this.canAdd = true,
    this.canEdit = true,
    this.canDelete = true,
    this.actions = const <RowAction>[],
    this.trailing,
    this.onCreate,
    this.validate,
    this.iconFor,
  });

  final String table;
  final String titleAr;
  final String titleEn;
  final IconData icon;
  final List<FieldDef> fields;
  final String titleKey;
  final List<String> subtitleKeys;
  final String? filterKey;
  final bool canAdd;
  final bool canEdit;
  final bool canDelete;
  final List<RowAction> actions;
  final String? Function(AppState app, Rec rec)? trailing;
  final Map<String, String> Function(AppState app, Map<String, String> data)?
      onCreate;
  final String? Function(Map<String, String> data)? validate;
  final IconData Function(Rec rec)? iconFor;
}

class CrudScreen extends StatefulWidget {
  const CrudScreen({super.key, required this.config});

  final CrudConfig config;

  @override
  State<CrudScreen> createState() => _CrudScreenState();
}

class _CrudScreenState extends State<CrudScreen> {
  final TextEditingController _search = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  FieldDef? _fieldOf(String key) {
    for (final f in widget.config.fields) {
      if (f.key == key) return f;
    }
    return null;
  }

  String _subtitle(Rec rec) {
    final parts = <String>[];
    for (final key in widget.config.subtitleKeys) {
      final raw = rec[key];
      if (raw.isEmpty) continue;
      final f = _fieldOf(key);
      parts.add(f == null ? raw : displayValue(context, f, raw));
    }
    return parts.join(' • ');
  }

  Future<void> _add() async {
    final cfg = widget.config;
    final app = context.app;
    final data = await showRecordForm(
      context,
      title: '${context.tr('إضافة', 'Add')} - ${context.tr(cfg.titleAr, cfg.titleEn)}',
      fields: cfg.fields,
      validate: cfg.validate,
    );
    if (data == null || !mounted) return;
    final out = cfg.onCreate != null ? cfg.onCreate!(app, data) : data;
    app.add(cfg.table, out);
    snack(context, context.tr('تمت الإضافة بنجاح', 'Added successfully'));
  }

  Future<void> _edit(Rec rec) async {
    final cfg = widget.config;
    final app = context.app;
    final data = await showRecordForm(
      context,
      title: '${context.tr('تعديل', 'Edit')} - ${context.tr(cfg.titleAr, cfg.titleEn)}',
      fields: cfg.fields,
      initial: rec.data,
      validate: cfg.validate,
    );
    if (data == null || !mounted) return;
    app.update(cfg.table, rec.id, data);
    snack(context, context.tr('تم الحفظ بنجاح', 'Saved successfully'));
  }

  Future<void> _delete(Rec rec) async {
    final cfg = widget.config;
    final app = context.app;
    final ok = await confirmDialog(
      context,
      context.tr('هل تريد حذف هذا السجل؟', 'Delete this record?'),
    );
    if (!ok || !mounted) return;
    app.remove(cfg.table, rec.id);
    snack(context, context.tr('تم الحذف', 'Deleted'));
  }

  void _showDetail(Rec rec) {
    final cfg = widget.config;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec[cfg.titleKey],
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final f in cfg.fields)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            ctx.tr(f.ar, f.en),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          child: Text(displayValue(ctx, f, rec[f.key])),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in cfg.actions)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          a.onTap(context, rec);
                        },
                        icon: Icon(a.icon),
                        label: Text(ctx.tr(a.ar, a.en)),
                      ),
                    if (cfg.canEdit)
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _edit(rec);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(ctx.tr('تعديل', 'Edit')),
                      ),
                    if (cfg.canDelete)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _delete(rec);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(ctx).colorScheme.error,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(ctx.tr('حذف', 'Delete')),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final cfg = widget.config;
    final all = app.table(cfg.table);

    // Distinct values for the optional filter dropdown.
    final filterValues = <String>[];
    if (cfg.filterKey != null) {
      final seen = <String>{};
      for (final r in all) {
        final v = r[cfg.filterKey!];
        if (v.isNotEmpty && seen.add(v)) filterValues.add(v);
      }
      filterValues.sort();
    }
    final activeFilter = filterValues.contains(_filter) ? _filter : '';

    final query = _search.text.trim().toLowerCase();
    final rows = all.where((r) {
      if (activeFilter.isNotEmpty && r[cfg.filterKey!] != activeFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return r.data.values.any((v) => v.toLowerCase().contains(query));
    }).toList();

    final filterField = cfg.filterKey == null ? null : _fieldOf(cfg.filterKey!);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: cfg.canAdd
          ? FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: Text(context.tr('إضافة', 'Add')),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      hintText: context.tr('بحث', 'Search'),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                if (cfg.filterKey != null && filterValues.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: activeFilter,
                    items: [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text(context.tr('الكل', 'All')),
                      ),
                      for (final v in filterValues)
                        DropdownMenuItem<String>(
                          value: v,
                          child: Text(
                            filterField == null
                                ? v
                                : displayValue(context, filterField, v),
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _filter = v ?? ''),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${rows.length} ${context.tr('سجل', 'records')}',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? EmptyState(message: context.tr('لا توجد بيانات', 'No Data Available'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: rows.length,
                    itemBuilder: (ctx, i) {
                      final rec = rows[i];
                      final trailing = cfg.trailing?.call(app, rec);
                      final sub = _subtitle(rec);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              cfg.iconFor != null ? cfg.iconFor!(rec) : cfg.icon,
                            ),
                          ),
                          title: Text(rec[cfg.titleKey]),
                          subtitle: sub.isEmpty ? null : Text(sub),
                          trailing: trailing == null
                              ? null
                              : Text(
                                  trailing,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          onTap: () => _showDetail(rec),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
