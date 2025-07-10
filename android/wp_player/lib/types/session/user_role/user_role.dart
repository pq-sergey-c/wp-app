enum UserRole {
  listener("listener"),
  provider("provider");

  final String value;

  const UserRole(this.value);

  static UserRole fromString(final String value) {
    try {
      return UserRole.values.firstWhere((e) => e.value == value);
    } catch (e) {
      throw StateError("User role: unknown string value of role - $value");
    }
  }
}
