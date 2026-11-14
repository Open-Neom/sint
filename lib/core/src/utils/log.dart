import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../sint_main.dart';

final RegExp _kSintLogInternalTags = RegExp(
  r'<\|(?:channel|turn)\s*>\s*thought\b[\s\S]*?(?:<(?:channel|turn)\|>|$)'
  r'|<\|tool_call\s*>[\s\S]*?(?:<tool_call\|>|$)'
  r'|<\s*(think|thinking|thought|memory_recall|auto_memory|system_context)\b[^>]*>[\s\S]*?(?:<\s*/\s*\1\s*>|$)'
  r'|<\|/?(?:turn|channel|tool_call|eot_id|im_start|im_end)\|>|<(?:channel|turn|tool_call)\|>|<end_of_turn>',
  caseSensitive: false,
);
final RegExp _kSintLogUrlBasicAuth = RegExp(
  r'(https?://)[^\s/@:]+:[^\s/@]+@',
  caseSensitive: false,
);
final RegExp _kSintLogSecretQuery = RegExp(
  r'([?&](?:token|access_token|id_token|refresh_token|secret|key|api_key|apikey|auth|password|passwd|code|sig|signature|oobcode|state|session)=)[^&\s#]+',
  caseSensitive: false,
);
final RegExp _kSintLogInlineToken = RegExp(
  r'(?:Bearer\s+[A-Za-z0-9._\-~+/]+=*|Basic\s+[A-Za-z0-9._\-~+/]+=*|eyJ[A-Za-z0-9_\-]{8,}\.eyJ[A-Za-z0-9_\-]{8,}\.[A-Za-z0-9_\-]{8,}|(?:sk_live_|sk_test_|rk_live_|rk_test_|sk-)[A-Za-z0-9_\-]{8,}|hf_[A-Za-z0-9]{16,}|AIza[0-9A-Za-z_\-]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|glpat-[A-Za-z0-9_\-]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9\-]{10,}|(?:cookie|set-cookie)\s*:\s*[^\r\n;]+)',
  caseSensitive: false,
);
final RegExp _kSintLogControlsAndBidi = RegExp(
  r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060-\u2069\uFEFF]',
);

/// Redacts query-string tokens, inline API credentials, Gemma-4 reasoning blocks,
/// and Bidi/C0-C1 controls before emitting framework logs.
@visibleForTesting
String sanitizeSintLogMessage(String raw, {int maxChars = 2000}) {
  final safeCap = maxChars.isFinite ? maxChars : 2000;
  if (safeCap <= 0) return '';
  final cleaned = raw
      .replaceAll(_kSintLogInternalTags, '')
      .replaceAllMapped(_kSintLogUrlBasicAuth, (m) => '${m[1]}[REDACTED]@')
      .replaceAllMapped(_kSintLogSecretQuery, (m) => '${m[1]}REDACTED')
      .replaceAll(_kSintLogInlineToken, '[REDACTED]')
      .replaceAll(_kSintLogControlsAndBidi, '');
  if (cleaned.length <= safeCap) return cleaned;
  var end = safeCap;
  final lastCode = cleaned.codeUnitAt(end - 1);
  if (lastCode >= 0xD800 && lastCode <= 0xDBFF) end--;
  return end <= 0 ? '' : cleaned.substring(0, end);
}

/// default logger from SINT
void defaultLogWriterCallback(String value, {bool isError = false}) {
  if (isError || Sint.isLogEnable) {
    developer.log(sanitizeSintLogMessage(value), name: 'SINT');
  }
}
