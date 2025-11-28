# Especificación de Pantalla de Login Estandarizada CETAM

## 📱 Pantalla: Portal de Trabajadores - Login

Esta especificación define el diseño estándar de la pantalla de inicio de sesión que debe replicarse en todos los sistemas CETAM.

---

## 🎨 DISEÑO GENERAL

### Estructura de Layout

```dart
Scaffold(
  backgroundColor: Color(0xFFF8F9FA), // Gray-50
  body: Center(
    child: SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Componentes según especificación
        ],
      ),
    ),
  ),
)
```

### Distribución Vertical (de arriba hacia abajo)

1. **Espacio superior** (flexible)
2. **Título principal**
3. **Descripción**
4. **Campo de Correo**
5. **Campo de Contraseña**
6. **Botón Ingresar**
7. **Enlace Recuperar Contraseña**
8. **Espacio inferior** (flexible)

---

## 📐 ESPECIFICACIÓN DE COMPONENTES

### 1. Título Principal

**Texto:** "Portal de trabajadores"

```dart
Text(
  'Portal de trabajadores',
  style: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1F2937), // Gray-900 (Primary)
    letterSpacing: -0.5,
  ),
  textAlign: TextAlign.center,
)
```

**Espaciado inferior:** 12px

---

### 2. Descripción/Subtítulo

**Texto:** "Accede con tu correo institucional para consultar tus trámites"

```dart
Text(
  'Accede con tu correo institucional para\nconsultar tus trámites',
  style: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xFF6C757D), // Gray-600
    height: 1.5,
  ),
  textAlign: TextAlign.center,
)
```

**Espaciado inferior:** 40px

---

### 3. Campo de Correo Institucional

**Ícono:** `Icons.email` (o `Icons.mail_outline`)  
**Placeholder:** "Correo institucional"  
**Tipo:** Email input

```dart
SizedBox(
  width: double.infinity,
  height: 60, // Altura fija obligatoria
  child: TextField(
    keyboardType: TextInputType.emailAddress,
    decoration: InputDecoration(
      prefixIcon: Icon(
        Icons.email,
        color: Color(0xFFADB5BD), // Gray-500
        size: 20,
      ),
      hintText: 'Correo institucional',
      hintStyle: TextStyle(
        color: Color(0xFFADB5BD), // Gray-500
        fontSize: 14,
      ),
      filled: true,
      fillColor: Color(0xFFFFFFFF), // White
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Color(0xFFE9ECEF), // Gray-200
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Color(0xFFE9ECEF), // Gray-200
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Color(0xFF4F46E5), // Indigo
          width: 2,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
    ),
  ),
)
```

**Espaciado inferior:** 16px

---

### 4. Campo de Contraseña

**Ícono:** `Icons.lock` (o `Icons.lock_outline`)  
**Placeholder:** "Contraseña"  
**Tipo:** Password input (obscureText: true)  
**Funcionalidad:** Toggle para mostrar/ocultar contraseña

```dart
SizedBox(
  width: double.infinity,
  height: 60, // Altura fija obligatoria
  child: TextField(
    obscureText: _obscurePassword,
    decoration: InputDecoration(
      prefixIcon: Icon(
        Icons.lock,
        color: Color(0xFFADB5BD), // Gray-500
        size: 20,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          color: Color(0xFFADB5BD), // Gray-500
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
      hintText: 'Contraseña',
      hintStyle: TextStyle(
        color: Color(0xFFADB5BD), // Gray-500
        fontSize: 14,
      ),
      filled: true,
      fillColor: Color(0xFFFFFFFF), // White
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Color(0xFFE9ECEF), // Gray-200
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Color(0xFFE9ECEF), // Gray-200
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Color(0xFF4F46E5), // Indigo
          width: 2,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
    ),
  ),
)
```

**Espaciado inferior:** 24px

---

### 5. Botón Ingresar

**Texto:** "Ingresar"  
**Ícono:** `Icons.login` (opcional, a la izquierda del texto)  
**Tamaño:** Grande (según estándares CETAM)

```dart
SizedBox(
  width: double.infinity,
  height: 52, // Tamaño Grande
  child: ElevatedButton(
    onPressed: _handleLogin,
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF1F2937), // Primary (Gray-900)
      foregroundColor: Color(0xFFFFFFFF), // White
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Radio Grande
      ),
      padding: EdgeInsets.symmetric(vertical: 16),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.login, size: 20),
        SizedBox(width: 8),
        Text(
          'Ingresar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  ),
)
```

**Espaciado inferior:** 16px

---

### 6. Enlace Recuperar Contraseña

**Texto:** "Recuperar contraseña"  
**Ícono:** `Icons.lock_reset` (pequeño, a la izquierda)  
**Tipo:** TextButton

```dart
TextButton(
  onPressed: _handleForgotPassword,
  style: TextButton.styleFrom(
    foregroundColor: Color(0xFF6C757D), // Gray-600
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.lock_reset,
        size: 16,
        color: Color(0xFF6C757D), // Gray-600
      ),
      SizedBox(width: 6),
      Text(
        'Recuperar contraseña',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.none,
        ),
      ),
    ],
  ),
)
```

---

## 🎨 PALETA DE COLORES UTILIZADA

```dart
class LoginColors {
  // Colores de la paleta CETAM usados en login
  static const background = Color(0xFFF8F9FA);      // Gray-50
  static const titleText = Color(0xFF1F2937);        // Gray-900 (Primary)
  static const subtitleText = Color(0xFF6C757D);     // Gray-600
  static const inputBorder = Color(0xFFE9ECEF);      // Gray-200
  static const inputFocused = Color(0xFF4F46E5);     // Indigo
  static const inputFill = Color(0xFFFFFFFF);        // White
  static const iconInactive = Color(0xFFADB5BD);     // Gray-500
  static const buttonPrimary = Color(0xFF1F2937);    // Primary (Gray-900)
  static const buttonText = Color(0xFFFFFFFF);       // White
  static const linkText = Color(0xFF6C757D);         // Gray-600
}
```

---

## 📏 ESPACIADOS Y DIMENSIONES

### Espaciados Verticales
```yaml
Margen superior del contenido: flexible (usa Spacer o SizedBox con height flexible)
Título → Descripción: 12px
Descripción → Campo Email: 40px
Campo Email → Campo Contraseña: 16px
Campo Contraseña → Botón: 24px
Botón → Enlace: 16px
Margen inferior: flexible
```

### Espaciados Horizontales
```yaml
Padding lateral de la pantalla: 24px
Padding interno de campos: 16px horizontal
Espacio ícono-texto en botón: 8px
Espacio ícono-texto en enlace: 6px
```

### Alturas
```yaml
Campos de texto: 60px (FIJO)
Botón principal: 52px (Grande)
```

### Radios de Borde
```yaml
Campos de texto: 8px
Botón principal: 10px
```

### Anchos
```yaml
Todos los elementos: double.infinity (ancho completo menos padding)
```

---

## 🔧 FUNCIONALIDADES REQUERIDAS

### Validaciones

```dart
// 1. Validación de email
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'El correo institucional es requerido';
  }
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) {
    return 'Ingrese un correo válido';
  }
  return null;
}

// 2. Validación de contraseña
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'La contraseña es requerida';
  }
  if (value.length < 6) {
    return 'La contraseña debe tener al menos 6 caracteres';
  }
  return null;
}
```

### Manejo de Estado del Botón

```dart
bool _isLoading = false;

void _handleLogin() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    // Llamada a servicio de autenticación
    await authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    
    // Navegación exitosa
    Navigator.pushReplacementNamed(context, '/home');
    
  } catch (e) {
    // Mostrar error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Color(0xFFE11D48), // Danger
      ),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
```

### Toggle de Visibilidad de Contraseña

```dart
bool _obscurePassword = true;

// En el suffixIcon del campo de contraseña
IconButton(
  icon: Icon(
    _obscurePassword ? Icons.visibility_off : Icons.visibility,
    color: Color(0xFFADB5BD),
    size: 20,
  ),
  onPressed: () {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  },
)
```

### Navegación a Recuperar Contraseña

```dart
void _handleForgotPassword() {
  Navigator.pushNamed(context, '/forgot-password');
}
```

---

## 📱 RESPONSIVIDAD

### Adaptación a Diferentes Tamaños

```dart
// Para tablets o pantallas más grandes
double getMaxWidth(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width > 600 ? 400 : double.infinity;
}

// Uso en el Container principal
Container(
  width: getMaxWidth(context),
  child: Column(
    children: [
      // Componentes
    ],
  ),
)
```

---

## 🔐 SEGURIDAD

### Buenas Prácticas Implementadas

```dart
// 1. No almacenar credenciales en texto plano
// 2. Usar TextEditingController con dispose
@override
void dispose() {
  _emailController.dispose();
  _passwordController.dispose();
  super.dispose();
}

// 3. Limpiar campos después de intentos fallidos si es necesario
void _clearSensitiveData() {
  _passwordController.clear();
}

// 4. Implementar rate limiting en el backend
// 5. Usar HTTPS para todas las comunicaciones
```

---

## 📋 EJEMPLO DE CÓDIGO COMPLETO

```dart
/*
 * ============================================================================
 * Project:        Portal CETAM
 * File:           login_screen.dart
 * Author:         [Tu Nombre]
 * Creation Date:  2025-11-27
 * Last Modified:  2025-11-27
 * Version:        1.0.0
 * Description:    Pantalla de inicio de sesión estandarizada CETAM
 * Dependencies:   flutter/material.dart
 * Notes:          Cumple con estándares CETAM v3.0
 * ============================================================================
 */

import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Gray-50
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título
                const Text(
                  'Portal de trabajadores',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Descripción
                const Text(
                  'Accede con tu correo institucional para\nconsultar tus trámites',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6C757D),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Campo Email
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.email,
                        color: Color(0xFFADB5BD),
                        size: 20,
                      ),
                      hintText: 'Correo institucional',
                      hintStyle: const TextStyle(
                        color: Color(0xFFADB5BD),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFFFFFF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFE9ECEF),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFE9ECEF),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF4F46E5),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFE11D48),
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campo Contraseña
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Color(0xFFADB5BD),
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFFADB5BD),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      hintText: 'Contraseña',
                      hintStyle: const TextStyle(
                        color: Color(0xFFADB5BD),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFFFFFF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFE9ECEF),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFE9ECEF),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF4F46E5),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFE11D48),
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botón Ingresar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      foregroundColor: const Color(0xFFFFFFFF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFFFFF),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.login, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Ingresar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Enlace Recuperar Contraseña
                TextButton(
                  onPressed: _handleForgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6C757D),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.lock_reset,
                        size: 16,
                        color: Color(0xFF6C757D),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Recuperar contraseña',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo institucional es requerido';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingrese un correo válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implementar llamada al servicio de autenticación
      await Future.delayed(const Duration(seconds: 2)); // Simulación
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFE11D48),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleForgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }
}
```

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

### Antes de Iniciar
- [ ] Revisar paleta de colores CETAM
- [ ] Confirmar tamaños estándar de componentes
- [ ] Verificar íconos aprobados

### Durante el Desarrollo
- [ ] Implementar estructura básica del Scaffold
- [ ] Agregar título y descripción con estilos correctos
- [ ] Crear campo de email con validación
- [ ] Crear campo de contraseña con toggle
- [ ] Implementar botón principal con loading state
- [ ] Agregar enlace de recuperación
- [ ] Configurar Form y validaciones
- [ ] Implementar manejo de estado

### Testing
- [ ] Probar validaciones de campos
- [ ] Verificar toggle de visibilidad de contraseña
- [ ] Confirmar estado de loading del botón
- [ ] Probar navegación a recuperar contraseña
- [ ] Verificar colores contra paleta CETAM
- [ ] Medir dimensiones de componentes
- [ ] Probar en diferentes tamaños de pantalla
- [ ] Verificar accesibilidad (contraste, tamaños táctiles)

### Post-Desarrollo
- [ ] Agregar cabecera de prólogo al archivo
- [ ] Documentar métodos públicos con ///
- [ ] Ejecutar dart format
- [ ] Ejecutar dart analyze
- [ ] Revisar contra estándares CETAM

---

## 🎯 VARIACIONES PERMITIDAS

### Personalización por Proyecto

**Lo que SÍ se puede personalizar:**
- Texto del título (mantener estilo)
- Texto de la descripción
- Labels de los campos (mantener estructura)
- Ruta de navegación después del login

**Lo que NO se puede cambiar:**
- Paleta de colores
- Tamaños de componentes
- Íconos utilizados
- Espaciados entre elementos
- Estructura general del layout
- Radios de borde

---

## 📱 CAPTURAS DE REFERENCIA

### Estados de la Pantalla

**Estado Normal (Idle):**
- Campos vacíos
- Botón habilitado
- Sin mensajes de error

**Estado con Errores:**
- Campos con borde rojo
- Mensajes de validación en rojo debajo de campos
- Botón habilitado

**Estado Loading:**
- Campos deshabilitados
- Botón muestra CircularProgressIndicator
- No se puede interactuar

**Estado con Focus:**
- Campo enfocado con borde Indigo (2px)
- Otros campos con borde Gray-200 (1px)

---

**Versión:** 1.0  
**Fecha:** 2025-11-27  
**Basado en:** Manual CETAM v3.0 y Portal de Trabajadores existente
