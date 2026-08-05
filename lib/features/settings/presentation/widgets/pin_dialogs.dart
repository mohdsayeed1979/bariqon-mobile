import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/pin_input_field.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../controllers/app_lock_controller.dart';

const int _minPinLength = 4;

/// Two-step "enter new PIN, then confirm it" dialog shared by both PIN
/// creation and PIN change (change just adds a leading "verify current
/// PIN" step first) — avoids two near-identical dialog implementations.
class _NewPinFlow extends ConsumerStatefulWidget {
  const _NewPinFlow({required this.requireCurrentPin});

  final bool requireCurrentPin;

  @override
  ConsumerState<_NewPinFlow> createState() => _NewPinFlowState();
}

enum _NewPinStep { current, enter, confirm }

class _NewPinFlowState extends ConsumerState<_NewPinFlow> {
  late _NewPinStep _step = widget.requireCurrentPin
      ? _NewPinStep.current
      : _NewPinStep.enter;
  final _controller = TextEditingController();
  String? _currentPin;
  String? _newPin;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final value = _controller.text;

    if (value.length < _minPinLength) {
      setState(() => _error = l10n.pinTooShortError);
      return;
    }

    switch (_step) {
      case _NewPinStep.current:
        setState(() => _busy = true);
        final verified = await ref
            .read(appLockControllerProvider.notifier)
            .verifyPin(value);
        if (!mounted) return;
        setState(() => _busy = false);
        if (!verified) {
          setState(() => _error = l10n.pinIncorrectError);
          return;
        }
        _currentPin = value;
        _controller.clear();
        setState(() {
          _step = _NewPinStep.enter;
          _error = null;
        });
      case _NewPinStep.enter:
        _newPin = value;
        _controller.clear();
        setState(() {
          _step = _NewPinStep.confirm;
          _error = null;
        });
      case _NewPinStep.confirm:
        if (value != _newPin) {
          setState(() => _error = l10n.pinMismatchError);
          return;
        }
        Navigator.of(context).pop((_currentPin, _newPin));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (_step) {
      _NewPinStep.current => l10n.pinCurrentLabel,
      _NewPinStep.enter => l10n.pinEnterNewLabel,
      _NewPinStep.confirm => l10n.pinConfirmLabel,
    };

    return AlertDialog(
      title: Text(
        widget.requireCurrentPin
            ? l10n.pinManagementChangeTitle
            : l10n.pinManagementCreateTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PinInputField(
            controller: _controller,
            label: label,
            autofocus: true,
            errorText: _error,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _busy ? null : _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.ok),
        ),
      ],
    );
  }
}

/// Creates a PIN and enables PIN-method App Lock. Returns true on success.
Future<bool> showCreatePinDialog(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<(String?, String?)>(
    context: context,
    builder: (context) => const _NewPinFlow(requireCurrentPin: false),
  );
  if (result == null) return false;
  final (_, newPin) = result;
  if (newPin == null) return false;
  await ref.read(appLockControllerProvider.notifier).enableWithNewPin(newPin);
  return true;
}

/// Verifies the current PIN, then sets a new one. Returns true on success.
Future<bool> showChangePinDialog(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<(String?, String?)>(
    context: context,
    builder: (context) => const _NewPinFlow(requireCurrentPin: true),
  );
  if (result == null) return false;
  final (currentPin, newPin) = result;
  if (currentPin == null || newPin == null) return false;
  return ref
      .read(appLockControllerProvider.notifier)
      .changePin(currentPin: currentPin, newPin: newPin);
}

/// Verifies the current PIN, then removes it (and disables App Lock if PIN
/// was the active method). Returns true on success.
Future<bool> showRemovePinDialog(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  String? error;

  final verified = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.pinManagementRemoveTitle),
        content: PinInputField(
          controller: controller,
          label: l10n.pinCurrentLabel,
          autofocus: true,
          errorText: error,
          onChanged: (_) => setState(() => error = null),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await ref
                  .read(appLockControllerProvider.notifier)
                  .verifyPin(controller.text);
              if (!context.mounted) return;
              if (!ok) {
                setState(() => error = l10n.pinIncorrectError);
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    ),
  );
  controller.dispose();

  if (verified != true) return false;
  await ref.read(appLockControllerProvider.notifier).removePin();
  return true;
}
