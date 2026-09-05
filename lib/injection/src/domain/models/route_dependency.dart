/// A route owns one initialized generation of a dependency, not merely its
/// type/tag. These callbacks become no-ops if that generation is replaced.
class RouteDependency {
  const RouteDependency({required this.markAsDirty, required this.delete});

  final void Function() markAsDirty;
  final bool Function() delete;
}
