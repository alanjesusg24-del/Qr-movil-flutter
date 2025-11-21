# Implementación del Sistema de Autenticación - Backend Laravel

## 📋 Paso 1: Crear Migraciones

### Migración 1: Crear tabla `users` (si no existe)

```bash
php artisan make:migration create_users_table
```

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password')->nullable(); // Nullable para Google Sign-In
            $table->string('google_id')->unique()->nullable();
            $table->text('profile_photo_url')->nullable();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('current_device_id')->nullable();
            $table->timestamp('device_linked_at')->nullable();
            $table->timestamps();

            $table->index('email');
            $table->index('google_id');
            $table->index('current_device_id');
        });
    }

    public function down()
    {
        Schema::dropIfExists('users');
    }
};
```

### Migración 2: Tabla `device_change_requests`

```bash
php artisan make:migration create_device_change_requests_table
```

```php
<?php

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
            $table->string('old_device_id')->nullable();
            $table->string('new_device_id');
            $table->string('verification_code', 6);
            $table->timestamp('expires_at');
            $table->timestamp('verified_at')->nullable();
            $table->enum('status', ['pending', 'verified', 'expired', 'cancelled'])->default('pending');
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->timestamps();

            $table->index('user_id');
            $table->index('verification_code');
            $table->index('status');
            $table->index('expires_at');
        });
    }

    public function down()
    {
        Schema::dropIfExists('device_change_requests');
    }
};
```

### Migración 3: Tabla `login_attempts`

```bash
php artisan make:migration create_login_attempts_table
```

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('login_attempts', function (Blueprint $table) {
            $table->id();
            $table->string('email');
            $table->string('device_id');
            $table->boolean('success')->default(false);
            $table->string('failure_reason')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->timestamp('created_at');

            $table->index('email');
            $table->index('device_id');
            $table->index('created_at');
        });
    }

    public function down()
    {
        Schema::dropIfExists('login_attempts');
    }
};
```

### Migración 4: Actualizar tabla `mobile_users`

```bash
php artisan make:migration add_user_id_to_mobile_users_table
```

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('mobile_users', function (Blueprint $table) {
            $table->foreignId('user_id')->nullable()->after('id')->constrained()->onDelete('set null');
            $table->boolean('is_active')->default(true)->after('last_active_at');
        });
    }

    public function down()
    {
        Schema::table('mobile_users', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->dropColumn(['user_id', 'is_active']);
        });
    }
};
```

### Ejecutar Migraciones

```bash
php artisan migrate
```

## 📦 Paso 2: Instalar Dependencias

```bash
# JWT para tokens
composer require tymon/jwt-auth

# Para emails
composer require illuminate/mail

# Para rate limiting (ya viene con Laravel)
```

### Configurar JWT

```bash
php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider"
php artisan jwt:secret
```

En `config/auth.php`:

```php
'guards' => [
    'web' => [
        'driver' => 'session',
        'provider' => 'users',
    ],

    'api' => [
        'driver' => 'jwt',
        'provider' => 'users',
    ],
],
```

## 🎯 Paso 3: Crear Modelos

### Modelo `User`

```php
<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Tymon\JWTAuth\Contracts\JWTSubject;

class User extends Authenticatable implements JWTSubject
{
    use Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'google_id',
        'profile_photo_url',
        'email_verified_at',
        'current_device_id',
        'device_linked_at',
    ];

    protected $hidden = [
        'password',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'device_linked_at' => 'datetime',
    ];

    // JWT Methods
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    public function getJWTCustomClaims()
    {
        return [];
    }

    // Relationships
    public function mobileUser()
    {
        return $this->hasOne(MobileUser::class);
    }

    public function deviceChangeRequests()
    {
        return $this->hasMany(DeviceChangeRequest::class);
    }

    // Helper Methods
    public function hasDeviceLinked(): bool
    {
        return !is_null($this->current_device_id);
    }

    public function isDeviceLinked(string $deviceId): bool
    {
        return $this->current_device_id === $deviceId;
    }

    public function linkDevice(string $deviceId): void
    {
        $this->update([
            'current_device_id' => $deviceId,
            'device_linked_at' => now(),
        ]);
    }

    public function unlinkDevice(): void
    {
        $this->update([
            'current_device_id' => null,
            'device_linked_at' => null,
        ]);
    }

    public function isEmailVerified(): bool
    {
        return !is_null($this->email_verified_at);
    }

    public function markEmailAsVerified(): void
    {
        $this->update([
            'email_verified_at' => now(),
        ]);
    }
}
```

### Modelo `DeviceChangeRequest`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DeviceChangeRequest extends Model
{
    protected $fillable = [
        'user_id',
        'old_device_id',
        'new_device_id',
        'verification_code',
        'expires_at',
        'verified_at',
        'status',
        'ip_address',
        'user_agent',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'verified_at' => 'datetime',
    ];

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Helper Methods
    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    public function isPending(): bool
    {
        return $this->status === 'pending';
    }

    public function markAsVerified(): void
    {
        $this->update([
            'status' => 'verified',
            'verified_at' => now(),
        ]);
    }

    public function markAsExpired(): void
    {
        $this->update([
            'status' => 'expired',
        ]);
    }

    public function cancel(): void
    {
        $this->update([
            'status' => 'cancelled',
        ]);
    }

    // Generate random 6-digit code
    public static function generateVerificationCode(): string
    {
        return str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
    }
}
```

### Modelo `LoginAttempt`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LoginAttempt extends Model
{
    const UPDATED_AT = null; // Solo created_at

    protected $fillable = [
        'email',
        'device_id',
        'success',
        'failure_reason',
        'ip_address',
        'user_agent',
    ];

    protected $casts = [
        'success' => 'boolean',
        'created_at' => 'datetime',
    ];

    // Log attempt
    public static function log(
        string $email,
        string $deviceId,
        bool $success,
        ?string $failureReason = null,
        ?string $ipAddress = null,
        ?string $userAgent = null
    ): void {
        self::create([
            'email' => $email,
            'device_id' => $deviceId,
            'success' => $success,
            'failure_reason' => $failureReason,
            'ip_address' => $ipAddress,
            'user_agent' => $userAgent,
        ]);
    }

    // Check if device is rate limited
    public static function isRateLimited(string $deviceId, int $maxAttempts = 5, int $decayMinutes = 60): bool
    {
        $attempts = self::where('device_id', $deviceId)
            ->where('success', false)
            ->where('created_at', '>=', now()->subMinutes($decayMinutes))
            ->count();

        return $attempts >= $maxAttempts;
    }
}
```

## 📧 Paso 4: Crear Notificaciones de Email

### Notification: Verificación de Email

```bash
php artisan make:notification EmailVerificationNotification
```

```php
<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class EmailVerificationNotification extends Notification
{
    use Queueable;

    protected $code;

    public function __construct(string $code)
    {
        $this->code = $code;
    }

    public function via($notifiable)
    {
        return ['mail'];
    }

    public function toMail($notifiable)
    {
        return (new MailMessage)
            ->subject('Verifica tu cuenta - Order QR')
            ->greeting('¡Hola ' . $notifiable->name . '!')
            ->line('Tu código de verificación es:')
            ->line('**' . $this->code . '**')
            ->line('Este código expira en 15 minutos.')
            ->line('Si no solicitaste este código, ignora este email.');
    }
}
```

### Notification: Cambio de Dispositivo

```bash
php artisan make:notification DeviceChangeRequestNotification
```

```php
<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use App\Models\DeviceChangeRequest;

class DeviceChangeRequestNotification extends Notification
{
    use Queueable;

    protected $request;

    public function __construct(DeviceChangeRequest $request)
    {
        $this->request = $request;
    }

    public function via($notifiable)
    {
        return ['mail'];
    }

    public function toMail($notifiable)
    {
        return (new MailMessage)
            ->subject('Solicitud de cambio de dispositivo - Order QR')
            ->greeting('¡Hola ' . $notifiable->name . '!')
            ->line('Se ha solicitado vincular tu cuenta a un nuevo dispositivo.')
            ->line('Tu código de verificación es:')
            ->line('**' . $this->request->verification_code . '**')
            ->line('Información del dispositivo:')
            ->line('- IP: ' . $this->request->ip_address)
            ->line('- Fecha: ' . $this->request->created_at->format('d M Y, h:i A'))
            ->line('Si no fuiste tú, cambia tu contraseña inmediatamente.')
            ->line('Este código expira en 15 minutos.');
    }
}
```

## 🎯 Paso 5: Crear Servicios

### Servicio: AuthService

```bash
mkdir -p app/Services
```

Crear `app/Services/AuthService.php`:

```php
<?php

namespace App\Services;

use App\Models\User;
use App\Models\MobileUser;
use App\Models\LoginAttempt;
use App\Models\DeviceChangeRequest;
use App\Notifications\EmailVerificationNotification;
use App\Notifications\DeviceChangeRequestNotification;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Cache;
use Tymon\JWTAuth\Facades\JWTAuth;

class AuthService
{
    /**
     * Registrar nuevo usuario
     */
    public function register(array $data): array
    {
        // Validar si el email ya existe
        if (User::where('email', $data['email'])->exists()) {
            return [
                'success' => false,
                'message' => 'El email ya está registrado',
            ];
        }

        // Crear usuario
        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
        ]);

        // Generar código de verificación
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // Guardar código en cache (15 minutos)
        Cache::put(
            "email_verification:{$user->id}",
            $code,
            now()->addMinutes(15)
        );

        // Enviar email
        $user->notify(new EmailVerificationNotification($code));

        return [
            'success' => true,
            'message' => 'Usuario registrado. Verifica tu email.',
            'user' => $user,
            'requires_email_verification' => true,
        ];
    }

    /**
     * Verificar email
     */
    public function verifyEmail(int $userId, string $code): array
    {
        $cachedCode = Cache::get("email_verification:{$userId}");

        if (!$cachedCode || $cachedCode !== $code) {
            return [
                'success' => false,
                'message' => 'Código inválido o expirado',
            ];
        }

        $user = User::find($userId);
        $user->markEmailAsVerified();

        Cache::forget("email_verification:{$userId}");

        return [
            'success' => true,
            'message' => 'Email verificado exitosamente',
            'user' => $user,
        ];
    }

    /**
     * Login con email y contraseña
     */
    public function login(string $email, string $password, string $deviceId, ?string $ipAddress = null, ?string $userAgent = null): array
    {
        // Verificar rate limiting
        if (LoginAttempt::isRateLimited($deviceId)) {
            return [
                'success' => false,
                'message' => 'Demasiados intentos fallidos. Intenta más tarde.',
            ];
        }

        // Buscar usuario
        $user = User::where('email', $email)->first();

        if (!$user || !Hash::check($password, $user->password)) {
            LoginAttempt::log($email, $deviceId, false, 'Credenciales inválidas', $ipAddress, $userAgent);

            return [
                'success' => false,
                'message' => 'Credenciales inválidas',
            ];
        }

        // Verificar si el email está verificado
        if (!$user->isEmailVerified()) {
            return [
                'success' => false,
                'message' => 'Debes verificar tu email primero',
                'requires_email_verification' => true,
                'user_id' => $user->id,
            ];
        }

        // Verificar dispositivo vinculado
        if ($user->hasDeviceLinked() && !$user->isDeviceLinked($deviceId)) {
            LoginAttempt::log($email, $deviceId, false, 'Dispositivo diferente', $ipAddress, $userAgent);

            return [
                'success' => false,
                'message' => 'Esta cuenta está vinculada a otro dispositivo',
                'requires_device_change' => true,
                'user_id' => $user->id,
            ];
        }

        // Vincular dispositivo si no está vinculado
        if (!$user->hasDeviceLinked()) {
            $user->linkDevice($deviceId);

            // Vincular con mobile_user si existe
            $mobileUser = MobileUser::where('device_id', $deviceId)->first();
            if ($mobileUser) {
                $mobileUser->update(['user_id' => $user->id]);
            }
        }

        // Generar token JWT
        $token = JWTAuth::fromUser($user);

        LoginAttempt::log($email, $deviceId, true, null, $ipAddress, $userAgent);

        return [
            'success' => true,
            'message' => 'Login exitoso',
            'token' => $token,
            'user' => $user,
        ];
    }

    /**
     * Login con Google
     */
    public function loginWithGoogle(string $googleId, string $email, string $name, ?string $photoUrl, string $deviceId): array
    {
        // Buscar usuario por google_id o email
        $user = User::where('google_id', $googleId)
            ->orWhere('email', $email)
            ->first();

        // Si no existe, crear nuevo usuario
        if (!$user) {
            $user = User::create([
                'name' => $name,
                'email' => $email,
                'google_id' => $googleId,
                'profile_photo_url' => $photoUrl,
                'email_verified_at' => now(), // Google ya verificó el email
            ]);
        } else {
            // Actualizar google_id si no lo tiene
            if (!$user->google_id) {
                $user->update(['google_id' => $googleId]);
            }
        }

        // Verificar dispositivo
        if ($user->hasDeviceLinked() && !$user->isDeviceLinked($deviceId)) {
            return [
                'success' => false,
                'message' => 'Esta cuenta está vinculada a otro dispositivo',
                'requires_device_change' => true,
                'user_id' => $user->id,
            ];
        }

        // Vincular dispositivo si no está vinculado
        if (!$user->hasDeviceLinked()) {
            $user->linkDevice($deviceId);
        }

        // Generar token JWT
        $token = JWTAuth::fromUser($user);

        return [
            'success' => true,
            'message' => 'Login exitoso',
            'token' => $token,
            'user' => $user,
        ];
    }

    /**
     * Solicitar cambio de dispositivo
     */
    public function requestDeviceChange(int $userId, string $newDeviceId, ?string $ipAddress = null, ?string $userAgent = null): array
    {
        $user = User::find($userId);

        if (!$user) {
            return [
                'success' => false,
                'message' => 'Usuario no encontrado',
            ];
        }

        // Cancelar solicitudes pendientes anteriores
        DeviceChangeRequest::where('user_id', $userId)
            ->where('status', 'pending')
            ->update(['status' => 'cancelled']);

        // Crear nueva solicitud
        $request = DeviceChangeRequest::create([
            'user_id' => $userId,
            'old_device_id' => $user->current_device_id,
            'new_device_id' => $newDeviceId,
            'verification_code' => DeviceChangeRequest::generateVerificationCode(),
            'expires_at' => now()->addMinutes(15),
            'ip_address' => $ipAddress,
            'user_agent' => $userAgent,
        ]);

        // Enviar email
        $user->notify(new DeviceChangeRequestNotification($request));

        return [
            'success' => true,
            'message' => 'Código de verificación enviado a tu email',
            'request_id' => $request->id,
            'expires_at' => $request->expires_at,
        ];
    }

    /**
     * Verificar cambio de dispositivo
     */
    public function verifyDeviceChange(int $requestId, string $code, string $password): array
    {
        $request = DeviceChangeRequest::find($requestId);

        if (!$request) {
            return [
                'success' => false,
                'message' => 'Solicitud no encontrada',
            ];
        }

        // Verificar si está expirada
        if ($request->isExpired()) {
            $request->markAsExpired();
            return [
                'success' => false,
                'message' => 'El código ha expirado',
            ];
        }

        // Verificar código
        if ($request->verification_code !== $code) {
            return [
                'success' => false,
                'message' => 'Código incorrecto',
            ];
        }

        // Verificar contraseña
        $user = $request->user;
        if (!Hash::check($password, $user->password)) {
            return [
                'success' => false,
                'message' => 'Contraseña incorrecta',
            ];
        }

        // Actualizar dispositivo del usuario
        $user->linkDevice($request->new_device_id);

        // Marcar solicitud como verificada
        $request->markAsVerified();

        // Generar nuevo token
        $token = JWTAuth::fromUser($user);

        return [
            'success' => true,
            'message' => 'Dispositivo cambiado exitosamente',
            'token' => $token,
            'user' => $user,
        ];
    }
}
```

Este es el backend completo. Continúo con el resto en el siguiente mensaje...

¿Quieres que continúe con los controladores y rutas, o prefieres pasar directamente a la implementación en Flutter?
