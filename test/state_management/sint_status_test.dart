// SINT — State Manager Pillar (SintStatus) Test Suite
//
// Cubre el ADT `SintStatus<T>` con sus 5 estados: loading, success, error,
// empty, custom. Verifica `when` (exhaustivo), `maybeWhen` (parcial con
// orElse), getters de conveniencia (isLoading, dataOrNull, etc.) y la
// igualdad estructural vía Equality mixin.

import 'package:flutter_test/flutter_test.dart';
import 'package:sint/state_manager/sint_state_manager.dart';

void main() {
  group('SintStatus factories', () {
    test('loading() crea LoadingStatus', () {
      final status = SintStatus<String>.loading();
      expect(status, isA<LoadingStatus<String>>());
      expect(status.isLoading, isTrue);
      expect(status.isSuccess, isFalse);
      expect(status.isError, isFalse);
      expect(status.isEmpty, isFalse);
    });

    test('success(data) crea SuccessStatus con la data', () {
      final status = SintStatus<int>.success(42);
      expect(status, isA<SuccessStatus<int>>());
      expect(status.isSuccess, isTrue);
      expect(status.dataOrNull, 42);
    });

    test('error(msg) crea ErrorStatus', () {
      final status = SintStatus<String>.error('boom');
      expect(status, isA<ErrorStatus<String, Object>>());
      expect(status.isError, isTrue);
      expect(status.errorOrNull, 'boom');
    });

    test('empty() crea EmptyStatus', () {
      final status = SintStatus<int>.empty();
      expect(status, isA<EmptyStatus<int>>());
      expect(status.isEmpty, isTrue);
    });

    test('custom() crea CustomStatus', () {
      final status = SintStatus<int>.custom();
      expect(status, isA<CustomStatus<int>>());
    });
  });

  group('SintStatus.when (exhaustivo)', () {
    test('llama a loading() en estado loading', () {
      final status = SintStatus<String>.loading();
      final result = status.when(
        loading: () => 'L',
        success: (s) => 'S:$s',
        error: (e) => 'E:$e',
        empty: () => 'EMP',
      );
      expect(result, 'L');
    });

    test('llama a success(data) en estado success', () {
      final status = SintStatus<String>.success('hello');
      final result = status.when(
        loading: () => 'L',
        success: (s) => 'S:$s',
        error: (e) => 'E:$e',
        empty: () => 'EMP',
      );
      expect(result, 'S:hello');
    });

    test('llama a error(err) en estado error', () {
      final status = SintStatus<String>.error('crash');
      final result = status.when(
        loading: () => 'L',
        success: (s) => 'S:$s',
        error: (e) => 'E:$e',
        empty: () => 'EMP',
      );
      expect(result, 'E:crash');
    });

    test('llama a empty() en estado empty', () {
      final status = SintStatus<String>.empty();
      final result = status.when(
        loading: () => 'L',
        success: (s) => 'S:$s',
        error: (e) => 'E:$e',
        empty: () => 'EMP',
      );
      expect(result, 'EMP');
    });

    test('en estado custom usa custom() si está provisto', () {
      final status = SintStatus<int>.custom();
      final result = status.when(
        loading: () => 'L',
        success: (s) => 'S',
        error: (e) => 'E',
        empty: () => 'EMP',
        custom: () => 'CUSTOM',
      );
      expect(result, 'CUSTOM');
    });

    test('en estado custom cae a empty() si custom no fue provisto', () {
      final status = SintStatus<int>.custom();
      final result = status.when(
        loading: () => 'L',
        success: (s) => 'S',
        error: (e) => 'E',
        empty: () => 'EMP',
      );
      expect(result, 'EMP');
    });

    test('preserva el tipo genérico en data', () {
      final status = SintStatus<List<int>>.success([1, 2, 3]);
      final result = status.when(
        loading: () => 0,
        success: (list) => list.length,
        error: (e) => -1,
        empty: () => 0,
      );
      expect(result, 3);
    });
  });

  group('SintStatus.maybeWhen (parcial)', () {
    test('orElse cuando ningún handler matchea', () {
      final status = SintStatus<int>.success(1);
      final result = status.maybeWhen<String>(
        loading: () => 'L',
        orElse: () => 'fallback',
      );
      expect(result, 'fallback');
    });

    test('llama al handler correcto si está provisto', () {
      final status = SintStatus<int>.success(1);
      final result = status.maybeWhen<String>(
        success: (data) => 'S:$data',
        orElse: () => 'fallback',
      );
      expect(result, 'S:1');
    });

    test('error con handler', () {
      final status = SintStatus<int>.error('x');
      final result = status.maybeWhen<String>(
        error: (e) => 'E:$e',
        orElse: () => 'F',
      );
      expect(result, 'E:x');
    });

    test('custom con handler', () {
      final status = SintStatus<int>.custom();
      final result = status.maybeWhen<String>(
        custom: () => 'C',
        orElse: () => 'F',
      );
      expect(result, 'C');
    });
  });

  group('SintStatus getters de conveniencia', () {
    test('dataOrNull retorna null fuera de success', () {
      expect(SintStatus<String>.loading().dataOrNull, isNull);
      expect(SintStatus<String>.error('x').dataOrNull, isNull);
      expect(SintStatus<String>.empty().dataOrNull, isNull);
    });

    test('errorOrNull retorna null fuera de error', () {
      expect(SintStatus<int>.loading().errorOrNull, isNull);
      expect(SintStatus<int>.success(0).errorOrNull, isNull);
      expect(SintStatus<int>.empty().errorOrNull, isNull);
    });

    test('flags isLoading/isSuccess/isError/isEmpty son mutuamente exclusivos', () {
      final states = [
        SintStatus<int>.loading(),
        SintStatus<int>.success(1),
        SintStatus<int>.error('x'),
        SintStatus<int>.empty(),
      ];
      for (final s in states) {
        final flags = [s.isLoading, s.isSuccess, s.isError, s.isEmpty];
        expect(flags.where((f) => f).length, 1,
            reason: 'Exactly one flag should be true for $s');
      }
    });
  });

  group('SintStatus equality (Equality mixin)', () {
    test('dos SuccessStatus con misma data son iguales', () {
      final a = SintStatus<int>.success(7);
      final b = SintStatus<int>.success(7);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('dos SuccessStatus con data distinta NO son iguales', () {
      expect(
        SintStatus<int>.success(1),
        isNot(equals(SintStatus<int>.success(2))),
      );
    });

    test('dos LoadingStatus son iguales (sin estado interno)', () {
      expect(
        SintStatus<int>.loading(),
        equals(SintStatus<int>.loading()),
      );
    });

    test('dos ErrorStatus con mismo error son iguales', () {
      expect(
        SintStatus<int>.error('boom'),
        equals(SintStatus<int>.error('boom')),
      );
    });

    test('Loading != Success aunque sean del mismo tipo T', () {
      expect(
        SintStatus<int>.loading(),
        isNot(equals(SintStatus<int>.success(1))),
      );
    });
  });

  group('SintStatus en flujos comunes', () {
    test('transición loading → success no muta el original', () {
      // SintStatus es inmutable: cambiar de estado significa crear uno nuevo.
      final loading = SintStatus<String>.loading();
      final success = SintStatus<String>.success('done');

      expect(loading.isLoading, isTrue);
      expect(success.isSuccess, isTrue);
      expect(loading, isNot(equals(success)));
    });

    test('un List<SintStatus> mantiene sus referencias correctas', () {
      final list = <SintStatus<int>>[
        SintStatus.loading(),
        SintStatus.success(1),
        SintStatus.error('x'),
        SintStatus.empty(),
      ];
      expect(list.where((s) => s.isLoading).length, 1);
      expect(list.where((s) => s.isSuccess).length, 1);
      expect(list.where((s) => s.isError).length, 1);
      expect(list.where((s) => s.isEmpty).length, 1);
    });
  });
}
