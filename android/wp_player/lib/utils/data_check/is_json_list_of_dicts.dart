bool isJsonListOfDicts(dynamic json) {
  if (json is! List) return false;
  if (json.isEmpty) return true;

  return json.every((entry) => entry is Map<String, dynamic>);
}
