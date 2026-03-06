import 'dart:io';

void main() async {
  final result = await Process.run('dart', ['analyze', '--format=machine']);
  final lines = result.stdout.toString().split('\n');
  final errors = lines.where((line) => line.contains('ERROR'));
  if (errors.isEmpty) {
    File('errors.txt').writeAsStringSync('NO COMPILE ERRORS');
  } else {
    File('errors.txt').writeAsStringSync(errors.join('\n'));
  }
}
