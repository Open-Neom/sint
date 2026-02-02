# Gerenciamento de Traduções

O SINT oferece um sistema completo de internacionalização (i18n) que permite suportar múltiplos idiomas em seu aplicativo de forma simples e eficiente.

## Índice

- [Conceitos Básicos](#conceitos-básicos)
- [Classe Translations](#classe-translations)
  - [Estrutura Básica](#estrutura-básica)
  - [Organização de Traduções](#organização-de-traduções)
- [Configuração](#configuração)
  - [SintMaterialApp](#sintmaterialapp)
  - [Locale Padrão](#locale-padrão)
  - [Fallback Locale](#fallback-locale)
- [Usando Traduções](#usando-traduções)
  - [Método .tr](#método-tr)
  - [Keys Aninhadas](#keys-aninhadas)
- [Traduções com Parâmetros](#traduções-com-parâmetros)
  - [trParams](#trparams)
  - [Múltiplos Parâmetros](#múltiplos-parâmetros)
- [Pluralização](#pluralização)
  - [trPlural](#trplural)
  - [Regras de Pluralização](#regras-de-pluralização)
- [Mudança de Idioma](#mudança-de-idioma)
  - [Sint.updateLocale](#sintupdatelocale)
  - [Persistência de Idioma](#persistência-de-idioma)
- [Locale do Dispositivo](#locale-do-dispositivo)
  - [Detectar Idioma](#detectar-idioma)
  - [Locale Atual](#locale-atual)
- [Organização Avançada](#organização-avançada)
  - [Arquivos Separados](#arquivos-separados)
  - [Carregamento Lazy](#carregamento-lazy)
- [Boas Práticas](#boas-práticas)
- [Roteiro de Testes](#roteiro-de-testes)

## Conceitos Básicos

O sistema de traduções do SINT permite que você:

- **Suporte múltiplos idiomas:** Adicione quantos idiomas precisar
- **Traduções dinâmicas:** Mude o idioma em tempo de execução
- **Parâmetros:** Insira valores dinâmicos nas traduções
- **Pluralização:** Gerencie singular/plural automaticamente
- **Fallback:** Defina idioma padrão quando tradução não existir
- **Organização:** Mantenha traduções organizadas por módulo/tela

## Classe Translations

### Estrutura Básica

Crie uma classe que extends `Translations`:

```dart
import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'pt_BR': {
      'hello': 'Olá',
      'welcome': 'Bem-vindo',
      'goodbye': 'Até logo',
    },
    'en_US': {
      'hello': 'Hello',
      'welcome': 'Welcome',
      'goodbye': 'Goodbye',
    },
    'es_ES': {
      'hello': 'Hola',
      'welcome': 'Bienvenido',
      'goodbye': 'Adiós',
    },
  };
}
```

### Organização de Traduções

**Traduções completas:**

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'pt_BR': {
      // Navegação
      'nav_home': 'Início',
      'nav_profile': 'Perfil',
      'nav_settings': 'Configurações',

      // Botões
      'btn_save': 'Salvar',
      'btn_cancel': 'Cancelar',
      'btn_delete': 'Excluir',
      'btn_confirm': 'Confirmar',

      // Mensagens
      'msg_success': 'Operação realizada com sucesso',
      'msg_error': 'Ocorreu um erro',
      'msg_loading': 'Carregando...',

      // Formulários
      'form_name': 'Nome',
      'form_email': 'E-mail',
      'form_password': 'Senha',
      'form_phone': 'Telefone',

      // Validações
      'validation_required': 'Campo obrigatório',
      'validation_email': 'E-mail inválido',
      'validation_min_length': 'Mínimo de caracteres',
    },
    'en_US': {
      // Navigation
      'nav_home': 'Home',
      'nav_profile': 'Profile',
      'nav_settings': 'Settings',

      // Buttons
      'btn_save': 'Save',
      'btn_cancel': 'Cancel',
      'btn_delete': 'Delete',
      'btn_confirm': 'Confirm',

      // Messages
      'msg_success': 'Operation completed successfully',
      'msg_error': 'An error occurred',
      'msg_loading': 'Loading...',

      // Forms
      'form_name': 'Name',
      'form_email': 'Email',
      'form_password': 'Password',
      'form_phone': 'Phone',

      // Validations
      'validation_required': 'Required field',
      'validation_email': 'Invalid email',
      'validation_min_length': 'Minimum characters',
    },
  };
}
```

## Configuração

### SintMaterialApp

Configure traduções no `SintMaterialApp`:

```dart
void main() {
  runApp(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: Locale('pt', 'BR'), // Idioma padrão
      fallbackLocale: Locale('en', 'US'), // Idioma de fallback
      home: HomePage(),
    ),
  );
}
```

### Locale Padrão

O locale padrão é o idioma inicial do app:

```dart
SintMaterialApp(
  locale: Locale('pt', 'BR'), // Português brasileiro
  // ou
  locale: Locale('en', 'US'), // Inglês americano
  // ou
  locale: Locale('es', 'ES'), // Espanhol
)
```

### Fallback Locale

Quando uma tradução não existe no idioma atual, o sistema usa o fallback:

```dart
SintMaterialApp(
  translations: AppTranslations(),
  locale: Locale('fr', 'FR'), // Francês (não tem traduções)
  fallbackLocale: Locale('en', 'US'), // Volta para inglês
)
```

**Exemplo:**

```dart
// Se 'welcome' não existe em francês, usa inglês
Text('welcome'.tr) // Mostra "Welcome"
```

## Usando Traduções

### Método .tr

Use `.tr` em qualquer String para traduzir:

```dart
// Simples
Text('hello'.tr) // "Olá" em pt_BR, "Hello" em en_US

// Em widgets
AppBar(
  title: Text('nav_home'.tr),
)

// Em variáveis
final message = 'msg_success'.tr;
print(message);

// Em listas
final items = [
  'nav_home'.tr,
  'nav_profile'.tr,
  'nav_settings'.tr,
];
```

### Keys Aninhadas

Organize traduções com pontos:

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'pt_BR': {
      'home.title': 'Página Inicial',
      'home.subtitle': 'Bem-vindo ao app',
      'profile.title': 'Meu Perfil',
      'profile.edit': 'Editar Perfil',
      'settings.title': 'Configurações',
      'settings.language': 'Idioma',
      'settings.theme': 'Tema',
    },
    'en_US': {
      'home.title': 'Home Page',
      'home.subtitle': 'Welcome to the app',
      'profile.title': 'My Profile',
      'profile.edit': 'Edit Profile',
      'settings.title': 'Settings',
      'settings.language': 'Language',
      'settings.theme': 'Theme',
    },
  };
}

// Uso
Text('home.title'.tr)
Text('profile.edit'.tr)
Text('settings.language'.tr)
```

## Traduções com Parâmetros

### trParams

Insira valores dinâmicos nas traduções:

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'pt_BR': {
      'greeting': 'Olá, @name!',
      'welcome_back': 'Bem-vindo de volta, @name',
      'items_count': 'Você tem @count itens',
    },
    'en_US': {
      'greeting': 'Hello, @name!',
      'welcome_back': 'Welcome back, @name',
      'items_count': 'You have @count items',
    },
  };
}

// Uso
Text('greeting'.trParams({'name': 'João'}))
// Saída: "Olá, João!" em pt_BR
// Saída: "Hello, João!" em en_US

Text('items_count'.trParams({'count': '5'}))
// Saída: "Você tem 5 itens"
```

### Múltiplos Parâmetros

```dart
// Traduções
'pt_BR': {
  'order_status': 'Pedido #@order de @customer está @status',
  'price_info': '@product custa R$ @price',
}

// Uso
Text('order_status'.trParams({
  'order': '123',
  'customer': 'Maria',
  'status': 'em preparação',
}))
// Saída: "Pedido #123 de Maria está em preparação"

Text('price_info'.trParams({
  'product': 'Notebook',
  'price': '2500,00',
}))
// Saída: "Notebook custa R$ 2500,00"
```

**Exemplo em formulário:**

```dart
class LoginPage extends StatelessWidget {
  final nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('login.title'.tr),
      ),
      body: Column(
        children: [
          Text('login.welcome_message'.trParams({
            'app': 'MyApp',
          })),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'form.name'.tr,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text;
              Sint.snackbar(
                'success.title'.tr,
                'success.login'.trParams({'name': name}),
              );
            },
            child: Text('btn.login'.tr),
          ),
        ],
      ),
    );
  }
}
```

## Pluralização

### trPlural

Gerencie singular e plural automaticamente:

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'pt_BR': {
      'item': 'item',
      'items': 'itens',
      'notification': 'notificação',
      'notifications': 'notificações',
    },
    'en_US': {
      'item': 'item',
      'items': 'items',
      'notification': 'notification',
      'notifications': 'notifications',
    },
  };
}

// Uso
Text('item'.trPlural('items', 1))  // "1 item"
Text('item'.trPlural('items', 5))  // "5 itens"
Text('item'.trPlural('items', 0))  // "0 itens"

Text('notification'.trPlural('notifications', 1))  // "1 notificação"
Text('notification'.trPlural('notifications', 3))  // "3 notificações"
```

### Regras de Pluralização

**Com parâmetros:**

```dart
'pt_BR': {
  'cart_message': 'Você tem @count @item no carrinho',
}

// Uso
int count = 1;
String item = 'item'.trPlural('items', count);
Text('cart_message'.trParams({
  'count': count.toString(),
  'item': item,
}))
// Saída: "Você tem 1 item no carrinho"

int count = 5;
String item = 'item'.trPlural('items', count);
Text('cart_message'.trParams({
  'count': count.toString(),
  'item': item,
}))
// Saída: "Você tem 5 itens no carrinho"
```

**Exemplo completo:**

```dart
class ShoppingCartWidget extends StatelessWidget {
  final int itemCount;

  ShoppingCartWidget({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    final itemWord = 'item'.trPlural('items', itemCount);

    return Card(
      child: ListTile(
        leading: Icon(Icons.shopping_cart),
        title: Text('cart.title'.tr),
        subtitle: Text('cart.message'.trParams({
          'count': itemCount.toString(),
          'item': itemWord,
        })),
        trailing: Text(itemCount.toString()),
      ),
    );
  }
}
```

## Mudança de Idioma

### Sint.updateLocale

Mude o idioma em tempo de execução:

```dart
// Mudar para português
Sint.updateLocale(Locale('pt', 'BR'));

// Mudar para inglês
Sint.updateLocale(Locale('en', 'US'));

// Mudar para espanhol
Sint.updateLocale(Locale('es', 'ES'));
```

**Widget de seleção de idioma:**

```dart
class LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      onSelected: (locale) {
        Sint.updateLocale(locale);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: Locale('pt', 'BR'),
          child: Row(
            children: [
              Text('🇧🇷'),
              SizedBox(width: 10),
              Text('Português'),
            ],
          ),
        ),
        PopupMenuItem(
          value: Locale('en', 'US'),
          child: Row(
            children: [
              Text('🇺🇸'),
              SizedBox(width: 10),
              Text('English'),
            ],
          ),
        ),
        PopupMenuItem(
          value: Locale('es', 'ES'),
          child: Row(
            children: [
              Text('🇪🇸'),
              SizedBox(width: 10),
              Text('Español'),
            ],
          ),
        ),
      ],
      child: Icon(Icons.language),
    );
  }
}
```

### Persistência de Idioma

Salve a preferência do usuário:

```dart
class LanguageService extends SintController {
  final storage = Sint.find<StorageService>();

  Future<void> saveLanguage(Locale locale) async {
    await storage.write('language', locale.languageCode);
    await storage.write('country', locale.countryCode);
  }

  Future<Locale?> getSavedLanguage() async {
    final language = await storage.read('language');
    final country = await storage.read('country');

    if (language != null && country != null) {
      return Locale(language, country);
    }
    return null;
  }

  Future<void> changeLanguage(Locale locale) async {
    await saveLanguage(locale);
    Sint.updateLocale(locale);
  }
}

// Uso na inicialização
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Sint.putAsync(() async {
    final storage = StorageService();
    await storage.init();
    return storage;
  });

  Sint.put(LanguageService());

  final savedLocale = await Sint.find<LanguageService>().getSavedLanguage();

  runApp(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: savedLocale ?? Locale('pt', 'BR'),
      fallbackLocale: Locale('en', 'US'),
      home: HomePage(),
    ),
  );
}
```

## Locale do Dispositivo

### Detectar Idioma

Use o idioma do dispositivo como padrão:

```dart
void main() {
  runApp(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: Sint.deviceLocale, // Usa idioma do dispositivo
      fallbackLocale: Locale('en', 'US'),
      home: HomePage(),
    ),
  );
}
```

**Com verificação:**

```dart
Locale getInitialLocale() {
  final deviceLocale = Sint.deviceLocale;

  // Idiomas suportados
  final supported = [
    Locale('pt', 'BR'),
    Locale('en', 'US'),
    Locale('es', 'ES'),
  ];

  // Verifica se idioma do dispositivo é suportado
  final isSupported = supported.any(
    (locale) => locale.languageCode == deviceLocale?.languageCode,
  );

  if (isSupported) {
    return deviceLocale!;
  }

  // Retorna padrão se não suportado
  return Locale('en', 'US');
}

void main() {
  runApp(
    SintMaterialApp(
      translations: AppTranslations(),
      locale: getInitialLocale(),
      fallbackLocale: Locale('en', 'US'),
      home: HomePage(),
    ),
  );
}
```

### Locale Atual

Acesse o locale atual:

```dart
// Obter locale atual
final currentLocale = Sint.locale;
print('Idioma atual: ${currentLocale?.languageCode}');

// Verificar idioma
if (Sint.locale?.languageCode == 'pt') {
  print('Aplicativo em português');
}

// Widget reativo ao locale
class LocaleDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final locale = Sint.locale;
      return Text('Idioma: ${locale?.languageCode}');
    });
  }
}
```

## Organização Avançada

### Arquivos Separados

Organize traduções em arquivos separados:

```dart
// translations/pt_br.dart
class PtBR {
  static const Map<String, String> translations = {
    'nav_home': 'Início',
    'nav_profile': 'Perfil',
    // ...
  };
}

// translations/en_us.dart
class EnUS {
  static const Map<String, String> translations = {
    'nav_home': 'Home',
    'nav_profile': 'Profile',
    // ...
  };
}

// translations/app_translations.dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'pt_BR': PtBR.translations,
    'en_US': EnUS.translations,
  };
}
```

**Por módulo:**

```dart
// translations/modules/home_translations.dart
class HomeTranslations {
  static const pt_BR = {
    'home.title': 'Início',
    'home.subtitle': 'Bem-vindo',
  };

  static const en_US = {
    'home.title': 'Home',
    'home.subtitle': 'Welcome',
  };
}

// translations/modules/profile_translations.dart
class ProfileTranslations {
  static const pt_BR = {
    'profile.title': 'Perfil',
    'profile.edit': 'Editar',
  };

  static const en_US = {
    'profile.title': 'Profile',
    'profile.edit': 'Edit',
  };
}

// translations/app_translations.dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'pt_BR': {
      ...HomeTranslations.pt_BR,
      ...ProfileTranslations.pt_BR,
    },
    'en_US': {
      ...HomeTranslations.en_US,
      ...ProfileTranslations.en_US,
    },
  };
}
```

### Carregamento Lazy

Carregue traduções sob demanda para apps grandes:

```dart
class TranslationService extends SintController {
  final _translations = <String, Map<String, String>>{}.obs;

  Future<void> loadTranslations(String locale) async {
    if (_translations.containsKey(locale)) {
      return; // Já carregado
    }

    // Simular carregamento de arquivo/API
    final json = await loadTranslationFile(locale);
    _translations[locale] = json;
  }

  String translate(String key, String locale) {
    return _translations[locale]?[key] ?? key;
  }
}
```

## Boas Práticas

1. **Use prefixos:** Organize keys com prefixos (nav_, btn_, msg_, etc.)

2. **Seja consistente:** Mantenha mesmo padrão de nomenclatura

3. **Documente:** Comente traduções complexas ou que precisam contexto

4. **Evite hardcoded strings:** Sempre use .tr para textos visíveis

5. **Teste todos os idiomas:** Verifique se todas as traduções existem

6. **Use placeholders descritivos:** `@name` é melhor que `@1`

7. **Mantenha traduções curtas:** Considere diferentes tamanhos de texto

8. **Revise por nativos:** Peça para falantes nativos revisarem

## Roteiro de Testes

### Teste 1: Configuração Básica de Traduções
**Objetivo:** Configurar sistema de traduções e exibir textos traduzidos.

**Passos:**
1. Criar classe `AppTranslations extends Translations`
2. Adicionar traduções para pt_BR e en_US (keys: 'hello', 'welcome', 'goodbye')
3. Configurar `SintMaterialApp` com `translations`, `locale` e `fallbackLocale`
4. Criar tela com `Text('hello'.tr)`
5. Executar app e verificar que texto aparece em português

**Resultado esperado:** O texto deve aparecer traduzido no idioma configurado (pt_BR).

---

### Teste 2: Mudança de Idioma em Tempo Real
**Objetivo:** Alterar idioma do app dinamicamente.

**Passos:**
1. Criar botão que chama `Sint.updateLocale(Locale('en', 'US'))`
2. Criar outro botão que chama `Sint.updateLocale(Locale('pt', 'BR'))`
3. Adicionar vários textos traduzidos na tela
4. Clicar no botão de inglês e verificar que todos os textos mudam
5. Clicar no botão de português e verificar que textos voltam

**Resultado esperado:** Todos os textos devem mudar instantaneamente ao trocar o locale.

---

### Teste 3: Traduções com Parâmetros
**Objetivo:** Inserir valores dinâmicos em traduções.

**Passos:**
1. Adicionar tradução: `'greeting': 'Olá, @name!'` em pt_BR
2. Adicionar tradução: `'greeting': 'Hello, @name!'` em en_US
3. Criar TextField para entrada de nome
4. Exibir `Text('greeting'.trParams({'name': inputName}))`
5. Digitar "João" e verificar saída em português
6. Trocar para inglês e verificar saída

**Resultado esperado:** Em pt_BR deve mostrar "Olá, João!", em en_US "Hello, João!".

---

### Teste 4: Múltiplos Parâmetros
**Objetivo:** Usar múltiplos placeholders em uma tradução.

**Passos:**
1. Adicionar: `'order_info': 'Pedido #@order de @customer está @status'`
2. Usar `.trParams()` com três parâmetros: order, customer, status
3. Exibir resultado com valores reais
4. Trocar idioma e verificar que parâmetros são mantidos

**Resultado esperado:** A frase deve conter os três valores substituídos corretamente.

---

### Teste 5: Pluralização Básica
**Objetivo:** Usar `.trPlural()` para singular/plural.

**Passos:**
1. Adicionar traduções: `'item': 'item'` e `'items': 'itens'`
2. Criar contador que varia de 0 a 5
3. Exibir `Text('item'.trPlural('items', count))`
4. Incrementar contador e observar mudança entre singular/plural
5. Verificar que 1 usa singular, outros usam plural

**Resultado esperado:** Deve mostrar "item" para 1, "itens" para qualquer outro número.

---

### Teste 6: Combinação de Pluralização com Parâmetros
**Objetivo:** Usar plural e parâmetros juntos.

**Passos:**
1. Criar tradução: `'cart_message': 'Você tem @count @item'`
2. Usar contador para quantidade de itens
3. Usar `.trPlural()` para palavra item/itens
4. Combinar com `.trParams()` para inserir quantidade
5. Testar com 1 item e 5 itens

**Resultado esperado:** "Você tem 1 item" e "Você tem 5 itens" respectivamente.

---

### Teste 7: Fallback Locale
**Objetivo:** Validar que fallback é usado quando tradução não existe.

**Passos:**
1. Configurar `locale: Locale('fr', 'FR')` (francês - sem traduções)
2. Configurar `fallbackLocale: Locale('en', 'US')`
3. Tentar usar `'hello'.tr`
4. Verificar que exibe tradução em inglês (fallback)
5. Adicionar tradução em francês e verificar que agora usa francês

**Resultado esperado:** Sem tradução em francês, deve usar inglês; com tradução em francês, deve usar francês.

---

### Teste 8: Keys Aninhadas
**Objetivo:** Organizar traduções com pontos (home.title, profile.edit).

**Passos:**
1. Criar traduções: `'home.title': 'Início'`, `'home.subtitle': 'Bem-vindo'`
2. Criar traduções: `'profile.title': 'Perfil'`, `'profile.edit': 'Editar'`
3. Usar `Text('home.title'.tr)` em uma tela
4. Usar `Text('profile.edit'.tr)` em outra
5. Verificar que todas funcionam corretamente

**Resultado esperado:** Keys aninhadas devem ser acessadas normalmente com `.tr`.

---

### Teste 9: Seletor de Idioma com PopupMenu
**Objetivo:** Criar widget de seleção de idioma.

**Passos:**
1. Criar `PopupMenuButton` com opções: Português, English, Español
2. Cada opção deve chamar `Sint.updateLocale()` com locale correspondente
3. Adicionar bandeiras emoji para cada idioma
4. Clicar em cada opção e verificar mudança de idioma
5. Verificar que toda UI é atualizada

**Resultado esperado:** Ao selecionar idioma no menu, todo app deve trocar instantaneamente.

---

### Teste 10: Persistência de Idioma
**Objetivo:** Salvar preferência de idioma e restaurar ao reiniciar.

**Passos:**
1. Criar `LanguageService` com métodos `saveLanguage()` e `getSavedLanguage()`
2. Usar SharedPreferences para persistir
3. Ao trocar idioma, salvar preferência
4. Ao iniciar app, carregar idioma salvo
5. Trocar idioma, reiniciar app (hot restart)
6. Verificar que idioma escolhido foi mantido

**Resultado esperado:** O app deve iniciar no último idioma selecionado pelo usuário.

---

### Teste 11: Locale do Dispositivo
**Objetivo:** Usar idioma do sistema como padrão.

**Passos:**
1. Configurar `locale: Sint.deviceLocale`
2. Mudar idioma do dispositivo para português
3. Iniciar app e verificar que está em português
4. Mudar idioma do dispositivo para inglês
5. Reiniciar app e verificar que está em inglês

**Resultado esperado:** O app deve respeitar o idioma configurado no sistema operacional.

---

### Teste 12: Arquivos Separados por Idioma
**Objetivo:** Organizar traduções em arquivos distintos.

**Passos:**
1. Criar `pt_br.dart` com `Map<String, String>` de traduções
2. Criar `en_us.dart` com `Map<String, String>` de traduções
3. Importar ambos em `AppTranslations`
4. Usar spread operator `...` para combinar
5. Verificar que traduções funcionam normalmente

**Resultado esperado:** Organização em arquivos separados não deve afetar funcionamento.

---

### Teste 13: Traduções por Módulo
**Objetivo:** Separar traduções de home, profile, settings em classes distintas.

**Passos:**
1. Criar `HomeTranslations`, `ProfileTranslations`, `SettingsTranslations`
2. Cada classe tem suas próprias keys com prefixo (home.*, profile.*, settings.*)
3. Combinar todas em `AppTranslations` usando spread
4. Usar traduções em cada tela correspondente
5. Verificar que não há conflito de keys

**Resultado esperado:** Traduções modulares devem funcionar e facilitar manutenção.

---

### Teste 14: Validação de Campos com Traduções
**Objetivo:** Usar traduções em mensagens de validação de formulário.

**Passos:**
1. Criar traduções para erros: `'validation.required'`, `'validation.email'`, `'validation.min_length'`
2. Criar formulário com TextField e validação
3. Se campo vazio, exibir `'validation.required'.tr`
4. Se email inválido, exibir `'validation.email'.tr`
5. Trocar idioma e verificar que mensagens de erro mudam

**Resultado esperado:** Mensagens de validação devem aparecer traduzidas no idioma correto.

---

### Teste 15: Locale Atual e Display
**Objetivo:** Acessar e exibir o locale atual.

**Passos:**
1. Criar widget que exibe `Sint.locale?.languageCode`
2. Adicionar seletor de idioma
3. Trocar idioma e verificar que display do locale muda
4. Usar `Obx` para tornar widget reativo ao locale
5. Verificar que atualiza automaticamente

**Resultado esperado:** O widget deve exibir o código do idioma atual e atualizar ao trocar.
