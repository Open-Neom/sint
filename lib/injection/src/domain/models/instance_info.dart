class InstanceInfo {
  final bool? isPermanent;
  final bool? isSingleton;
  bool get isCreate => !isSingleton!;
  final bool isRegistered;
  final bool isPrepared;
  final bool? isInit;
  const InstanceInfo({
    required this.isPermanent,
    required this.isSingleton,
    required this.isRegistered,
    required this.isPrepared,
    required this.isInit,
  });

  @override
  String toString() {
    return 'InstanceInfo(isPermanent: $isPermanent, isSingleton: $isSingleton, isRegistered: $isRegistered, isPrepared: $isPrepared, isInit: $isInit)';
  }
}