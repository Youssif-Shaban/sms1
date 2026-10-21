import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import 'common.dart';

/// Opens a dialog with one input per [FieldDef]. Returns the entered values
/// (key -> text) or null when the dialog is cancelled.
///
/// [validate] runs after the field validators pass; return an error message
/// to keep the dialog open, or null to accept.
Future<Map<String, String>?> showRecordForm(
  BuildContext context, {
  required String title,
  required List<FieldDef> fields,
  Map<String, String>? initial,
  String? Function(Map<String, String> values)? validate,
}) {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => _RecordFormDialog(
      title: title,
      fields: fields,
      initial: initial,
      validate: validate,
    ),
  );
}

class _RecordFormDialog extends StatefulWidget {
  const _RecordFormDialog({
    required this.title,
    required this.fields,
    required this.initial,
    required this.validate,
  });

  final String title;
  final List<FieldDef> fields;
  final Map<String, String>? initial;
  final String? Function(Map<String, String> values)? validate;

  @override
  State<_RecordFormDialog> createState() => _RecordFormDialogState();
}

class _RecordFormDialogState extends State<_RecordFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, String> _values;
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  String? _error;

  bool _isPicker(FieldType t) => t == FieldType.choice || t == FieldType.ref;

  @override
  void initState() {
    super.initState();
    _values = <String, String>{
      for (final f in widget.fields) f.key: widget.initial?[f.key] ?? '',
    };
    for (final f in widget.fields) {
      if (_isPicker(f.type)) continue;
      final raw = _values[f.key] ?? '';
      _controllers[f.key] = TextEditingController(
        text: f.type == FieldType.date && raw.isNotEmpty ? fmtDate(raw) : raw,
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<DropdownMenuItem<String>> _items(FieldDef f) {
    if (f.type == FieldType.ref) {
      final names = context.app
          .table(f.refTable)
          .map((r) => r[f.refKey])
          .where((v) => v.isNotEmpty)
          .toSet()
          .toList();
      return names
          .map((n) => DropdownMenuItem<String>(value: n, child: Text(n)))
          .toList();
    }
    return f.options
        .map((o) => DropdownMenuItem<String>(
              value: o.value,
              child: Text(context.tr(o.ar, o.en)),
            ))
        .toList();
  }

  Widget _field(FieldDef f) {
    final label = context.tr(f.ar, f.en) + (f.required ? ' *' : '');
    final requiredMsg = context.tr('هذا الحقل مطلوب', 'This field is required');

    if (_isPicker(f.type)) {
      final items = _items(f);
      final current = _values[f.key] ?? '';
      final valid = items.any((i) => i.value == current);
      return DropdownButtonFormField<String>(
        value: valid ? current : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: items,
        onChanged: (v) => setState(() => _values[f.key] = v ?? ''),
        validator: (v) =>
            f.required && (v == null || v.isEmpty) ? requiredMsg : null,
      );
    }

    if (f.type == FieldType.date) {
      return TextFormField(
        controller: _controllers[f.key],
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        onTap: () async {
          final picked = await pickDate(context, _values[f.key] ?? '');
          if (picked != null) {
            _values[f.key] = picked;
            _controllers[f.key]!.text = fmtDate(picked);
          }
        },
        validator: (v) =>
            f.required && (v == null || v.isEmpty) ? requiredMsg : null,
      );
    }

    var keyboard = TextInputType.text;
    if (f.type == FieldType.number) {
      keyboard = const TextInputType.numberWithOptions(decimal: true);
    } else if (f.type == FieldType.phone) {
      keyboard = TextInputType.phone;
    } else if (f.type == FieldType.email) {
      keyboard = TextInputType.emailAddress;
    }
    final multiline = f.type == FieldType.multiline;

    return TextFormField(
      controller: _controllers[f.key],
      keyboardType: multiline ? TextInputType.multiline : keyboard,
      minLines: multiline ? 2 : 1,
      maxLines: multiline ? 4 : 1,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        final t = (v ?? '').trim();
        if (f.required && t.isEmpty) return requiredMsg;
        if (t.isNotEmpty &&
            f.type == FieldType.number &&
            double.tryParse(t) == null) {
          return context.tr('أدخل رقماً صحيحاً', 'Enter a valid number');
        }
        if (t.isNotEmpty && f.type == FieldType.email && !t.contains('@')) {
          return context.tr('بريد إلكتروني غير صحيح', 'Invalid e-mail address');
        }
        return null;
      },
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final out = <String, String>{};
    for (final f in widget.fields) {
      if (_isPicker(f.type) || f.type == FieldType.date) {
        out[f.key] = (_values[f.key] ?? '').trim();
      } else {
        out[f.key] = _controllers[f.key]!.text.trim();
      }
    }
    final err = widget.validate?.call(out);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context, out);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                for (final f in widget.fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _field(f),
                  ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('إلغاء', 'Cancel')),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(context.tr('حفظ', 'Save')),
        ),
      ],
    );
  }
}
