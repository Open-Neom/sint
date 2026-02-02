/// SINT by default disposes unused controllers from memory,
/// Through different behaviors.
/// SmartManagement.full
/// [SmartManagement.full] is the default one. Dispose classes that are
/// not being used and were not set to be permanent. In the majority
/// of the cases you will want to keep this config untouched.
/// If you new to SINT then don't change this.
/// [SmartManagement.onlyBuilder] only controllers started in init:
/// or loaded into a Binding with Sint.lazyPut() will be disposed. If you use
/// Sint.put() or Sint.putAsync() or any other approach, SmartManagement
/// will not have permissions to exclude this dependency. With the default
/// behavior, even ui instantiated with "Sint.put" will be removed,
/// unlike SmartManagement.onlyBuilders.
/// [SmartManagement.keepFactory]Just like SmartManagement.full,
/// it will remove it's dependencies when it's not being used anymore.
/// However, it will keep their factory, which means it will recreate
/// the dependency if you need that instance again.
enum SmartManagement {
  full,
  onlyBuilder,
  keepFactory,
}
