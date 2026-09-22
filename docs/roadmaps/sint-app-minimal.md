# SINT 1.7.0: SintApp adaptativo con cambios acotados

Diseño del 12 de septiembre de 2026, actualizado al estado local del 21 de
septiembre: **SINT 1.7.0-dev.1 ya implementa `SintApp`** y declara Flutter >=3.44 /
Dart >=3.12 con dependencias directas de `material_ui` y `cupertino_ui`.
La extracción de un entrypoint neutral y paquetes adaptadores deja de ser
requisito inicial. Esta preview no equivale a una publicación estable ni a
confirmar todos los builds de los pilotos. La [guía de migración](../../MIGRATION_DESIGN_SYSTEMS.md)
describe las APIs actuales.

## Contrato implementado en la preview

`SintApp` reutiliza un único `SintRoot`, los controllers, bindings, rutas y
traducciones existentes. Selecciona el host visual en su construcción:

- iOS: `cupertino_ui.CupertinoApp.router` y `cupertinoTheme`.
- Android y demás plataformas: `material_ui.MaterialApp.router` y `materialTheme`.
- Usar `defaultTargetPlatform`, compatible con web, con una opción explícita
  para fijar Material o Cupertino si una aplicación lo requiere. En web, el
  valor describe la plataforma del navegador; un navegador en iOS selecciona
  Cupertino en modo automático. La política puede fijarse a Material por app.
- Si falta el tema de la familia seleccionada, usar su tema predeterminado;
  nunca convertir un tema Material a Cupertino ni viceversa.
- Configurar ambos temas permite elegir entre ellos; no crea dos roots.

Las clases `SintMaterialApp` y `SintCupertinoApp` existentes conservan su
comportamiento. Una app Material en iOS no cambia por actualizar SINT.
Adoptar el nuevo modo automático sí es una decisión visual de la aplicación.

Los argumentos modernos son fuertemente tipados:

```dart
// Tipos de la API de la preview; no es un programa completo.
final material.ThemeData? materialTheme;
final cupertino.CupertinoThemeData? cupertinoTheme;

@Deprecated(
  'SDK theme: incompatible with standalone Material/Cupertino types. '
  'Use materialTheme (material_ui.ThemeData) or '
  'cupertinoTheme (cupertino_ui.CupertinoThemeData). '
  'This parameter will be removed in a future announced major release.',
)
final legacy.ThemeData? theme;
```

`material`, `cupertino` y `legacy` representan imports con prefijo de las
bibliotecas standalone y de `flutter/material.dart`, respectivamente. El aviso
se introduce junto con alternativas funcionales. No describe el uso legacy
coherente como un error; explica por qué no acepta tipos standalone.

Para conservar un camino compatible, `SintApp(theme: antiguo)` delega
en el host Material legacy, también en iOS, durante la transición. No se pasa
ese objeto al host moderno. Combinar `theme` con argumentos modernos produce
un error de configuración claro también en release. La selección automática
por plataforma se aplica al camino moderno; esta excepción legacy debe quedar
documentada y probada.

## Implementación y límites que deben validarse

1. `SintApp` selecciona el host alrededor del `SintRoot` existente.
   No duplicar el runtime ni extraer paquetes como primer paso.
2. Se añadieron almacenamiento y setters tipados para temas modernos. Conservar las
   firmas legacy de `ConfigData` y `SintRoot`; resolver también modo, tema
   oscuro, alto contraste y claves específicas de Material.
3. Se añadieron consultas tipadas para Material y Cupertino. `Sint.theme` y
   `context.theme` actuales siguen retornando Material legacy; no pueden
   cambiar de tipo según el dispositivo sin romper su contrato estático.
4. Dirigir localizaciones, transiciones, diálogos, sheets y snackbars al host
   adecuado mediante ramas puntuales. No todas esas operaciones pasan por el
   constructor de la aplicación: hoy consultan Material legacy directamente.
5. Mantener `SintBuilder` como constructor reactivo, sin decisiones visuales.
   Los widgets descendientes consultan `Theme.of` o `CupertinoTheme.of` de su
   biblioteca. Su import de Material puede reducirse a Widgets si procede.

Cambiar el host no transforma un `Scaffold` en `CupertinoPageScaffold`. Las
páginas Material dentro de un host Cupertino requieren las dependencias de
tema/localizaciones correspondientes, o seleccionar Material para esa app.
Los bridges ayudan a subárboles legacy; no convierten parámetros públicos.

## Condición de distribución

Incorporar los dos paquetes standalone directamente a `sint` exige actualmente
Flutter >=3.44 y Dart >=3.12 para esa versión. Se deja de poder prometer el
mínimo anterior Flutter 3.32/Dart 3.8 en ella, aunque se utilice el camino legacy.
Un `if` de plataforma no modifica la resolución de dependencias.

El manifiesto de la preview ya adopta ese mínimo de SDK; las aplicaciones que
no puedan actualizar deben conservar una versión compatible de SINT 1.6.x.
Si conservar Flutter 3.32 en la misma versión vuelve a ser un requisito, habrá
que distribuir la fachada moderna aparte. La matriz CI incluye 3.44.4 y la
última estable 3.x; ejecutar la versión exacta del mínimo declarado, 3.44.0,
sigue siendo una verificación de release.

## Verificaciones para la entrega estable

Probar selección iOS/resto, override, temas predeterminados y ambos temas;
compatibilidad de `theme` legacy sin casts; identidad y lifecycle del único
root; cambios de tema; localizaciones y un diálogo/sheet en cada host.
Mantener una app Material en iOS como control. La primera prueba usa el patrón
`MyApp -> SentinelApp -> SintApp` del ejemplo del usuario. No declarar resuelto
el issue #12 hasta validar también sus APIs públicas fuera del constructor.
Los pilotos son **Cyberneom y Giglab** en Android, macOS y web según los targets
de cada proyecto. Giglab sustituye a Gigmeout para la comprobación nativa macOS.
Distinguir análisis, widget tests, builds y ejecución de la app en el informe;
este documento no declara resultados satisfactorios por adelantado.

Fuentes: [plataforma Flutter](https://api.flutter.dev/flutter/foundation/defaultTargetPlatform.html),
[límites del bridge](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui#bridge-capabilities-and-limitations),
[mínimos de Material standalone](https://raw.githubusercontent.com/flutter/packages/main/packages/material_ui/pubspec.yaml).
