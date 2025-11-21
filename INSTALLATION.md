# Guía de Instalación Rápida - Order QR Mobile

Esta guía te llevará desde cero hasta tener la app corriendo en tu dispositivo en menos de 30 minutos.

## ✅ Checklist Rápido

Antes de empezar, verifica que tengas:

- [ ] Flutter SDK instalado (versión 3.0+)
- [ ] Git instalado
- [ ] Un editor de código (VS Code recomendado)
- [ ] Android Studio o Xcode (según tu plataforma)
- [ ] Un dispositivo físico o emulador configurado
- [ ] Backend Laravel corriendo (o URL de producción)

## 🚀 Instalación en 5 Pasos

### Paso 1️⃣: Clonar e instalar dependencias (5 min)

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/order_qr_mobile.git
cd order_qr_mobile

# Instalar dependencias
flutter pub get
```

### Paso 2️⃣: Configurar Firebase (10 min)

#### Opción A: Automática (Recomendada)

```bash
# Instalar herramientas
dart pub global activate flutterfire_cli
npm install -g firebase-tools

# Login y configurar
firebase login
flutterfire configure
```

#### Opción B: Manual

1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Crear nuevo proyecto
3. Agregar app Android con package name: `com.orderqr.mobile`
4. Descargar `google-services.json` y colocar en `android/app/`

### Paso 3️⃣: Configurar URL del Backend (2 min)

Edita `lib/config/api_config.dart`:

```dart
static const String baseUrl = 'TU_URL_AQUI';
```

**Ejemplos:**

- **Emulador Android + Backend local:**
  ```dart
  'http://10.0.2.2:8000/api/v1'
  ```

- **Dispositivo físico + Backend local (misma red WiFi):**
  ```dart
  'http://TU_IP_LOCAL:8000/api/v1'  // Ejemplo: http://192.168.1.100:8000/api/v1
  ```

- **Ngrok:**
  ```dart
  'https://tu-subdominio.ngrok-free.app/api/v1'
  ```

- **Servidor de producción:**
  ```dart
  'https://api.tudominio.com/api/v1'
  ```

**¿Cómo obtengo mi IP local?**

**Windows:**
```bash
ipconfig
# Busca "Dirección IPv4"
```

**macOS/Linux:**
```bash
ifconfig
# o
hostname -I
```

### Paso 4️⃣: Conectar dispositivo (3 min)

#### Opción A: Dispositivo físico Android

1. Habilitar **Modo desarrollador**:
   - Ir a Configuración → Acerca del teléfono
   - Tocar "Número de compilación" 7 veces

2. Habilitar **Depuración USB**:
   - Ir a Configuración → Opciones de desarrollador
   - Activar "Depuración USB"

3. Conectar por USB y verificar:
```bash
flutter devices
```

#### Opción B: Emulador Android

```bash
# Ver emuladores disponibles
flutter emulators

# Iniciar emulador
flutter emulators --launch <nombre_emulador>
```

### Paso 5️⃣: Ejecutar la app (5 min)

```bash
flutter run
```

Si tienes múltiples dispositivos:
```bash
flutter devices  # Ver IDs de dispositivos
flutter run -d <device-id>
```

## 🎯 Verificación

Después de ejecutar, deberías ver en los logs:

```
✅ Dispositivo inicializado: [uuid]
✅ Permisos de notificación concedidos
📱 FCM Token: [token]
```

Si ves esto, **¡felicidades!** La app está correctamente instalada.

## ❌ Solución de Problemas Comunes

### "Failed to load Firebase"

```bash
flutterfire configure
flutter clean
flutter pub get
flutter run
```

### "Cannot connect to backend"

1. Verifica que el backend esté corriendo:
```bash
curl -X POST TU_URL/mobile/register -H "Content-Type: application/json" -d '{"device_id":"test"}'
```

2. Si usas emulador + backend local, usa `http://10.0.2.2:8000/api/v1`

3. Si usas dispositivo físico, verifica:
   - Estar en la misma red WiFi
   - Firewall no esté bloqueando
   - URL correcta en `api_config.dart`

### "Camera permission denied"

Desinstala y reinstala la app:
```bash
flutter clean
flutter run
```

### Error de Kotlin version

```bash
flutter run --android-skip-build-dependency-validation
```

### Logs y debugging

```bash
# Ver logs en tiempo real
flutter logs

# Ver logs de Android
adb logcat | grep flutter

# Limpiar proyecto
flutter clean
flutter pub get
```

## 🔄 Próximos Pasos

Ahora que tienes la app instalada:

1. **Escanea un QR** de orden desde la pantalla principal
2. **Recibe notificaciones** cuando el estado de la orden cambie
3. **Visualiza el timeline** del progreso de tu orden
4. **Muestra el QR** de recolección cuando esté lista

## 📖 Documentación Completa

Para más detalles, consulta:
- [README.md](README.md) - Documentación completa
- [BACKEND_REQUIREMENTS.md](BACKEND_REQUIREMENTS.md) - Requisitos del backend

## 💬 ¿Necesitas ayuda?

- Crea un issue en GitHub
- Revisa la sección de Troubleshooting en el README
- Contacta al equipo de soporte

---

**Tiempo estimado total:** 25-30 minutos

**¡Listo para usar! 🎉**
