## [1.0.0] - 2026-02-01

🏛️ The Birth of SINT (Initial Stable Release)
SINT 1.0.0 is a hard fork and Clean Architecture evolution of GetX (v5.0.0-rc). This version marks the transition from a "do-everything" framework to a "do the right things" infrastructure, focused exclusively on four pillars: State, Injection, Navigation, and Translation.

🛠️ Key Architectural Changes

Massive Code Pruning: Removed 7,766 lines of code (~37.7%) by stripping away non-core features like the HTTP client, animations, and unused string validators.

Clean Architecture Restructuring: Reorganized the entire codebase into a modular domain/engine/ui structure for every pilar, replacing the legacy flat-file layout.

Pillar Consolidation: Unified the framework into 5 core modules (core, injection, navigation, state_manager, translation) instead of the original 9+ scattered directories.

Reactive Sovereignty: Consolidated all reactive types (Rx) into the core/ module and moved platform detection into the navigation/ module where it is actually consumed.

🔄 Compatibility & Migration

Legacy Bridge: Included a deprecated Get alias to allow a seamless migration for the existing apps.

Single Entry Point: All pillars are now accessible through a single, clean import: package:sint/sint.dart.

🌍 Documentation & Global Ready

Standardized Documentation: Shipped with complete guides for each of the four pillars in 12 languages, ensuring global adoption across the Open Neom ecosystem.