class ObxError {
  const ObxError();
  @override
  String toString() {
    return """
      [SINT] the improper use of a SINT has been detected.
      You should only use SINT or Obx for the specific widget that will be updated.
      If you are seeing this error, you probably did not insert any observable variables into SINT/Obx
      or insert them outside the scope that SINT considers suitable for an update
      (example: SINT => HeavyWidget => variableObservable).
      If you need to update a parent widget and a child widget, wrap each one in an Obx/SINT.
      """;
  }
}