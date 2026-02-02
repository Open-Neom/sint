# Gerenciamento de Injeção

O SINT oferece um sistema robusto de injeção de dependências que permite gerenciar o ciclo de vida de controllers, serviços e outras classes de forma eficiente e organizada.

## Índice

- [Conceitos Básicos](#conceitos-básicos)
- [Métodos de Injeção](#métodos-de-injeção)
  - [Sint.put](#sintput)
  - [Sint.lazyPut](#sintlazyput)
  - [Sint.putAsync](#sintputasync)
  - [Sint.create](#sintcreate)
- [Recuperando Instâncias](#recuperando-instâncias)
  - [Sint.find](#sintfind)
  - [Busca por Tag](#busca-por-tag)
- [Bindings](#bindings)
  - [O que são Bindings](#o-que-são-bindings)
  - [Criando Bindings](#criando-bindings)
  - [Usando Bindings](#usando-bindings)
  - [BindingsBuilder](#bindingsbuilder)
- [SmartManagement](#smartmanagement)
  - [Modos de Gerenciamento](#modos-de-gerenciamento)
  - [Configuração](#configuração)
- [Gerenciamento Manual](#gerenciamento-manual)
  - [Sint.delete](#sintdelete)
  - [Sint.reset](#sintreset)
- [Roteiro de Testes](#roteiro-de-testes)

## Conceitos Básicos

O sistema de injeção de dependências do SINT permite que você:

- **Desacoplar código:** Separe a criação de instâncias da sua lógica de negócio
- **Reutilizar instâncias:** Compartilhe a mesma instância entre múltiplas telas
- **Gerenciar ciclo de vida:** Controle quando instâncias são criadas e destruídas
- **Facilitar testes:** Injete mocks e stubs facilmente

## Métodos de Injeção

### Sint.put

Instancia uma classe imediatamente e a mantém em memória:

```dart
class ApiService {
  void fetchData() {
    print('Buscando dados...');
  }
}

class Controller extends SintController {
  final ApiService api = Sint.find();

  void loadData() {
    api.fetchData();
  }
}

// Em algum lugar do código, antes de usar
void main() {
  // Instancia imediatamente
  Sint.put(ApiService());

  runApp(MyApp());
}
```

**Com permanente:**

```dart
// A instância nunca será removida automaticamente
Sint.put(ConfigService(), permanent: true);
```

**Com tag para múltiplas instâncias:**

```dart
Sint.put(DatabaseService(), tag: 'local');
Sint.put(DatabaseService(), tag: 'remote');

// Recuperar específica
final localDb = Sint.find<DatabaseService>(tag: 'local');
final remoteDb = Sint.find<DatabaseService>(tag: 'remote');
```

### Sint.lazyPut

Registra uma instância que só será criada quando for usada pela primeira vez:

```dart
// Registra, mas não cria ainda
Sint.lazyPut(() => ExpensiveController());

// ... em algum outro lugar do código

// Agora sim cria a instância
final controller = Sint.find<ExpensiveController>();
```

**Com fenix (recriação automática):**

```dart
Sint.lazyPut(
  () => SessionController(),
  fenix: true, // Recria a instância se for deletada e chamada novamente
);
```

**Exemplo prático:**

```dart
class Injector {
  static void init() {
    // Controllers que só serão criados quando necessário
    Sint.lazyPut(() => HomeController());
    Sint.lazyPut(() => ProfileController());
    Sint.lazyPut(() => SettingsController());

    // Serviços que precisam estar sempre disponíveis
    Sint.put(AuthService(), permanent: true);
    Sint.put(StorageService(), permanent: true);
  }
}

void main() {
  Injector.init();
  runApp(MyApp());
}
```

### Sint.putAsync

Para instâncias que precisam de inicialização assíncrona:

```dart
class DatabaseService {
  Database? _db;

  Future<DatabaseService> init() async {
    _db = await openDatabase('app.db');
    return this;
  }

  Database get db => _db!;
}

// Uso
void main() async {
  await Sint.putAsync(() async {
    final dbService = DatabaseService();
    await dbService.init();
    return dbService;
  });

  runApp(MyApp());
}
```

**Com permanent:**

```dart
await Sint.putAsync(
  () async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  },
  permanent: true,
);
```

**Exemplo completo de inicialização:**

```dart
class AppInitializer {
  static Future<void> initialize() async {
    // Serviços assíncronos
    await Sint.putAsync(() async {
      final db = DatabaseService();
      await db.init();
      return db;
    });

    await Sint.putAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      return PreferencesService(prefs);
    });

    // Serviços síncronos
    Sint.put(ApiService());
    Sint.put(AuthService());

    // Controllers lazy
    Sint.lazyPut(() => HomeController());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initialize();
  runApp(MyApp());
}
```

### Sint.create

Cria uma nova instância toda vez que for chamado (factory pattern):

```dart
// Registra o factory
Sint.create(() => TransactionController());

// Cada find retorna uma NOVA instância
final transaction1 = Sint.find<TransactionController>(); // Instância 1
final transaction2 = Sint.find<TransactionController>(); // Instância 2
// transaction1 != transaction2
```

**Exemplo com parâmetros:**

```dart
class ReportController extends SintController {
  final String reportType;

  ReportController(this.reportType);

  void generate() {
    print('Gerando relatório: $reportType');
  }
}

// Na UI
class ReportPage extends StatelessWidget {
  final String type;

  ReportPage({required this.type});

  @override
  Widget build(BuildContext context) {
    // Nova instância para cada relatório
    final controller = Sint.put(ReportController(type));

    return Scaffold(
      appBar: AppBar(title: Text('Relatório $type')),
      body: SintBuilder<ReportController>(
        builder: (controller) {
          return Center(
            child: ElevatedButton(
              onPressed: controller.generate,
              child: Text('Gerar'),
            ),
          );
        },
      ),
    );
  }
}
```

## Recuperando Instâncias

### Sint.find

Recupera uma instância previamente injetada:

```dart
// Recuperar instância
final controller = Sint.find<HomeController>();

// Uso direto
Sint.find<ApiService>().fetchData();
```

**Com tratamento de erro:**

```dart
try {
  final controller = Sint.find<HomeController>();
  controller.loadData();
} catch (e) {
  print('Controller não encontrado: $e');
  // Criar instância se não existir
  Sint.put(HomeController());
}
```

### Busca por Tag

Quando você tem múltiplas instâncias do mesmo tipo:

```dart
// Injetar com tags
Sint.put(PaymentService(type: 'credit'), tag: 'credit');
Sint.put(PaymentService(type: 'debit'), tag: 'debit');
Sint.put(PaymentService(type: 'pix'), tag: 'pix');

// Recuperar específica
final creditPayment = Sint.find<PaymentService>(tag: 'credit');
final pixPayment = Sint.find<PaymentService>(tag: 'pix');
```

## Bindings

### O que são Bindings

Bindings são classes que agrupam injeções de dependências relacionadas. Eles facilitam a organização e permitem que você prepare todas as dependências de uma tela antes de navegá-la.

### Criando Bindings

```dart
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Será criado quando a tela for acessada
    Sint.lazyPut(() => HomeController());

    // Serviços necessários
    Sint.lazyPut(() => ProductService());
    Sint.lazyPut(() => CartService());
  }
}
```

**Binding com put:**

```dart
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // Criado imediatamente
    Sint.put(LoginController());
    Sint.put(AuthService());
  }
}
```

**Binding com putAsync:**

```dart
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Sint.putAsync(() async {
      final configService = ConfigService();
      await configService.loadConfig();
      return configService;
    });
  }
}
```

### Usando Bindings

**Com rotas nomeadas:**

```dart
void main() {
  runApp(
    SintMaterialApp(
      initialRoute: '/home',
      getPages: [
        GetPage(
          name: '/home',
          page: () => HomePage(),
          binding: HomeBinding(), // Binding vinculado à rota
        ),
        GetPage(
          name: '/profile',
          page: () => ProfilePage(),
          binding: ProfileBinding(),
        ),
        GetPage(
          name: '/settings',
          page: () => SettingsPage(),
          binding: SettingsBinding(),
        ),
      ],
    ),
  );
}
```

**Múltiplos Bindings:**

```dart
GetPage(
  name: '/checkout',
  page: () => CheckoutPage(),
  bindings: [
    CheckoutBinding(),
    PaymentBinding(),
    ShippingBinding(),
  ],
),
```

### BindingsBuilder

Para casos onde você não quer criar uma classe separada:

```dart
GetPage(
  name: '/simple',
  page: () => SimplePage(),
  binding: BindingsBuilder(() {
    Sint.lazyPut(() => SimpleController());
  }),
),
```

**Exemplo com múltiplas dependências:**

```dart
GetPage(
  name: '/complex',
  page: () => ComplexPage(),
  binding: BindingsBuilder(() {
    Sint.lazyPut(() => ComplexController());
    Sint.lazyPut(() => DataService());
    Sint.put(CacheService());
  }),
),
```

## SmartManagement

O SmartManagement controla como e quando as dependências são descartadas.

### Modos de Gerenciamento

#### full (padrão)

Descarta controllers que não estão sendo usados e não foram marcados como permanent. Considera tanto `SintBuilder` quanto `.obs`:

```dart
// Controllers são mantidos enquanto há listeners
// São removidos quando nenhuma tela os está usando
```

#### onlyBuilder

Descarta apenas quando não há `SintBuilder` usando. Ignora `.obs`:

```dart
// Controller mantido mesmo sem SintBuilder se houver Obx
// Útil quando você usa principalmente estado reativo
```

#### keepFactory

Mantém a capacidade de recriar instâncias usando factory:

```dart
// Permite que controllers sejam descartados
// mas podem ser recriados quando necessário
```

### Configuração

**Global:**

```dart
void main() {
  runApp(
    SintMaterialApp(
      smartManagement: SmartManagement.full,
      home: HomePage(),
    ),
  );
}
```

**Por controller:**

```dart
class MyController extends SintController {
  // Força o controller a nunca ser descartado
  @override
  bool get permanent => true;
}
```

## Gerenciamento Manual

### Sint.delete

Remove uma instância manualmente:

```dart
// Remover controller
Sint.delete<HomeController>();

// Remover com tag
Sint.delete<PaymentService>(tag: 'credit');

// Força remoção mesmo se permanent
Sint.delete<ConfigService>(force: true);
```

**Exemplo prático:**

```dart
class SessionController extends SintController {
  void logout() {
    // Limpar dados
    clearUserData();

    // Remover controller
    Sint.delete<UserController>();
    Sint.delete<ProfileController>();
    Sint.delete<SettingsController>();

    // Navegar para login
    Sint.offAllNamed('/login');
  }
}
```

### Sint.reset

Remove todas as instâncias:

```dart
// Remove tudo exceto permanent
Sint.reset();

// Remove tudo, incluindo permanent
Sint.reset(clearRouteBindings: true);
```

**Exemplo de reset na tela de login:**

```dart
class LoginController extends SintController {
  void onLoginSuccess() {
    // Limpar tudo do estado anterior
    Sint.reset();

    // Recriar serviços necessários
    Sint.put(AuthService());
    Sint.put(UserService());

    // Navegar para home
    Sint.offAllNamed('/home');
  }
}
```

## Padrões de Uso

### Inicialização por Camadas

```dart
class AppDependencies {
  static Future<void> init() async {
    // Camada 1: Serviços de infraestrutura
    await _initInfrastructure();

    // Camada 2: Serviços de dados
    await _initDataServices();

    // Camada 3: Serviços de negócio
    _initBusinessServices();

    // Camada 4: Controllers
    _initControllers();
  }

  static Future<void> _initInfrastructure() async {
    await Sint.putAsync(() async {
      final db = DatabaseService();
      await db.init();
      return db;
    }, permanent: true);

    await Sint.putAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      return StorageService(prefs);
    }, permanent: true);
  }

  static Future<void> _initDataServices() async {
    Sint.put(ApiService(), permanent: true);
    Sint.put(CacheService(), permanent: true);
  }

  static void _initBusinessServices() {
    Sint.put(AuthService(), permanent: true);
    Sint.lazyPut(() => UserService());
    Sint.lazyPut(() => ProductService());
  }

  static void _initControllers() {
    Sint.lazyPut(() => HomeController());
    Sint.lazyPut(() => ProfileController());
    Sint.lazyPut(() => SettingsController());
  }
}
```

### Injeção Condicional

```dart
class ConfigService {
  final bool isDevelopment;

  ConfigService(this.isDevelopment);
}

void main() {
  const isDev = bool.fromEnvironment('DEV');

  if (isDev) {
    Sint.put(ApiService(baseUrl: 'https://dev.api.com'));
    Sint.put(LogService(level: LogLevel.debug));
  } else {
    Sint.put(ApiService(baseUrl: 'https://api.com'));
    Sint.put(LogService(level: LogLevel.error));
  }

  runApp(MyApp());
}
```

## Roteiro de Testes

### Teste 1: Sint.put e Sint.find
**Objetivo:** Verificar injeção e recuperação básica de dependências.

**Passos:**
1. Criar uma classe `CounterService` com um método `increment()`
2. Usar `Sint.put(CounterService())` para injetar
3. Em outro arquivo/widget, usar `Sint.find<CounterService>()`
4. Verificar que a mesma instância é retornada
5. Chamar método `increment()` e verificar que o estado persiste

**Resultado esperado:** A mesma instância deve ser acessível em qualquer lugar do app após a injeção.

---

### Teste 2: Sint.lazyPut
**Objetivo:** Validar que a instância só é criada quando necessária.

**Passos:**
1. Criar um controller com um `print` no construtor
2. Usar `Sint.lazyPut(() => LazyController())`
3. Verificar que o `print` do construtor NÃO foi executado
4. Chamar `Sint.find<LazyController>()`
5. Verificar que AGORA o `print` foi executado
6. Chamar `Sint.find<LazyController>()` novamente
7. Verificar que o `print` não executa segunda vez (mesma instância)

**Resultado esperado:** O controller só deve ser instanciado na primeira chamada do `find()`, e reutilizado nas chamadas subsequentes.

---

### Teste 3: Sint.putAsync
**Objetivo:** Testar inicialização assíncrona de dependências.

**Passos:**
1. Criar um `DatabaseService` com método async `init()` que demora 2 segundos
2. Usar `await Sint.putAsync(() async { ... })`
3. Medir tempo de execução
4. Verificar que o app só inicia após inicialização completa
5. Usar `Sint.find<DatabaseService>()` e verificar que database está pronta

**Resultado esperado:** O app deve aguardar a inicialização assíncrona antes de continuar, garantindo que o serviço esteja pronto para uso.

---

### Teste 4: Sint.create (Factory Pattern)
**Objetivo:** Verificar que cada `find()` retorna uma nova instância.

**Passos:**
1. Criar um controller `ReportController` com ID único gerado no construtor
2. Usar `Sint.create(() => ReportController())`
3. Chamar `final report1 = Sint.find<ReportController>()`
4. Chamar `final report2 = Sint.find<ReportController>()`
5. Comparar `report1.id` com `report2.id`
6. Verificar que os IDs são diferentes

**Resultado esperado:** Cada chamada do `find()` deve criar uma nova instância com ID diferente.

---

### Teste 5: Tags para Múltiplas Instâncias
**Objetivo:** Gerenciar múltiplas instâncias do mesmo tipo.

**Passos:**
1. Criar classe `DatabaseService`
2. Injetar `Sint.put(DatabaseService(), tag: 'local')`
3. Injetar `Sint.put(DatabaseService(), tag: 'remote')`
4. Recuperar `final local = Sint.find<DatabaseService>(tag: 'local')`
5. Recuperar `final remote = Sint.find<DatabaseService>(tag: 'remote')`
6. Modificar estado em `local` e verificar que `remote` não é afetado

**Resultado esperado:** Cada tag deve manter sua própria instância independente.

---

### Teste 6: Bindings com Rotas
**Objetivo:** Verificar que bindings injetam dependências ao navegar.

**Passos:**
1. Criar `HomeBinding` que injeta `HomeController` com `lazyPut`
2. Configurar rota `/home` com binding
3. Antes de navegar, verificar que controller não existe
4. Navegar para `/home` usando `Sint.toNamed('/home')`
5. Após navegação, verificar que controller foi criado
6. Navegar para outra rota e depois voltar
7. Verificar ciclo de vida do controller

**Resultado esperado:** O controller deve ser criado automaticamente ao acessar a rota e descartado ao sair (dependendo do SmartManagement).

---

### Teste 7: Múltiplos Bindings
**Objetivo:** Testar injeção de múltiplas dependências de diferentes bindings.

**Passos:**
1. Criar `CheckoutBinding` que injeta `CheckoutController`
2. Criar `PaymentBinding` que injeta `PaymentService`
3. Criar `ShippingBinding` que injeta `ShippingService`
4. Configurar rota com array de bindings
5. Navegar para a rota
6. Verificar que todos os controllers e services foram injetados
7. Usar `Sint.find()` para recuperar cada um

**Resultado esperado:** Todos os bindings devem ser executados e todas as dependências devem estar disponíveis.

---

### Teste 8: SmartManagement.full
**Objetivo:** Validar remoção automática de controllers não utilizados.

**Passos:**
1. Configurar app com `SmartManagement.full`
2. Injetar controller com `lazyPut` em uma rota
3. Navegar para a rota (controller é criado)
4. Verificar que controller existe
5. Navegar para outra rota usando `Sint.off()`
6. Verificar que controller foi removido automaticamente
7. Tentar usar `Sint.find()` e verificar que lança exceção

**Resultado esperado:** O controller deve ser automaticamente removido quando não houver mais listeners.

---

### Teste 9: Permanent Controllers
**Objetivo:** Garantir que controllers permanent nunca são removidos.

**Passos:**
1. Criar controller com `@override bool get permanent => true`
2. Ou injetar com `Sint.put(Controller(), permanent: true)`
3. Navegar entre múltiplas rotas
4. Usar `Sint.reset()` (sem clearRouteBindings)
5. Verificar que controller ainda existe
6. Tentar deletar com `Sint.delete<Controller>()`
7. Verificar que controller ainda existe
8. Deletar com `Sint.delete<Controller>(force: true)`
9. Verificar que agora foi removido

**Resultado esperado:** Controllers permanent devem persistir independente de navegação ou reset, exceto quando deletados com `force: true`.

---

### Teste 10: BindingsBuilder Inline
**Objetivo:** Usar bindings sem criar classe separada.

**Passos:**
1. Criar rota usando `BindingsBuilder(() { ... })`
2. Dentro do builder, injetar múltiplas dependências
3. Navegar para a rota
4. Verificar que todas as dependências foram injetadas
5. Comparar comportamento com Binding tradicional

**Resultado esperado:** BindingsBuilder deve funcionar exatamente como um Binding tradicional, mas de forma inline.

---

### Teste 11: Inicialização por Camadas
**Objetivo:** Validar ordem de inicialização de dependências.

**Passos:**
1. Criar método que inicializa dependências em camadas (infra, data, business, controllers)
2. Adicionar logs em cada camada para registrar ordem de execução
3. Fazer camada superior depender da camada inferior
4. Executar inicialização
5. Verificar ordem correta nos logs
6. Tentar usar dependência antes da inicialização e verificar erro

**Resultado esperado:** Dependências devem ser inicializadas na ordem correta, com camadas inferiores antes das superiores.

---

### Teste 12: Sint.delete Manual
**Objetivo:** Remover controllers manualmente em eventos específicos.

**Passos:**
1. Criar `SessionController` e `UserController`
2. Injetar ambos com `Sint.put()`
3. Implementar método `logout()` que chama `Sint.delete<UserController>()`
4. Verificar que controller existe antes do logout
5. Chamar `logout()`
6. Verificar que `UserController` foi removido
7. Verificar que `SessionController` ainda existe

**Resultado esperado:** Apenas o controller especificado deve ser removido, outros devem permanecer.

---

### Teste 13: Fenix Mode
**Objetivo:** Validar recriação automática com `fenix: true`.

**Passos:**
1. Injetar controller com `Sint.lazyPut(() => Controller(), fenix: true)`
2. Usar `Sint.find<Controller>()` para criar instância
3. Deletar com `Sint.delete<Controller>()`
4. Verificar que controller foi removido
5. Chamar `Sint.find<Controller>()` novamente
6. Verificar que controller foi recriado automaticamente

**Resultado esperado:** Com fenix mode, o controller deve ser recriado automaticamente após deleção.

---

### Teste 14: Injeção Condicional
**Objetivo:** Injetar diferentes implementações baseado em condições.

**Passos:**
1. Criar interface `IApiService`
2. Criar `DevApiService` e `ProdApiService` implementando a interface
3. Baseado em variável de ambiente, injetar implementação correta
4. Em modo DEV, verificar que `DevApiService` foi injetado
5. Em modo PROD, verificar que `ProdApiService` foi injetado
6. Usar `Sint.find<IApiService>()` e verificar comportamento específico

**Resultado esperado:** A implementação correta deve ser injetada baseada na condição, permitindo diferentes comportamentos em dev/prod.

---

### Teste 15: Sint.reset Completo
**Objetivo:** Limpar todas as dependências do app.

**Passos:**
1. Injetar múltiplos controllers e services (alguns permanent)
2. Verificar que todos existem usando `Sint.find()`
3. Chamar `Sint.reset()`
4. Verificar que controllers não-permanent foram removidos
5. Verificar que permanent ainda existem
6. Chamar `Sint.reset(clearRouteBindings: true)`
7. Verificar que TODOS foram removidos, incluindo permanent

**Resultado esperado:** `reset()` deve limpar tudo exceto permanent; com `clearRouteBindings: true` deve limpar absolutamente tudo.
