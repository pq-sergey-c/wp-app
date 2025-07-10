class SessionVariableInputs {
  final String name;

  const SessionVariableInputs({required this.name});

  static SessionVariableInputs? fromJson(Map<String, dynamic> json) {
    final dynamic name = json["name"];

    if (name is! String) {
      return null;
    }

    return SessionVariableInputs(name: name);
  }
}
