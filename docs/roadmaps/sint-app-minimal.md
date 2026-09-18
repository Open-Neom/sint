# SINT 1.7.0: SintApp adaptativo con cambios acotados

Revisión de diseño del 12 de septiembre de 2026. Esta propuesta sustituye la
extracción de un entrypoint neutral y los paquetes adaptadores como requisitos
iniciales. Todavía no implementa `SintApp` ni modifica dependencias o versiones.

## Contrato propuesto

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
// Fragmento de API propuesta; no disponible todavía.
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

Para conservar un camino compatible, `SintApp(theme: antiguo)` puede delegar
en el host Material legacy, también en iOS, durante la transición. No se pasa
ese objeto al host moderno. Combinar `theme` con argumentos modernos produce
un error de configuración claro también en release. La selección automática
por plataforma se aplica al camino moderno; esta excepción legacy debe quedar
documentada y probada.

## Ajustes internos necesarios

1. Añadir `SintApp` y la selección de host alrededor del `SintRoot` existente.
   No duplicar el runtime ni extraer paquetes como primer paso.
2. Añadir almacenamiento y setters tipados para temas modernos. Conservar las
   firmas legacy de `ConfigData` y `SintRoot`; resolver también modo, tema
   oscuro, alto contraste y claves específicas de Material.
3. Añadir consultas tipadas para Material y Cupertino. `Sint.theme` y
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
mínimo actual Flutter 3.32/Dart 3.8 en ella, aunque se utilice el camino legacy.
Un `if` de plataforma no modifica la resolución de dependencias.

Este diseño evita la separación inicial en paquetes, pero requiere adoptar y
comunicar ese mínimo de SDK al preparar el release. Si conservar Flutter 3.32
en la misma versión vuelve a ser un requisito, habrá que distribuir la fachada
moderna aparte. Este documento no modifica el manifiesto ni da por resuelta
esa condición de compatibilidad.

## Primera entrega verificable

Probar selección iOS/resto, override, temas predeterminados y ambos temas;
compatibilidad de `theme` legacy sin casts; identidad y lifecycle del único
root; cambios de tema; localizaciones y un diálogo/sheet en cada host.
Mantener una app Material en iOS como control. La primera prueba usa el patrón
`MyApp -> SentinelApp -> SintApp` del ejemplo del usuario. No declarar resuelto
el issue #12 hasta validar también sus APIs públicas fuera del constructor.

Fuentes: [plataforma Flutter](https://api.flutter.dev/flutter/foundation/defaultTargetPlatform.html),
[límites del bridge](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui#bridge-capabilities-and-limitations),
[mínimos de Material standalone](https://raw.githubusercontent.com/flutter/packages/main/packages/material_ui/pubspec.yaml).
