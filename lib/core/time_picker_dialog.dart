import 'package:flutter/material.dart';

/// Shows a dialog with hour/minute dropdowns and AM/PM toggle instead of
/// the built-in clock picker, which many users find unintuitive.
Future<TimeOfDay?> showTimeDropdownPicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (_) => _TimeDropdownDialog(initialTime: initialTime),
  );
}

class _TimeDropdownDialog extends StatefulWidget {
  const _TimeDropdownDialog({required this.initialTime});
  final TimeOfDay initialTime;

  @override
  State<_TimeDropdownDialog> createState() => _TimeDropdownDialogState();
}

class _TimeDropdownDialogState extends State<_TimeDropdownDialog> {
  late int _hour12;
  late int _minute;
  late bool _isPm;

  @override
  void initState() {
    super.initState();
    final h = widget.initialTime.hour;
    _isPm = h >= 12;
    _hour12 = h % 12 == 0 ? 12 : h % 12;
    // Snap to nearest 5-minute increment.
    _minute = ((widget.initialTime.minute / 5).round() * 5) % 60;
  }

  int get _hour24 {
    if (_isPm) return _hour12 == 12 ? 12 : _hour12 + 12;
    return _hour12 == 12 ? 0 : _hour12;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select time'),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<int>(
            value: _hour12,
            items: [
              for (int h = 1; h <= 12; h++)
                DropdownMenuItem(value: h, child: Text('$h')),
            ],
            onChanged: (v) => setState(() => _hour12 = v!),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ':',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          DropdownButton<int>(
            value: _minute,
            items: [
              for (int m = 0; m < 60; m += 5)
                DropdownMenuItem(
                  value: m,
                  child: Text(m.toString().padLeft(2, '0')),
                ),
            ],
            onChanged: (v) => setState(() => _minute = v!),
          ),
          const SizedBox(width: 12),
          ToggleButtons(
            isSelected: [!_isPm, _isPm],
            onPressed: (i) => setState(() => _isPm = i == 1),
            borderRadius: BorderRadius.circular(6),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text('AM'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text('PM'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            TimeOfDay(hour: _hour24, minute: _minute),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
