import 'dart:convert';

void main() {
  final jsonString = '''{
  "subjects": [
    {
      "code": "2113111",
      "subjectName": "Mathematics",
      "semester": 3,
      "credits": 4,
      "type": "theory",
      "modules": [
        {
          "moduleNumber": 1,
          "moduleTitle": "Linear Algebra",
          "hours": 8,
          "topics": [
            "Topic 1"
          ]
        }
      ]
    }
  ]
}''';

  String clean = jsonString;
  final match = RegExp(r'\{[\s\S]*\}').firstMatch(clean);
  clean = match!.group(0)!;

  try {
    final Map<String, dynamic> data = json.decode(clean);
    print("Subjects count: \${data['subjects']?.length}");
  } catch(e) {
    print(e);
  }
}
