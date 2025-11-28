# Estándares de Programación Flutter - CETAM
## Manual de Auditoría y Cumplimiento Normativo

**Versión del Manual:** 3.0 (2025-11-01)  
**Propósito:** Este documento detalla TODOS los estándares obligatorios que debe cumplir la aplicación Flutter para aprobar la auditoría institucional del Centro de Desarrollo Tecnológico Aplicado de México (CETAM).

---

## 📋 ÍNDICE DE REQUISITOS

1. [Requisitos Previos de Software](#1-requisitos-previos-de-software)
2. [Estructura del Proyecto](#2-estructura-del-proyecto)
3. [Estándares de Nomenclatura](#3-estándares-de-nomenclatura)
4. [Documentación Obligatoria](#4-documentación-obligatoria)
5. [Estructuras de Control](#5-estructuras-de-control)
6. [Lógica de Dominio y Datos](#6-lógica-de-dominio-y-datos)
7. [Estándares de Frontend](#7-estándares-de-frontend)
8. [Diseño de Interfaz](#8-diseño-de-interfaz)

---

## 1. REQUISITOS PREVIOS DE SOFTWARE

### ✅ Versiones Obligatorias (CRÍTICO)

**PROHIBIDO usar versiones diferentes a las especificadas:**

```yaml
# Requisitos de versión estrictos
Flutter SDK: 3.24.x (canal stable únicamente)
Dart: 3.x (null safety OBLIGATORIO)
Pub: Gestor incluido en Flutter SDK
```

### Lineamientos de Versión:
- ✅ **PERMITIDO:** Canal `stable` de Flutter
- ❌ **PROHIBIDO:** Canales `beta`, `dev`, o `master`
- ✅ **OBLIGATORIO:** Usar FVM para fijar versiones
- ✅ **OBLIGATORIO:** Archivo `.fvm/fvm_config.json` debe estar presente

### Entorno de Desarrollo Aprobado:
- **Visual Studio Code:** v1.90 o superior
- **Android Studio:** v2025.1.1 o superior

---

## 2. ESTRUCTURA DEL PROYECTO

### 2.1 Jerarquía de Carpetas Obligatoria

```
lib/
├── main.dart                    # Punto de entrada obligatorio
├── core/                        # Elementos globales reutilizables
│   ├── config/                  # Configuración general
│   ├── connection/              # Gestión de conexiones externas
│   ├── constants/               # Valores fijos (colores, fuentes, textos)
│   ├── errors/                  # Manejo centralizado de errores
│   ├── theme/                   # Temas visuales (light/dark)
│   ├── usecases/               # Casos de uso generales
│   └── widgets/                # Widgets reutilizables globales
│
└── features/                    # Módulos funcionales
    └── [module_name]/          # Nombre en snake_case
        ├── business/           # Lógica de negocio
        ├── data/              # Modelos y repositorios
        └── presentation/      # Elementos visuales
            ├── screens/       # Pantallas principales
            ├── widgets/       # Componentes del módulo
            └── dialogs/       # Ventanas emergentes
```

### 2.2 Reglas de Nomenclatura de Módulos

**FORMATO OBLIGATORIO:** `snake_case`

✅ **CORRECTO:**
```
auth
user_management
product_catalog
order_tracking
```

❌ **INCORRECTO:**
```
Auth
userManagement
ProductCatalog
order-tracking
```

### 2.3 Archivos Barrel (OBLIGATORIO)

**Cada módulo DEBE tener su archivo de exportación:**

```dart
// Nomenclatura: [module_name]_exports.dart
// Ejemplos:
auth_exports.dart
user_exports.dart
core_widgets_exports.dart

// CONTENIDO PERMITIDO: Solo exports
export 'screens/login_screen.dart';
export 'widgets/user_card.dart';
```

❌ **PROHIBIDO:** Archivo de exportación global en `/lib/`

---

## 3. ESTÁNDARES DE NOMENCLATURA

### 3.1 Convenciones Generales (CRÍTICO)

```yaml
Idioma: Inglés técnico (OBLIGATORIO)
Sangría: 2 espacios (NO tabuladores)
Longitud máxima de línea: 120 caracteres
Excepciones permitidas:
  - Cadenas literales extensas (SQL, JSON, HTML)
  - URLs y rutas
  - Código autogenerado
```

### 3.2 Posición de Llaves (ESTRICTO)

#### Clases y Métodos:
```dart
// ✅ CORRECTO: Llave en línea siguiente
class UserController
{
  void fetchUsers()
  {
    // código
  }
}
```

#### Estructuras de Control:
```dart
// ✅ CORRECTO: Llave en misma línea
if (condition) {
  // código
}

for (var item in items) {
  // código
}

while (isRunning) {
  // código
}
```

#### Llave de Cierre:
```dart
// ✅ CORRECTO: En su propia línea, mismo nivel de sangría
class Example
{
  void method()
  {
    if (condition) {
      // código
    } // <-- mismo nivel que 'if'
  } // <-- mismo nivel que 'void'
} // <-- mismo nivel que 'class'
```

### 3.3 Nomenclatura en Dart

| Elemento | Formato | Ejemplo |
|----------|---------|---------|
| **Clases** | PascalCase | `User`, `OrderDetail` |
| **Controladores** | PascalCase + Controller | `UserController`, `LoginController` |
| **Servicios** | PascalCase + Service | `AuthService`, `PaymentService` |
| **Repositorios** | PascalCase + Repository | `UserRepository`, `ProductRepository` |
| **Métodos** | camelCase | `getUserList()`, `calculateTotal()` |
| **Variables** | camelCase | `userName`, `orderCount` |
| **Constantes** | UPPER_SNAKE_CASE | `DEFAULT_PAGE_SIZE`, `MAX_RETRY_COUNT` |
| **Colecciones** | camelCase plural | `users`, `pendingOrders` |
| **Booleanos** | is/has/can/should | `isActive`, `hasErrors`, `canProceed` |

### 3.4 Nomenclatura en Archivos

```yaml
Archivos y carpetas: snake_case
Ejemplos:
  ✅ login_page.dart
  ✅ user_card_widget.dart
  ✅ auth_service.dart
  
  ❌ LoginPage.dart
  ❌ userCard.dart
  ❌ Auth-Service.dart
```

### 3.5 Sufijos Obligatorios por Tipo

```dart
// Clases deben terminar con su tipo específico
AuthService          // Servicio
UserModel           // Modelo
UserEntity          // Entidad
HomeScreen          // Pantalla
UserCardWidget      // Widget
UserController      // Controlador
UserRepository      // Repositorio
ConfirmDialog       // Diálogo
RegisterUseCase     // Caso de uso
DateHelper          // Helper
StringUtils         // Utilidad
ServerException     // Excepción
ValidationError     // Error
InputValidator      // Validador
AppTheme            // Tema
AuthState           // Estado
ThemeCubit          // Cubit
UserBloc            // Bloc
SettingsProvider    // Provider
```

### 3.6 Identificación de Proyectos

```yaml
Código corto (2-4 letras mayúsculas):
  Ejemplos: CS, EMM, ABT

Slug (kebab-case):
  Ejemplos: cs, expo-mm, abasto-facil

Uso obligatorio en:
  - Application ID (Android)
  - Paquete Dart (pubspec.yaml)
  - Archivos .env
```

---

## 4. DOCUMENTACIÓN OBLIGATORIA

### 4.1 Cabecera de Prólogo (OBLIGATORIA EN CADA ARCHIVO)

**TODOS los archivos creados manualmente deben incluir:**

```dart
/*
 * ============================================================================
 * Project:        [Nombre del Proyecto - Siglas]
 * File:           [nombre_del_archivo.dart]
 * Author:         [Nombre Completo]
 * Creation Date:  [YYYY-MM-DD]
 * Last Modified:  [YYYY-MM-DD]
 * Version:        [X.Y.Z]
 * Description:    [Descripción clara y concisa del propósito del archivo]
 * Dependencies:   [Librerías o servicios externos utilizados]
 * Notes:          [Observaciones adicionales, si aplica]
 * ============================================================================
 */

// Código comienza aquí
```

### 4.2 Comentarios de Documentación (///)

**OBLIGATORIO en:**
- Todas las clases públicas
- Todos los métodos públicos
- Todos los widgets

```dart
/// Represents a user in the system.
///
/// This class contains all the user information including
/// authentication details and profile data.
///
/// Example:
/// ```dart
/// final user = User(
///   id: '123',
///   name: 'John Doe',
///   email: 'john@example.com',
/// );
/// ```
class User {
  /// The unique identifier for the user.
  final String id;
  
  /// The full name of the user.
  final String name;
  
  /// Creates a new [User] instance.
  ///
  /// Throws [ArgumentError] if [id] is empty.
  User({
    required this.id,
    required this.name,
  });
}
```

### 4.3 Comentarios Inline

**Reglas:**
- Máximo 100 caracteres por línea
- Siempre ARRIBA de la línea referenciada
- Alineados con el código

```dart
// ✅ CORRECTO
// Calculate the total price including tax
final totalPrice = price * (1 + taxRate);

// ❌ INCORRECTO
final totalPrice = price * (1 + taxRate); // Calculate total
```

### 4.4 Versionado Semántico (SemVer)

**Formato OBLIGATORIO:** `MAJOR.MINOR.PATCH`

```yaml
1.0.0 - Primera versión estable
1.1.0 - Nueva funcionalidad compatible
1.1.5 - Corrección de errores
2.0.0 - Cambios incompatibles (breaking changes)
```

---

## 5. ESTRUCTURAS DE CONTROL

### 5.1 Condicionales

**Llaves SIEMPRE obligatorias:**

```dart
// ✅ CORRECTO
if (isValid) {
  processData();
}

if (status == 'active') {
  enableFeature();
} else {
  disableFeature();
}

// ❌ PROHIBIDO (sin llaves)
if (isValid) processData();
if (status == 'active') enableFeature();
```

**Uso de switch para múltiples alternativas:**

```dart
// ✅ PREFERIDO cuando hay 3+ opciones
switch (userRole) {
  case 'admin':
    showAdminPanel();
    break;
  case 'user':
    showUserDashboard();
    break;
  default:
    showGuestView();
}
```

**Operador ternario (uso limitado):**

```dart
// ✅ PERMITIDO para asignaciones simples
final message = isSuccess ? 'Success' : 'Failed';

// ❌ PROHIBIDO para lógica compleja
final result = condition1 
    ? (condition2 ? value1 : value2) 
    : (condition3 ? value3 : value4);
```

### 5.2 Ciclos

**Llaves SIEMPRE obligatorias:**

```dart
// ✅ CORRECTO: foreach (preferido)
for (var user in users) {
  print(user.name);
}

// ✅ CORRECTO: for con índice (solo cuando sea necesario)
for (var i = 0; i < items.length; i++) {
  print('Item $i: ${items[i]}');
}

// ⚠️ PERMITIDO: while (casos excepcionales)
while (hasMoreData) {
  fetchData();
}

// ❌ PROHIBIDO: sin llaves
for (var user in users) print(user.name);
```

### 5.3 Funciones de Alto Orden (PREFERIDAS)

```dart
// ✅ PREFERIDO: Usar funciones de alto orden
final activeUsers = users.where((user) => user.isActive).toList();
final userNames = users.map((user) => user.name).toList();
final totalPrice = prices.reduce((a, b) => a + b);
final hasAdmin = users.any((user) => user.role == 'admin');

// ❌ EVITAR: Bucles manuales para operaciones simples
List<User> activeUsers = [];
for (var user in users) {
  if (user.isActive) {
    activeUsers.add(user);
  }
}
```

### 5.4 Límite de Anidamiento

**MÁXIMO 3 niveles de anidamiento:**

```dart
// ❌ PROHIBIDO: Demasiado anidamiento
void processOrder(Order order) {
  if (order != null) {
    if (order.isValid) {
      if (order.items.isNotEmpty) {
        if (order.user.isActive) {
          // código
        }
      }
    }
  }
}

// ✅ CORRECTO: Usar early returns
void processOrder(Order order) {
  if (order == null) return;
  if (!order.isValid) return;
  if (order.items.isEmpty) return;
  if (!order.user.isActive) return;
  
  // código principal
}
```

### 5.5 Guard Clauses (OBLIGATORIO)

```dart
// ✅ CORRECTO: Guard clauses
String getUserEmail(User? user) {
  if (user == null) return '';
  if (user.email.isEmpty) return 'No email';
  
  return user.email;
}

// ❌ EVITAR: Anidamiento innecesario
String getUserEmail(User? user) {
  if (user != null) {
    if (user.email.isNotEmpty) {
      return user.email;
    }
  }
  return '';
}
```

### 5.6 List.generate y ListView.builder

```dart
// ✅ List.generate
List<Widget> items = List.generate(
  10,
  (index) => ListTile(
    title: Text('Item $index'),
  ),
);

// ✅ ListView.builder
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      title: Text(items[index].name),
    );
  },
)
```

---

## 6. LÓGICA DE DOMINIO Y DATOS

### 6.1 Arquitectura MVVM (OBLIGATORIO)

```
Model (Modelo)
├── Lógica de negocio
├── Entidades de datos
└── Repositorios y servicios

View (Vista)
├── Widgets (StatelessWidget/StatefulWidget)
└── NO contiene lógica de negocio

ViewModel
├── Gestión de estado
├── Intermediario Model-View
└── Notificadores de cambios
```

**Gestores de Estado Permitidos:**
- ✅ setState (nativo)
- ✅ InheritedWidget (nativo)
- ✅ Provider
- ✅ BLoC / Cubit
- ✅ Riverpod
- ✅ GetX

### 6.2 Modelos y Entidades

**Requisitos obligatorios:**

```dart
// ✅ CORRECTO: Modelo inmutable con métodos de conversión
class User {
  final String id;
  final String name;
  final String email;
  
  const User({
    required this.id,
    required this.name,
    required this.email,
  });
  
  // OBLIGATORIO: fromJson
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
  
  // OBLIGATORIO: toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
```

### 6.3 Manejo de Excepciones (OBLIGATORIO)

**Todas las llamadas a API/BD deben usar try/catch:**

```dart
// ✅ CORRECTO
Future<List<User>> fetchUsers() async {
  try {
    final response = await http.get(Uri.parse(apiUrl));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw ServerException('Failed to load users');
    }
  } on SocketException {
    throw NetworkException('No internet connection');
  } on ServerException {
    rethrow;
  } catch (e) {
    throw UnknownException('Unexpected error: $e');
  }
}

// Uso en UI
void loadUsers() async {
  try {
    final users = await fetchUsers();
    setState(() => _users = users);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}
```

**Configuración global obligatoria:**

```dart
// En main.dart
void main() {
  FlutterError.onError = (details) {
    // Log error
    print('Flutter Error: ${details.exception}');
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    // Log uncaught error
    print('Uncaught Error: $error');
    return true;
  };
  
  runApp(MyApp());
}
```

### 6.4 Internacionalización (i18n) - OBLIGATORIO

**Dependencias requeridas:**

```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

**Configuración l10n.yaml (raíz del proyecto):**

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/flutter_gen
nullable-getter: false
```

**Archivos .arb obligatorios:**

```json
// lib/l10n/app_en.arb
{
  "@@locale": "en",
  "app_title": "My App",
  "welcome_message": "Welcome, {userName}!",
  "@welcome_message": {
    "description": "Welcome message with username",
    "placeholders": {
      "userName": {
        "type": "String"
      }
    }
  },
  "item_count": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@item_count": {
    "description": "Number of items with pluralization"
  }
}

// lib/l10n/app_es.arb
{
  "@@locale": "es",
  "app_title": "Mi App",
  "welcome_message": "Bienvenido, {userName}!",
  "item_count": "{count, plural, =0{Sin artículos} =1{1 artículo} other{{count} artículos}}"
}
```

**Inicialización en MaterialApp:**

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ...
)

// Uso en widgets
Text(AppLocalizations.of(context)!.app_title)
Text(AppLocalizations.of(context)!.welcome_message('John'))
```

**Reglas de nomenclatura para keys:**

```yaml
Formato: snake_case
Agrupación por contexto:
  - home_title, home_subtitle
  - action_save, action_cancel
  - error_network, error_unauthorized
  - form_email_label, form_email_hint

❌ PROHIBIDO: concatenación de strings
✅ CORRECTO: uso de placeholders
```

### 6.5 Cliente HTTP (OBLIGATORIO: Dio)

**Configuración estándar:**

```dart
import 'package:dio/dio.dart';

class ApiClient {
  late final Dio _dio;
  
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 20),
      sendTimeout: Duration(seconds: 20),
    ));
    
    // OBLIGATORIO: Interceptor de logging (solo dev)
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
    
    // OBLIGATORIO: Headers comunes
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Authorization'] = 'Bearer $token';
        options.headers['X-Trace-Id'] = generateTraceId();
        return handler.next(options);
      },
      onError: (error, handler) async {
        // OBLIGATORIO: Retry con backoff exponencial
        if (error.response?.statusCode == 500 ||
            error.type == DioExceptionType.connectionTimeout) {
          return handler.resolve(await _retry(error.requestOptions));
        }
        return handler.next(error);
      },
    ));
  }
  
  Future<Response> _retry(RequestOptions options) async {
    await Future.delayed(Duration(seconds: 2));
    return _dio.fetch(options);
  }
}
```

**Mapeo de errores obligatorio:**

```dart
Future<User> getUser(String id) async {
  try {
    final response = await _dio.get('/users/$id');
    return User.fromJson(response.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      throw AuthException('Unauthorized');
    } else if (e.response?.statusCode == 404) {
      throw NotFoundException('User not found');
    } else if (e.type == DioExceptionType.connectionTimeout) {
      throw NetworkException('Connection timeout');
    } else {
      throw UnknownException(e.message ?? 'Unknown error');
    }
  }
}
```

---

## 7. ESTÁNDARES DE FRONTEND

### 7.1 Distribución de Pantalla OBLIGATORIA

**Estructura estándar de todas las pantallas:**

```dart
Scaffold(
  appBar: AppBar(
    // OBLIGATORIO: AppBar fijo en parte superior
    title: Text('Screen Title'),
    actions: [/* Botones de acción alineados a la derecha */],
  ),
  drawer: Drawer(
    // OBLIGATORIO: Drawer para menú lateral
    child: Column(
      children: [
        DrawerHeader(/* Logo + Usuario */),
        ListTile(/* Opciones de navegación */),
        // ...
      ],
    ),
  ),
  body: /* Contenido principal */,
)
```

**Menú Lateral (Drawer) - Estructura Obligatoria:**

```dart
Drawer(
  child: Column(
    children: [
      // 1. Header OBLIGATORIO
      DrawerHeader(
        child: Row(
          children: [
            Image.asset('assets/logo.png', width: 40),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Company Name', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('user@example.com', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      
      // 2. Opciones de navegación
      ListTile(
        leading: Icon(Icons.home),
        title: Text('Inicio'),
        onTap: () => Navigator.pushNamed(context, '/home'),
      ),
      // ...
    ],
  ),
)
```

### 7.2 Fuente Tipográfica

**OBLIGATORIO: Roboto (default de Material Design 3)**

```dart
// Ya incluida por defecto, no requiere configuración adicional
// Si se necesita personalizar:
ThemeData(
  fontFamily: 'Roboto',
  textTheme: TextTheme(
    displayLarge: TextStyle(fontFamily: 'Roboto'),
    // ...
  ),
)
```

### 7.3 Íconos Obligatorios

**Tabla de referencia obligatoria:**

| Acción | Ícono | Código |
|--------|-------|--------|
| Inicio | 🏠 | `Icons.home` |
| Regresar | ⬅️ | `Icons.arrow_back` |
| Siguiente | ➡️ | `Icons.arrow_forward` |
| Crear | ➕ | `Icons.add` |
| Editar | ✏️ | `Icons.edit_square` |
| Eliminar | 🗑️ | `Icons.delete` |
| Guardar | ✅ | `Icons.check_circle` |
| Cancelar | ❌ | `Icons.cancel` |
| Ver | 👁️ | `Icons.visibility` |
| Buscar | 🔍 | `Icons.search` |
| Actualizar | 🔄 | `Icons.autorenew` |
| Descargar | ⬇️ | `Icons.download` |
| Configuración | ⚙️ | `Icons.settings` |
| Usuario | 👤 | `Icons.person` |
| Notificación | ⚠️ | `Icons.warning` |
| Confirmación | ✔️ | `Icons.check` |

**Tamaños permitidos:**
- Chico: 16px
- Mediano: 24px (default)
- Grande: 32px

### 7.4 Mensajes y Alertas

**7.4.1 Guía de Microcopy:**

```yaml
Principios:
  - Claridad: Frases breves sin tecnicismos
  - Empatía: Enfocado en ayudar, no culpar
  - Acción: Verbos en imperativo positivo

Acciones estándar:
  Aceptar: Confirmar operación
  Cancelar: Detener proceso
  Guardar: Almacenar información
  Enviar: Finalizar formulario
  Editar: Modificar datos
  Reintentar: Repetir acción fallida
  Volver: Regresar sin perder progreso
  Continuar: Avanzar al siguiente paso
  Cerrar: Salir de ventana
  Eliminar: Borrar definitivamente (requiere confirmación)
```

**7.4.2 Tipos de Alertas Obligatorias:**

```dart
// 1. ⚠️ ADVERTENCIA (Warning)
AlertDialog(
  icon: Icon(Icons.warning, color: Color(0xFFF3C78E), size: 32),
  title: Text('Advertencia'),
  content: Text('Esta acción requiere atención'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Aceptar'),
    ),
  ],
)

// 2. ℹ️ INFORMATIVA (Info)
AlertDialog(
  icon: Icon(Icons.info, color: Color(0xFF2361CE), size: 32),
  title: Text('Información'),
  content: Text('Proceso completado'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Aceptar'),
    ),
  ],
)

// 3. ✅ ÉXITO (Success)
AlertDialog(
  icon: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
  title: Text('Operación exitosa'),
  content: Text('Los datos se guardaron correctamente'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Aceptar'),
    ),
  ],
)

// 4. ❌ ERROR (Danger)
AlertDialog(
  icon: Icon(Icons.error, color: Color(0xFFE11D48), size: 32),
  title: Text('Error'),
  content: Text('No se pudo completar la operación'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Aceptar'),
    ),
  ],
)

// 5. ❓ CONFIRMACIÓN (Continuar)
AlertDialog(
  icon: Icon(Icons.help, color: Color(0xFF4F46E5), size: 32),
  title: Text('Confirmación'),
  content: Text('¿Desea proceder con la operación?'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context, false),
      child: Text('Cancelar'),
    ),
    ElevatedButton(
      onPressed: () => Navigator.pop(context, true),
      child: Text('Continuar'),
    ),
  ],
)
```

### 7.5 Tamaños Estándar de Componentes

**7.5.1 Botones y Acciones:**

| Tamaño | Altura | Ancho mínimo | Radio |
|--------|--------|--------------|-------|
| Pequeño | 36px | 100px | 6px |
| Mediano | 44px | 140px | 8px |
| Grande | 52px | 180px | 10px |
| Extra grande | 64px | 220px | 12px |

```dart
// Implementación
ElevatedButton(
  style: ElevatedButton.styleFrom(
    minimumSize: Size(140, 44), // Mediano
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  onPressed: () {},
  child: Text('Guardar'),
)

// IconButton
IconButton(
  iconSize: 24, // Usar campo 'altura' de la tabla
  icon: Icon(Icons.save),
  onPressed: () {},
)

// FloatingActionButton
FloatingActionButton.small(/* Pequeño */)
FloatingActionButton(/* Estándar - Mediano */)
FloatingActionButton.large(/* Grande */)
```

**7.5.2 Campos de Texto:**

| Tamaño | Ancho mínimo |
|--------|--------------|
| Pequeño | 100px |
| Mediano | 175px |
| Grande | 280px |
| Extra grande | 375px |

```dart
// TODOS los campos: altura fija 60px, radio 8px
SizedBox(
  width: 175, // Mediano
  height: 60, // FIJO
  child: TextField(
    decoration: InputDecoration(
      labelText: 'Email',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // FIJO
      ),
    ),
  ),
)

// Campo para texto extenso (>100 palabras)
SizedBox(
  width: 375, // Mínimo
  height: 120, // Variable, >60px
  child: TextField(
    maxLines: 5,
    decoration: InputDecoration(
      labelText: 'Descripción',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
)
```

**7.5.3 Selectores y Controles:**

| Tamaño | Dimensión |
|--------|-----------|
| Pequeño | 20px |
| Mediano | 28px |
| Grande | 36px |
| Extra grande | 44px |

```dart
// Checkbox, Radio, Switch: radio fijo 4px
Checkbox(
  value: isChecked,
  onChanged: (value) {},
  // Radio aplicado automáticamente
)

Radio(
  value: selectedValue,
  groupValue: groupValue,
  onChanged: (value) {},
)

Switch(
  value: isEnabled,
  onChanged: (value) {},
)
```

**7.5.4 Tarjetas y Contenedores:**

| Tamaño | Altura mínima | Ancho | Radio |
|--------|---------------|-------|-------|
| Pequeño | 60px | 40% pantalla | 6px |
| Mediano | 80px | 50% pantalla | 8px |
| Grande | 100px | 60% pantalla | 10px |
| Extra grande | 140px | 70% o total | 12px |

```dart
Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8), // Mediano
  ),
  child: Container(
    width: double.infinity, // Ancho total
    height: 80, // Altura mínima
    child: ListTile(
      title: Text('Card Title'),
      subtitle: Text('Card Content'),
    ),
  ),
)
```

**7.5.5 Avatares e Imágenes:**

| Tamaño | Dimensiones | Radio |
|--------|-------------|-------|
| Pequeño | 64px | 12px |
| Mediano | 96px | 16px |
| Grande | 128px | 20px |
| Extra grande | 180px | 24px |

```dart
CircleAvatar(
  radius: 48, // 96px mediano (dimensiones/2)
  backgroundImage: NetworkImage(imageUrl),
)

// Imágenes paisaje/informativas: ancho completo, altura mínima 220px
Image.network(
  imageUrl,
  width: double.infinity,
  height: 240,
  fit: BoxFit.cover,
)
```

### 7.6 Mapeo de Acciones y Colores

**Tabla de colores por acción:**

| Acción | Color | Ícono | Descripción |
|--------|-------|-------|-------------|
| Crear | `Color(0xFF4F46E5)` (Indigo) | `Icons.add` | Inicia nuevo registro |
| Guardar | `Color(0xFF4F46E5)` (Indigo) | `Icons.check_circle` | Confirma cambios |
| Editar | `Color(0xFFCED4DA)` (Gray-400) | `Icons.edit_square` | Modifica registros |
| Eliminar | `Color(0xFFE11D48)` (Danger) | `Icons.delete` | Acción irreversible |
| Cancelar | `Color(0xFFE11D48)` (Danger) | `Icons.cancel` | Cancela acción |
| Actualizar | `Color(0xFFADB5BD)` (Gray-500) | `Icons.autorenew` | Reintenta/recarga |
| Descargar | `Color(0xFF6C757D)` (Gray-600) | `Icons.download` | Descarga archivo |
| Ver | `Color(0xFF7C3AED)` (Purple) | `Icons.visibility` | Modo lectura |
| Buscar | `Color(0xFFADB5BD)` (Gray-500) | `Icons.search` | Inicia búsqueda |
| Configuración | `Color(0xFFADB5BD)` (Gray-500) | `Icons.settings` | Accede a ajustes |
| Confirmar | `Color(0xFF2361CE)` (Info) | `Icons.check` | Confirma operación |

---

## 8. DISEÑO DE INTERFAZ

### 8.1 Paleta de Colores Institucional CETAM

**OBLIGATORIO para todos los proyectos internos:**

```dart
class AppColors {
  // Colores principales
  static const primary = Color(0xFF1F2937);
  static const secondary = Color(0xFFFB503B);
  static const tertiary = Color(0xFF31316A);
  
  // Estados
  static const success = Color(0xFF10B981);
  static const info = Color(0xFF2361CE);
  static const warning = Color(0xFFF3C78E);
  static const danger = Color(0xFFE11D48);
  
  // Base
  static const white = Color(0xFFFFFFFF);
  static const indigo = Color(0xFF4F46E5);
  static const purple = Color(0xFF7C3AED);
  
  // Grises
  static const gray50 = Color(0xFFF8F9FA);
  static const gray100 = Color(0xFFF1F3F5);
  static const gray200 = Color(0xFFE9ECEF);
  static const gray300 = Color(0xFFDEE2E6);
  static const gray400 = Color(0xFFCED4DA);
  static const gray500 = Color(0xFFADB5BD);
  static const gray600 = Color(0xFF6C757D);
  static const gray700 = Color(0xFF495057);
  static const gray800 = Color(0xFF343A40);
  static const gray900 = Color(0xFF212529);
  
  // Rojos
  static const red100 = Color(0xFFFBBAB5);
  static const red200 = Color(0xFFFBAEA7);
}
```

**Configuración de tema obligatoria:**

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    tertiary: AppColors.tertiary,
    error: AppColors.danger,
    surface: AppColors.white,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.indigo,
      foregroundColor: AppColors.white,
    ),
  ),
  // ...
)
```

### 8.2 Proyectos Externos

**Para clientes externos al CETAM:**
- Seguir lineamientos y colores acordados con el cliente
- Mantener estructura clara y accesible
- Documentar paleta de colores personalizada en archivo separado
- Respetar todas las demás reglas de este manual

---

## ✅ CHECKLIST DE AUDITORÍA

### Pre-Auditoría (Verificar ANTES de solicitar revisión)

#### 1. Versiones de Software
- [ ] Flutter SDK 3.24.x (canal stable)
- [ ] Dart 3.x con null safety
- [ ] Archivo `.fvm/fvm_config.json` presente
- [ ] VS Code 1.90+ o Android Studio 2025.1.1+

#### 2. Estructura del Proyecto
- [ ] Carpeta `/lib/core/` con todas las subcarpetas obligatorias
- [ ] Carpeta `/lib/features/` con módulos en snake_case
- [ ] Cada módulo tiene `business/`, `data/`, `presentation/`
- [ ] Cada `presentation/` tiene `screens/`, `widgets/`, `dialogs/`
- [ ] Todos los módulos tienen su archivo `_exports.dart`

#### 3. Nomenclatura
- [ ] Clases en PascalCase con sufijos correctos
- [ ] Archivos y carpetas en snake_case
- [ ] Variables y métodos en camelCase
- [ ] Constantes en UPPER_SNAKE_CASE
- [ ] Booleanos con prefijos is/has/can/should

#### 4. Documentación
- [ ] TODOS los archivos manuales tienen cabecera de prólogo
- [ ] Todas las clases públicas tienen comentarios ///
- [ ] Todos los métodos públicos documentados
- [ ] Versionado semántico en pubspec.yaml

#### 5. Llaves y Formato
- [ ] Clases y métodos: llave en línea siguiente
- [ ] Estructuras de control: llave en misma línea
- [ ] Todas las llaves de cierre en su propia línea
- [ ] Máximo 120 caracteres por línea (excepciones justificadas)
- [ ] Sangría de 2 espacios (no tabs)
- [ ] Llaves SIEMPRE presentes (no omitir)

#### 6. Estructuras de Control
- [ ] Máximo 3 niveles de anidamiento
- [ ] Early returns implementados
- [ ] Funciones de alto orden preferidas sobre bucles
- [ ] No hay condicionales sin llaves
- [ ] Switch usado para múltiples alternativas

#### 7. Lógica de Negocio
- [ ] Arquitectura MVVM implementada
- [ ] Modelos con fromJson() y toJson()
- [ ] Try/catch en todas las llamadas a API
- [ ] Manejadores globales de errores configurados
- [ ] Cliente HTTP (Dio) con interceptors
- [ ] Retry con backoff exponencial

#### 8. Internacionalización
- [ ] flutter_localizations configurado
- [ ] Archivo `l10n.yaml` en raíz
- [ ] Archivos .arb en `lib/l10n/`
- [ ] Keys en snake_case
- [ ] Sin concatenación de strings
- [ ] MaterialApp configurado con delegates

#### 9. UI/Frontend
- [ ] Todas las pantallas con AppBar fijo
- [ ] Drawer con logo + usuario
- [ ] Íconos según tabla obligatoria
- [ ] Alertas con colores y formato correcto
- [ ] Fuente Roboto (default MD3)

#### 10. Tamaños de Componentes
- [ ] Botones según tabla de tamaños
- [ ] Campos de texto: altura 60px, radio 8px
- [ ] Selectores con radio 4px
- [ ] Tarjetas con anchos/alturas mínimas
- [ ] Avatares según dimensiones especificadas

#### 11. Colores
- [ ] Paleta CETAM implementada (proyectos internos)
- [ ] Clase AppColors definida
- [ ] Theme configurado con ColorScheme
- [ ] Mapeo de acciones y colores respetado

#### 12. Calidad de Código
- [ ] `dart analyze` sin errores
- [ ] `dart format` aplicado
- [ ] Null safety habilitado
- [ ] Sin warnings en consola
- [ ] Tipado fuerte (no dynamic sin justificar)

---

## 📝 NOTAS FINALES PARA AUDITORÍA

### Criterios de Aprobación
Para que la aplicación sea **APROBADA**, debe cumplir:

1. **100% de requisitos CRÍTICOS** (marcados como OBLIGATORIO)
2. **95%+ de requisitos ESTRICTOS** (marcados como PROHIBIDO/PERMITIDO)
3. **90%+ de mejores prácticas** (marcados como PREFERIDO/RECOMENDADO)

### Causas de Rechazo Inmediato
La aplicación será **RECHAZADA automáticamente** si:

- ❌ Usa versiones NO autorizadas de Flutter/Dart
- ❌ Falta la estructura obligatoria de carpetas
- ❌ Archivos sin cabecera de prólogo
- ❌ Código sin tipado fuerte
- ❌ APIs sin manejo de errores
- ❌ UI sin internacionalización
- ❌ Colores incorrectos (proyectos CETAM)
- ❌ Más de 3 niveles de anidamiento
- ❌ Código sin llaves obligatorias

### Proceso de Corrección
Si la auditoría detecta incumplimientos:

1. Se generará reporte detallado con ubicaciones exactas
2. Se priorizarán correcciones por severidad (crítico > alto > medio > bajo)
3. Plazo máximo de corrección: 5 días hábiles
4. Re-auditoría completa después de correcciones

---

## 🚀 COMANDOS ÚTILES

```bash
# Verificar versiones
flutter --version
dart --version

# Análisis estático
dart analyze

# Formateo de código
dart format lib/ --set-exit-if-changed

# Generar traducciones
flutter gen-l10n

# Verificar dependencias
flutter pub outdated
flutter pub get

# Tests
flutter test

# Build release
flutter build apk --release
flutter build ios --release
```

---

## 📚 REFERENCIAS

- [Effective Dart: Style](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Lints Package](https://pub.dev/packages/flutter_lints)
- [Material Design 3](https://m3.material.io/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Dio Package](https://pub.dev/packages/dio)

---

**Versión del documento:** 1.0  
**Fecha de creación:** 2025-11-27  
**Basado en:** Manual de Programación Flutter CETAM v3.0 (2025-11-01)

---

## ⚖️ DECLARACIÓN DE CUMPLIMIENTO

Al finalizar la auditoría, el desarrollador debe firmar:

> "Declaro que he revisado este documento completo y que la aplicación Flutter cumple al 100% con todos los estándares OBLIGATORIOS y CRÍTICOS establecidos por CETAM. Cualquier desviación ha sido documentada y justificada formalmente."

**Firma del Desarrollador:** ________________  
**Fecha:** ________________  
**Proyecto:** ________________

---

**FIN DEL DOCUMENTO**
