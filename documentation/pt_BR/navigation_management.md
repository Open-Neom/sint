# Gerenciamento de Navegação

O SINT oferece um sistema de navegação poderoso que elimina a necessidade de `context`, suporta rotas nomeadas, URLs dinâmicas, middleware e muito mais.

## Índice

- [SintMaterialApp](#sintmaterialapp)
- [Navegação Básica](#navegação-básica)
  - [Navegar para Próxima Tela](#navegar-para-próxima-tela)
  - [Fechar Telas](#fechar-telas)
  - [Navegar com Dados](#navegar-com-dados)
- [Rotas Nomeadas](#rotas-nomeadas)
  - [Definindo Rotas](#definindo-rotas)
  - [Navegação Nomeada](#navegação-nomeada)
  - [Parâmetros de Rota](#parâmetros-de-rota)
- [URLs Dinâmicas](#urls-dinâmicas)
  - [Parâmetros de Path](#parâmetros-de-path)
  - [Query Parameters](#query-parameters)
- [Middleware](#middleware)
  - [Criando Middleware](#criando-middleware)
  - [Redirecionamento](#redirecionamento)
  - [Prioridade](#prioridade)
- [SnackBars](#snackbars)
  - [SnackBar Simples](#snackbar-simples)
  - [SnackBar Customizado](#snackbar-customizado)
- [Dialogs](#dialogs)
  - [Dialog Padrão](#dialog-padrão)
  - [Dialog Customizado](#dialog-customizado)
- [BottomSheets](#bottomsheets)
- [Transições](#transições)
  - [Transições Padrão](#transições-padrão)
  - [Transições Customizadas](#transições-customizadas)
- [Navegação Aninhada](#navegação-aninhada)
- [Roteiro de Testes](#roteiro-de-testes)

## SintMaterialApp

Para usar o sistema de navegação do SINT, substitua `MaterialApp` por `SintMaterialApp`:

```dart
void main() {
  runApp(
    SintMaterialApp(
      title: 'Meu App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: HomePage(),
    ),
  );
}
```

**Com rotas nomeadas:**

```dart
void main() {
  runApp(
    SintMaterialApp(
      title: 'Meu App',
      initialRoute: '/home',
      getPages: [
        GetPage(name: '/home', page: () => HomePage()),
        GetPage(name: '/profile', page: () => ProfilePage()),
        GetPage(name: '/settings', page: () => SettingsPage()),
      ],
    ),
  );
}
```

## Navegação Básica

### Navegar para Próxima Tela

Sem necessidade de `context`:

```dart
// Navegar para próxima tela
Sint.to(NextPage());

// Com animação específica
Sint.to(
  NextPage(),
  transition: Transition.fadeIn,
  duration: Duration(milliseconds: 300),
);

// Sem animação
Sint.to(NextPage(), transition: Transition.noTransition);
```

### Fechar Telas

```dart
// Voltar para tela anterior
Sint.back();

// Voltar com dados
Sint.back(result: 'Dados para tela anterior');

// Fechar até chegar na primeira rota
Sint.until((route) => route.isFirst);

// Fechar dialogs, bottomsheets, drawers, etc
Sint.close(1); // Fecha 1 overlay
Sint.close(2); // Fecha 2 overlays
```

**Navegação com substituição:**

```dart
// Remove a tela atual e navega
Sint.off(NextPage());

// Remove todas as rotas anteriores e navega
Sint.offAll(HomePage());

// Remove até encontrar a rota especificada
Sint.offUntil(LoginPage(), (route) => route.isFirst);
```

### Navegar com Dados

**Enviando dados:**

```dart
// Enviando dados
Sint.to(
  ProductDetails(),
  arguments: {
    'id': 123,
    'name': 'Produto XYZ',
    'price': 99.90,
  },
);
```

**Recebendo dados:**

```dart
class ProductDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Recuperar argumentos
    final args = Sint.arguments as Map<String, dynamic>;
    final productId = args['id'];
    final productName = args['name'];

    return Scaffold(
      appBar: AppBar(title: Text(productName)),
      body: Center(
        child: Text('ID do Produto: $productId'),
      ),
    );
  }
}
```

**Aguardando retorno:**

```dart
// Navegar e aguardar resultado
final result = await Sint.to(SelectionPage());

if (result != null) {
  print('Selecionado: $result');
}

// Na página de seleção
ElevatedButton(
  onPressed: () {
    Sint.back(result: 'Item Selecionado');
  },
  child: Text('Selecionar'),
)
```

## Rotas Nomeadas

### Definindo Rotas

```dart
void main() {
  runApp(
    SintMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => SplashPage(),
        ),
        GetPage(
          name: '/home',
          page: () => HomePage(),
          binding: HomeBinding(),
        ),
        GetPage(
          name: '/login',
          page: () => LoginPage(),
          binding: LoginBinding(),
        ),
        GetPage(
          name: '/profile',
          page: () => ProfilePage(),
          binding: ProfileBinding(),
          transition: Transition.fadeIn,
        ),
      ],
    ),
  );
}
```

**Organizando rotas:**

```dart
class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const login = '/login';
  static const profile = '/profile';
  static const settings = '/settings';
}

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => SplashPage()),
    GetPage(name: AppRoutes.home, page: () => HomePage(), binding: HomeBinding()),
    GetPage(name: AppRoutes.login, page: () => LoginPage()),
    GetPage(name: AppRoutes.profile, page: () => ProfilePage()),
    GetPage(name: AppRoutes.settings, page: () => SettingsPage()),
  ];
}

void main() {
  runApp(
    SintMaterialApp(
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    ),
  );
}
```

### Navegação Nomeada

```dart
// Navegar para rota nomeada
Sint.toNamed('/profile');

// Navegar e remover rota atual
Sint.offNamed('/login');

// Remover todas e navegar
Sint.offAllNamed('/home');

// Com argumentos
Sint.toNamed('/product/details', arguments: productId);
```

### Parâmetros de Rota

```dart
// Definir rota
GetPage(
  name: '/user/:userId/posts/:postId',
  page: () => PostDetailPage(),
)

// Navegar
Sint.toNamed('/user/123/posts/456');

// Acessar parâmetros
final userId = Sint.parameters['userId']; // '123'
final postId = Sint.parameters['postId']; // '456'
```

## URLs Dinâmicas

### Parâmetros de Path

```dart
// Definir rota com parâmetro
GetPage(
  name: '/product/:id',
  page: () => ProductPage(),
)

// Navegar
Sint.toNamed('/product/42');

// Acessar
class ProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productId = Sint.parameters['id']; // '42'

    return Scaffold(
      appBar: AppBar(title: Text('Produto $productId')),
    );
  }
}
```

**Múltiplos parâmetros:**

```dart
// Rota
GetPage(
  name: '/category/:category/product/:id',
  page: () => ProductPage(),
)

// Navegar
Sint.toNamed('/category/electronics/product/42');

// Acessar
final category = Sint.parameters['category']; // 'electronics'
final id = Sint.parameters['id']; // '42'
```

### Query Parameters

```dart
// Navegar com query parameters
Sint.toNamed('/search?query=flutter&sort=recent&page=1');

// Acessar query parameters
final query = Sint.parameters['query']; // 'flutter'
final sort = Sint.parameters['sort']; // 'recent'
final page = Sint.parameters['page']; // '1'
```

**Exemplo completo:**

```dart
class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final query = Sint.parameters['query'] ?? '';
    final sort = Sint.parameters['sort'] ?? 'relevance';
    final page = int.tryParse(Sint.parameters['page'] ?? '1') ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Busca: $query'),
      ),
      body: SearchResults(
        query: query,
        sortBy: sort,
        page: page,
      ),
    );
  }
}
```

## Middleware

Middleware permite executar código antes de navegar para uma rota, perfeito para autenticação e validações.

### Criando Middleware

```dart
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Verificar se usuário está autenticado
    final authService = Sint.find<AuthService>();

    if (!authService.isAuthenticated) {
      return RouteSettings(name: '/login');
    }

    return null; // null = permite navegação
  }
}
```

**Aplicando middleware:**

```dart
GetPage(
  name: '/profile',
  page: () => ProfilePage(),
  middlewares: [AuthMiddleware()],
)
```

### Redirecionamento

**Middleware com lógica complexa:**

```dart
class RoleMiddleware extends GetMiddleware {
  final String requiredRole;

  RoleMiddleware(this.requiredRole);

  @override
  RouteSettings? redirect(String? route) {
    final authService = Sint.find<AuthService>();

    if (!authService.isAuthenticated) {
      return RouteSettings(name: '/login');
    }

    if (!authService.hasRole(requiredRole)) {
      Sint.snackbar(
        'Acesso Negado',
        'Você não tem permissão para acessar esta página',
      );
      return RouteSettings(name: '/home');
    }

    return null;
  }
}

// Uso
GetPage(
  name: '/admin',
  page: () => AdminPage(),
  middlewares: [RoleMiddleware('admin')],
)
```

### Prioridade

Middleware com menor número de prioridade executa primeiro:

```dart
class LogMiddleware extends GetMiddleware {
  @override
  int? get priority => 0; // Executa primeiro

  @override
  RouteSettings? redirect(String? route) {
    print('Navegando para: $route');
    return null;
  }
}

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1; // Executa depois

  @override
  RouteSettings? redirect(String? route) {
    // Verificação de autenticação
    return null;
  }
}

GetPage(
  name: '/profile',
  page: () => ProfilePage(),
  middlewares: [
    AuthMiddleware(), // priority: 1
    LogMiddleware(),  // priority: 0 (executa primeiro)
  ],
)
```

## SnackBars

### SnackBar Simples

```dart
Sint.snackbar(
  'Título',
  'Mensagem do snackbar',
);
```

### SnackBar Customizado

```dart
Sint.snackbar(
  'Sucesso',
  'Operação realizada com sucesso!',
  snackPosition: SnackPosition.BOTTOM,
  backgroundColor: Colors.green,
  colorText: Colors.white,
  duration: Duration(seconds: 3),
  icon: Icon(Icons.check_circle, color: Colors.white),
  shouldIconPulse: false,
  borderRadius: 10,
  margin: EdgeInsets.all(15),
  isDismissible: true,
  dismissDirection: DismissDirection.horizontal,
  onTap: (_) {
    print('Snackbar clicado');
  },
);
```

**SnackBar com ação:**

```dart
Sint.snackbar(
  'Item Removido',
  'Item removido da lista',
  mainButton: TextButton(
    onPressed: () {
      // Desfazer ação
      restoreItem();
    },
    child: Text('DESFAZER', style: TextStyle(color: Colors.white)),
  ),
  backgroundColor: Colors.red,
  colorText: Colors.white,
);
```

**Diferentes tipos:**

```dart
// Sucesso
Sint.snackbar(
  'Sucesso',
  'Dados salvos!',
  backgroundColor: Colors.green,
  icon: Icon(Icons.check_circle),
);

// Erro
Sint.snackbar(
  'Erro',
  'Falha ao salvar dados',
  backgroundColor: Colors.red,
  icon: Icon(Icons.error),
);

// Aviso
Sint.snackbar(
  'Atenção',
  'Verifique os dados antes de continuar',
  backgroundColor: Colors.orange,
  icon: Icon(Icons.warning),
);

// Info
Sint.snackbar(
  'Informação',
  'Você tem 3 novas mensagens',
  backgroundColor: Colors.blue,
  icon: Icon(Icons.info),
);
```

## Dialogs

### Dialog Padrão

```dart
Sint.defaultDialog(
  title: 'Confirmar',
  middleText: 'Deseja realmente sair?',
  textConfirm: 'Sim',
  textCancel: 'Não',
  onConfirm: () {
    Sint.back();
    logout();
  },
  onCancel: () {
    print('Cancelado');
  },
);
```

### Dialog Customizado

```dart
Sint.dialog(
  AlertDialog(
    title: Text('Título Customizado'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Conteúdo do dialog'),
        SizedBox(height: 20),
        TextField(
          decoration: InputDecoration(
            labelText: 'Digite algo',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Sint.back(),
        child: Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: () {
          Sint.back(result: 'confirmado');
        },
        child: Text('Confirmar'),
      ),
    ],
  ),
  barrierDismissible: false, // Não fecha ao clicar fora
);
```

**Dialog com retorno:**

```dart
final result = await Sint.dialog<bool>(
  AlertDialog(
    title: Text('Deletar item?'),
    content: Text('Esta ação não pode ser desfeita'),
    actions: [
      TextButton(
        onPressed: () => Sint.back(result: false),
        child: Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: () => Sint.back(result: true),
        child: Text('Deletar'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      ),
    ],
  ),
);

if (result == true) {
  deleteItem();
}
```

## BottomSheets

```dart
Sint.bottomSheet(
  Container(
    height: 200,
    color: Colors.white,
    child: Center(
      child: Text('BottomSheet Conteúdo'),
    ),
  ),
);
```

**BottomSheet customizado:**

```dart
Sint.bottomSheet(
  Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(height: 20),
        ListTile(
          leading: Icon(Icons.share),
          title: Text('Compartilhar'),
          onTap: () {
            Sint.back();
            share();
          },
        ),
        ListTile(
          leading: Icon(Icons.copy),
          title: Text('Copiar link'),
          onTap: () {
            Sint.back();
            copyLink();
          },
        ),
        ListTile(
          leading: Icon(Icons.delete, color: Colors.red),
          title: Text('Deletar', style: TextStyle(color: Colors.red)),
          onTap: () {
            Sint.back();
            delete();
          },
        ),
        SizedBox(height: 20),
      ],
    ),
  ),
  backgroundColor: Colors.transparent,
  isDismissible: true,
  enableDrag: true,
);
```

## Transições

### Transições Padrão

```dart
// Fade
Sint.to(NextPage(), transition: Transition.fade);

// RightToLeft
Sint.to(NextPage(), transition: Transition.rightToLeft);

// LeftToRight
Sint.to(NextPage(), transition: Transition.leftToRight);

// UpToDown
Sint.to(NextPage(), transition: Transition.upToDown);

// DownToUp
Sint.to(NextPage(), transition: Transition.downToUp);

// Zoom
Sint.to(NextPage(), transition: Transition.zoom);

// Sem transição
Sint.to(NextPage(), transition: Transition.noTransition);
```

**Transição global:**

```dart
SintMaterialApp(
  defaultTransition: Transition.fadeIn,
  transitionDuration: Duration(milliseconds: 300),
  // ...
)
```

**Transição por rota:**

```dart
GetPage(
  name: '/profile',
  page: () => ProfilePage(),
  transition: Transition.zoom,
  transitionDuration: Duration(milliseconds: 500),
)
```

### Transições Customizadas

```dart
Sint.to(
  NextPage(),
  transition: Transition.custom,
  customTransition: CustomPageTransition(),
);

class CustomPageTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }
}
```

## Navegação Aninhada

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navegação aninhada com ID
            Sint.toNamed('/nested/detail', id: 1);
          },
          child: Text('Abrir Detalhe'),
        ),
      ),
      // Navigator aninhado
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Busca'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
```

## Roteiro de Testes

### Teste 1: Navegação Básica sem Context
**Objetivo:** Verificar navegação entre telas sem usar `context`.

**Passos:**
1. Criar duas páginas: `HomePage` e `SecondPage`
2. Na `HomePage`, adicionar botão que chama `Sint.to(SecondPage())`
3. Clicar no botão e verificar navegação
4. Na `SecondPage`, adicionar botão que chama `Sint.back()`
5. Clicar e verificar retorno para `HomePage`

**Resultado esperado:** Deve navegar entre telas sem necessidade de `BuildContext`.

---

### Teste 2: Navegação com Dados
**Objetivo:** Enviar e receber dados entre telas.

**Passos:**
1. Criar tela de listagem com produtos
2. Ao clicar em produto, navegar com `Sint.to(DetailPage(), arguments: productData)`
3. Na `DetailPage`, recuperar dados com `Sint.arguments`
4. Exibir informações do produto
5. Verificar que dados foram transferidos corretamente

**Resultado esperado:** Os dados enviados devem ser acessíveis na tela de destino através de `Sint.arguments`.

---

### Teste 3: Navegação com Retorno
**Objetivo:** Aguardar resultado de tela navegada.

**Passos:**
1. Criar tela de seleção de opções
2. Navegar com `final result = await Sint.to(SelectionPage())`
3. Na `SelectionPage`, selecionar opção e chamar `Sint.back(result: selectedOption)`
4. Na tela original, verificar que `result` contém a opção selecionada
5. Atualizar UI baseado no resultado

**Resultado esperado:** O valor retornado deve ser recebido após `Sint.back(result: ...)`.

---

### Teste 4: Rotas Nomeadas
**Objetivo:** Configurar e usar rotas nomeadas.

**Passos:**
1. Configurar `getPages` no `SintMaterialApp` com rotas `/home`, `/profile`, `/settings`
2. Usar `Sint.toNamed('/profile')` para navegar
3. Verificar que a tela correta foi aberta
4. Usar `Sint.offAllNamed('/home')` e verificar que todas rotas anteriores foram removidas
5. Verificar pilha de navegação

**Resultado esperado:** Navegação por nome deve funcionar e manipular a pilha corretamente.

---

### Teste 5: Parâmetros Dinâmicos em URLs
**Objetivo:** Usar parâmetros de rota dinâmicos.

**Passos:**
1. Definir rota `GetPage(name: '/product/:id', page: () => ProductPage())`
2. Navegar com `Sint.toNamed('/product/123')`
3. Na `ProductPage`, recuperar com `Sint.parameters['id']`
4. Verificar que `id == '123'`
5. Navegar para `/product/456` e verificar novo ID

**Resultado esperado:** Parâmetros dinâmicos devem ser extraídos corretamente da URL.

---

### Teste 6: Query Parameters
**Objetivo:** Usar query parameters em rotas.

**Passos:**
1. Navegar com `Sint.toNamed('/search?query=flutter&page=2')`
2. Recuperar parâmetros com `Sint.parameters['query']` e `Sint.parameters['page']`
3. Verificar valores: `query == 'flutter'` e `page == '2'`
4. Realizar busca baseada nos parâmetros
5. Atualizar URL com novos parâmetros

**Resultado esperado:** Query parameters devem ser acessíveis via `Sint.parameters`.

---

### Teste 7: Middleware de Autenticação
**Objetivo:** Implementar middleware que protege rotas.

**Passos:**
1. Criar `AuthMiddleware` que verifica se usuário está autenticado
2. Aplicar middleware na rota `/profile`
3. Tentar navegar para `/profile` sem estar autenticado
4. Verificar que middleware redireciona para `/login`
5. Fazer login e tentar novamente
6. Verificar que agora consegue acessar `/profile`

**Resultado esperado:** Middleware deve interceptar navegação e redirecionar quando necessário.

---

### Teste 8: Múltiplos Middlewares com Prioridade
**Objetivo:** Validar ordem de execução de middlewares.

**Passos:**
1. Criar `LogMiddleware` com `priority: 0`
2. Criar `AuthMiddleware` com `priority: 1`
3. Adicionar ambos em uma rota
4. Adicionar logs em cada middleware
5. Navegar para a rota
6. Verificar ordem de execução nos logs

**Resultado esperado:** Middleware com menor prioridade deve executar primeiro (LogMiddleware antes de AuthMiddleware).

---

### Teste 9: SnackBar Customizado
**Objetivo:** Exibir snackbars com diferentes estilos.

**Passos:**
1. Criar snackbar de sucesso com fundo verde
2. Criar snackbar de erro com fundo vermelho
3. Criar snackbar com botão de ação "DESFAZER"
4. Testar diferentes posições (top/bottom)
5. Testar duração customizada
6. Verificar que snackbar pode ser dispensado

**Resultado esperado:** Snackbars devem aparecer com estilos e comportamentos configurados.

---

### Teste 10: Dialog com Retorno
**Objetivo:** Mostrar dialog e obter resposta do usuário.

**Passos:**
1. Mostrar dialog de confirmação com `Sint.defaultDialog()`
2. Adicionar botões "Sim" e "Não"
3. Aguardar resposta com `final result = await Sint.dialog(...)`
4. No botão "Sim", chamar `Sint.back(result: true)`
5. No botão "Não", chamar `Sint.back(result: false)`
6. Executar ação baseada no resultado

**Resultado esperado:** Dialog deve retornar o valor correto baseado no botão clicado.

---

### Teste 11: BottomSheet Interativo
**Objetivo:** Criar bottomsheet com opções.

**Passos:**
1. Criar botão que abre `Sint.bottomSheet()`
2. BottomSheet deve conter lista de opções (Compartilhar, Copiar, Deletar)
3. Cada opção deve ter ícone e texto
4. Ao clicar em opção, fechar bottomsheet com `Sint.back()`
5. Executar ação correspondente
6. Testar fechar arrastando para baixo

**Resultado esperado:** BottomSheet deve abrir, permitir seleção e fechar corretamente.

---

### Teste 12: Transições Customizadas
**Objetivo:** Aplicar diferentes transições de página.

**Passos:**
1. Navegar com `transition: Transition.fade`
2. Navegar com `transition: Transition.zoom`
3. Navegar com `transition: Transition.rightToLeft`
4. Criar transição customizada com `CustomTransition`
5. Configurar duração com `transitionDuration`
6. Observar animações

**Resultado esperado:** Cada transição deve produzir animação visual diferente.

---

### Teste 13: Bindings com Rotas
**Objetivo:** Injetar dependências automaticamente ao navegar.

**Passos:**
1. Criar `HomeBinding` que injeta `HomeController`
2. Configurar rota com binding
3. Navegar para a rota
4. Verificar que controller foi injetado automaticamente
5. Usar `Sint.find<HomeController>()` na página
6. Navegar para outra rota e verificar ciclo de vida

**Resultado esperado:** Controller deve ser injetado automaticamente ao acessar a rota.

---

### Teste 14: Navegação Off e OffAll
**Objetivo:** Gerenciar pilha de navegação.

**Passos:**
1. Navegar para múltiplas telas: Home -> A -> B -> C
2. Em C, usar `Sint.off(D())` para substituir C por D
3. Verificar que C foi removida da pilha
4. Usar `Sint.offAll(Home())` para remover todas e ir para Home
5. Verificar que pilha contém apenas Home
6. Tentar voltar com `Sint.back()` e verificar comportamento

**Resultado esperado:** `off` substitui tela atual, `offAll` limpa toda pilha.

---

### Teste 15: Navegação Aninhada com IDs
**Objetivo:** Gerenciar múltiplos navigators.

**Passos:**
1. Criar BottomNavigationBar com 3 abas
2. Cada aba deve ter seu próprio Navigator
3. Navegar dentro de uma aba usando `id: 1`
4. Trocar de aba e verificar que estado é mantido
5. Voltar para aba original e verificar pilha de navegação
6. Usar `Sint.back(id: 1)` para voltar no navigator específico

**Resultado esperado:** Cada navigator deve manter sua própria pilha independente, identificada pelo ID.
