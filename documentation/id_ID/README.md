# SINT

**State, Injection, Navigation, Translation — Empat Pilar Infrastruktur Flutter Fidelitas Tinggi.**

[![pub package](https://img.shields.io/pub/v/sint.svg?label=sint&color=blue)](https://pub.dev/packages/sint)

<div align="center">

**Bahasa:**

[![English](https://img.shields.io/badge/Language-English-blueviolet?style=for-the-badge)](../../README.md)
[![Spanish](https://img.shields.io/badge/Language-Spanish-blueviolet?style=for-the-badge)](../es_ES/README.md)
[![Arabic](https://img.shields.io/badge/Language-Arabic-blueviolet?style=for-the-badge)](../ar_EG/README.md)
[![French](https://img.shields.io/badge/Language-French-blueviolet?style=for-the-badge)](../fr_FR/README.md)
[![Portuguese](https://img.shields.io/badge/Language-Portuguese-blueviolet?style=for-the-badge)](../pt_BR/README.md)
[![Russian](https://img.shields.io/badge/Language-Russian-blueviolet?style=for-the-badge)](../ru_RU/README.md)
[![Japanese](https://img.shields.io/badge/Language-Japanese-blueviolet?style=for-the-badge)](../ja_JP/README.md)
[![Chinese](https://img.shields.io/badge/Language-Chinese-blueviolet?style=for-the-badge)](../zh_CN/README.md)
[![Korean](https://img.shields.io/badge/Language-Korean-blueviolet?style=for-the-badge)](../kr_KO/README.md)
[![Indonesian](https://img.shields.io/badge/Language-Indonesian-blueviolet?style=for-the-badge)](#)
[![Turkish](https://img.shields.io/badge/Language-Turkish-blueviolet?style=for-the-badge)](../tr_TR/README.md)
[![Vietnamese](https://img.shields.io/badge/Language-Vietnamese-blueviolet?style=for-the-badge)](../vi_VI/README.md)

</div>

---

- [Tentang SINT](#tentang-sint)
- [Instalasi](#instalasi)
- [Empat Pilar](#empat-pilar)
  - [Manajemen State (S)](#manajemen-state-s)
  - [Injeksi (I)](#injeksi-i)
  - [Navigasi (N)](#navigasi-n)
  - [Terjemahan (T)](#terjemahan-t)
- [Aplikasi Counter dengan SINT](#aplikasi-counter-dengan-sint)
- [Migrasi dari GetX](#migrasi-dari-getx)
- [Asal dan Filosofi](#asal-dan-filosofi)

---

## Tentang SINT

SINT adalah evolusi arsitektural dari GetX (v5.0.0-rc), dibangun sebagai framework yang fokus hanya pada empat pilar:

| Pilar | Tanggung Jawab |
|---|---|
| **S** — Manajemen State | `SintController`, `SintBuilder`, `Obx`, `.obs`, tipe Rx, Workers |
| **I** — Injeksi | `Sint.put`, `Sint.find`, `Sint.lazyPut`, Bindings, SmartManagement |
| **N** — Navigasi | `SintPage`, `Sint.toNamed`, middleware, `SintMaterialApp`, transisi |
| **T** — Terjemahan | ekstensi `.tr`, kelas `Translations`, manajemen locale |

Semua yang berada di luar empat pilar ini telah dihapus: tidak ada klien HTTP, tidak ada animasi, tidak ada validator string, tidak ada utilitas generik. Hasilnya adalah **37.7% lebih sedikit kode** dari GetX — 12,849 LOC vs 20,615 LOC.

**Prinsip utama:**

- **PERFORMA:** Tidak ada overhead Streams atau ChangeNotifier. Konsumsi RAM minimal.
- **PRODUKTIVITAS:** Sintaks sederhana. Satu impor: `import 'package:sint/sint.dart';`
- **ORGANISASI:** Struktur Clean Architecture. 5 modul, masing-masing memetakan ke pilar.

---

## Instalasi

Tambahkan SINT ke `pubspec.yaml` Anda:

```yaml
dependencies:
  sint: ^1.0.0
```

Import:

```dart
import 'package:sint/sint.dart';
```

---

## Empat Pilar

### Manajemen State (S)

Dua pendekatan: **Reaktif** (`.obs` + `Obx`) dan **Sederhana** (`SintBuilder`).

```dart
// Reaktif
var count = 0.obs;
Obx(() => Text('${count.value}'));

// Sederhana
SintBuilder<Controller>(
  builder: (_) => Text('${_.counter}'),
)
```

[Dokumentasi lengkap](state_management.md)

### Injeksi (I)

Injeksi dependensi tanpa context:

```dart
Sint.put(AuthController());
final controller = Sint.find<AuthController>();
```

[Dokumentasi lengkap](injection_management.md)

### Navigasi (N)

Manajemen rute tanpa context:

```dart
SintMaterialApp(
  getPages: [
    SintPage(name: '/', page: () => Home()),
    SintPage(name: '/details', page: () => Details()),
  ],
)

Sint.toNamed('/details');
Sint.back();
Sint.snackbar('Title', 'Message');
```

[Dokumentasi lengkap](navigation_management.md)

### Terjemahan (T)

Internasionalisasi dengan `.tr`:

```dart
Text('hello'.tr);
Text('welcome'.trParams({'name': 'Serzen'}));
Sint.updateLocale(Locale('id', 'ID'));
```

[Dokumentasi lengkap](translation_management.md)

---

## Aplikasi Counter dengan SINT

```dart
void main() => runApp(SintMaterialApp(home: Home()));

class Controller extends SintController {
  var count = 0.obs;
  increment() => count++;
}

class Home extends StatelessWidget {
  @override
  Widget build(context) {
    final c = Sint.put(Controller());
    return Scaffold(
      appBar: AppBar(title: Obx(() => Text("Clicks: ${c.count}"))),
      body: Center(
        child: ElevatedButton(
          child: Text("Go to Other"),
          onPressed: () => Sint.to(Other()),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: c.increment,
      ),
    );
  }
}

class Other extends StatelessWidget {
  final Controller c = Sint.find();
  @override
  Widget build(context) {
    return Scaffold(body: Center(child: Text("${c.count}")));
  }
}
```

---

## Migrasi dari GetX

1. Ganti `get:` dengan `sint:` di `pubspec.yaml`
2. Ganti `import 'package:get/get.dart'` dengan `import 'package:sint/sint.dart'`
3. Panggilan `Get.` Anda yang ada akan berfungsi — ganti secara bertahap dengan `Sint.` untuk menghilangkan peringatan deprecation
4. `GetMaterialApp` → `SintMaterialApp`
5. `GetPage` → `SintPage`

---

## Asal dan Filosofi

SINT adalah hard fork dari GetX v5.0.0-rc. Setelah 8 tahun akumulasi kode, repositori GetX menjadi tidak aktif dan membawa beban yang tidak digunakan secara signifikan. SINT menghapus semua yang tidak melayani empat pilar, menghasilkan fondasi yang bersih dan dapat dipelihara yang dibangun dengan prinsip Clean Architecture.

**GetX:** "Lakukan segalanya."
**SINT:** "Lakukan hal yang benar."

**S + I + N + T** — State, Injection, Navigation, Translation. Tidak lebih, tidak kurang.

---

## Lisensi

SINT dirilis di bawah [Lisensi MIT](../../LICENSE).

Bagian dari ekosistem [Open Neom](https://github.com/Open-Neom).
