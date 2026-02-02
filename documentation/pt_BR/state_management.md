# Gerenciamento de Estado

O SINT oferece uma solução completa e poderosa para gerenciamento de estado no Flutter, permitindo que você escolha entre diferentes abordagens conforme a necessidade da sua aplicação.

## Índice

- [Estado Reativo](#estado-reativo)
  - [Variáveis Observáveis (.obs)](#variáveis-observáveis-obs)
  - [Widget Obx](#widget-obx)
  - [GetX Widget](#getx-widget)
  - [ValueBuilder](#valuebuilder)
- [Gerenciamento Simples](#gerenciamento-simples)
  - [SintBuilder](#SintBuilder)
  - [Atualização Seletiva](#atualização-seletiva)
- [StateMixin](#statemixin)
  - [Estados de Carregamento](#estados-de-carregamento)
  - [Tratamento de Erros](#tratamento-de-erros)
- [Workers](#workers)
  - [Tipos de Workers](#tipos-de-workers)
  - [Casos de Uso](#casos-de-uso)
- [Roteiro de Testes](#roteiro-de-testes)

## Estado Reativo

O gerenciamento de estado reativo do SINT permite que você crie variáveis observáveis que automaticamente atualizam a UI quando seus valores mudam.

### Variáveis Observáveis (.obs)

Para tornar uma variável reativa, simplesmente adicione `.obs` ao seu valor inicial:

```dart
class Controller extends SintController {
  // Variáveis reativas
  var count = 0.obs;
  var name = ''.obs;
  var isLogged = false.obs;
  var user = User().obs;
  var items = <String>[].obs;
}
```

Para acessar e modificar o valor:

```dart
// Ler o valor
print(count.value);

// Modificar o valor
count.value++;
name.value = 'João';
isLogged.value = true;

// Para listas, você pode usar métodos nativos
items.add('Item novo');
items.removeAt(0);
```

### Widget Obx

`Obx` é o widget mais simples para observar mudanças reativas. Ele reconstrói automaticamente quando qualquer variável `.obs` dentro dele muda:

```dart
class HomePage extends StatelessWidget {
  final Controller controller = Sint.put(Controller());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contador Reativo')),
      body: Center(
        child: Obx(() => Text(
          'Cliques: ${controller.count}',
          style: TextStyle(fontSize: 30),
        )),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => controller.count++,
      ),
    );
  }
}
```

**Importante:** O `Obx` deve sempre ter uma função de retorno (arrow function `() =>`), não um widget diretamente.

### GetX Widget

`GetX` é uma alternativa ao `Obx` que também permite injetar o controller:

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GetX<Controller>(
          init: Controller(), // Injeta o controller se não existir
          builder: (controller) {
            return Text('Cliques: ${controller.count}');
          },
        ),
      ),
    );
  }
}
```

### ValueBuilder

Para valores não reativos que precisam ser reconstruídos manualmente:

```dart
ValueBuilder<int>(
  initialValue: 0,
  builder: (value, updateFn) => Switch(
    value: value < 10,
    onChanged: (flag) {
      if (flag) {
        updateFn(value + 1);
      } else {
        updateFn(value - 1);
      }
    },
  ),
  onUpdate: (value) => print("Valor atualizado: $value"),
  onDispose: () => print("Widget descartado"),
)
```

## Gerenciamento Simples

Para casos onde você não precisa de reatividade completa, o SINT oferece o `SintBuilder`.

### SintBuilder

`SintBuilder` é uma solução de gerenciamento de estado mais leve que não usa streams ou observáveis:

```dart
class Controller extends SintController {
  int count = 0;

  void increment() {
    count++;
    update(); // Notifica os SintBuilders para reconstruir
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SintBuilder<Controller>(
          init: Controller(),
          builder: (controller) {
            return Text('Cliques: ${controller.count}');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Sint.find<Controller>().increment();
        },
      ),
    );
  }
}
```

### Atualização Seletiva

Você pode usar IDs para atualizar apenas widgets específicos:

```dart
class Controller extends SintController {
  int count1 = 0;
  int count2 = 0;

  void incrementCount1() {
    count1++;
    update(['counter1']); // Atualiza apenas widgets com ID 'counter1'
  }

  void incrementCount2() {
    count2++;
    update(['counter2']); // Atualiza apenas widgets com ID 'counter2'
  }
}

// Na UI
SintBuilder<Controller>(
  id: 'counter1',
  builder: (controller) => Text('Count 1: ${controller.count1}'),
)

SintBuilder<Controller>(
  id: 'counter2',
  builder: (controller) => Text('Count 2: ${controller.count2}'),
)
```

Você também pode usar condições para decidir quando atualizar:

```dart
update((ids) {
  return ids.contains('contador') && count > 10;
});
```

## StateMixin

`StateMixin` é uma poderosa ferramenta para gerenciar estados de carregamento, sucesso, erro e vazio.

### Estados de Carregamento

```dart
class UserController extends SintController with StateMixin<User> {
  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  Future<void> loadUser() async {
    // Define estado de carregamento
    change(null, status: RxStatus.loading());

    try {
      final user = await userRepository.getUser();

      if (user == null) {
        change(null, status: RxStatus.empty());
      } else {
        change(user, status: RxStatus.success());
      }
    } catch (e) {
      change(null, status: RxStatus.error('Erro ao carregar usuário'));
    }
  }
}
```

Na UI, use o widget de acordo com o estado:

```dart
class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SintBuilder<UserController>(
        init: UserController(),
        builder: (controller) {
          return controller.obx(
            (user) => UserProfile(user: user!),
            onLoading: CircularProgressIndicator(),
            onEmpty: Text('Nenhum usuário encontrado'),
            onError: (error) => Text('Erro: $error'),
          );
        },
      ),
    );
  }
}
```

### Tratamento de Erros

Você pode personalizar completamente os estados:

```dart
controller.obx(
  (data) => ListaTarefas(tarefas: data),
  onLoading: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text('Carregando tarefas...'),
      ],
    ),
  ),
  onEmpty: Center(
    child: Column(
      children: [
        Icon(Icons.inbox, size: 100, color: Colors.grey),
        Text('Nenhuma tarefa encontrada'),
        ElevatedButton(
          onPressed: () => controller.loadTasks(),
          child: Text('Tentar novamente'),
        ),
      ],
    ),
  ),
  onError: (error) => Center(
    child: Column(
      children: [
        Icon(Icons.error, size: 100, color: Colors.red),
        Text('Erro: $error'),
        ElevatedButton(
          onPressed: () => controller.loadTasks(),
          child: Text('Recarregar'),
        ),
      ],
    ),
  ),
);
```

## Workers

Workers são callbacks que são chamados quando um evento ocorre. São extremamente úteis para executar ações em resposta a mudanças de estado.

### Tipos de Workers

#### ever

Chamado toda vez que a variável muda:

```dart
class Controller extends SintController {
  var count = 0.obs;

  @override
  void onInit() {
    ever(count, (value) {
      print('Count mudou para: $value');
    });
    super.onInit();
  }
}
```

#### once

Chamado apenas uma vez quando a variável muda:

```dart
@override
void onInit() {
  once(isLogged, (value) {
    if (value == true) {
      print('Usuário fez login pela primeira vez');
      // Navegar para home
      Sint.offAllNamed('/home');
    }
  });
  super.onInit();
}
```

#### debounce

Chamado após um período de inatividade (útil para campos de busca):

```dart
class SearchController extends SintController {
  var searchQuery = ''.obs;

  @override
  void onInit() {
    debounce(
      searchQuery,
      (value) {
        // Executado 800ms após o usuário parar de digitar
        performSearch(value);
      },
      time: Duration(milliseconds: 800),
    );
    super.onInit();
  }

  void performSearch(String query) {
    print('Buscando por: $query');
    // Realizar busca na API
  }
}
```

#### interval

Ignora mudanças durante um intervalo de tempo:

```dart
@override
void onInit() {
  interval(
    position,
    (value) {
      // Atualiza localização no servidor no máximo a cada 30 segundos
      updateLocationOnServer(value);
    },
    time: Duration(seconds: 30),
  );
  super.onInit();
}
```

### Casos de Uso

**Validação em tempo real:**

```dart
class FormController extends SintController {
  var email = ''.obs;
  var emailError = ''.obs;

  @override
  void onInit() {
    debounce(
      email,
      (value) {
        if (!isValidEmail(value)) {
          emailError.value = 'Email inválido';
        } else {
          emailError.value = '';
        }
      },
      time: Duration(milliseconds: 500),
    );
    super.onInit();
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
```

**Sincronização de dados:**

```dart
class SyncController extends SintController {
  var localData = <Item>[].obs;
  var isSyncing = false.obs;

  @override
  void onInit() {
    interval(
      localData,
      (data) {
        if (!isSyncing.value && data.isNotEmpty) {
          syncWithServer(data);
        }
      },
      time: Duration(minutes: 5),
    );
    super.onInit();
  }

  Future<void> syncWithServer(List<Item> data) async {
    isSyncing.value = true;
    try {
      await api.sync(data);
    } finally {
      isSyncing.value = false;
    }
  }
}
```

**Navegação automática:**

```dart
class AuthController extends SintController {
  var authToken = Rxn<String>();

  @override
  void onInit() {
    ever(authToken, (token) {
      if (token == null || token.isEmpty) {
        Sint.offAllNamed('/login');
      } else {
        Sint.offAllNamed('/home');
      }
    });
    super.onInit();
  }
}
```

## Boas Práticas

1. **Use Obx para reatividade simples:** Quando você só precisa observar uma ou poucas variáveis.

2. **Use SintBuilder para performance:** Quando você tem muitos widgets ou não precisa de reatividade automática.

3. **Combine ambos quando necessário:** Você pode usar Obx e SintBuilder no mesmo controller.

4. **Use StateMixin para operações assíncronas:** Facilita muito o gerenciamento de estados de loading, erro e vazio.

5. **Workers para side effects:** Use workers para executar código em resposta a mudanças, não dentro dos widgets.

6. **Evite lógica complexa nos widgets:** Mantenha a lógica no controller.

7. **Dispose workers:** Workers são automaticamente descartados quando o controller é removido, mas você pode cancelá-los manualmente se necessário:

```dart
Worker? myWorker;

@override
void onInit() {
  myWorker = ever(count, (value) {
    print(value);
  });
  super.onInit();
}

@override
void onClose() {
  myWorker?.dispose();
  super.onClose();
}
```

## Roteiro de Testes

### Teste 1: Estado Reativo Básico
**Objetivo:** Verificar que variáveis `.obs` atualizam a UI automaticamente.

**Passos:**
1. Criar um controller com uma variável `counter` do tipo `RxInt`
2. Criar uma tela com `Obx` exibindo o valor de `counter`
3. Adicionar um botão que incrementa `counter.value++`
4. Verificar se o texto na tela atualiza automaticamente

**Resultado esperado:** O valor exibido deve incrementar a cada clique sem necessidade de chamar `setState` ou `update()`.

---

### Teste 2: SintBuilder com IDs
**Objetivo:** Verificar atualização seletiva com IDs.

**Passos:**
1. Criar um controller com dois contadores: `counter1` e `counter2`
2. Criar métodos `incrementCounter1()` com `update(['counter1'])` e `incrementCounter2()` com `update(['counter2'])`
3. Criar dois `SintBuilder` widgets, um com `id: 'counter1'` e outro com `id: 'counter2'`
4. Adicionar botões para incrementar cada contador
5. Verificar que apenas o widget com ID correspondente é reconstruído

**Resultado esperado:** Apenas o texto do contador específico deve atualizar, o outro permanece inalterado.

---

### Teste 3: StateMixin com Requisição Assíncrona
**Objetivo:** Validar os estados de loading, sucesso, erro e vazio.

**Passos:**
1. Criar um controller que extends SintController with StateMixin<List<String>>
2. Implementar método `loadData()` que simula uma requisição async
3. Testar estado loading: chamar `change(null, status: RxStatus.loading())`
4. Testar estado sucesso: retornar dados e chamar `change(data, status: RxStatus.success())`
5. Testar estado vazio: retornar lista vazia e chamar `change(null, status: RxStatus.empty())`
6. Testar estado erro: simular exceção e chamar `change(null, status: RxStatus.error('Mensagem de erro'))`
7. Usar `controller.obx()` na UI com callbacks para cada estado

**Resultado esperado:** A UI deve exibir o widget apropriado para cada estado (loading spinner, lista de dados, mensagem de vazio, mensagem de erro).

---

### Teste 4: Worker Debounce em Campo de Busca
**Objetivo:** Validar que o debounce só executa após período de inatividade.

**Passos:**
1. Criar um controller com `var searchQuery = ''.obs`
2. Adicionar um `debounce` worker com `time: Duration(milliseconds: 800)`
3. O worker deve chamar um método `performSearch()`
4. Criar um TextField que atualiza `searchQuery.value`
5. Digitar caracteres rapidamente e verificar que `performSearch()` não é chamado imediatamente
6. Parar de digitar e aguardar 800ms
7. Verificar que `performSearch()` foi chamado apenas uma vez

**Resultado esperado:** O método `performSearch()` só deve ser executado 800ms após o usuário parar de digitar, evitando múltiplas chamadas desnecessárias.

---

### Teste 5: Worker Ever para Navegação Automática
**Objetivo:** Validar que o worker `ever` reage a toda mudança de estado.

**Passos:**
1. Criar um controller com `var isAuthenticated = false.obs`
2. Adicionar um `ever` worker que observa `isAuthenticated`
3. Quando `isAuthenticated` mudar para `true`, navegar para '/home'
4. Quando mudar para `false`, navegar para '/login'
5. Alternar o valor de `isAuthenticated` múltiplas vezes
6. Verificar que a navegação ocorre em cada mudança

**Resultado esperado:** Cada mudança no valor de `isAuthenticated` deve disparar a navegação correspondente.

---

### Teste 6: Combinação de Obx e SintBuilder
**Objetivo:** Verificar que ambos os métodos podem coexistir no mesmo controller.

**Passos:**
1. Criar um controller com `var reactiveCount = 0.obs` e `int simpleCount = 0`
2. Criar método `incrementReactive()` que faz `reactiveCount++`
3. Criar método `incrementSimple()` que faz `simpleCount++` e chama `update()`
4. Criar UI com um `Obx` exibindo `reactiveCount` e um `SintBuilder` exibindo `simpleCount`
5. Adicionar botões para incrementar cada contador
6. Verificar que ambos funcionam independentemente

**Resultado esperado:** Os dois tipos de gerenciamento de estado devem funcionar simultaneamente sem conflitos.

---

### Teste 7: Worker Interval para Limitação de Requisições
**Objetivo:** Validar que `interval` ignora mudanças dentro do período definido.

**Passos:**
1. Criar um controller com `var locationData = Rx<Location>()`
2. Adicionar um `interval` worker com `time: Duration(seconds: 5)`
3. O worker deve chamar `updateLocationOnServer()`
4. Simular atualizações rápidas de localização (a cada segundo)
5. Verificar que `updateLocationOnServer()` só é chamado a cada 5 segundos, não a cada segundo

**Resultado esperado:** Mesmo com múltiplas atualizações de localização, o servidor deve ser atualizado apenas uma vez a cada 5 segundos.

---

### Teste 8: Worker Once para Primeira Mudança
**Objetivo:** Validar que `once` executa apenas na primeira mudança.

**Passos:**
1. Criar um controller com `var hasSeenTutorial = false.obs`
2. Adicionar um `once` worker que navega para '/tutorial' quando `hasSeenTutorial` muda para `true`
3. Mudar `hasSeenTutorial` para `true` (deve navegar)
4. Mudar novamente para `false` e depois `true`
5. Verificar que a navegação só ocorreu na primeira mudança

**Resultado esperado:** A navegação para o tutorial deve ocorrer apenas uma vez, mesmo que o valor mude múltiplas vezes.

---

### Teste 9: Performance SintBuilder vs Obx
**Objetivo:** Comparar performance entre SintBuilder e Obx com muitos widgets.

**Passos:**
1. Criar uma lista com 1000 itens usando `SintBuilder`
2. Criar outra lista com 1000 itens usando `Obx`
3. Medir o tempo de build inicial e de atualização
4. Incrementar um contador e medir tempo de rebuild
5. Comparar uso de memória

**Resultado esperado:** SintBuilder deve ter melhor performance em listas grandes, enquanto Obx é mais conveniente para poucos widgets.

---

### Teste 10: Validação em Tempo Real com Debounce
**Objetivo:** Implementar validação de formulário com feedback imediato.

**Passos:**
1. Criar um controller com `var email = ''.obs` e `var emailError = ''.obs`
2. Adicionar `debounce` worker que valida email após 500ms
3. Se email inválido, definir `emailError.value = 'Email inválido'`
4. Se válido, definir `emailError.value = ''`
5. Criar TextField com `Obx` exibindo mensagem de erro
6. Digitar email inválido e verificar que erro aparece após 500ms
7. Corrigir email e verificar que erro desaparece

**Resultado esperado:** A validação deve ocorrer automaticamente 500ms após o usuário parar de digitar, exibindo ou removendo a mensagem de erro conforme necessário.
