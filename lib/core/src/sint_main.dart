// ignore_for_file: non_constant_identifier_names

import 'domain/interfaces/sint_interface.dart';

///Use to instead of Navigator.push, off instead of Navigator.pushReplacement,
///offAll instead of Navigator.pushAndRemoveUntil. For named router just
///add "named" after them. Example: toNamed, offNamed, and AllNamed.
///To return to the previous screen, use back().
///No need to pass any context to Get, just put the name of the route inside
///the parentheses and the magic will occur.
class _SintImpl extends SintInterface {}

/// The official SINT 1.0.0 API
final Sint = _SintImpl();

/// DEPRECATED: Legacy alias for seamless migration of the 38 repos.
/// Prune this once SINT-Native adoption reaches 100%.
@Deprecated('Use Sint instead. Get alias will be removed in SINT 2.0')
final Get = Sint;