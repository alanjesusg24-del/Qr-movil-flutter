# 🚀 Setup Rápido de Firebase en Laravel

## Tu archivo de credenciales

**Ubicación actual:**
```
C:\Users\alanG\Documentos\VSC\Flutter\order_qr_mobile\focus-qr-firebase-adminsdk-fbsvc-a71741a1ff.json
```

## 📋 Comandos para Copiar y Pegar

### 1. En tu proyecto Laravel, ejecuta estos comandos:

```bash
# Crear la carpeta firebase
mkdir -p storage/app/firebase

# Copiar el archivo de credenciales
# IMPORTANTE: Reemplaza /ruta/al/proyecto/laravel con la ruta real
cp "C:\Users\alanG\Documentos\VSC\Flutter\order_qr_mobile\focus-qr-firebase-adminsdk-fbsvc-a71741a1ff.json" storage/app/firebase/credentials.json

# Instalar la librería de Firebase
composer require kreait/firebase-php

# Limpiar caché
php artisan config:cache
```

### 2. Agrega al archivo `.env`:

```env
FIREBASE_CREDENTIALS=storage/app/firebase/credentials.json
FIREBASE_PROJECT_ID=focus-qr
```

### 3. Agrega al archivo `.gitignore`:

```gitignore
# Firebase credentials
storage/app/firebase/
```

### 4. Actualiza `config/services.php`:

Agrega al final del array que retorna:

```php
'firebase' => [
    'credentials' => env('FIREBASE_CREDENTIALS'),
    'project_id' => env('FIREBASE_PROJECT_ID', 'focus-qr'),
],
```

### 5. Crea el archivo `app/Services/FirebaseService.php`

**El código completo está en:** `INSTRUCCIONES_BACKEND_FIREBASE.md`

Copia todo el código de la clase `FirebaseService` desde ese archivo.

### 6. Prueba que funcione

Crea una ruta de prueba en `routes/api.php`:

```php
use App\Services\FirebaseService;

Route::get('/test-fcm', function () {
    try {
        $firebase = app(FirebaseService::class);

        return response()->json([
            'success' => true,
            'message' => 'Firebase service initialized successfully!',
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'error' => $e->getMessage(),
        ], 500);
    }
});
```

Visita: `http://tu-servidor/api/test-fcm`

Deberías ver:
```json
{
    "success": true,
    "message": "Firebase service initialized successfully!"
}
```

## 🎯 Siguiente Paso: Obtener Token FCM

1. Ejecuta tu app Flutter en un dispositivo o emulador
2. Al iniciar, verás en los logs:
   ```
   📱 FCM Token: ePQk9x7R...
   ```
3. Copia ese token completo

## 🧪 Probar Notificación Real

Una vez que tengas el token, prueba enviar una notificación:

```bash
php artisan tinker
```

En tinker:

```php
$firebase = app(\App\Services\FirebaseService::class);

$token = 'PEGA_EL_TOKEN_AQUI';

$firebase->sendNotification(
    $token,
    ['type' => 'test', 'order_id' => '1'],
    'Prueba desde Laravel',
    'Si ves esto, funciona!'
);
```

Si todo está bien, recibirás la notificación en tu dispositivo móvil! 📱

## ❓ Problemas Comunes

### Error: "Credentials file not found"
- Verifica que copiaste el archivo a `storage/app/firebase/credentials.json`
- Asegúrate de usar rutas absolutas

### Error: "Permission denied"
- Verifica que la Firebase Cloud Messaging API esté habilitada en Google Cloud Console
- Ve a: https://console.cloud.google.com/apis/library/fcm.googleapis.com

### Error: "Invalid token"
- El token FCM cambió o expiró
- Vuelve a copiar el token desde los logs de Flutter

## 📚 Documentación Completa

Ver archivo: **`INSTRUCCIONES_BACKEND_FIREBASE.md`**

Incluye:
- Código completo del servicio
- Ejemplos de uso en controladores
- Implementación de Observers
- Todas las funciones disponibles

---

¡Éxito con la configuración! 🎉
