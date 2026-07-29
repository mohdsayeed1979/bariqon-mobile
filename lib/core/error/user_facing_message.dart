import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';
import 'failure.dart';

/// Picks the right user-facing string for a caught error. A
/// [NetworkFailure] reads as "check your connection" rather than the
/// generic fallback — the two mean different things to a user (one says
/// try again later, the other says check your wifi) — every other
/// [Failure] subtype (and anything not a [Failure] at all) falls back to
/// the generic message: their `.message` strings are plain English, not
/// localized or written for end users. Shared by every screen's catch
/// block and by [ErrorStateView.forError], so the distinction is made in
/// exactly one place.
String userFacingErrorMessage(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  return error is NetworkFailure
      ? l10n.networkErrorMessage
      : l10n.genericErrorMessage;
}
