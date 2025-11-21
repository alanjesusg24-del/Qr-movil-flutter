# Guía de Contribución

Gracias por tu interés en contribuir a Order QR Mobile. Esta guía te ayudará a hacer contribuciones de manera efectiva.

## 📋 Tabla de Contenidos

- [Código de Conducta](#código-de-conducta)
- [Cómo Contribuir](#cómo-contribuir)
- [Configuración del Entorno](#configuración-del-entorno)
- [Estándares de Código](#estándares-de-código)
- [Proceso de Pull Request](#proceso-de-pull-request)
- [Reporte de Bugs](#reporte-de-bugs)
- [Sugerencias de Features](#sugerencias-de-features)

## 📜 Código de Conducta

Este proyecto se adhiere a un código de conducta. Al participar, se espera que mantengas un ambiente respetuoso y colaborativo.

### Nuestros Valores

- **Respeto**: Trata a todos con cortesía y profesionalismo
- **Inclusión**: Da la bienvenida a perspectivas diversas
- **Colaboración**: Trabaja en equipo y comparte conocimiento
- **Calidad**: Esfuérzate por crear código de alta calidad

## 🤝 Cómo Contribuir

Hay muchas formas de contribuir:

1. **Reportar bugs** - Encuentra y reporta errores
2. **Sugerir features** - Propón nuevas funcionalidades
3. **Mejorar documentación** - Ayuda a clarificar o expandir docs
4. **Escribir código** - Implementa features o arregla bugs
5. **Revisar PRs** - Ayuda a revisar contribuciones de otros
6. **Responder preguntas** - Ayuda en issues y discusiones

## 🛠️ Configuración del Entorno

### 1. Fork y Clone

```bash
# Fork el repositorio en GitHub, luego:
git clone https://github.com/TU_USUARIO/order_qr_mobile.git
cd order_qr_mobile

# Agregar remote upstream
git remote add upstream https://github.com/USUARIO_ORIGINAL/order_qr_mobile.git
```

### 2. Instalar Dependencias

```bash
flutter pub get
```

### 3. Configurar Firebase

Sigue las instrucciones en [INSTALLATION.md](INSTALLATION.md)

### 4. Verificar que todo funciona

```bash
# Ejecutar tests
flutter test

# Ejecutar análisis de código
flutter analyze

# Ejecutar la app
flutter run
```

## 📏 Estándares de Código

### Estilo de Código Dart

Seguimos las [Effective Dart Guidelines](https://dart.dev/guides/language/effective-dart):

```dart
// ✅ BIEN
class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Text(order.name),
    );
  }
}

// ❌ MAL
class ordercard extends StatelessWidget {
  Order o;
  ordercard(this.o);
  build(context) {
    return Card(child: Text(o.name));
  }
}
```

### Convenciones de Nombrado

- **Classes**: `PascalCase` (ej: `OrderDetailScreen`)
- **Variables/Functions**: `camelCase` (ej: `fetchOrders`)
- **Constants**: `lowerCamelCase` (ej: `maxRetries`)
- **Files**: `snake_case` (ej: `order_card.dart`)
- **Private members**: Prefijo `_` (ej: `_privateMethod`)

### Estructura de Archivos

```dart
// 1. Imports de Dart/Flutter
import 'dart:async';
import 'package:flutter/material.dart';

// 2. Imports de paquetes externos
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

// 3. Imports locales
import '../models/order.dart';
import '../services/api_service.dart';

// 4. Código
class MyWidget extends StatelessWidget {
  // ...
}
```

### Comentarios y Documentación

```dart
/// Fetches all orders for the current device from the backend.
///
/// Returns a list of [Order] objects. Throws [DioException] if
/// the network request fails.
///
/// Example:
/// ```dart
/// final orders = await apiService.fetchOrders();
/// ```
Future<List<Order>> fetchOrders() async {
  // Implementación...
}
```

### Formateo de Código

Antes de hacer commit:

```bash
# Formatear automáticamente
dart format lib/

# Verificar issues
flutter analyze
```

### Tests

Todo código nuevo debe incluir tests:

```dart
// test/services/api_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:order_qr_mobile/services/api_service.dart';

void main() {
  group('ApiService', () {
    test('fetchOrders returns list of orders', () async {
      final apiService = ApiService();
      final orders = await apiService.fetchOrders();

      expect(orders, isA<List<Order>>());
    });
  });
}
```

## 🔄 Proceso de Pull Request

### 1. Crear una Branch

```bash
# Actualizar main
git checkout main
git pull upstream main

# Crear branch descriptiva
git checkout -b feature/agregar-modo-oscuro
# o
git checkout -b fix/corregir-escaneo-qr
```

**Nomenclatura de Branches:**
- `feature/nombre-feature` - Para nuevas funcionalidades
- `fix/nombre-bug` - Para corrección de bugs
- `docs/descripcion` - Para cambios en documentación
- `refactor/descripcion` - Para refactorización
- `test/descripcion` - Para agregar/mejorar tests

### 2. Hacer Cambios

```bash
# Hacer cambios en el código
# Asegurarte de seguir los estándares

# Formatear código
dart format lib/

# Verificar análisis
flutter analyze

# Ejecutar tests
flutter test
```

### 3. Commit

Usa commits descriptivos siguiendo [Conventional Commits](https://www.conventionalcommits.org/):

```bash
git add .
git commit -m "feat: agregar modo oscuro a toda la app"
# o
git commit -m "fix: corregir crash al escanear QR inválido"
# o
git commit -m "docs: actualizar guía de instalación"
```

**Tipos de commits:**
- `feat:` - Nueva funcionalidad
- `fix:` - Corrección de bug
- `docs:` - Cambios en documentación
- `style:` - Cambios de formato (no afectan lógica)
- `refactor:` - Refactorización de código
- `test:` - Agregar o modificar tests
- `chore:` - Tareas de mantenimiento

### 4. Push y Pull Request

```bash
# Push a tu fork
git push origin feature/agregar-modo-oscuro
```

Luego en GitHub:
1. Ir a tu fork
2. Click en "Compare & pull request"
3. Llenar el template de PR:

```markdown
## Descripción
Breve descripción de los cambios

## Tipo de cambio
- [ ] Bug fix
- [ ] Nueva feature
- [ ] Breaking change
- [ ] Documentación

## Checklist
- [ ] Mi código sigue los estándares del proyecto
- [ ] He comentado código complejo
- [ ] He actualizado la documentación
- [ ] He agregado tests
- [ ] Todos los tests pasan
- [ ] No hay warnings en flutter analyze

## Screenshots (si aplica)
Agregar capturas de pantalla

## Testing
Cómo se probó este cambio
```

### 5. Code Review

- Responde a comentarios constructivamente
- Haz cambios solicitados en commits adicionales
- Una vez aprobado, se hará merge

## 🐛 Reporte de Bugs

### Antes de Reportar

1. **Busca issues existentes** - Puede que ya esté reportado
2. **Verifica que es un bug** - No un error de configuración
3. **Reproduce el bug** - Asegúrate de que es consistente

### Template de Bug Report

Crea un issue con:

```markdown
## Descripción del Bug
Descripción clara y concisa del bug

## Pasos para Reproducir
1. Ir a '...'
2. Click en '...'
3. Scroll hasta '...'
4. Ver error

## Comportamiento Esperado
Qué debería suceder

## Comportamiento Actual
Qué sucede actualmente

## Screenshots
Si es aplicable

## Entorno
- Dispositivo: [ej. Pixel 5]
- OS: [ej. Android 13]
- Versión de la app: [ej. 1.0.0]
- Flutter version: [ej. 3.24.0]

## Logs
```
Pega logs relevantes aquí
```

## Información Adicional
Cualquier contexto adicional
```

## 💡 Sugerencias de Features

### Template de Feature Request

```markdown
## Descripción de la Feature
Descripción clara de la funcionalidad propuesta

## Problema que Resuelve
¿Qué problema o necesidad aborda?

## Solución Propuesta
Cómo debería funcionar

## Alternativas Consideradas
Otras formas de resolver esto

## Mockups/Wireframes (opcional)
Imágenes o diseños si los tienes

## Beneficios
- Beneficio 1
- Beneficio 2

## Impacto en Performance
¿Afectará el rendimiento?
```

## 🎨 Guías de UI/UX

### Diseño Volt

Este proyecto usa el diseño Volt Dashboard. Al agregar componentes UI:

1. Mantén consistencia con componentes existentes
2. Usa los colores del tema en `lib/config/theme.dart`
3. Sigue el spacing y padding estándar
4. Asegura accesibilidad (contraste, tamaños táctiles)

### Componentes Reutilizables

Antes de crear un widget nuevo, verifica si ya existe en `lib/widgets/`:

- `VoltCard` - Cards estilo Volt
- `VoltButton` - Botones
- `VoltBadge` - Badges de estado
- etc.

## 🧪 Testing

### Tipos de Tests

1. **Unit Tests** - Lógica de negocio, servicios, providers
2. **Widget Tests** - UI components
3. **Integration Tests** - Flujos completos

### Cobertura de Tests

Apuntamos a >80% de cobertura:

```bash
# Generar reporte de cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 📝 Documentación

### Comentarios en Código

- Usa `///` para documentación pública
- Usa `//` para comentarios internos
- Explica el "por qué", no el "qué"

### Actualizar README

Si tu PR afecta la funcionalidad principal, actualiza:
- README.md
- INSTALLATION.md
- Changelog

## 🏆 Reconocimiento

Los contribuidores serán reconocidos en:
- README.md (sección de contribuidores)
- Releases notes
- Changelog

## 📞 Contacto

¿Tienes preguntas?

- Abre un issue con la etiqueta `question`
- Participa en GitHub Discussions
- Contacta a los maintainers

## 📚 Recursos

- [Flutter Documentation](https://docs.flutter.dev/)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Material Design Guidelines](https://material.io/design)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**¡Gracias por contribuir! 🎉**

Cada contribución, grande o pequeña, hace este proyecto mejor.
