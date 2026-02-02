---
name: 🐛 Bug Report
about: Create a report to help us maintain High-Fidelity infrastructure
title: '[BUG] '
labels: 'bug'
assignees: 'emmanuel-montoya'

---

**ATTENTION: DO NOT USE THIS FIELD TO ASK SUPPORT QUESTIONS. Use the Open Neom Discussions for that. This space is dedicated strictly to technical bug descriptions.**

**Fill in the template completely. Issues that do not respect the architectural model will be closed.**

## 🎯 Affected Pillar
Which pillar is failing?
- [ ] **S (State):** Reactivity errors or controller lifecycle issues.
- [ ] **I (Injection):** Dependency resolution or memory leaks.
- [ ] **N (Navigation):** Routing errors, middleware loops, or overlay failures.
- [ ] **T (Translation):** Localization mismatches or key resolution bugs.

## 🐛 Description
A clear and concise description of what the bug is.

## 🚀 Minimal Reproduction Code (MANDATORY)
Provide a minimal, standalone `main.dart` that demonstrates the issue using SINT standards.

```dart
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

void main() => runApp(SintMaterialApp(home: Home()));

class Controller extends SintController {
  final count = 0.obs;
  void increment() => count.value++;
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Sint.put(Controller());
    return Scaffold(
      appBar: AppBar(title: const Text("SINT Bug Reproduction")),
      body: Center(
        child: Obx(() => Text("Count: ${c.count}")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: c.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}