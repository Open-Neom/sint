SINT Framework
State, Injection, Navigation, Translation — The Four Pillars of High-Fidelity Flutter Infrastructure.
<div align="center">
<img src="Gemini_Generated_Image_5g3vv45g3vv45g3v.jpg" alt="SINT Shield" width="250">
</div>
"GetX was built to do everything. SINT was built to do the right things." 

🏛️ The Four Pillars
SINT reorganiza el ecosistema de Flutter en cuatro pilares esenciales, eliminando el 37.7% de la "grasa técnica" para ofrecer un núcleo quirúrgico de 12,849 líneas de código.
Pillar	Focus	Key Responsibilities
<span class="pillar-s">State</span>	Performance	SintController, Obx, and high-speed reactive Workers.
<span class="pillar-i">Injection</span>	Decoupling	Context-less dependency injection and module-aware scopes.
<span class="pillar-n">Navigation</span>	Flow	High-fidelity routing, middleware, and spatial navigation ready.
<span class="pillar-t">Translation</span>	Globalization	Integrated i18n with .tr extension as a first-class citizen.

🚀 Why SINT?
•	Sovereign Infrastructure: Un hard fork de GetX v5.0.0-rc totalmente bajo el control del SRZNVERSO, libre de dependencias externas inactivas.
•	Clean Architecture: Cada módulo sigue internamente una estructura de domain/engine/ui, separando la lógica de negocio de la implementación visual.
•	Minimalist Core: Se eliminó todo lo que no servía a los cuatro pilares: sin cliente HTTP, sin animaciones y sin validadores genéricos.
•	AI-Native Design: Estructura predecible de 5 módulos diseñada para ser navegada y optimizada eficientemente por herramientas como Claude Code.

🏁 Quick Start
Para iniciar la evolución en tus módulos, solo necesitas un punto de entrada:
Dart
import 'package:sint/sint.dart'; // One import to rule them all [cite: 23]

void main() {
Sint.put(ProfileController()); // I - Injection [cite: 23]
runApp(SintMaterialApp(home: HomeView())); // N - Navigation [cite: 23]
}

🔄 Migration from GetX
SINT 1.0.0 incluye un puente de compatibilidad para que tus módulos actuales sigan funcionando mientras realizas la transición hacia la soberanía técnica.
1.	Update Imports: Reemplaza package:get/get.dart por package:sint/sint.dart.
2.	Naming Strategy: El alias Get está marcado como @deprecated. Comienza a usar Sint. para adoptar el nuevo estándar.
3.	Pillar Alignment: Mueve tus traducciones al nuevo módulo dedicado y tus controladores a la estructura Clean sugerida.

🌐 Documentation (12 Languages)
Explore the full guides for each pillar in your preferred language:
•	English (US)
•	Español (ES)
•	日本語 (JP)
•	See all 12 languages...

S + I + N + T: Nothing more, nothing less. Built by Open Neom. 

