# Instrucciones para Configurar Firebase en el Backend Laravel

## 📁 Archivo de Credenciales Descargado

Ya tienes el archivo: **`focus-qr-firebase-adminsdk-fbsvc-a71741a1ff.json`**

## 🔧 Pasos a Seguir en el Backend Laravel

### Paso 1: Mover el archivo JSON al proyecto Laravel

```bash
# Ve a la carpeta de tu proyecto Laravel
cd /ruta/a/tu/proyecto/laravel

# Crear la carpeta firebase si no existe
mkdir -p storage/app/firebase

# Copiar el archivo desde la carpeta de Flutter
cp /ruta/al/archivo/focus-qr-firebase-adminsdk-fbsvc-a71741a1ff.json storage/app/firebase/credentials.json
```

**Ruta completa del archivo actual:**
```
C:\Users\alanG\Documentos\VSC\Flutter\order_qr_mobile\focus-qr-firebase-adminsdk-fbsvc-a71741a1ff.json
```

### Paso 2: Actualizar `.gitignore` en Laravel

Agrega esta línea al archivo `.gitignore`:

```gitignore
# Firebase credentials
storage/app/firebase/
```

### Paso 3: Actualizar `.env` en Laravel

Agrega estas variables:

```env
FIREBASE_CREDENTIALS=storage/app/firebase/credentials.json
FIREBASE_PROJECT_ID=focus-qr
```

### Paso 4: Instalar la librería de Firebase

```bash
cd /ruta/a/tu/proyecto/laravel
composer require kreait/firebase-php
```

### Paso 5: Actualizar `config/services.php`

Agrega esta configuración:

```php
return [
    // ... otras configuraciones ...

    'firebase' => [
        'credentials' => env('FIREBASE_CREDENTIALS'),
        'project_id' => env('FIREBASE_PROJECT_ID', 'focus-qr'),
    ],
];
```

### Paso 6: Crear el Servicio de Firebase

Crea el archivo: `app/Services/FirebaseService.php`

```php
<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Illuminate\Support\Facades\Log;

class FirebaseService
{
    protected $messaging;

    public function __construct()
    {
        try {
            $credentialsPath = storage_path('app/firebase/credentials.json');

            if (!file_exists($credentialsPath)) {
                throw new \Exception("Firebase credentials file not found at: {$credentialsPath}");
            }

            $factory = (new Factory)->withServiceAccount($credentialsPath);
            $this->messaging = $factory->createMessaging();

            Log::info('Firebase service initialized successfully');
        } catch (\Exception $e) {
            Log::error('Error initializing Firebase service', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            throw $e;
        }
    }

    /**
     * Enviar notificación push a un dispositivo
     *
     * @param string $fcmToken Token FCM del dispositivo
     * @param array $data Datos adicionales (type, order_id, etc.)
     * @param string|null $title Título de la notificación
     * @param string|null $body Cuerpo de la notificación
     * @return mixed
     */
    public function sendNotification(string $fcmToken, array $data, ?string $title = null, ?string $body = null)
    {
        try {
            $messageData = [
                'token' => $fcmToken,
                'data' => array_map('strval', $data), // FCM requiere que todos los datos sean strings
            ];

            // Si hay título y cuerpo, agregar notificación
            if ($title && $body) {
                $messageData['notification'] = [
                    'title' => $title,
                    'body' => $body,
                ];
            }

            // Configuración para Android
            $messageData['android'] = [
                'priority' => 'high',
                'notification' => [
                    'channel_id' => 'order_updates',
                    'sound' => 'default',
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ],
            ];

            // Configuración para iOS
            $messageData['apns'] = [
                'headers' => [
                    'apns-priority' => '10',
                ],
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                        'badge' => 1,
                        'content-available' => 1,
                    ],
                ],
            ];

            $message = CloudMessage::fromArray($messageData);
            $result = $this->messaging->send($message);

            Log::info('FCM notification sent successfully', [
                'token' => substr($fcmToken, 0, 20) . '...',
                'data' => $data,
                'title' => $title,
            ]);

            return $result;
        } catch (\Exception $e) {
            Log::error('Error sending FCM notification', [
                'error' => $e->getMessage(),
                'token' => substr($fcmToken, 0, 20) . '...',
                'data' => $data,
            ]);
            throw $e;
        }
    }

    /**
     * Enviar notificación de nuevo mensaje de chat
     */
    public function sendNewMessageNotification(string $fcmToken, int $orderId, string $messageText, string $businessName)
    {
        return $this->sendNotification(
            $fcmToken,
            [
                'type' => 'new_message',
                'order_id' => (string) $orderId,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ],
            'Nuevo mensaje de ' . $businessName,
            $this->truncateMessage($messageText, 100)
        );
    }

    /**
     * Enviar notificación de cambio de estado de orden
     */
    public function sendOrderStatusNotification(string $fcmToken, int $orderId, string $newStatus, string $folioNumber)
    {
        $statusMessages = [
            'pending' => 'Tu orden está siendo procesada',
            'ready' => '¡Tu orden está lista para recoger!',
            'delivered' => 'Tu orden ha sido entregada',
            'cancelled' => 'Tu orden ha sido cancelada',
        ];

        return $this->sendNotification(
            $fcmToken,
            [
                'type' => 'order_status_change',
                'order_id' => (string) $orderId,
                'new_status' => $newStatus,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ],
            "Orden {$folioNumber}",
            $statusMessages[$newStatus] ?? 'El estado de tu orden ha cambiado'
        );
    }

    /**
     * Enviar notificación de orden asociada
     */
    public function sendOrderAssociatedNotification(string $fcmToken, int $orderId, string $folioNumber)
    {
        return $this->sendNotification(
            $fcmToken,
            [
                'type' => 'order_associated',
                'order_id' => (string) $orderId,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ],
            'Orden asociada',
            "Tu orden {$folioNumber} ha sido asociada exitosamente"
        );
    }

    /**
     * Enviar notificación de recordatorio
     */
    public function sendOrderReminderNotification(string $fcmToken, int $orderId, string $folioNumber)
    {
        return $this->sendNotification(
            $fcmToken,
            [
                'type' => 'order_reminder',
                'order_id' => (string) $orderId,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ],
            'Recordatorio de orden',
            "Tu orden {$folioNumber} está lista para recoger"
        );
    }

    /**
     * Truncar mensaje a una longitud específica
     */
    private function truncateMessage(string $message, int $length): string
    {
        if (mb_strlen($message) <= $length) {
            return $message;
        }
        return mb_substr($message, 0, $length - 3) . '...';
    }

    /**
     * Validar si un token FCM es válido
     */
    public function validateToken(string $fcmToken): bool
    {
        try {
            // Intenta enviar una notificación de prueba (sin contenido)
            $this->messaging->validateRegistrationTokens([$fcmToken]);
            return true;
        } catch (\Exception $e) {
            Log::warning('Invalid FCM token', [
                'token' => substr($fcmToken, 0, 20) . '...',
                'error' => $e->getMessage(),
            ]);
            return false;
        }
    }
}
```

### Paso 7: Registrar el Servicio en el Service Provider (Opcional)

Si quieres usar inyección de dependencias, agrega en `app/Providers/AppServiceProvider.php`:

```php
use App\Services\FirebaseService;

public function register()
{
    $this->app->singleton(FirebaseService::class, function ($app) {
        return new FirebaseService();
    });
}
```

### Paso 8: Usar el Servicio en tus Controladores

#### Ejemplo: En el Controlador de Chat

Archivo: `app/Http/Controllers/Api/V1/Mobile/ChatMessageController.php`

```php
<?php

namespace App\Http\Controllers\Api\V1\Mobile;

use App\Http\Controllers\Controller;
use App\Models\ChatMessage;
use App\Models\Order;
use App\Services\FirebaseService;
use Illuminate\Http\Request;

class ChatMessageController extends Controller
{
    protected $firebaseService;

    public function __construct(FirebaseService $firebaseService)
    {
        $this->firebaseService = $firebaseService;
    }

    /**
     * Enviar mensaje desde el negocio al cliente
     */
    public function store(Request $request, $orderId)
    {
        $request->validate([
            'message' => 'required|string|max:1000',
        ]);

        // Buscar la orden
        $order = Order::with('mobileUser', 'business')->findOrFail($orderId);

        // Crear el mensaje
        $message = ChatMessage::create([
            'order_id' => $orderId,
            'sender_type' => 'business', // El negocio está enviando
            'message' => $request->message,
        ]);

        // Enviar notificación push al cliente móvil
        if ($order->mobileUser && $order->mobileUser->fcm_token) {
            try {
                $this->firebaseService->sendNewMessageNotification(
                    $order->mobileUser->fcm_token,
                    $order->order_id,
                    $request->message,
                    $order->business->business_name
                );
            } catch (\Exception $e) {
                \Log::error('Error sending notification', [
                    'error' => $e->getMessage(),
                    'order_id' => $orderId,
                ]);
                // No fallar si la notificación falla
            }
        }

        return response()->json([
            'success' => true,
            'data' => $message,
        ], 201);
    }
}
```

#### Ejemplo: En el Observer de Order (para cambios de estado)

Archivo: `app/Observers/OrderObserver.php`

```php
<?php

namespace App\Observers;

use App\Models\Order;
use App\Services\FirebaseService;

class OrderObserver
{
    protected $firebaseService;

    public function __construct(FirebaseService $firebaseService)
    {
        $this->firebaseService = $firebaseService;
    }

    /**
     * Cuando se actualiza una orden
     */
    public function updated(Order $order)
    {
        // Detectar si cambió el estado
        if ($order->isDirty('status') && $order->mobileUser && $order->mobileUser->fcm_token) {
            try {
                $this->firebaseService->sendOrderStatusNotification(
                    $order->mobileUser->fcm_token,
                    $order->order_id,
                    $order->status,
                    $order->folio_number
                );
            } catch (\Exception $e) {
                \Log::error('Error sending status notification', [
                    'error' => $e->getMessage(),
                    'order_id' => $order->order_id,
                ]);
            }
        }
    }
}
```

No olvides registrar el Observer en `app/Providers/EventServiceProvider.php`:

```php
use App\Models\Order;
use App\Observers\OrderObserver;

public function boot()
{
    Order::observe(OrderObserver::class);
}
```

### Paso 9: Limpiar caché y probar

```bash
php artisan config:cache
php artisan cache:clear
```

## 🧪 Probar las Notificaciones

### Opción 1: Crear una ruta de prueba

En `routes/api.php`:

```php
use App\Services\FirebaseService;

Route::get('/test-notification', function (FirebaseService $firebase) {
    // Obtén el token FCM de la app (lo verás en los logs de Flutter)
    $testToken = 'PEGA_AQUI_EL_TOKEN_DE_TU_DISPOSITIVO';

    try {
        $result = $firebase->sendNotification(
            $testToken,
            [
                'type' => 'new_message',
                'order_id' => '123',
            ],
            'Prueba',
            'Este es un mensaje de prueba desde Laravel'
        );

        return response()->json([
            'success' => true,
            'message' => 'Notificación enviada',
            'result' => $result,
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'error' => $e->getMessage(),
        ], 500);
    }
});
```

Luego visita: `http://tu-servidor/api/test-notification`

### Opción 2: Usar Tinker

```bash
php artisan tinker
```

Luego:

```php
$firebase = app(\App\Services\FirebaseService::class);
$token = 'TU_TOKEN_FCM_AQUI';
$firebase->sendNotification($token, ['type' => 'test', 'order_id' => '1'], 'Test', 'Mensaje de prueba');
```

## 📱 Obtener el Token FCM del Dispositivo

En Flutter, el token se imprime en los logs cuando inicias la app. Busca:

```
📱 FCM Token: ePQk9x...
```

Copia ese token completo para hacer las pruebas.

## ✅ Checklist Final

- [ ] Archivo `credentials.json` copiado a `storage/app/firebase/`
- [ ] `.gitignore` actualizado
- [ ] `.env` actualizado con las variables de Firebase
- [ ] Librería `kreait/firebase-php` instalada
- [ ] `config/services.php` actualizado
- [ ] `FirebaseService.php` creado
- [ ] Servicio implementado en controladores
- [ ] Caché limpiada
- [ ] Notificación de prueba enviada exitosamente

## 🎯 Resultado Final

Una vez completado, cuando:
- Un negocio envíe un mensaje de chat → El cliente recibe notificación push
- Una orden cambie de estado → El cliente recibe notificación push
- Se asocie una orden → El cliente recibe notificación push

**¡El sistema estará 100% funcional!** 🚀

---

**Nota:** Si tienes algún error, revisa los logs de Laravel en `storage/logs/laravel.log`
