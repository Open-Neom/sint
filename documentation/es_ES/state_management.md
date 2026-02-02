# Gestion del Estado

SINT proporciona dos sistemas principales de gestion del estado: **Reactive State Manager** y **Simple State Manager**, ademas de herramientas avanzadas como **StateMixin** y **Workers**.

## Tabla de Contenidos

- [Reactive State Manager](#reactive-state-manager)
  - [Variables Observables (.obs)](#variables-observables-obs)
  - [Obx Widget](#obx-widget)
  - [GetX Widget](#getx-widget)
  - [Rx Types](#rx-types)
- [Simple State Manager](#simple-state-manager)
  - [SintBuilder](#SintBuilder)
  - [Uso Basico](#uso-basico)
- [StateMixin](#statemixin)
- [Workers](#workers)
- [Test Roadmap](#test-roadmap)

---

## Reactive State Manager

El **Reactive State Manager** utiliza programacion reactiva para actualizar automaticamente la UI cuando cambia el estado. Se basa en **observables** (.obs) y **observers** (Obx, GetX).

### Variables Observables (.obs)

Cualquier variable puede convertirse en observable agregando `.obs`:

```dart
import 'package:sint/sint.dart';

class CounterController extends SintController {
  var count = 0.obs;

  void increment() {
    count++;
  }
}
```

Cuando `count` cambia, todos los widgets que lo observan se reconstruyen automaticamente.

### Obx Widget

`Obx` es un widget que se reconstruye cuando cambia cualquier observable dentro de su closure:

```dart
class CounterPage extends StatelessWidget {
  final CounterController controller = Sint.put(CounterController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contador Reactivo')),
      body: Center(
        child: Obx(() => Text(
          'Clicks: ${controller.count}',
          style: TextStyle(fontSize: 30),
        )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

**Nota importante:** `Obx` solo detecta observables que se usan **dentro** de su closure. Si no se usa ninguno, no se reconstruira.

### GetBuilder Widget

`GetBuilder` es similar a `Obx`, pero permite acceder al controller directamente:

```dart
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GetBuilder<CounterController>(
          init: CounterController(),
          builder: (controller) => Text(
            'Clicks: ${controller.count}',
            style: TextStyle(fontSize: 30),
          ),
        ),
      ),
    );
  }
}
```

**Diferencia clave:**
- `Obx`: Requiere que el controller ya este inyectado
- `GetBuilder`: Puede inicializar el controller automaticamente

### Rx Types

SINT proporciona tipos especializados para diferentes estructuras de datos:

```dart
class DataController extends SintController {
  // Primitivos
  var name = ''.obs;
  var age = 0.obs;
  var isActive = false.obs;
  var price = 0.0.obs;

  // Colecciones
  var list = <String>[].obs;
  var set = <String>{}.obs;
  var map = <String, int>{}.obs;

  // Tipos Rx especificos (alternativa)
  RxString username = ''.obs;
  RxInt counter = 0.obs;
  RxBool isLoading = false.obs;
  RxDouble rating = 0.0.obs;
  RxList<Product> products = <Product>[].obs;
  RxMap<String, dynamic> settings = <String, dynamic>{}.obs;
}
```

**Trabajando con colecciones observables:**

```dart
// Agregar elementos
controller.list.add('item');
controller.map['key'] = value;

// Metodos reactivos
controller.list.assignAll(['a', 'b', 'c']);
controller.map.addAll({'x': 1, 'y': 2});

// Acceder al valor
print(controller.name.value);
controller.age.value = 25;
```

**Objetos personalizados:**

```dart
class User {
  String name;
  int age;

  User({required this.name, required this.age});
}

class UserController extends SintController {
  var user = User(name: 'Juan', age: 30).obs;

  void updateName(String newName) {
    // Opcion 1: Actualizar y notificar
    user.update((val) {
      val!.name = newName;
    });

    // Opcion 2: Asignar nuevo objeto
    user.value = User(name: newName, age: user.value.age);
  }
}
```

---

## Simple State Manager

El **Simple State Manager** usa `SintBuilder` para actualizaciones manuales y es mas eficiente cuando no necesitas reactividad automatica.

### SintBuilder

`SintBuilder` se reconstruye solo cuando llamas a `update()` en el controller:

```dart
class CounterController extends SintController {
  int count = 0;

  void increment() {
    count++;
    update(); // Notifica a SintBuilder que se reconstruya
  }
}

class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SintBuilder<CounterController>(
          init: CounterController(),
          builder: (controller) => Text(
            'Clicks: ${controller.count}',
            style: TextStyle(fontSize: 30),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Sint.find<CounterController>().increment(),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### Uso Basico

**Ventajas de SintBuilder:**
- Consume menos memoria
- Mas rapido para actualizaciones frecuentes
- Control preciso sobre reconstrucciones

**IDs para actualizaciones selectivas:**

```dart
class ProductController extends SintController {
  String productName = 'Widget';
  double productPrice = 9.99;

  void updateName(String newName) {
    productName = newName;
    update(['name']); // Solo reconstruye widgets con id 'name'
  }

  void updatePrice(double newPrice) {
    productPrice = newPrice;
    update(['price']); // Solo reconstruye widgets con id 'price'
  }
}

// En la UI
SintBuilder<ProductController>(
  id: 'name',
  builder: (controller) => Text(controller.productName),
)

SintBuilder<ProductController>(
  id: 'price',
  builder: (controller) => Text('\$${controller.productPrice}'),
)
```

---

## StateMixin

`StateMixin` facilita el manejo de estados de carga, error y exito:

```dart
class ApiController extends SintController with StateMixin<List<User>> {
  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    change(null, status: RxStatus.loading());

    try {
      final users = await userRepository.getUsers();
      if (users.isEmpty) {
        change(null, status: RxStatus.empty());
      } else {
        change(users, status: RxStatus.success());
      }
    } catch (e) {
      change(null, status: RxStatus.error(e.toString()));
    }
  }
}

// En la UI
class UsersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SintBuilder<ApiController>(
        init: ApiController(),
        builder: (controller) {
          return controller.obx(
            (users) => ListView.builder(
              itemCount: users!.length,
              itemBuilder: (_, index) => UserTile(users[index]),
            ),
            onLoading: Center(child: CircularProgressIndicator()),
            onEmpty: Center(child: Text('No hay usuarios')),
            onError: (error) => Center(child: Text('Error: $error')),
          );
        },
      ),
    );
  }
}
```

**Estados disponibles:**
- `RxStatus.loading()` - Cargando datos
- `RxStatus.success()` - Datos cargados exitosamente
- `RxStatus.empty()` - Sin datos
- `RxStatus.error(message)` - Error con mensaje

---

## Workers

Los **Workers** son callbacks reactivos que escuchan cambios en observables:

```dart
class FormController extends SintController {
  var email = ''.obs;
  var password = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // ever: Se ejecuta cada vez que cambia
    ever(email, (value) {
      print('Email cambio a: $value');
    });

    // once: Se ejecuta solo la primera vez que cambia
    once(password, (value) {
      print('Password establecida por primera vez');
    });

    // debounce: Espera que el usuario deje de escribir
    debounce(email, (value) {
      validateEmail(value);
    }, time: Duration(milliseconds: 800));

    // interval: Ignora cambios durante el intervalo
    interval(password, (value) {
      checkPasswordStrength(value);
    }, time: Duration(milliseconds: 500));
  }

  void validateEmail(String email) {
    // Validacion de email
  }

  void checkPasswordStrength(String password) {
    // Verificar fortaleza de password
  }
}
```

**Tipos de Workers:**

| Worker | Descripcion |
|--------|-------------|
| `ever` | Se ejecuta cada vez que cambia el observable |
| `once` | Se ejecuta solo la primera vez que cambia |
| `debounce` | Espera a que el usuario deje de hacer cambios |
| `interval` | Ignora cambios dentro del intervalo especificado |

**Cancelar Workers:**

```dart
class SearchController extends SintController {
  var searchTerm = ''.obs;
  late Worker searchWorker;

  @override
  void onInit() {
    super.onInit();
    searchWorker = debounce(
      searchTerm,
      performSearch,
      time: Duration(milliseconds: 500),
    );
  }

  void performSearch(String term) {
    // Buscar...
  }

  @override
  void onClose() {
    searchWorker.dispose(); // Cancelar worker
    super.onClose();
  }
}
```

---

## Test Roadmap

### Pruebas Planificadas - Pilar de Estado

1. **Profiling Reactivo**
   - Benchmarks de rendimiento para Obx vs SintBuilder
   - Medicion de reconstrucciones innecesarias
   - Optimizacion de memoria en listas grandes con .obs
   - Comparativa de performance con Provider y Riverpod

2. **Contenedores Rx con Alcance**
   - Tests de aislamiento de estado entre modulos
   - Validacion de garbage collection de observables
   - Pruebas de state scoping en navegacion profunda
   - Verificacion de memory leaks en Workers

3. **Interoperabilidad con Stream**
   - Integracion bidireccional Stream <-> Rx
   - Tests de conversion .obs.stream y stream.value
   - Validacion de backpressure handling
   - Pruebas de sincronizacion con StreamController

4. **StateMixin Avanzado**
   - Estados personalizados mas alla de loading/error/success
   - Composicion de multiples StateMixin
   - Tests de transiciones de estado invalidas
   - Validacion de rollback automatico en errores

5. **Workers Edge Cases**
   - Comportamiento con cambios rapidos consecutivos
   - Memory profiling de workers no dispuestos
   - Tests de race conditions en debounce/interval
   - Validacion de orden de ejecucion en multiple workers
