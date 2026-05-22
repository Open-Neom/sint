// SINT — Core Pillar (Rx Primitives) Test Suite
//
// Cubre los wrappers reactivos básicos exportados desde `sint/core/sint_core.dart`:
// RxBool / RxnBool, RxInt / RxnInt, RxDouble / RxnDouble, RxString / RxnString,
// RxNum / RxnNum, y las extensions `.obs` de cada tipo nativo.
//
// Foco: valor inicial, mutaciones vía operadores/extensions, toString,
// caminos null-safe, y reactividad básica (listeners se disparan al setear value).

import 'package:flutter_test/flutter_test.dart';
import 'package:sint/core/sint_core.dart';

void main() {
  group('RxBool', () {
    test('valor inicial se respeta', () {
      final flag = RxBool(true);
      expect(flag.value, isTrue);
    });

    test('toString refleja el valor', () {
      expect(RxBool(true).toString(), 'true');
      expect(RxBool(false).toString(), 'false');
    });

    test('isTrue / isFalse getters', () {
      final t = RxBool(true);
      final f = RxBool(false);
      expect(t.isTrue, isTrue);
      expect(t.isFalse, isFalse);
      expect(f.isTrue, isFalse);
      expect(f.isFalse, isTrue);
    });

    test('toggle invierte el valor', () {
      final flag = RxBool(false);
      flag.toggle();
      expect(flag.value, isTrue);
      flag.toggle();
      expect(flag.value, isFalse);
    });

    test('operadores lógicos & | ^', () {
      final t = RxBool(true);
      final f = RxBool(false);
      expect(t & true, isTrue);
      expect(t & false, isFalse);
      expect(f | true, isTrue);
      expect(f | false, isFalse);
      expect(t ^ false, isTrue);
      expect(t ^ true, isFalse);
    });

    test('extension .obs sobre bool', () {
      final RxBool r = true.obs;
      expect(r.value, isTrue);
      expect(r, isA<RxBool>());
    });
  });

  group('RxnBool (nullable)', () {
    test('acepta null inicial', () {
      final r = RxnBool();
      expect(r.value, isNull);
    });

    test('toString cuando es null', () {
      expect(RxnBool().toString(), 'null');
      expect(RxnBool(true).toString(), 'true');
    });

    test('isFalse devuelve null si value es null', () {
      final r = RxnBool();
      expect(r.isFalse, isNull);
      expect(r.isTrue, isNull);
    });

    test('toggle es no-op cuando value es null', () {
      final r = RxnBool();
      r.toggle();
      expect(r.value, isNull);
    });

    test('toggle invierte cuando value no es null', () {
      final r = RxnBool(true);
      r.toggle();
      expect(r.value, isFalse);
    });

    test('operadores devuelven null cuando value es null', () {
      final r = RxnBool();
      expect(r & true, isNull);
      expect(r | true, isNull);
    });
  });

  group('RxInt', () {
    test('valor inicial', () {
      expect(RxInt(42).value, 42);
    });

    test('operador + muta el valor y retorna el Rx', () {
      final n = RxInt(0);
      final result = n + 5;
      expect(n.value, 5);
      expect(result, same(n));
    });

    test('operador - muta el valor', () {
      final n = RxInt(10);
      n - 3;
      expect(n.value, 7);
    });

    test('cadena de mutaciones acumula', () {
      final n = RxInt(0);
      n + 1;
      n + 2;
      n + 3;
      expect(n.value, 6);
    });

    test('isEven / isOdd', () {
      expect(RxInt(4).isEven, isTrue);
      expect(RxInt(3).isOdd, isTrue);
    });

    test('operadores bit-wise', () {
      expect(RxInt(0xF0) & 0x0F, 0x00);
      expect(RxInt(0xF0) | 0x0F, 0xFF);
      expect(RxInt(0xFF) ^ 0x0F, 0xF0);
    });

    test('extension .obs sobre int', () {
      final r = 7.obs;
      expect(r, isA<RxInt>());
      expect(r.value, 7);
    });
  });

  group('RxnInt (nullable)', () {
    test('acepta null inicial', () {
      expect(RxnInt().value, isNull);
    });

    test('+ es no-op si value es null', () {
      final n = RxnInt();
      n + 5;
      expect(n.value, isNull);
    });

    test('+ muta cuando value no es null', () {
      final n = RxnInt(10);
      n + 5;
      expect(n.value, 15);
    });
  });

  group('RxDouble', () {
    test('valor inicial', () {
      expect(RxDouble(1.5).value, 1.5);
    });

    test('operador * sobre Rx<double>', () {
      final d = RxDouble(2.0);
      expect(d * 3, 6.0);
    });

    test('round / floor / ceil / truncate', () {
      expect(RxDouble(3.7).round(), 4);
      expect(RxDouble(3.7).floor(), 3);
      expect(RxDouble(3.2).ceil(), 4);
      expect(RxDouble(3.7).truncate(), 3);
    });

    test('isNegative / sign', () {
      expect(RxDouble(-1.5).sign, -1.0);
      expect(RxDouble(2.5).sign, 1.0);
    });

    test('extension .obs sobre double', () {
      final r = 3.14.obs;
      expect(r, isA<RxDouble>());
      expect(r.value, 3.14);
    });
  });

  group('RxString', () {
    test('valor inicial', () {
      expect(RxString('hello').value, 'hello');
    });

    test('operador + concatena', () {
      final s = RxString('hello ');
      expect(s + 'world', 'hello world');
      // El operador devuelve una nueva String, no muta el Rx.
      expect(s.value, 'hello ');
    });

    test('isEmpty / isNotEmpty', () {
      expect(RxString('').isEmpty, isTrue);
      expect(RxString('a').isNotEmpty, isTrue);
    });

    test('contains / startsWith / endsWith', () {
      final s = RxString('hello world');
      expect(s.contains('world'), isTrue);
      expect(s.startsWith('hello'), isTrue);
      expect(s.endsWith('world'), isTrue);
    });

    test('toUpperCase / toLowerCase', () {
      expect(RxString('Hi').toUpperCase(), 'HI');
      expect(RxString('Hi').toLowerCase(), 'hi');
    });

    test('split y trim', () {
      expect(RxString('a,b,c').split(','), ['a', 'b', 'c']);
      expect(RxString('  pad  ').trim(), 'pad');
    });

    test('replaceAll', () {
      expect(RxString('a.b.c').replaceAll('.', '-'), 'a-b-c');
    });

    test('extension .obs sobre String', () {
      final r = 'sint'.obs;
      expect(r, isA<RxString>());
      expect(r.value, 'sint');
    });

    test('compareTo respeta orden lexicográfico', () {
      expect(RxString('a').compareTo('b'), lessThan(0));
      expect(RxString('b').compareTo('a'), greaterThan(0));
      expect(RxString('a').compareTo('a'), 0);
    });
  });

  group('RxnString (nullable)', () {
    test('acepta null inicial', () {
      expect(RxnString().value, isNull);
    });

    test('+ usa cadena vacía cuando value es null', () {
      final s = RxnString();
      expect(s + 'x', 'x');
    });

    test('isEmpty devuelve null cuando value es null', () {
      expect(RxnString().isEmpty, isNull);
    });

    test('isNotEmpty con valor no-null', () {
      expect(RxnString('hi').isNotEmpty, isTrue);
    });
  });

  group('RxNum', () {
    test('+ y - mutan el valor', () {
      final n = RxNum(0);
      n + 5;
      expect(n.value, 5);
      n - 2;
      expect(n.value, 3);
    });

    test('mantiene el subtipo num (int o double)', () {
      final n = RxNum(2);
      n + 1.5;
      expect(n.value, 3.5);
    });
  });

  group('RxnNum (nullable)', () {
    test('+ es no-op si null', () {
      final n = RxnNum();
      n + 5;
      expect(n.value, isNull);
    });

    test('+ muta cuando hay valor', () {
      final n = RxnNum(2);
      n + 3;
      expect(n.value, 5);
    });
  });

  group('Reactividad: setear value notifica', () {
    test('RxInt notifica al cambiar value', () {
      final n = RxInt(0);
      var notifications = 0;
      n.addListener(() => notifications++);

      n.value = 1;
      n.value = 2;

      expect(notifications, greaterThanOrEqualTo(2));
    });

    test('RxBool no notifica si el valor no cambia', () {
      // Comportamiento esperado en frameworks reactivos: setear el mismo
      // valor no debería disparar listeners. Si la implementación NO hace
      // diff, el test fallará y lo registramos.
      final flag = RxBool(true);
      var notifications = 0;
      flag.addListener(() => notifications++);

      flag.value = true; // mismo valor

      expect(notifications, 0);
    });
  });
}
