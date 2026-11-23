/// SINT Example — The Four Pillars (S·I·N·T)
///
/// A minimal counter app demonstrating all four pillars on Flutter 3.47+
/// standalone `material_ui`:
/// - **S**tate: Reactive `.obs` + `Obx` + `SintBuilder` + zero-Stream workers
/// - **I**njection: Single-element `MultiBinder` (`binds: [Bind.put(...)]`) + `Sint.find()`
/// - **N**avigation: `SintApp` + named routes + `SintAppBar` + `Sint.snackbar()`
/// - **T**ranslation: Reactive `.tr` / `.trParams` localized strings
library;

import 'package:material_ui/material_ui.dart';
import 'package:sint/sint.dart';

// ─── Pillar T: Translations ───────────────────────────────────

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'title': 'SINT Counter',
      'count': 'Count',
      'increment': 'Increment',
      'milestone': 'You reached @value!',
      'details': 'Details',
    },
    'es_MX': {
      'title': 'Contador SINT',
      'count': 'Cuenta',
      'increment': 'Incrementar',
      'milestone': 'Llegaste a @value!',
      'details': 'Detalles',
    },
  };
}

// ─── Pillar S: State Management ───────────────────────────────

class CounterController extends SintController {
  final count = 0.obs;
  late final doubled = computed(() => count.value * 2);

  @override
  void onInit() {
    super.onInit();
    // Zero-Stream synchronous worker: fires every time count changes
    ever(count, (value) {
      if (value % 10 == 0 && value > 0) {
        Sint.snackbar(
          'milestone'.tr,
          'milestone'.trParams({'value': '$value'}),
        );
      }
    });
  }

  void increment() => count.value++;
}

// ─── Pillar N: Navigation (Routes) ───────────────────────────

class AppRoutes {
  static const home = '/';
  static const details = '/details';

  static final pages = [
    SintPage(name: home, page: () => const HomePage()),
    SintPage(name: details, page: () => const DetailsPage()),
  ];
}

// ─── Main App ─────────────────────────────────────────────────

void main() {
  runApp(
    SintApp(
      design: SintDesign.material,
      // Pillar N: Navigation config
      title: 'SINT Example',
      initialRoute: AppRoutes.home,
      sintPages: AppRoutes.pages,
      materialTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      // Pillar N: Global snackbar style
      snackBarStyle: const SintSnackBarStyle(
        snackPosition: SnackPosition.top,
        backgroundColor: Colors.indigo,
        colorText: Colors.white,
        borderRadius: 12,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        duration: Duration(seconds: 2),
      ),
      // Pillar I: Root bindings (flattened into a single MultiBinder Element)
      binds: [Bind.put(CounterController())],
      // Pillar T: Translations
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
    ),
  );
}

// ─── Home Page ────────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Pillar I: Retrieve the injected controller
    final controller = Sint.find<CounterController>();

    return Scaffold(
      appBar: SintAppBar(
        title: 'title'.tr, // Pillar T
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Sint.toNamed(AppRoutes.details), // Pillar N
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('count'.tr, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // Pillar S: Reactive rebuild on count changes
            Obx(
              () => Text(
                '${controller.count.value} (×2 = ${controller.doubled.value})',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        tooltip: 'increment'.tr,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Details Page ─────────────────────────────────────────────

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Sint.find<CounterController>();

    return Scaffold(
      appBar: SintAppBar(title: 'details'.tr),
      body: Center(
        // Pillar S: SintBuilder alternative to Obx
        child: SintBuilder<CounterController>(
          builder: (ctrl) => Text(
            '${'count'.tr}: ${ctrl.count.value}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
