// SINT — Core Pillar (Errors + Enums) Test Suite
//
// Cubre `BindError<T>`, `ObxError`, `SmartManagement`. Son superficies
// chicas pero importantes: BindError es lo primero que un dev ve cuando se
// le olvida registrar una dependencia, así que su mensaje debe ser nítido.

import 'package:flutter_test/flutter_test.dart';
import 'package:sint/core/sint_core.dart';

void main() {
  group('BindError', () {
    test('extiende Error de dart:core', () {
      final err = BindError(controller: 'MyController', tag: null);
      expect(err, isA<Error>());
    });

    test('mensaje normal incluye el tipo solicitado', () {
      final err = BindError<String>(controller: 'MyController', tag: null);
      final msg = err.toString();
      expect(msg, contains('MyController'));
      expect(msg, contains('No Bind'));
      expect(msg, contains('ancestor'));
    });

    test('mensaje cambia cuando controller es la string "dynamic"', () {
      // El código fuente compara `controller == 'dynamic'` (string),
      // así que sólo entra a esa rama cuando se pasa la string literal.
      final err = BindError<dynamic>(controller: 'dynamic', tag: null);
      expect(err.toString(), contains('please specify type'));
      expect(err.toString(), contains('context.find<T>()'));
    });

    test('toString es estable (mismo input ⇒ mismo output)', () {
      final a = BindError<String>(controller: 'C', tag: 'tag1');
      final b = BindError<String>(controller: 'C', tag: 'tag1');
      expect(a.toString(), b.toString());
    });

    test('tag se almacena pero no aparece en el mensaje (comportamiento actual)', () {
      // Si el comportamiento cambia y el tag empieza a aparecer, este test
      // es la primera línea de aviso.
      final err = BindError(controller: 'C', tag: 'mySpecialTag');
      expect(err.tag, 'mySpecialTag');
      expect(err.toString().contains('mySpecialTag'), isFalse);
    });
  });

  group('ObxError', () {
    test('toString contiene la marca [SINT]', () {
      const err = ObxError();
      expect(err.toString(), contains('[SINT]'));
    });

    test('toString menciona el patrón de uso correcto', () {
      const err = ObxError();
      final msg = err.toString();
      expect(msg, contains('Obx'));
      expect(msg, contains('observable'));
    });

    test('es const-constructible', () {
      const a = ObxError();
      const b = ObxError();
      expect(identical(a, b), isTrue);
    });
  });

  group('SmartManagement enum', () {
    test('tiene exactamente 3 valores', () {
      expect(SmartManagement.values.length, 3);
    });

    test('contiene full / onlyBuilder / keepFactory', () {
      expect(SmartManagement.values, contains(SmartManagement.full));
      expect(SmartManagement.values, contains(SmartManagement.onlyBuilder));
      expect(SmartManagement.values, contains(SmartManagement.keepFactory));
    });

    test('full es el primero (default lógico documentado)', () {
      // El doc-comment dice "SmartManagement.full is the default one".
      expect(SmartManagement.values.first, SmartManagement.full);
    });

    test('comparaciones por valor', () {
      expect(SmartManagement.full, SmartManagement.full);
      expect(SmartManagement.full, isNot(SmartManagement.onlyBuilder));
    });

    test('toString contiene el nombre del enum', () {
      expect(SmartManagement.full.toString(), contains('full'));
      expect(SmartManagement.keepFactory.toString(), contains('keepFactory'));
    });
  });
}
