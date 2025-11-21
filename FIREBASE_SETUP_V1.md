# Configuración de Firebase Cloud Messaging (FCM) API v1

## 🚨 Importante: Firebase cambió su sistema

Firebase **deprecó** la Cloud Messaging API (Legacy) y ahora usa **Firebase Cloud Messaging API (v1)**.

La diferencia principal:
- ❌ **Antes**: Usabas una "Server Key" simple
- ✅ **Ahora**: Usas **Service Account** con autenticación OAuth2

## 📋 Configuración Paso a Paso

### 1. Habilitar Firebase Cloud Messaging API

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: **`focus-qr`**
3. Haz clic en el ícono de engranaje ⚙️ → **"Project Settings"**
4. Ve a la pestaña **"Service accounts"**
5. En la parte inferior, haz clic en **"Manage service account permissions"**
6. Esto te llevará a Google Cloud Console

### 2. Habilitar la API de FCM

En Google Cloud Console:

1. Ve al menú lateral → **"APIs & Services"** → **"Library"**
2. Busca: **"Firebase Cloud Messaging API"**
3. Haz clic en el resultado
4. Presiona el botón **"ENABLE"** (Habilitar)

### 3. Crear una Service Account Key

1. Regresa a Firebase Console → **Project Settings** → **Service accounts**
2. Haz clic en el botón **"Generate new private key"**
3. Confirma haciendo clic en **"Generate key"**
4. Se descargará un archivo JSON (ejemplo: `focus-qr-firebase-adminsdk-xxxxx.json`)

**⚠️ IMPORTANTE:** Este archivo contiene credenciales sensibles. Nunca lo subas a GitHub.

### 4. Configurar en Laravel

#### A. Copiar el archivo de credenciales

Coloca el archivo JSON descargado en tu proyecto Laravel:

```bash
# Crear directorio si no existe
mkdir -p storage/app/firebase

# Copiar el archivo (renómbralo a algo simple)
cp /ruta/del/archivo/descargado.json storage/app/firebase/credentials.json
```

#### B. Actualizar `.env`

```env
FIREBASE_CREDENTIALS=storage/app/firebase/credentials.json
FIREBASE_PROJECT_ID=focus-qr
```

#### C. Agregar a `.gitignore`

Asegúrate de que el archivo de credenciales NO se suba a Git:

```gitignore
# Firebase credentials
storage/app/firebase/
```

### 5. Actualizar el Código de Laravel

#### Opción 1: Usar la librería oficial de Firebase Admin SDK

```bash
composer require kreait/firebase-php
```

En tu `config/services.php`:

```php
'firebase' => [
    'credentials' => env('FIREBASE_CREDENTIALS'),
    'project_id' => env('FIREBASE_PROJECT_ID', 'focus-qr'),
],
```

Crear un servicio para FCM (`app/Services/FirebaseService.php`):

```php
<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

class FirebaseService
{
    protected $messaging;

    public function __construct()
    {
        $factory = (new Factory)->withServiceAccount(config('services.firebase.credentials'));
        $this->messaging = $factory->createMessaging();
    }

    /**
     * Enviar notificación push a un dispositivo
     */
    public function sendNotification(string $fcmToken, array $data, ?string $title = null, ?string $body = null)
    {
        try {
            $messageData = [
                'token' => $fcmToken,
                'data' => $data,
            ];

            // Si hay título y cuerpo, agregar notificación
            if ($title && $body) {
                $messageData['notification'] = Notification::create($title, $body);
            }

            // Configuración para Android
            $messageData['android'] = [
                'priority' => 'high',
                'notification' => [
                    'channel_id' => 'order_updates',
                    'sound' => 'default',
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
                    ],
                ],
            ];

            $message = CloudMessage::fromArray($messageData);

            $result = $this->messaging->send($message);

            \Log::info('FCM notification sent successfully', [
                'token' => $fcmToken,
                'result' => $result,
            ]);

            return $result;
        } catch (\Exception $e) {
            \Log::error('Error sending FCM notification', [
                'error' => $e->getMessage(),
                'token' => $fcmToken,
            ]);
            throw $e;
        }
    }

    /**
     * Enviar notificación de nuevo mensaje
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
            'Nuevo mensaje',
            substr($messageText, 0, 100) // Limitar a 100 caracteres
        );
    }

    /**
     * Enviar notificación de cambio de estado
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
}
```

#### Opción 2: Hacer peticiones HTTP manualmente

Si prefieres no usar la librería, puedes hacer peticiones HTTP directas:

```php
<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Google\Auth\Credentials\ServiceAccountCredentials;

class FirebaseService
{
    protected $accessToken;

    public function __construct()
    {
        $this->accessToken = $this->getAccessToken();
    }

    /**
     * Obtener Access Token usando Service Account
     */
    protected function getAccessToken()
    {
        $credentialsPath = storage_path('app/firebase/credentials.json');

        $credentials = new ServiceAccountCredentials(
            'https://www.googleapis.com/auth/firebase.messaging',
            json_decode(file_get_contents($credentialsPath), true)
        );

        $token = $credentials->fetchAuthToken();
        return $token['access_token'];
    }

    /**
     * Enviar notificación push
     */
    public function sendNotification(string $fcmToken, array $data, ?string $title = null, ?string $body = null)
    {
        $projectId = config('services.firebase.project_id');
        $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

        $message = [
            'message' => [
                'token' => $fcmToken,
                'data' => $data,
                'android' => [
                    'priority' => 'high',
                    'notification' => [
                        'channel_id' => 'order_updates',
                        'sound' => 'default',
                    ],
                ],
                'apns' => [
                    'headers' => [
                        'apns-priority' => '10',
                    ],
                    'payload' => [
                        'aps' => [
                            'sound' => 'default',
                            'badge' => 1,
                        ],
                    ],
                ],
            ],
        ];

        // Agregar notificación si hay título y cuerpo
        if ($title && $body) {
            $message['message']['notification'] = [
                'title' => $title,
                'body' => $body,
            ];
        }

        try {
            $response = Http::withToken($this->accessToken)
                ->post($url, $message);

            if ($response->successful()) {
                \Log::info('FCM notification sent', [
                    'token' => $fcmToken,
                    'response' => $response->json(),
                ]);
                return $response->json();
            } else {
                \Log::error('FCM error', [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);
                throw new \Exception('FCM error: ' . $response->body());
            }
        } catch (\Exception $e) {
            \Log::error('Error sending FCM', ['error' => $e->getMessage()]);
            throw $e;
        }
    }
}
```

Para la opción 2, necesitas instalar:

```bash
composer require google/auth
```

### 6. Usar el Servicio en tu Controlador

Ejemplo en `ChatMessageController`:

```php
use App\Services\FirebaseService;

class ChatMessageController extends Controller
{
    protected $firebaseService;

    public function __construct(FirebaseService $firebaseService)
    {
        $this->firebaseService = $firebaseService;
    }

    public function store(Request $request, $orderId)
    {
        // ... código existente para guardar el mensaje ...

        // Obtener el FCM token del usuario móvil
        $mobileUser = $order->mobileUser;

        if ($mobileUser && $mobileUser->fcm_token) {
            // Enviar notificación
            $this->firebaseService->sendNewMessageNotification(
                $mobileUser->fcm_token,
                $order->order_id,
                $request->message,
                $order->business->business_name
            );
        }

        return response()->json([
            'success' => true,
            'data' => new ChatMessageResource($message),
        ], 201);
    }
}
```

## 🧪 Probar las Notificaciones

### Opción 1: Desde Firebase Console

1. Ve a Firebase Console → **Messaging**
2. Haz clic en **"Create your first campaign"**
3. Selecciona **"Firebase Notification messages"**
4. Completa:
   - **Notification title**: "Test"
   - **Notification text**: "Mensaje de prueba"
5. Haz clic en **"Send test message"**
6. Pega el FCM token de tu dispositivo (lo puedes ver en los logs de Flutter)

### Opción 2: Usando cURL

Primero obtén un Access Token:

```bash
# En la carpeta donde está credentials.json
gcloud auth activate-service-account --key-file=credentials.json
gcloud auth print-access-token
```

Luego envía una notificación:

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/focus-qr/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "TU_FCM_TOKEN_DEL_DISPOSITIVO",
      "notification": {
        "title": "Test",
        "body": "Mensaje de prueba"
      },
      "data": {
        "type": "new_message",
        "order_id": "123"
      }
    }
  }'
```

## 📱 Verificar en Flutter

Los logs en Flutter deberían mostrar:

```
📱 FCM Token: ePQk... (tu token)
📩 Notificación recibida en foreground
   Título: Test
   Cuerpo: Mensaje de prueba
   Data: {type: new_message, order_id: 123}
```

## 🔍 Troubleshooting

### Error: "Permission denied"

**Solución:** Asegúrate de que la Firebase Cloud Messaging API esté habilitada en Google Cloud Console.

### Error: "Invalid token"

**Solución:**
1. Verifica que el FCM token esté actualizado
2. El token cambia si desinstalas/reinstales la app
3. Revisa que el token se esté guardando correctamente en la BD

### Error: "Service account does not have permission"

**Solución:**
1. Ve a Google Cloud Console → IAM & Admin
2. Encuentra tu service account
3. Asegúrate de que tenga el rol: **"Firebase Cloud Messaging Admin"**

## 📚 Recursos

- [FCM HTTP v1 API](https://firebase.google.com/docs/cloud-messaging/migrate-v1)
- [Firebase Admin SDK PHP](https://github.com/kreait/firebase-php)
- [Google Auth Library](https://github.com/googleapis/google-auth-library-php)

---

## ✅ Checklist Final

- [ ] Firebase Cloud Messaging API habilitada en Google Cloud Console
- [ ] Service Account Key descargado
- [ ] Archivo JSON colocado en `storage/app/firebase/credentials.json`
- [ ] Variables de entorno configuradas
- [ ] Librería instalada (`kreait/firebase-php` o `google/auth`)
- [ ] Servicio FirebaseService creado
- [ ] Implementado en el controlador de mensajes
- [ ] Probado con notificación de prueba

**Una vez completado esto, tu sistema de notificaciones estará 100% funcional! 🚀**
