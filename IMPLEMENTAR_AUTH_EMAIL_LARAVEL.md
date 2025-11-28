# Implementación de Autenticación con Email/Password en Laravel

## 📋 Contexto

El sistema actualmente solo soporta autenticación con Google. Se requiere implementar autenticación tradicional con email y contraseña, donde cada cuenta esté vinculada a un dispositivo móvil.

---

## 🎯 Requisitos

### Funcionalidades Requeridas

1. **Registro de Usuario**
   - Email (único, requerido)
   - Contraseña (mínimo 6 caracteres, hash bcrypt)
   - Device ID (vinculación obligatoria al dispositivo)
   - Auto-login después del registro

2. **Login de Usuario**
   - Email y contraseña
   - Validación de dispositivo vinculado
   - Solicitud de cambio de dispositivo si es diferente

3. **Gestión de Sesiones**
   - Tokens JWT o Sanctum
   - Un dispositivo por cuenta
   - Cambio de dispositivo con confirmación

---

## 📐 Estructura de Base de Datos

### Tabla: `mobile_users`

```sql
CREATE TABLE mobile_users (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    email_verified_at TIMESTAMP NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    deleted_at TIMESTAMP NULL,

    INDEX idx_email (email),
    INDEX idx_device_id (device_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Notas:**
- `email`: Correo único del usuario
- `password`: Hash bcrypt de la contraseña
- `device_id`: UUID del dispositivo móvil
- `email_verified_at`: Opcional para verificación de email (puede ser NULL)
- `deleted_at`: Para soft deletes

---

## 🔐 Modelo: MobileUser

**Ubicación:** `app/Models/MobileUser.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class MobileUser extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected $table = 'mobile_users';

    protected $fillable = [
        'email',
        'password',
        'device_id',
        'email_verified_at',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    /**
     * Relación con órdenes (si existe)
     */
    public function orders()
    {
        return $this->hasMany(Order::class, 'mobile_user_id');
    }

    /**
     * Verificar si el email está verificado
     */
    public function hasVerifiedEmail(): bool
    {
        return !is_null($this->email_verified_at);
    }

    /**
     * Marcar email como verificado
     */
    public function markEmailAsVerified(): bool
    {
        return $this->forceFill([
            'email_verified_at' => $this->freshTimestamp(),
        ])->save();
    }
}
```

---

## 🛣️ Rutas API

**Ubicación:** `routes/api.php`

```php
use App\Http\Controllers\Api\V1\Auth\AuthController;

Route::prefix('v1')->group(function () {
    // Rutas públicas de autenticación
    Route::post('auth/register', [AuthController::class, 'register']);
    Route::post('auth/login', [AuthController::class, 'login']);

    // Rutas protegidas
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('auth/me', [AuthController::class, 'me']);
    });

    // Cambio de dispositivo
    Route::post('auth/device/change-request', [AuthController::class, 'requestDeviceChange']);
    Route::post('auth/device/verify-change', [AuthController::class, 'verifyDeviceChange']);
});
```

---

## 🎮 Controlador: AuthController

**Ubicación:** `app/Http/Controllers/Api/V1/Auth/AuthController.php`

```php
<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Models\MobileUser;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Registro de nuevo usuario
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|unique:mobile_users,email',
            'password' => 'required|string|min:6',
            'device_id' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Error de validación',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Verificar si el device_id ya está en uso
        $existingDevice = MobileUser::where('device_id', $request->device_id)->first();

        if ($existingDevice) {
            return response()->json([
                'success' => false,
                'message' => 'Este dispositivo ya está vinculado a otra cuenta',
            ], 409);
        }

        // Crear usuario
        $user = MobileUser::create([
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'device_id' => $request->device_id,
            'email_verified_at' => now(), // Auto-verificar o dejar NULL si requieres verificación
        ]);

        // Generar token
        $token = $user->createToken('mobile-app')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Usuario registrado exitosamente',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'email' => $user->email,
                'device_id' => $user->device_id,
                'email_verified' => $user->hasVerifiedEmail(),
            ],
        ], 201);
    }

    /**
     * Login de usuario
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string',
            'device_id' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Error de validación',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Buscar usuario por email
        $user = MobileUser::where('email', $request->email)->first();

        // Verificar credenciales
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Credenciales incorrectas',
            ], 401);
        }

        // Verificar device_id
        if ($user->device_id !== $request->device_id) {
            return response()->json([
                'success' => false,
                'message' => 'Esta cuenta está vinculada a otro dispositivo',
                'requires_device_change' => true,
                'user_id' => $user->id,
            ], 403);
        }

        // Revocar tokens anteriores (opcional)
        $user->tokens()->delete();

        // Generar nuevo token
        $token = $user->createToken('mobile-app')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login exitoso',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'email' => $user->email,
                'device_id' => $user->device_id,
                'email_verified' => $user->hasVerifiedEmail(),
            ],
        ], 200);
    }

    /**
     * Obtener información del usuario autenticado
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function me(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'user' => [
                'id' => $user->id,
                'email' => $user->email,
                'device_id' => $user->device_id,
                'email_verified' => $user->hasVerifiedEmail(),
            ],
        ], 200);
    }

    /**
     * Logout
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function logout(Request $request)
    {
        // Revocar token actual
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Sesión cerrada exitosamente',
        ], 200);
    }

    /**
     * Solicitar cambio de dispositivo
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function requestDeviceChange(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string',
            'new_device_id' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Error de validación',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Verificar credenciales
        $user = MobileUser::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Credenciales incorrectas',
            ], 401);
        }

        // Actualizar device_id directamente (simplificado)
        // En producción, deberías implementar un sistema de verificación con código
        $user->device_id = $request->new_device_id;
        $user->save();

        // Revocar todos los tokens anteriores
        $user->tokens()->delete();

        // Generar nuevo token
        $token = $user->createToken('mobile-app')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Dispositivo cambiado exitosamente',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'email' => $user->email,
                'device_id' => $user->device_id,
                'email_verified' => $user->hasVerifiedEmail(),
            ],
        ], 200);
    }

    /**
     * Verificar cambio de dispositivo (para implementación futura con códigos)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function verifyDeviceChange(Request $request)
    {
        // TODO: Implementar sistema de códigos de verificación si es necesario
        return response()->json([
            'success' => false,
            'message' => 'Función no implementada - usar requestDeviceChange',
        ], 501);
    }
}
```

---

## 📝 Validaciones y Reglas

### Request de Registro
```php
[
    'email' => 'required|email|unique:mobile_users,email',
    'password' => 'required|string|min:6',
    'device_id' => 'required|string',
]
```

### Request de Login
```php
[
    'email' => 'required|email',
    'password' => 'required|string',
    'device_id' => 'required|string',
]
```

---

## 🗄️ Migración

**Ubicación:** `database/migrations/2025_11_27_create_mobile_users_table.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('mobile_users', function (Blueprint $table) {
            $table->id();
            $table->string('email')->unique();
            $table->string('password');
            $table->string('device_id')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('email');
            $table->index('device_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mobile_users');
    }
};
```

---

## 🔧 Configuración de Sanctum

### 1. Instalar Sanctum (si no está instalado)
```bash
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate
```

### 2. Configurar en `config/sanctum.php`
```php
'expiration' => null, // Tokens no expiran (o configurar días: 60)
'middleware' => [
    'encrypt_cookies' => false,
    'verify_csrf_token' => false,
],
```

### 3. Agregar middleware en `app/Http/Kernel.php`
```php
'api' => [
    \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
    'throttle:api',
    \Illuminate\Routing\Middleware\SubstituteBindings::class,
],
```

---

## 📡 Respuestas de API

### Registro Exitoso (201)
```json
{
    "success": true,
    "message": "Usuario registrado exitosamente",
    "token": "1|AbC123XyZ...",
    "user": {
        "id": 1,
        "email": "user@example.com",
        "device_id": "abc-123-def-456",
        "email_verified": true
    }
}
```

### Login Exitoso (200)
```json
{
    "success": true,
    "message": "Login exitoso",
    "token": "2|XyZ789AbC...",
    "user": {
        "id": 1,
        "email": "user@example.com",
        "device_id": "abc-123-def-456",
        "email_verified": true
    }
}
```

### Error - Credenciales Incorrectas (401)
```json
{
    "success": false,
    "message": "Credenciales incorrectas"
}
```

### Error - Dispositivo Diferente (403)
```json
{
    "success": false,
    "message": "Esta cuenta está vinculada a otro dispositivo",
    "requires_device_change": true,
    "user_id": 1
}
```

### Error - Email Duplicado (422)
```json
{
    "success": false,
    "message": "Error de validación",
    "errors": {
        "email": ["El correo electrónico ya está registrado"]
    }
}
```

### Error - Dispositivo Duplicado (409)
```json
{
    "success": false,
    "message": "Este dispositivo ya está vinculado a otra cuenta"
}
```

---

## 🧪 Testing

### Comandos Artisan para Testing

```bash
# Ejecutar migraciones
php artisan migrate

# Crear un usuario de prueba
php artisan tinker
>>> MobileUser::create(['email' => 'test@test.com', 'password' => bcrypt('123456'), 'device_id' => 'test-device-123', 'email_verified_at' => now()]);
```

### Tests con cURL

**Registro:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "password": "securepassword",
    "device_id": "device-uuid-12345"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "password": "securepassword",
    "device_id": "device-uuid-12345"
  }'
```

**Me (con token):**
```bash
curl -X GET http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 🔐 Seguridad

### Mejores Prácticas Implementadas

1. ✅ **Passwords hasheados** con bcrypt
2. ✅ **Validación de unicidad** de email y device_id
3. ✅ **Tokens revocables** con Sanctum
4. ✅ **Validación de dispositivo** antes de login
5. ✅ **Rate limiting** en rutas API
6. ✅ **Soft deletes** para mantener histórico

### Recomendaciones Adicionales

- Implementar rate limiting agresivo en login/register
- Agregar logs de intentos fallidos
- Implementar verificación de email con códigos
- Agregar 2FA opcional
- Implementar bloqueo temporal tras múltiples intentos fallidos

---

## 📋 Checklist de Implementación

### Backend
- [ ] Ejecutar migración de `mobile_users`
- [ ] Crear modelo `MobileUser`
- [ ] Crear controlador `AuthController`
- [ ] Agregar rutas en `routes/api.php`
- [ ] Configurar Sanctum
- [ ] Probar endpoints con Postman/cURL
- [ ] Verificar respuestas JSON
- [ ] Testear validaciones
- [ ] Testear cambio de dispositivo

### Base de Datos
- [ ] Verificar índices en `email` y `device_id`
- [ ] Verificar constraint de unicidad
- [ ] Probar soft deletes

### Integración
- [ ] Conectar con app Flutter
- [ ] Verificar flujo completo de registro
- [ ] Verificar flujo completo de login
- [ ] Verificar cambio de dispositivo
- [ ] Testear logout

---

## 🚀 Despliegue

### Variables de Entorno

Asegúrate de configurar en `.env`:

```env
SANCTUM_STATEFUL_DOMAINS=localhost,127.0.0.1
SESSION_DOMAIN=localhost
```

### Comandos de Deploy

```bash
# Optimizar configuración
php artisan config:cache
php artisan route:cache

# Ejecutar migraciones en producción
php artisan migrate --force
```

---

## 📞 Soporte

**Endpoints implementados:**
- `POST /api/v1/auth/register` - Registro
- `POST /api/v1/auth/login` - Login
- `GET /api/v1/auth/me` - Usuario actual (protegido)
- `POST /api/v1/auth/logout` - Cerrar sesión (protegido)
- `POST /api/v1/auth/device/change-request` - Cambiar dispositivo

**Documentación completa:** Este archivo

---

**Versión:** 1.0.0
**Fecha:** 2025-11-27
**Compatibilidad:** Laravel 10+, Sanctum 3+
