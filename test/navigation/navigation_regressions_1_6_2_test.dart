import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

SintPage _page(
  String name, {
  List<SintPage> children = const [],
  List<SintMiddleware> middlewares = const [],
  List<BindingsInterface> bindings = const [],
  BindingsInterface? binding,
  bool inheritParentPath = true,
  String? title,
}) =>
    SintPage(
      name: name,
      page: () => const SizedBox(),
      children: children,
      middlewares: middlewares,
      bindings: bindings,
      binding: binding,
      inheritParentPath: inheritParentPath,
      title: title,
    );

class _Middleware extends SintMiddleware {}

class _Binding extends BindingsInterface<void> {
  @override
  void dependencies() {}
}

void main() {
  tearDown(Sint.reset);

  group('Nested registration', () {
    test('registers and removes each descendant exactly once', () {
      SintPage nested = _page('/level10');
      for (var depth = 9; depth >= 1; depth--) {
        nested = _page('/level$depth', children: [nested]);
      }
      final parser = RouteParser(routes: []);
      parser.addRoute(nested);
      expect(parser.routes, hasLength(10));
      expect(parser.routes.map((page) => page.name).toSet(), hasLength(10));
      final leafPath = List.generate(10, (i) => '/level${i + 1}').join();
      expect(parser.matchRoute(leafPath).route, isNotNull);

      parser.removeRoute(nested);
      expect(parser.routes, isEmpty);
      expect(parser.matchRoute(leafPath).route, isNull);
    });

    test('removing a branch preserves children with the same relative key', () {
      final first = _page('/first', children: [_page('/details')]);
      final second = _page('/second', children: [_page('/details')]);
      final parser = RouteParser(routes: [])..addRoutes([first, second]);
      expect(parser.matchRoute('/second/details').route, isNotNull);

      parser.removeRoute(second);
      expect(
          parser.routes.map((page) => page.name), ['/first', '/first/details']);
      expect(parser.matchRoute('/first/details').route, isNotNull);
      expect(parser.matchRoute('/second/details').route, isNull);
    });

    test('absolute child paths are inherited correctly by their descendants',
        () {
      final root = _page('/root', children: [
        _page('/detached',
            inheritParentPath: false, children: [_page('/leaf')]),
      ]);
      final parser = RouteParser(routes: [])..addRoute(root);
      expect(parser.routes.map((page) => page.name),
          ['/root', '/detached', '/detached/leaf']);
      expect(parser.matchRoute('/detached/leaf').route, isNotNull);
      parser.removeRoute(root);
      expect(parser.routes, isEmpty);
    });

    test('inherits ancestor middleware and bindings once per descendant', () {
      final rootMiddleware = _Middleware();
      final childMiddleware = _Middleware();
      final leafMiddleware = _Middleware();
      final rootBinding = _Binding();
      final childBinding = _Binding();
      final leafBinding = _Binding();
      final root = _page('/root',
          middlewares: [rootMiddleware],
          binding: rootBinding,
          children: [
            _page('/child',
                middlewares: [childMiddleware],
                binding: childBinding,
                children: [
                  _page('/leaf',
                      middlewares: [leafMiddleware], binding: leafBinding),
                ]),
          ]);
      final parser = RouteParser(routes: [])..addRoute(root);
      final leaf = parser.routes.last;
      expect(
          leaf.middlewares, [leafMiddleware, childMiddleware, rootMiddleware]);
      expect(leaf.bindings, [rootBinding, childBinding]);
      expect(leaf.binding, same(leafBinding));
    });
  });

  group('Mutable route index', () {
    test('owns a snapshot of the constructor list', () {
      final source = [_page('/original')];
      final parser = RouteParser(routes: source);
      expect(parser.matchRoute('/original').route, isNotNull);
      source[0] = _page('/external');
      expect(parser.matchRoute('/external').route, isNull);
      expect(parser.matchRoute('/original').route, isNotNull);
    });

    test('same-length replacement invalidates both the old and new route', () {
      final parser = RouteParser(routes: [_page('/old')]);
      expect(parser.matchRoute('/old').route, isNotNull);
      parser.routes[0] = _page('/new');
      expect(parser.matchRoute('/new').route, isNotNull);
      expect(parser.matchRoute('/old').route, isNull);
    });

    test('replacing a page with an equal Page key refreshes its builder data',
        () {
      final parser = RouteParser(routes: [_page('/page', title: 'old')]);
      expect(parser.matchRoute('/page').route!.title, 'old');
      parser.routes[0] = _page('/page', title: 'new');
      expect(parser.matchRoute('/page').route!.title, 'new');
    });

    test('same-size reordering preserves first-wins behavior', () {
      final parser = RouteParser(routes: [
        _page('/:id', title: 'first'),
        _page('/:name', title: 'second'),
      ]);
      expect(parser.matchRoute('/42').route!.title, 'first');
      parser.routes.setAll(0, parser.routes.reversed.toList());
      expect(parser.matchRoute('/42').route!.title, 'second');
    });

    test('clear and refill invalidates even when final size is unchanged', () {
      final parser = RouteParser(routes: [_page('/old')]);
      parser.matchRoute('/old');
      parser.routes
        ..clear()
        ..add(_page('/new'));
      expect(parser.matchRoute('/new').route, isNotNull);
      expect(parser.matchRoute('/old').route, isNull);
    });

    test('delegate registeredRoutes exposes the invalidating collection', () {
      final delegate = SintDelegate(pages: [_page('/old')]);
      addTearDown(delegate.dispose);
      expect(delegate.matchRoute('/old').route, isNotNull);
      delegate.registeredRoutes[0] = _page('/new');
      expect(delegate.matchRoute('/new').route, isNotNull);
      expect(delegate.matchRoute('/old').route, isNull);
    });

    test('growing replacements and insertions support non-nullable pages', () {
      final parser = RouteParser(routes: [_page('/old')]);
      parser.matchRoute('/old');
      parser.routes.replaceRange(0, 1, [_page('/a'), _page('/b')]);
      parser.routes.insert(1, _page('/c'));
      parser.routes.insertAll(0, [_page('/d')]);
      expect(parser.routes.map((page) => page.name), ['/d', '/a', '/c', '/b']);
      expect(parser.matchRoute('/old').route, isNull);
      for (final name in ['/a', '/b', '/c', '/d']) {
        expect(parser.matchRoute(name).route, isNotNull);
      }
    });
  });

  group('Separated route parameters', () {
    test('deep links keep query parameters out of pathParams', () {
      final parser = RouteParser(routes: [_page('/user/:id')]);
      final settings = PageSettings(Uri.parse('/user/42?tab=posts&id=query'));
      final decoder = parser.matchRoute(settings.name, arguments: settings);
      expect(decoder.pathParams, {'id': '42'});
      expect(decoder.queryParams, {'tab': 'posts', 'id': 'query'});
      expect(decoder.parameters, {'tab': 'posts', 'id': '42'});
    });

    test('failed matches clear path parameters on reused settings', () {
      final parser = RouteParser(routes: [_page('/'), _page('/user/:id')]);
      final settings = PageSettings(Uri.parse('/user/42'));
      parser.matchRoute('/user/42', arguments: settings);
      expect(settings.pathParams, {'id': '42'});
      expect(parser.matchRoute('/missing?tab=posts', arguments: settings).route,
          isNull);
      expect(settings.pathParams, isEmpty);
      expect(settings.params, {'tab': 'posts'});
    });
  });

  group('Route templates and literal matching', () {
    test('resolves optional parameters before subsequent path segments', () {
      const template = '/user/:id?/edit';
      final parser = RouteParser(routes: [_page(template)]);
      final url = resolveRoutePath(template, pathParams: {'id': '42'});
      expect(url, '/user/42/edit');
      final settings = PageSettings(Uri.parse(url));
      expect(parser.matchRoute(url, arguments: settings).route, isNotNull);
      expect(settings.pathParams, {'id': '42'});
      final missing = resolveRoutePath(template, pathParams: {});
      expect(missing, '/user/edit');
      expect(parser.matchRoute(missing).route, isNotNull);
    });

    test('resolves dotted parameters and their optional separators', () {
      expect(resolveRoutePath('/file.:ext', pathParams: {'ext': 'pdf'}),
          '/file.pdf');
      expect(resolveRoutePath('/file.:ext?', pathParams: {}), '/file');
      final parser = RouteParser(routes: [_page('/file.:ext?')]);
      expect(parser.matchRoute('/file').route, isNotNull);
      expect(parser.matchRoute('/file.pdf').route, isNotNull);
      expect(parser.matchRoute('/fileXpdf').route, isNull);
    });

    test('an omitted optional root parameter resolves to the root path', () {
      final url = resolveRoutePath('/:id?', pathParams: {});
      expect(url, '/');
      expect(RouteParser(routes: [_page('/:id?')]).matchRoute(url).route,
          isNotNull);
    });

    test('distinguishes optional markers, existing queries and fragments', () {
      expect(
          resolveRoutePath('/user/:id?lang=es#details',
              pathParams: {'id': '42'}, queryParams: {'tab': 'posts'}),
          '/user/42?lang=es&tab=posts#details');
      expect(
          resolveRoutePath('/user/:id??lang=es#details',
              pathParams: {'id': '42'}),
          '/user/42?lang=es#details');
      expect(resolveRoutePath('/user/:id?#details', pathParams: {}),
          '/user#details');
    });

    test('keeps unresolved required params and encodes values per segment', () {
      expect(resolveRoutePath('/user/:id', pathParams: {'other': 'x'}),
          '/user/:id');
      final url = resolveRoutePath('/user/:id', pathParams: {'id': 'a/b +ñ'});
      expect(url, '/user/a%2Fb%20%2B%C3%B1');
      final parser = RouteParser(routes: [_page('/user/:id')]);
      final settings = PageSettings(Uri.parse(url));
      parser.matchRoute(url, arguments: settings);
      expect(settings.pathParams, {'id': 'a/b +ñ'});
    });

    test('wildcards capture raw slashes and decode encoded values once', () {
      final parser = RouteParser(routes: [_page('/docs/:path*')]);
      var settings = PageSettings(Uri.parse('/docs/a/b'));
      expect(parser.matchRoute(settings.name, arguments: settings).route,
          isNotNull);
      expect(settings.pathParams, {'path': 'a/b'});
      expect(parser.matchRoute('/docs').route, isNull);
      final encoded =
          resolveRoutePath('/docs/:path*', pathParams: {'path': 'a/%2Fb'});
      expect(encoded, '/docs/a%2F%252Fb');
      settings = PageSettings(Uri.parse(encoded));
      parser.matchRoute(encoded, arguments: settings);
      expect(settings.pathParams, {'path': 'a/%2Fb'});
    });

    test('pattern captures do not shift subsequent parameter positions', () {
      const template = r'/code/:part((ab|cd)\d+)/:id';
      final parser = RouteParser(routes: [_page(template)]);
      final url =
          resolveRoutePath(template, pathParams: {'part': 'ab12', 'id': '42'});
      expect(url, '/code/ab12/42');
      final settings = PageSettings(Uri.parse(url));
      expect(parser.matchRoute(url, arguments: settings).route, isNotNull);
      expect(settings.pathParams, {'part': 'ab12', 'id': '42'});
      expect(parser.matchRoute('/code/xx12/42').route, isNull);
    });

    test('literal punctuation is escaped while custom patterns remain active',
        () {
      final parser = RouteParser(routes: [
        _page('/assets/file.json'),
        _page('/assets/a+b(1)'),
        _page(r'/assets/:id(\d+)'),
      ]);
      expect(parser.matchRoute('/assets/file.json').route, isNotNull);
      expect(parser.matchRoute('/assets/fileXjson').route, isNull);
      expect(parser.matchRoute('/assets/a+b(1)').route, isNotNull);
      expect(parser.matchRoute('/assets/aaab1').route, isNull);
      expect(parser.matchRoute('/assets/123').route, isNotNull);
      expect(parser.matchRoute('/assets/abc').route, isNull);
    });

    test('first-segment precedence remains literal, pattern, param, wildcard',
        () {
      final parser = RouteParser(routes: [
        _page('/:path*', title: 'wildcard'),
        _page('/:name', title: 'param'),
        _page(r'/:id(\d+)', title: 'pattern'),
        _page('/new', title: 'literal'),
      ]);
      expect(parser.matchRoute('/new').route!.title, 'literal');
      expect(parser.matchRoute('/42').route!.title, 'pattern');
      expect(parser.matchRoute('/someone').route!.title, 'param');
      expect(parser.matchRoute('/several/segments').route!.title, 'wildcard');
    });
  });
}
