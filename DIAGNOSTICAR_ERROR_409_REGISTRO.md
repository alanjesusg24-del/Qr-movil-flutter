# Diagnóstico y Solución - Error 409 al Registrar

## 🔴 Problema Actual

Al intentar registrar un usuario en la app Flutter, **SIEMPRE** se recibe un error 409 con el mensaje "El correo electrónico ya está registrado", sin importar qué correo se use.

---

## 🔍 Diagnóstico del Problema

### Posibles Causas

1. **Validación incorrecta en el backend**
   - La regla de validación está mal configurada
   - Se está buscando en la tabla incorrecta
   - Hay un problema con la conexión a la base de datos

2. **Migración no ejecutada**
   - La tabla `mobile_users` no existe
   - La consulta falla y siempre devuelve 409

3. **Middleware o configuración de CORS**
   - El request no llega correctamente al controlador
   - La validación se ejecuta de forma incorrecta

4. **Caché de validación**
   - Laravel está usando una validación cacheada incorrecta

---

## 🛠️ Soluciones a Implementar en Laravel

### **SOLUCIÓN 1: Verificar y Corregir el Controlador**

**Archivo:** `app/Http/Controllers/Api/V1/Auth/AuthController.php`

#### Problema común:
El controlador podría estar verificando la existencia del email ANTES de las validaciones automáticas.

#### Código CORRECTO:

```php
public function register(Request $request)
{
    // 1. PRIMERO: Validar los datos
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

    // 2. SEGUNDO: Verificar device_id
    $existingDevice = MobileUser::where('device_id', $request->device_id)->first();

    if ($existingDevice) {
        return response()->json([
            'success' => false,
            'message' => 'Este dispositivo ya está vinculado a otra cuenta',
        ], 409);
    }

    // 3. TERCERO: Crear usuario
    try {
        $user = MobileUser::create([
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'device_id' => $request->device_id,
            'email_verified_at' => now(),
        ]);

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
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Error al crear usuario: ' . $e->getMessage(),
        ], 500);
    }
}
```

#### ❌ Código INCORRECTO (no usar):

```php
public function register(Request $request)
{
    // ❌ MAL: Verificar email ANTES de la validación
    $existingUser = MobileUser::where('email', $request->email)->first();

    if ($existingUser) {
        return response()->json([
            'success' => false,
            'message' => 'El correo electrónico ya está registrado',
        ], 409);
    }

    // El resto del código...
}
```

---

### **SOLUCIÓN 2: Verificar la Tabla en la Base de Datos**

**Ejecutar en Laravel (Tinker o Route):**

```bash
# Entrar a tinker
php artisan tinker

# Verificar que la tabla existe
>>> Schema::hasTable('mobile_users')
# Debe devolver: true

# Verificar columnas
>>> Schema::getColumnListing('mobile_users')
# Debe devolver: ["id", "email", "password", "device_id", "email_verified_at", "created_at", "updated_at", "deleted_at"]

# Contar registros
>>> App\Models\MobileUser::count()
# Devuelve el número de usuarios registrados

# Listar todos los emails registrados
>>> App\Models\MobileUser::pluck('email')
# Muestra todos los emails en la BD

# Buscar un email específico
>>> App\Models\MobileUser::where('email', 'test@test.com')->first()
# Si devuelve null, el email NO existe
```

---

### **SOLUCIÓN 3: Agregar Logs de Debugging**

Agregar logs temporales para entender qué está pasando:

```php
public function register(Request $request)
{
    // LOG: Ver datos recibidos
    \Log::info('Datos de registro recibidos:', $request->all());

    $validator = Validator::make($request->all(), [
        'email' => 'required|email|unique:mobile_users,email',
        'password' => 'required|string|min:6',
        'device_id' => 'required|string',
    ]);

    if ($validator->fails()) {
        // LOG: Ver errores de validación
        \Log::error('Errores de validación:', $validator->errors()->toArray());

        return response()->json([
            'success' => false,
            'message' => 'Error de validación',
            'errors' => $validator->errors(),
        ], 422);
    }

    // LOG: Verificar device_id
    $existingDevice = MobileUser::where('device_id', $request->device_id)->first();
    \Log::info('Device existente?', ['exists' => !is_null($existingDevice)]);

    if ($existingDevice) {
        \Log::warning('Dispositivo duplicado:', ['device_id' => $request->device_id]);

        return response()->json([
            'success' => false,
            'message' => 'Este dispositivo ya está vinculado a otra cuenta',
        ], 409);
    }

    // Resto del código...
}
```

**Ver los logs:**
```bash
tail -f storage/logs/laravel.log
```

---

### **SOLUCIÓN 4: Ruta de Testing para Diagnóstico**

Crear una ruta temporal para diagnosticar:

**Archivo:** `routes/api.php`

```php
// Ruta temporal de diagnóstico (ELIMINAR EN PRODUCCIÓN)
Route::get('v1/auth/debug-users', function () {
    return response()->json([
        'tabla_existe' => Schema::hasTable('mobile_users'),
        'total_usuarios' => App\Models\MobileUser::count(),
        'emails_registrados' => App\Models\MobileUser::pluck('email'),
        'devices_registrados' => App\Models\MobileUser::pluck('device_id'),
    ]);
});
```

**Llamar desde Flutter o Postman:**
```
GET http://tu-ngrok-url/api/v1/auth/debug-users
```

---

### **SOLUCIÓN 5: Limpiar Caché de Laravel**

```bash
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
```

---

### **SOLUCIÓN 6: Verificar Modelo MobileUser**

**Archivo:** `app/Models/MobileUser.php`

Asegúrate de que el modelo esté correctamente configurado:

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

    protected $table = 'mobile_users'; // ✅ Importante

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
        'password' => 'hashed', // Laravel 10+
    ];

    public function hasVerifiedEmail(): bool
    {
        return !is_null($this->email_verified_at);
    }
}
```

---

### **SOLUCIÓN 7: Recrear la Tabla (SOLO SI ES NECESARIO)**

⚠️ **CUIDADO:** Esto borrará todos los datos.

```bash
# Rollback de la migración
php artisan migrate:rollback --step=1

# Volver a ejecutar
php artisan migrate

# Verificar
php artisan tinker
>>> App\Models\MobileUser::count()
# Debe devolver: 0
```

---

## 🧪 Test Completo con cURL

### 1. Verificar estado de la BD
```bash
curl -X GET http://tu-ngrok-url/api/v1/auth/debug-users
```

### 2. Intentar registro
```bash
curl -X POST http://tu-ngrok-url/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -H "ngrok-skip-browser-warning: true" \
  -d '{
    "email": "nuevo-usuario-' $(date +%s) '@test.com",
    "password": "123456",
    "device_id": "test-device-' $(date +%s) '"
  }'
```

**Nota:** El `$(date +%s)` genera un timestamp único para evitar duplicados.

---

## 🔧 Código Completo del Controlador (CORRECTO)

```php
<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Models\MobileUser;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        \Log::info('=== INICIO REGISTRO ===');
        \Log::info('Email recibido: ' . $request->email);
        \Log::info('Device ID recibido: ' . $request->device_id);

        // Validación
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|unique:mobile_users,email',
            'password' => 'required|string|min:6',
            'device_id' => 'required|string',
        ]);

        if ($validator->fails()) {
            \Log::error('Validación falló:', $validator->errors()->toArray());

            return response()->json([
                'success' => false,
                'message' => 'Error de validación',
                'errors' => $validator->errors(),
            ], 422);
        }

        // Verificar device_id duplicado
        $existingDevice = MobileUser::where('device_id', $request->device_id)->first();

        if ($existingDevice) {
            \Log::warning('Device ID duplicado: ' . $request->device_id);

            return response()->json([
                'success' => false,
                'message' => 'Este dispositivo ya está vinculado a otra cuenta',
                'debug_info' => [
                    'existing_email' => $existingDevice->email,
                ],
            ], 409);
        }

        // Crear usuario
        try {
            $user = MobileUser::create([
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'device_id' => $request->device_id,
                'email_verified_at' => now(),
            ]);

            \Log::info('Usuario creado exitosamente: ' . $user->email);

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

        } catch (\Exception $e) {
            \Log::error('Error al crear usuario: ' . $e->getMessage());
            \Log::error('Stack trace: ' . $e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'Error al crear usuario',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
```

---

## 📋 Checklist de Verificación

Ejecuta estos pasos en orden:

- [ ] 1. Verificar que la tabla `mobile_users` existe
- [ ] 2. Verificar que el modelo `MobileUser` está correctamente configurado
- [ ] 3. Limpiar caché de Laravel
- [ ] 4. Agregar logs de debugging al controlador
- [ ] 5. Crear ruta de debug temporal
- [ ] 6. Probar con cURL desde terminal
- [ ] 7. Revisar logs en `storage/logs/laravel.log`
- [ ] 8. Verificar que no hay middleware bloqueando
- [ ] 9. Asegurar que Sanctum está configurado
- [ ] 10. Probar desde Flutter nuevamente

---

## 🎯 Respuesta Esperada (Exitosa)

```json
{
    "success": true,
    "message": "Usuario registrado exitosamente",
    "token": "1|aBcDeFgHiJkLmNoPqRsTuVwXyZ123456789",
    "user": {
        "id": 1,
        "email": "usuario@test.com",
        "device_id": "abc-123-def-456",
        "email_verified": true
    }
}
```

---

## 🔍 Comandos de Diagnóstico Rápido

```bash
# 1. Ver estructura de la tabla
php artisan tinker
>>> \DB::select('DESCRIBE mobile_users');

# 2. Ver todos los usuarios
>>> App\Models\MobileUser::all();

# 3. Eliminar todos los usuarios (CUIDADO)
>>> App\Models\MobileUser::truncate();

# 4. Crear usuario de prueba
>>> App\Models\MobileUser::create(['email' => 'test@test.com', 'password' => bcrypt('123456'), 'device_id' => 'test-123', 'email_verified_at' => now()]);

# 5. Ver logs en tiempo real
tail -f storage/logs/laravel.log
```

---

**Versión:** 1.0.0
**Fecha:** 2025-11-27
**Propósito:** Diagnosticar y resolver error 409 en registro de usuarios
