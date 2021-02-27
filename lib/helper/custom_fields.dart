import 'dart:convert';

class CustomFields {
  static final activeFieldTypes = const {'text', 'secret', 'email', 'link'};

  List<Map<String, String>> _fields;

  String get asJson => json.encode(_fields);

  List<Map<String, String>> get fields => _fields
      .where((f) => activeFieldTypes.contains(f['type']))
      .toList(growable: false);

  CustomFields.fromJson(String jsonString) {
    final x = json.decode(jsonString) as List;
    if (x == null) {
      _fields = [];
    } else {
      _fields = x
          .map((f) => {
                'type': f['type'] as String,
                'label': f['label'] as String,
                'value': f['value'] as String
              })
          .toList();
    }
  }

  CustomFields.empty() {
    _fields = [];
  }

  bool createField(String type, String label, String value) {
    if (_fields.length > 19 ||
        !typeCheck(type) ||
        !labelCheck(label) ||
        !valueCheck(value) ||
        _fields.any((f) => f['label'] == label)) {
      return false;
    }
    _fields.add({'type': type, 'label': label, 'value': value});
    return true;
  }

  bool updateField(String label, String value) {
    if (!labelCheck(label) ||
        !valueCheck(value) ||
        !_fields.any((f) => f['label'] == label)) {
      return false;
    }
    _fields.where((f) => f['label'] == label).first['value'] = value;
    return true;
  }

  bool deleteField(String label) {
    if (labelCheck(label) || !_fields.any((f) => f['label'] == label)) {
      return false;
    }
    _fields.removeWhere((f) => f['label'] == label);
    return true;
  }

  bool labelCheck(String label) =>
      label != null && label.isNotEmpty && label.length <= 48;

  bool typeCheck(String type) =>
      type != null && activeFieldTypes.contains(type);

  bool valueCheck(String value) => value != null && value.length <= 370;
}
