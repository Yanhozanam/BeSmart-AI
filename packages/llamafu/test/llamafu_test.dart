import 'package:flutter_test/flutter_test.dart';
import 'package:llamafu/llamafu.dart';

void main() {
  group('Llamafu', () {
    test('Llamafu class exists', () {
      expect(Llamafu, isNotNull);
    });

    test('Llamafu.init is callable', () {
      expect(Llamafu.init, isNotNull);
    });

    test('maxTokens default is defined', () {
      expect(Llamafu.maxTokens, equals(8192));
    });

    test('maxPromptLength default is defined', () {
      expect(Llamafu.maxPromptLength, equals(100000));
    });
  });
}
