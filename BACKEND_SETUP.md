# Configuración del Backend para Order QR Mobile

Esta guía explica cómo configurar el backend Laravel para que funcione correctamente con la app móvil.

## 📋 Requisitos del Backend

El backend debe proporcionar los siguientes endpoints:

### Endpoints Requeridos

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/v1/mobile/register` | Registrar dispositivo móvil |
| POST | `/api/v1/mobile/update-token` | Actualizar FCM token |
| POST | `/api/v1/mobile/orders/associate` | Asociar orden con dispositivo |
| GET | `/api/v1/mobile/orders` | Obtener órdenes del dispositivo |
| GET | `/api/v1/mobile/orders/{id}` | Obtener detalles de una orden |

## 🔧 Configuración del Backend Laravel

### 1. Variables de Entorno

Agrega estas variables a tu archivo `.env` del backend:

```env
# Firebase Cloud Messaging
FIREBASE_SERVER_KEY=tu_firebase_server_key_aqui
FIREBASE_PROJECT_ID=tu_project_id

# CORS - Permitir app móvil
CORS_ALLOWED_ORIGINS=*

# Rate Limiting
API_RATE_LIMIT=60
```

### 2. Obtener Firebase Server Key

1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Seleccionar tu proyecto
3. Ir a **Project Settings** ⚙️
4. Pestaña **Cloud Messaging**
5. Buscar **Server key** bajo "Cloud Messaging API (Legacy)"
6. Copiar el valor

> **Nota:** Firebase recomienda usar la nueva Admin SDK, pero la Server Key legacy sigue funcionando.

### 3. Configurar CORS

En `config/cors.php`:

```php
return [
    'paths' => ['api/*'],
    'allowed_methods' => ['*'],
    'allowed_origins' => ['*'],
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => false,
];
```

### 4. Middleware de API

Asegúrate de que los endpoints estén protegidos apropiadamente en `routes/api.php`:

```php
Route::prefix('v1')->group(function () {
    Route::prefix('mobile')->group(function () {
        // Rutas públicas (no requieren autenticación de usuario)
        Route::post('/register', [MobileController::class, 'register']);
        Route::post('/update-token', [MobileController::class, 'updateToken']);
        Route::post('/orders/associate', [MobileController::class, 'associateOrder']);
        Route::get('/orders', [MobileController::class, 'getOrders']);
        Route::get('/orders/{id}', [MobileController::class, 'getOrderDetail']);
    });
});
```

## 📡 Schema de Requests y Responses

### 1. Registrar Dispositivo

**Request:**
```http
POST /api/v1/mobile/register
Content-Type: application/json

{
  "device_id": "ba95b33b-04a5-40bb-b8cd-80a219a97cad",
  "device_name": "Pixel 5",
  "platform": "android",
  "fcm_token": "eeNbEyYCQqCzZVfTL9j8zn:APA91b..."
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Dispositivo registrado exitosamente",
  "data": {
    "device_id": "ba95b33b-04a5-40bb-b8cd-80a219a97cad",
    "device_name": "Pixel 5",
    "platform": "android",
    "created_at": "2025-11-14T20:00:00.000000Z"
  }
}
```

**IMPORTANTE:** El `device_id` debe devolverse como **string**, no como número.

### 2. Actualizar FCM Token

**Request:**
```http
POST /api/v1/mobile/update-token
Content-Type: application/json

{
  "device_id": "ba95b33b-04a5-40bb-b8cd-80a219a97cad",
  "fcm_token": "eeNbEyYCQqCzZVfTL9j8zn:APA91b..."
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Token actualizado exitosamente"
}
```

### 3. Asociar Orden con Dispositivo

**Request:**
```http
POST /api/v1/mobile/orders/associate
Content-Type: application/json

{
  "device_id": "ba95b33b-04a5-40bb-b8cd-80a219a97cad",
  "qr_code": "ORD-20251114-001"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Orden asociada exitosamente",
  "data": {
    "id": 1,
    "order_number": "ORD-20251114-001",
    "business_name": "Café Central",
    "status": "pending",
    "items": [
      {
        "name": "Café Latte",
        "quantity": 1,
        "price": 4.50
      }
    ],
    "total": 4.50,
    "created_at": "2025-11-14T19:30:00.000000Z",
    "estimated_ready_time": "2025-11-14T19:45:00.000000Z"
  }
}
```

### 4. Obtener Órdenes

**Request:**
```http
GET /api/v1/mobile/orders?device_id=ba95b33b-04a5-40bb-b8cd-80a219a97cad&status=active
```

**Query Parameters:**
- `device_id` (requerido): UUID del dispositivo
- `status` (opcional): `active`, `pending`, `ready`, `completed`, `cancelled`

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "order_number": "ORD-20251114-001",
      "business_name": "Café Central",
      "status": "ready",
      "total": 4.50,
      "created_at": "2025-11-14T19:30:00.000000Z",
      "pickup_qr": "PICKUP-ORD-20251114-001"
    },
    {
      "id": 2,
      "order_number": "ORD-20251114-002",
      "business_name": "Burger House",
      "status": "pending",
      "total": 12.99,
      "created_at": "2025-11-14T20:00:00.000000Z",
      "pickup_qr": null
    }
  ]
}
```

### 5. Obtener Detalle de Orden

**Request:**
```http
GET /api/v1/mobile/orders/1?device_id=ba95b33b-04a5-40bb-b8cd-80a219a97cad
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "order_number": "ORD-20251114-001",
    "business": {
      "id": 1,
      "name": "Café Central",
      "logo_url": "https://example.com/logos/cafe-central.png",
      "address": "Calle Principal 123"
    },
    "items": [
      {
        "id": 1,
        "name": "Café Latte",
        "quantity": 1,
        "unit_price": 4.50,
        "total": 4.50,
        "notes": "Sin azúcar"
      }
    ],
    "subtotal": 4.50,
    "tax": 0.50,
    "total": 5.00,
    "status": "ready",
    "status_history": [
      {
        "status": "pending",
        "timestamp": "2025-11-14T19:30:00.000000Z"
      },
      {
        "status": "preparing",
        "timestamp": "2025-11-14T19:35:00.000000Z"
      },
      {
        "status": "ready",
        "timestamp": "2025-11-14T19:45:00.000000Z"
      }
    ],
    "created_at": "2025-11-14T19:30:00.000000Z",
    "estimated_ready_time": "2025-11-14T19:45:00.000000Z",
    "ready_at": "2025-11-14T19:45:00.000000Z",
    "pickup_qr": "PICKUP-ORD-20251114-001",
    "special_instructions": "Entregar en mesa 5"
  }
}
```

## 🔔 Envío de Notificaciones Push

Cuando el estado de una orden cambia, el backend debe enviar una notificación push al dispositivo.

### Usando Firebase Admin SDK (Recomendado)

```php
use Google\Client as GoogleClient;

class FirebaseService
{
    public function sendNotification($fcmToken, $title, $body, $data = [])
    {
        $client = new GoogleClient();
        $client->setAuthConfig(storage_path('app/firebase-service-account.json'));
        $client->addScope('https://www.googleapis.com/auth/firebase.messaging');

        $httpClient = $client->authorize();

        $message = [
            'message' => [
                'token' => $fcmToken,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                'data' => $data,
                'android' => [
                    'priority' => 'high',
                ],
                'apns' => [
                    'headers' => [
                        'apns-priority' => '10',
                    ],
                ],
            ],
        ];

        $projectId = config('services.firebase.project_id');
        $response = $httpClient->post(
            "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send",
            ['json' => $message]
        );

        return $response->getStatusCode() === 200;
    }
}
```

### Cuándo Enviar Notificaciones

```php
// En el controlador o servicio de órdenes
public function updateOrderStatus($orderId, $newStatus)
{
    $order = Order::findOrFail($orderId);
    $order->status = $newStatus;
    $order->save();

    // Enviar notificación
    if ($order->mobileUser && $order->mobileUser->fcm_token) {
        $messages = [
            'pending' => 'Tu orden ha sido recibida',
            'preparing' => 'Tu orden se está preparando',
            'ready' => '¡Tu orden está lista para recoger!',
            'completed' => 'Tu orden ha sido completada',
            'cancelled' => 'Tu orden ha sido cancelada',
        ];

        $firebaseService = new FirebaseService();
        $firebaseService->sendNotification(
            $order->mobileUser->fcm_token,
            'Actualización de Orden',
            $messages[$newStatus] ?? 'Tu orden ha sido actualizada',
            [
                'order_id' => (string)$order->id,
                'status' => $newStatus,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ]
        );
    }

    return $order;
}
```

## 🗄️ Schema de Base de Datos

### Tabla: mobile_users

```sql
CREATE TABLE mobile_users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    device_name VARCHAR(255),
    platform VARCHAR(50),
    fcm_token TEXT,
    last_active_at TIMESTAMP NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    INDEX idx_device_id (device_id)
);
```

### Tabla: orders

Debe incluir:

```sql
ALTER TABLE orders ADD COLUMN mobile_user_id BIGINT UNSIGNED NULL;
ALTER TABLE orders ADD FOREIGN KEY (mobile_user_id) REFERENCES mobile_users(id);
```

## 🔐 Seguridad

### Rate Limiting

```php
// app/Http/Kernel.php
protected $middlewareGroups = [
    'api' => [
        'throttle:60,1', // 60 requests por minuto
        \Illuminate\Routing\Middleware\SubstituteBindings::class,
    ],
];
```

### Validación de Dispositivos

```php
public function associateOrder(Request $request)
{
    $validated = $request->validate([
        'device_id' => 'required|uuid',
        'qr_code' => 'required|string|max:255',
    ]);

    $mobileUser = MobileUser::where('device_id', $validated['device_id'])->first();

    if (!$mobileUser) {
        return response()->json([
            'success' => false,
            'message' => 'Dispositivo no registrado',
        ], 404);
    }

    // Continuar con asociación...
}
```

### Sanitización de Datos

```php
use Illuminate\Support\Str;

$deviceName = Str::limit($request->device_name, 255);
$deviceName = strip_tags($deviceName);
```

## 🧪 Testing del Backend

### Usando cURL

```bash
# Registrar dispositivo
curl -X POST http://localhost:8000/api/v1/mobile/register \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test-device-123",
    "device_name": "Test Phone",
    "platform": "android",
    "fcm_token": "test-token"
  }'

# Asociar orden
curl -X POST http://localhost:8000/api/v1/mobile/orders/associate \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test-device-123",
    "qr_code": "ORD-20251114-001"
  }'

# Obtener órdenes
curl -X GET "http://localhost:8000/api/v1/mobile/orders?device_id=test-device-123"
```

### Usando Postman

Importa esta colección: [Link a colección de Postman]

## 📝 Checklist de Configuración

- [ ] Instalar dependencias de Firebase en Laravel
- [ ] Configurar variables de entorno
- [ ] Crear endpoints requeridos
- [ ] Configurar CORS
- [ ] Implementar envío de notificaciones
- [ ] Crear tablas en base de datos
- [ ] Configurar rate limiting
- [ ] Probar endpoints con cURL o Postman
- [ ] Verificar que notificaciones lleguen a la app

## 🆘 Problemas Comunes

### "CORS policy error"
- Verifica configuración en `config/cors.php`
- Asegúrate de tener el middleware CORS habilitado

### "FCM token inválido"
- Verifica que el Server Key sea correcto
- Verifica que el token no haya expirado

### "Orden no encontrada"
- Verifica que el QR code sea válido
- Verifica que la orden exista en la base de datos

## 📚 Referencias

- [Laravel Documentation](https://laravel.com/docs)
- [Firebase Admin SDK PHP](https://firebase-php.readthedocs.io/)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)

---

**¿Necesitas ayuda con el backend?**

Contacta al equipo de desarrollo o crea un issue en el repositorio del backend.
