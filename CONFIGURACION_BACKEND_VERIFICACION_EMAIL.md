# Configuración del Backend - Verificación de Email

## Problema Actual

El backend está solicitando verificación de email en **TODOS** los inicios de sesión, cuando debería solicitarla **SOLO** cuando el usuario intenta acceder desde un dispositivo diferente.

## Solución: Verificar device_id en el Backend

### Lógica Correcta del Login

El endpoint de login debe:

1. **Primer login** (device_id es null) → Asignar device_id, NO pedir verificación
2. **Mismo dispositivo** (device_id coincide) → Permitir acceso directo, NO pedir verificación
3. **Dispositivo diferente** (device_id diferente) → Pedir verificación de email

### Código PHP para el Backend

#### 1. AuthController.php - Método login()

```php
public function login(Request $request)
{
    // Validar datos
    $request->validate([
        'email' => 'required|email',
        'password' => 'required',
        'device_id' => 'required|string',
    ]);

    $email = $request->email;
    $password = $request->password;
    $deviceId = $request->device_id;

    // Buscar usuario
    $user = User::where('email', $email)->first();

    // Verificar credenciales
    if (!$user || !Hash::check($password, $user->password)) {
        return response()->json([
            'success' => false,
            'message' => 'Credenciales inválidas'
        ], 401);
    }

    // ============================================
    // VERIFICACIÓN DE DISPOSITIVO
    // ============================================

    if ($user->device_id === null || $user->device_id === '') {
        // CASO 1: Primera vez que inicia sesión
        // Asignar device_id automáticamente
        $user->device_id = $deviceId;
        $user->save();

        // Generar token
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'token' => $token,
            'message' => 'Login exitoso'
        ], 200);
    }

    if ($user->device_id === $deviceId) {
        // CASO 2: Mismo dispositivo
        // Permitir acceso directo SIN verificación

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'token' => $token,
            'message' => 'Login exitoso'
        ], 200);
    }

    // CASO 3: Dispositivo diferente
    // Requerir verificación de email

    // Generar código de 6 dígitos
    $code = rand(100000, 999999);

    // Crear solicitud de cambio de dispositivo
    $changeRequest = DeviceChangeRequest::create([
        'user_id' => $user->id,
        'new_device_id' => $deviceId,
        'verification_code' => $code,
        'expires_at' => now()->addMinutes(15),
    ]);

    // Enviar email con el código
    Mail::to($user->email)->send(new DeviceChangeVerification($user, $code));

    return response()->json([
        'success' => false,
        'requires_device_change' => true,
        'request_id' => $changeRequest->id,
        'expires_at' => $changeRequest->expires_at,
        'message' => 'Se detectó un dispositivo diferente. Se ha enviado un código de verificación a tu email.'
    ], 403);
}
```

#### 2. AuthController.php - Método loginWithGoogle()

```php
public function loginWithGoogle(Request $request)
{
    $request->validate([
        'google_id' => 'required|string',
        'email' => 'required|email',
        'name' => 'required|string',
        'device_id' => 'required|string',
    ]);

    $googleId = $request->google_id;
    $email = $request->email;
    $name = $request->name;
    $deviceId = $request->device_id;

    // Buscar o crear usuario
    $user = User::where('google_id', $googleId)->first();

    if (!$user) {
        // Usuario nuevo con Google
        $user = User::create([
            'google_id' => $googleId,
            'name' => $name,
            'email' => $email,
            'device_id' => $deviceId, // Asignar device_id desde el inicio
            'email_verified_at' => now(), // Google ya verificó el email
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'token' => $token,
            'message' => 'Cuenta creada exitosamente'
        ], 200);
    }

    // Usuario existente

    if ($user->device_id === null || $user->device_id === '') {
        // Primera vez desde este dispositivo
        $user->device_id = $deviceId;
        $user->save();

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'token' => $token,
            'message' => 'Login exitoso'
        ], 200);
    }

    if ($user->device_id === $deviceId) {
        // Mismo dispositivo - permitir acceso

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'token' => $token,
            'message' => 'Login exitoso'
        ], 200);
    }

    // Dispositivo diferente - requiere verificación

    $code = rand(100000, 999999);

    $changeRequest = DeviceChangeRequest::create([
        'user_id' => $user->id,
        'new_device_id' => $deviceId,
        'verification_code' => $code,
        'expires_at' => now()->addMinutes(15),
    ]);

    Mail::to($user->email)->send(new DeviceChangeVerification($user, $code));

    return response()->json([
        'success' => false,
        'requires_device_change' => true,
        'request_id' => $changeRequest->id,
        'expires_at' => $changeRequest->expires_at,
        'message' => 'Dispositivo diferente detectado. Verifica tu email.'
    ], 403);
}
```

#### 3. AuthController.php - Método register()

```php
public function register(Request $request)
{
    $request->validate([
        'name' => 'required|string|max:255',
        'email' => 'required|email|unique:users',
        'password' => 'required|min:8|confirmed',
        'device_id' => 'required|string',
    ]);

    // Crear usuario con device_id
    $user = User::create([
        'name' => $request->name,
        'email' => $request->email,
        'password' => Hash::make($request->password),
        'device_id' => $request->device_id, // Asignar device_id
        'email_verified_at' => now(), // Opcional: marcar como verificado
    ]);

    // Generar token inmediatamente
    $token = $user->createToken('auth_token')->plainTextToken;

    return response()->json([
        'success' => true,
        'token' => $token,
        'message' => 'Registro exitoso'
    ], 201);
}
```

#### 4. AuthController.php - Método me() (obtener usuario actual)

```php
public function me(Request $request)
{
    $user = $request->user();

    return response()->json([
        'success' => true,
        'data' => [
            'userId' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'deviceId' => $user->device_id,
            'emailVerified' => $user->email_verified_at !== null,
            'createdAt' => $user->created_at,
        ]
    ], 200);
}
```

### Migración: Agregar columna device_id

Si aún no existe la columna `device_id` en la tabla `users`:

```php
// database/migrations/xxxx_add_device_id_to_users_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('device_id')->nullable()->after('email');
            $table->index('device_id'); // Para búsquedas rápidas
        });
    }

    public function down()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('device_id');
        });
    }
};
```

Ejecutar migración:
```bash
php artisan migrate
```

### Modelo User.php

Agregar `device_id` a los campos fillable:

```php
class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'google_id',
        'device_id', // ✅ Agregar esto
        'email_verified_at',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
    ];
}
```

### Tabla device_change_requests

Crear migración para la tabla de solicitudes de cambio de dispositivo:

```php
// database/migrations/xxxx_create_device_change_requests_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('device_change_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('new_device_id');
            $table->string('verification_code');
            $table->timestamp('expires_at');
            $table->timestamps();

            $table->index(['user_id', 'expires_at']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('device_change_requests');
    }
};
```

### Modelo DeviceChangeRequest.php

```php
// app/Models/DeviceChangeRequest.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DeviceChangeRequest extends Model
{
    protected $fillable = [
        'user_id',
        'new_device_id',
        'verification_code',
        'expires_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Verificar si la solicitud está expirada
    public function isExpired()
    {
        return now()->isAfter($this->expires_at);
    }
}
```

## Resumen de Cambios

### ✅ Lo que DEBE hacer el backend:

1. **Primer login** → Asignar `device_id` automáticamente, NO pedir verificación
2. **Login desde mismo dispositivo** → Comparar `device_id`, permitir acceso directo
3. **Login desde dispositivo diferente** → Detectar cambio de `device_id`, pedir verificación

### ❌ Lo que NO debe hacer:

1. ❌ NO pedir verificación de email en primer registro/login
2. ❌ NO pedir verificación cuando el `device_id` coincide
3. ❌ NO requerir `email_verified_at` para login normal

## Flujo Correcto

```
Usuario registra cuenta
  └─> Backend asigna device_id automáticamente
  └─> Devuelve token inmediatamente
  └─> Usuario puede usar la app

Usuario hace login (mismo dispositivo)
  └─> Backend compara device_id
  └─> device_id coincide ✅
  └─> Devuelve token inmediatamente
  └─> NO pide código

Usuario hace login (dispositivo diferente)
  └─> Backend compara device_id
  └─> device_id NO coincide ❌
  └─> Crea DeviceChangeRequest
  └─> Envía código por email
  └─> Usuario debe verificar con código + password
  └─> Si verifica correctamente, actualiza device_id
```

## Verificar que funciona

1. **Test 1 - Registro**:
   - Registrar usuario → Debe entrar sin código
   - Verificar en BD que tiene `device_id` asignado

2. **Test 2 - Login mismo dispositivo**:
   - Hacer login con mismo `device_id` → Debe entrar sin código

3. **Test 3 - Login dispositivo diferente**:
   - Hacer login con diferente `device_id` → Debe pedir código
   - Verificar código → Debe actualizar `device_id` en BD

## Comandos útiles

```bash
# Crear migración
php artisan make:migration add_device_id_to_users_table

# Ejecutar migraciones
php artisan migrate

# Crear modelo
php artisan make:model DeviceChangeRequest -m

# Limpiar tokens expirados (opcional, agregar a scheduler)
php artisan sanctum:prune-expired --hours=24
```
