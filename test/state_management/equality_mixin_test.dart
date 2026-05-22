// SINT — State Manager Pillar (Equality Mixin) Test Suite
//
// Cubre `Equality` mixin (compara por `props` con DeepCollectionEquality)
// y la familia de IEquality: DefaultEquality, IdentityEquality, ListEquality,
// MapEquality, IterableEquality, SetEquality, UnorderedIterableEquality.
//
// Foco: simetría, transitividad, hashCode consistente con ==,
// y comportamiento con colecciones anidadas (deep equality).

import 'package:flutter_test/flutter_test.dart';
import 'package:sint/state_manager/sint_state_manager.dart';

class _Pair with Equality {
  final String a;
  final int b;
  _Pair(this.a, this.b);
  @override
  List get props => [a, b];
}

class _Triple with Equality {
  final String a;
  final int b;
  final List<int> nested;
  _Triple(this.a, this.b, this.nested);
  @override
  List get props => [a, b, nested];
}

void main() {
  group('Equality mixin (props-based)', () {
    test('reflexiva: x == x', () {
      final p = _Pair('a', 1);
      expect(p, equals(p));
    });

    test('simétrica: igual props ⇒ ==', () {
      final p1 = _Pair('a', 1);
      final p2 = _Pair('a', 1);
      expect(p1, equals(p2));
      expect(p2, equals(p1));
    });

    test('hashCode consistente con ==', () {
      final p1 = _Pair('a', 1);
      final p2 = _Pair('a', 1);
      expect(p1.hashCode, equals(p2.hashCode));
    });

    test('distintas props ⇒ !=', () {
      expect(_Pair('a', 1), isNot(equals(_Pair('b', 1))));
      expect(_Pair('a', 1), isNot(equals(_Pair('a', 2))));
    });

    test('transitiva: si a==b y b==c entonces a==c', () {
      final a = _Pair('x', 9);
      final b = _Pair('x', 9);
      final c = _Pair('x', 9);
      expect(a, equals(b));
      expect(b, equals(c));
      expect(a, equals(c));
    });

    test('runtimeType distinto ⇒ != aun con mismas props', () {
      // Confirmamos que la mixin compara runtimeType, no solo props.
      final a = _Pair('x', 1);

      // _Triple requiere 3 props pero podríamos hacer una con [x, 1] equivalentes
      // a las primeras dos de _Pair. Aún así runtimeType difiere ⇒ no iguales.
      final b = _Triple('x', 1, []);
      expect(a, isNot(equals(b)));
    });

    test('compara colecciones anidadas con deep equality', () {
      final a = _Triple('x', 1, [1, 2, 3]);
      final b = _Triple('x', 1, [1, 2, 3]);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('orden distinto en lista anidada ⇒ !=', () {
      final a = _Triple('x', 1, [1, 2, 3]);
      final b = _Triple('x', 1, [3, 2, 1]);
      expect(a, isNot(equals(b)));
    });
  });

  group('DefaultEquality<T>', () {
    test('equals delega a ==', () {
      const eq = DefaultEquality<int>();
      expect(eq.equals(1, 1), isTrue);
      expect(eq.equals(1, 2), isFalse);
    });

    test('hash delega a hashCode', () {
      const eq = DefaultEquality<String>();
      expect(eq.hash('hi'), 'hi'.hashCode);
    });

    test('isValidKey acepta cualquier objeto', () {
      const eq = DefaultEquality<int>();
      expect(eq.isValidKey(1), isTrue);
      expect(eq.isValidKey('s'), isTrue);
      expect(eq.isValidKey(null), isTrue);
    });

    test('factory IEquality<T>() construye DefaultEquality', () {
      const eq = IEquality<int>();
      expect(eq, isA<DefaultEquality<int>>());
    });
  });

  group('IdentityEquality<T>', () {
    test('compara por identidad, no por valor', () {
      const eq = IdentityEquality<List<int>>();
      final a = [1, 2];
      final b = [1, 2];
      expect(eq.equals(a, a), isTrue);
      expect(eq.equals(a, b), isFalse);
    });
  });

  group('ListEquality', () {
    test('listas con mismos elementos son iguales', () {
      const eq = ListEquality();
      expect(eq.equals([1, 2, 3], [1, 2, 3]), isTrue);
    });

    test('orden distinto ⇒ !=', () {
      const eq = ListEquality();
      expect(eq.equals([1, 2, 3], [3, 2, 1]), isFalse);
    });

    test('longitudes distintas ⇒ !=', () {
      const eq = ListEquality();
      expect(eq.equals([1, 2], [1, 2, 3]), isFalse);
    });

    test('nulos: ambos null ⇒ true', () {
      const eq = ListEquality();
      expect(eq.equals(null, null), isTrue);
    });

    test('nulos: uno null ⇒ false', () {
      const eq = ListEquality();
      expect(eq.equals([1], null), isFalse);
      expect(eq.equals(null, [1]), isFalse);
    });

    test('hash igual para listas iguales', () {
      const eq = ListEquality();
      expect(eq.hash([1, 2, 3]), eq.hash([1, 2, 3]));
    });

    test('isValidKey acepta List<E>', () {
      const eq = ListEquality<int>();
      expect(eq.isValidKey([1, 2]), isTrue);
      expect(eq.isValidKey('not a list'), isFalse);
    });
  });

  group('MapEquality', () {
    test('mapas con mismos pares son iguales sin importar orden', () {
      const eq = MapEquality();
      expect(eq.equals({'a': 1, 'b': 2}, {'b': 2, 'a': 1}), isTrue);
    });

    test('valores distintos ⇒ !=', () {
      const eq = MapEquality();
      expect(eq.equals({'a': 1}, {'a': 2}), isFalse);
    });

    test('llaves distintas ⇒ !=', () {
      const eq = MapEquality();
      expect(eq.equals({'a': 1}, {'b': 1}), isFalse);
    });

    test('hash de mapas iguales coincide', () {
      const eq = MapEquality();
      final h1 = eq.hash({'a': 1, 'b': 2});
      final h2 = eq.hash({'b': 2, 'a': 1});
      expect(h1, h2);
    });
  });

  group('IterableEquality', () {
    test('mismos elementos en orden ⇒ true', () {
      const eq = IterableEquality();
      final a = [1, 2, 3].cast<int>();
      final b = [1, 2, 3].cast<int>();
      expect(eq.equals(a, b), isTrue);
    });

    test('orden distinto ⇒ false', () {
      const eq = IterableEquality();
      expect(eq.equals([1, 2, 3], [3, 2, 1]), isFalse);
    });
  });

  group('SetEquality', () {
    test('mismos elementos sin importar orden de inserción ⇒ true', () {
      const eq = SetEquality();
      final a = {1, 2, 3};
      final b = {3, 2, 1};
      expect(eq.equals(a, b), isTrue);
    });

    test('elementos distintos ⇒ false', () {
      const eq = SetEquality();
      expect(eq.equals({1, 2}, {1, 3}), isFalse);
    });

    test('isValidKey acepta Set<E>', () {
      const eq = SetEquality<int>();
      expect(eq.isValidKey({1, 2}), isTrue);
      expect(eq.isValidKey([1, 2]), isFalse);
    });
  });

  group('UnorderedIterableEquality', () {
    test('iterables con mismos elementos en cualquier orden ⇒ true', () {
      const eq = UnorderedIterableEquality();
      expect(eq.equals([1, 2, 3], [3, 1, 2]), isTrue);
    });

    test('multiplicidad importa', () {
      const eq = UnorderedIterableEquality();
      expect(eq.equals([1, 1, 2], [1, 2]), isFalse);
    });
  });

  group('DeepCollectionEquality', () {
    test('listas anidadas iguales', () {
      const eq = DeepCollectionEquality();
      expect(
        eq.equals([
          [1, 2],
          [3, 4],
        ], [
          [1, 2],
          [3, 4],
        ]),
        isTrue,
      );
    });

    test('mapas anidados con listas iguales', () {
      const eq = DeepCollectionEquality();
      expect(
        eq.equals({
          'k': [1, 2],
        }, {
          'k': [1, 2],
        }),
        isTrue,
      );
    });

    test('escalares delegan a == base', () {
      const eq = DeepCollectionEquality();
      expect(eq.equals(1, 1), isTrue);
      expect(eq.equals('a', 'a'), isTrue);
      expect(eq.equals(1, 2), isFalse);
    });

    test('hash es estable para misma estructura', () {
      const eq = DeepCollectionEquality();
      final h1 = eq.hash([
        [1, 2],
        [3, 4],
      ]);
      final h2 = eq.hash([
        [1, 2],
        [3, 4],
      ]);
      expect(h1, h2);
    });

    test('isValidKey acepta colecciones', () {
      const eq = DeepCollectionEquality();
      expect(eq.isValidKey([1]), isTrue);
      expect(eq.isValidKey({1: 2}), isTrue);
      expect(eq.isValidKey({1, 2}), isTrue);
      // Escalares también son válidos por delegación
      expect(eq.isValidKey(1), isTrue);
    });
  });
}
