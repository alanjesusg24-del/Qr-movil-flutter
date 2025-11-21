# Solución de Errores de Autenticación

## Problema 1: Error 404 - Ruta `/api/v1/auth/register` no encontrada

### Causa
Tu backend Laravel no tiene registrada la ruta de registro.

### Solución

#### Opción A: Verificar y crear la ruta en el backend

1. Ve a tu proyecto backend Laravel
2. Abre el archivo `routes/api.php`
3. Verifica que existan estas rutas:

```php
// routes/api.php
use App\Http\Controllers\Auth\AuthController;

Route::prefix('v1')->group(function () {
    Route::prefix('auth')->group(function () {
        // Rutas públicas
        Route::post('/register', [AuthController::class, 'register']);
        Route::post('/login', [AuthController::class, 'login']);
        Route::post('/login/google', [AuthController::class, 'loginWithGoogle']);

        // Rutas protegidas
        Route::middleware('auth:sanctum')->group(function () {
            Route::post('/logout', [AuthController::class, 'logout']);
            Route::get('/me', [AuthController::class, 'me']);
            Route::post('/verify-email', [AuthController::class, 'verifyEmail']);
            Route::post('/resend-verification', [AuthController::class, 'resendVerification']);

            // Device management
            Route::post('/device/change-request', [AuthController::class, 'requestDeviceChange']);
            Route::post('/device/verify-change', [AuthController::class, 'verifyDeviceChange']);
            Route::post('/device/cancel-request', [AuthController::class, 'cancelDeviceRequest']);
        });

        // Password reset
        Route::post('/password/forgot', [AuthController::class, 'forgotPassword']);
        Route::post('/password/reset', [AuthController::class, 'resetPassword']);
        Route::post('/password/change', [AuthController::class, 'changePassword'])->middleware('auth:sanctum');
    });
});
```

4. Verifica que el `AuthController` exista y tenga el método `register`:

```php
// app/Http/Controllers/Auth/AuthController.php
namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
            'device_id' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Datos inválidos',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'device_id' => $request->device_id,
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Usuario registrado exitosamente',
            'data' => $user,
            'token' => $token,
        ], 201);
    }

    public function loginWithGoogle(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'google_id' => 'required|string',
            'email' => 'required|email',
            'name' => 'required|string',
            'device_id' => 'required|string',
            'id_token' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Datos inválidos',
                'errors' => $validator->errors()
            ], 422);
        }

        // Buscar o crear usuario
        $user = User::where('email', $request->email)->first();

        if (!$user) {
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'google_id' => $request->google_id,
                'profile_photo_url' => $request->profile_photo_url,
                'device_id' => $request->device_id,
                'email_verified_at' => now(), // Google ya verificó el email
            ]);
        } else {
            // Actualizar google_id si no existe
            if (!$user->google_id) {
                $user->update([
                    'google_id' => $request->google_id,
                    'profile_photo_url' => $request->profile_photo_url,
                ]);
            }

            // Verificar device_id
            if ($user->device_id !== $request->device_id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Este usuario está registrado en otro dispositivo',
                    'requires_device_change' => true,
                    'user_id' => $user->id,
                ], 403);
            }
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login exitoso con Google',
            'data' => $user,
            'token' => $token,
        ]);
    }
}
```

5. Ejecuta en tu backend:
```bash
php artisan route:clear
php artisan cache:clear
php artisan config:clear
```

#### Opción B: Verificar que ngrok esté funcionando correctamente

1. Verifica que ngrok esté corriendo:
```bash
ngrok http 8000
```

2. Copia la URL de ngrok (debe ser algo como `https://xxxx-xxxx.ngrok-free.app`)

3. Actualiza la URL en tu app Flutter en `lib/config/api_config.dart`

---

## Problema 2: Google Sign-In falla - oauth_client vacío

### Causa
El archivo `google-services.json` no tiene configurado el OAuth Client ID necesario para Google Sign-In.

### Solución

#### Paso 1: Configurar OAuth en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto **focus-qr**
3. Ve a **Authentication** > **Sign-in method**
4. Habilita el proveedor **Google**
5. Configura el soporte de email para el proyecto

#### Paso 2: Configurar OAuth en Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto **focus-qr**
3. Ve a **APIs & Services** > **Credentials**
4. Crea credenciales de tipo **OAuth 2.0 Client ID**:
   - Tipo de aplicación: **Android**
   - Nombre: `Order QR Mobile Android`
   - Package name: `com.orderqr.mobile` (debe coincidir con tu app)
   - SHA-1 certificate fingerprint: Ver paso 3

#### Paso 3: Obtener SHA-1 Certificate Fingerprint

En Windows (PowerShell), ejecuta:

```powershell
# Para Debug keystore
cd $env:USERPROFILE\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copia el SHA-1 que aparece (algo como: `AA:BB:CC:DD:...`)

Si no encuentras el archivo, créalo primero:
```powershell
keytool -genkey -v -keystore debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000
```

#### Paso 4: Agregar SHA-1 a Firebase

1. En Firebase Console, ve a **Project Settings** (ícono de engranaje)
2. Selecciona tu app Android
3. Haz clic en **Add fingerprint**
4. Pega el SHA-1 que copiaste
5. Guarda los cambios

#### Paso 5: Descargar nuevo google-services.json

1. En Firebase Console, en la configuración de tu app Android
2. Descarga el nuevo archivo `google-services.json`
3. Reemplaza el archivo en `android/app/google-services.json`

El nuevo archivo debe tener un `oauth_client` con tu Client ID:

```json
"oauth_client": [
  {
    "client_id": "XXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.orderqr.mobile",
      "certificate_hash": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    }
  }
]
```

#### Paso 6: Configurar Google Sign-In en el código (opcional)

Si necesitas especificar el Client ID manualmente en Flutter:

```dart
// lib/services/auth_service.dart
static final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: 'TU_WEB_CLIENT_ID.apps.googleusercontent.com', // Del OAuth Web Client
);
```

**Nota:** Necesitas también crear un OAuth Client ID de tipo **Web** en Google Cloud Console y usar ese Client ID aquí.

---

## Problema 3: Error de compilación Kotlin

### Causa
Dependencias de Google Play Services compiladas con Kotlin 2.1.0, pero algunas configuraciones antiguas pueden estar causando conflictos.

### Solución

#### Opción 1: Limpiar y reconstruir (Más simple)

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --debug
```

#### Opción 2: Actualizar dependencias de Android

1. Abre `android/app/build.gradle`
2. Verifica que tenga:

```gradle
android {
    compileSdkVersion 34

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:33.7.0')
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-messaging'
    implementation 'com.google.android.gms:play-services-auth:21.2.0'
}
```

---

## Verificación Final

### Test de Backend

1. Prueba la ruta de registro con curl o Postman:

```bash
curl -X POST https://gerald-ironical-contradictorily.ngrok-free.dev/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "device_id": "test-device-123"
  }'
```

Debe retornar 200/201 con los datos del usuario.

### Test de Google Sign-In

1. Limpia el build:
```bash
flutter clean
flutter pub get
```

2. Ejecuta en modo debug:
```bash
flutter run --debug
```

3. Intenta hacer login con Google
4. Si falla, verifica los logs:
```bash
flutter logs
```

---

## Checklist de Verificación

### Backend
- [ ] Rutas de auth registradas en `routes/api.php`
- [ ] AuthController existe y funciona
- [ ] Laravel Sanctum configurado
- [ ] Ngrok corriendo y URL actualizada en la app
- [ ] CORS configurado correctamente

### Google Sign-In
- [ ] OAuth habilitado en Firebase
- [ ] OAuth Client ID creado en Google Cloud Console
- [ ] SHA-1 agregado a Firebase
- [ ] Nuevo `google-services.json` descargado y reemplazado
- [ ] Package name coincide: `com.orderqr.mobile`

### Build de Android
- [ ] Kotlin 2.1.0 configurado
- [ ] Java 17 configurado
- [ ] Dependencias actualizadas
- [ ] Build limpio ejecutado

---

## Comandos Útiles

### Limpiar todo el proyecto
```bash
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get
```

### Ver logs detallados
```bash
flutter run -v
```

### Ver solo logs de Google Sign-In
```bash
flutter logs | grep -i "google\|sign"
```

### Verificar configuración de Firebase
```bash
flutterfire configure
```

---

## Necesitas ayuda adicional?

Si los problemas persisten:

1. Comparte los logs completos del error
2. Verifica que tu backend esté corriendo
3. Prueba las rutas del backend con Postman
4. Verifica que Firebase esté correctamente configurado
