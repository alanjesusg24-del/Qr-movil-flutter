# 🔥 Configuración Firebase + Laravel para Notificaciones Push

## 📋 Resumen

Este documento explica cómo configurar Firebase y Laravel para enviar notificaciones push automáticamente cuando una orden cambie de estado.

---

## PARTE 1: Configuración en Firebase Console

### Paso 1: Obtener el Server Key

1. **Ir a Firebase Console**
   - Abrir: https://console.firebase.google.com/
   - Seleccionar tu proyecto

2. **Ir a Configuración del Proyecto**
   - Click en el ⚙️ (engranaje) al lado de "Project Overview"
   - Seleccionar **"Project settings"**

3. **Ir a Cloud Messaging**
   - Click en la pestaña **"Cloud Messaging"**
   - Buscar la sección **"Cloud Messaging API (Legacy)"**

4. **Obtener las credenciales**

   Necesitas **UNA** de estas dos opciones:

   #### Opción A: Server Key (Legacy) - Más fácil ✅
   ```
   En "Cloud Messaging API (Legacy)":
   - Buscar "Server key"
   - Copiar el valor (ejemplo: AAAAxxxx-xxx:APA91b...)
   ```

   #### Opción B: API Key (Recomendado para nuevos proyectos)
   ```
   En "General":
   - Buscar "Web API Key"
   - Copiar el valor
   ```

   **⚠️ IMPORTANTE**: Si ves un mensaje que dice "Cloud Messaging API (Legacy) will be deprecated", necesitas habilitar la nueva API:

5. **Habilitar Firebase Cloud Messaging API (si es necesario)**
   - En la sección "Cloud Messaging API (Legacy)", buscar el link que dice **"Manage API in Google Cloud Console"**
   - O ir directamente a: https://console.cloud.google.com/apis/library/fcm.googleapis.com
   - Click en **"Enable"** (Habilitar)

---

## PARTE 2: Configuración en Laravel Backend

### Paso 1: Instalar Dependencias PHP para FCM

```bash
cd /ruta/a/tu/proyecto/laravel
composer require kreait/firebase-php
```

O si prefieres una librería más simple:

```bash
composer require brozot/laravel-fcm
```

### Paso 2: Crear Servicio de Notificaciones en Laravel

Crear archivo: `app/Services/PushNotificationService.php`

```php
<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PushNotificationService
{
    /**
     * Server Key de Firebase (obtener de Firebase Console)
     */
    private const FCM_SERVER_KEY = 'AAAA-xxxxx:APA91b...'; // ← Reemplazar con tu Server Key

    /**
     * URL de la API de FCM
     */
    private const FCM_URL = 'https://fcm.googleapis.com/fcm/send';

    /**
     * Enviar notificación de cambio de estado de orden
     *
     * @param string $fcmToken Token FCM del dispositivo móvil
     * @param object $order Objeto de la orden
     * @param string $oldStatus Estado anterior
     * @param string $newStatus Estado nuevo
     * @return bool
     */
    public static function sendOrderStatusChange($fcmToken, $order, $oldStatus, $newStatus)
    {
        // Determinar el título y mensaje según el estado
        [$title, $body] = self::getNotificationContent($order, $oldStatus, $newStatus);

        // Payload de la notificación
        $data = [
            'to' => $fcmToken,
            'notification' => [
                'title' => $title,
                'body' => $body,
                'sound' => 'default',
            ],
            'data' => [
                'type' => 'order_status_change',
                'order_id' => (string) $order->id,
                'order_number' => $order->order_number,
                'old_status' => $oldStatus,
                'new_status' => $newStatus,
                'folio_number' => $order->folio_number,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ],
            'priority' => 'high',
            'content_available' => true,
        ];

        return self::sendNotification($data);
    }

    /**
     * Enviar notificación de nueva orden asociada
     */
    public static function sendOrderAssociated($fcmToken, $order)
    {
        $data = [
            'to' => $fcmToken,
            'notification' => [
                'title' => '🎉 Nueva orden asociada',
                'body' => "Se ha asociado la orden {$order->order_number} a tu dispositivo",
                'sound' => 'default',
            ],
            'data' => [
                'type' => 'order_associated',
                'order_id' => (string) $order->id,
                'order_number' => $order->order_number,
                'new_status' => $order->status,
                'folio_number' => $order->folio_number,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ],
            'priority' => 'high',
            'content_available' => true,
        ];

        return self::sendNotification($data);
    }

    /**
     * Enviar notificación de orden cancelada
     */
    public static function sendOrderCancelled($fcmToken, $order)
    {
        $data = [
            'to' => $fcmToken,
            'notification' => [
                'title' => '❌ Orden cancelada',
                'body' => "La orden {$order->order_number} ha sido cancelada",
                'sound' => 'default',
            ],
            'data' => [
                'type' => 'order_cancelled',
                'order_id' => (string) $order->id,
                'order_number' => $order->order_number,
                'old_status' => 'pending',
                'new_status' => 'cancelled',
                'folio_number' => $order->folio_number,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ],
            'priority' => 'high',
            'content_available' => true,
        ];

        return self::sendNotification($data);
    }

    /**
     * Obtener el contenido de la notificación según el cambio de estado
     */
    private static function getNotificationContent($order, $oldStatus, $newStatus)
    {
        switch ($newStatus) {
            case 'ready':
                return [
                    '🎉 ¡Tu orden está lista!',
                    "La orden {$order->order_number} está lista para recoger. ¡Ve por ella!"
                ];

            case 'delivered':
                return [
                    '✅ Orden entregada',
                    "La orden {$order->order_number} ha sido entregada exitosamente"
                ];

            case 'cancelled':
                return [
                    '❌ Orden cancelada',
                    "La orden {$order->order_number} ha sido cancelada"
                ];

            case 'pending':
                return [
                    '⏳ Orden en preparación',
                    "Tu orden {$order->order_number} está siendo preparada"
                ];

            default:
                return [
                    '🔔 Actualización de orden',
                    "La orden {$order->order_number} cambió de estado a {$newStatus}"
                ];
        }
    }

    /**
     * Enviar notificación a FCM
     */
    private static function sendNotification($data)
    {
        try {
            $response = Http::withHeaders([
                'Authorization' => 'key=' . self::FCM_SERVER_KEY,
                'Content-Type' => 'application/json',
            ])->post(self::FCM_URL, $data);

            if ($response->successful()) {
                Log::info('✅ Notificación enviada exitosamente', [
                    'response' => $response->json(),
                ]);
                return true;
            } else {
                Log::error('❌ Error al enviar notificación', [
                    'status' => $response->status(),
                    'response' => $response->body(),
                ]);
                return false;
            }
        } catch (\Exception $e) {
            Log::error('❌ Excepción al enviar notificación', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            return false;
        }
    }
}
```

### Paso 3: Configurar el .env de Laravel

Agregar en `.env`:

```env
# Firebase Cloud Messaging
FCM_SERVER_KEY=AAAAxxxx-xxx:APA91b...
```

Y actualizar el servicio:

```php
// En PushNotificationService.php, cambiar:
private const FCM_SERVER_KEY = 'AAAA-xxxxx:APA91b...';

// Por:
private static function getServerKey()
{
    return env('FCM_SERVER_KEY');
}

// Y actualizar en sendNotification():
'Authorization' => 'key=' . self::getServerKey(),
```

### Paso 4: Actualizar el Modelo Order

Agregar en `app/Models/Order.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Services\PushNotificationService;

class Order extends Model
{
    protected $fillable = [
        'order_number',
        'folio_number',
        'status',
        'mobile_user_id',
        // ... otros campos
    ];

    /**
     * Relación con el usuario móvil
     */
    public function mobileUser()
    {
        return $this->belongsTo(MobileUser::class);
    }

    /**
     * Boot method para observar cambios en el modelo
     */
    protected static function booted()
    {
        // Escuchar cambios en el modelo
        static::updated(function ($order) {
            // Verificar si cambió el status
            if ($order->isDirty('status')) {
                $oldStatus = $order->getOriginal('status');
                $newStatus = $order->status;

                // Obtener el token FCM del usuario móvil
                $mobileUser = $order->mobileUser;

                if ($mobileUser && $mobileUser->fcm_token) {
                    // Enviar notificación push
                    PushNotificationService::sendOrderStatusChange(
                        $mobileUser->fcm_token,
                        $order,
                        $oldStatus,
                        $newStatus
                    );
                }
            }
        });
    }
}
```

### Paso 5: Alternativa - Usar en el Controlador

Si prefieres más control, puedes enviar la notificación manualmente desde el controlador:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Services\PushNotificationService;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    /**
     * Actualizar el estado de una orden
     */
    public function updateStatus(Request $request, $orderId)
    {
        $order = Order::findOrFail($orderId);
        $oldStatus = $order->status;

        // Actualizar el estado
        $order->status = $request->status;
        $order->save();

        // Enviar notificación push al usuario móvil
        $mobileUser = $order->mobileUser;

        if ($mobileUser && $mobileUser->fcm_token) {
            PushNotificationService::sendOrderStatusChange(
                $mobileUser->fcm_token,
                $order,
                $oldStatus,
                $request->status
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Estado actualizado y notificación enviada',
            'order' => $order,
        ]);
    }

    /**
     * Marcar orden como lista para recoger
     */
    public function markAsReady($orderId)
    {
        $order = Order::findOrFail($orderId);
        $oldStatus = $order->status;

        // Cambiar a "ready"
        $order->status = 'ready';
        $order->save();

        // Enviar notificación
        $mobileUser = $order->mobileUser;

        if ($mobileUser && $mobileUser->fcm_token) {
            PushNotificationService::sendOrderStatusChange(
                $mobileUser->fcm_token,
                $order,
                $oldStatus,
                'ready'
            );
        }

        return response()->json([
            'success' => true,
            'message' => '¡Notificación enviada! El cliente será notificado.',
            'order' => $order,
        ]);
    }
}
```

### Paso 6: Crear Rutas en Laravel

Agregar en `routes/api.php`:

```php
use App\Http\Controllers\OrderController;

// Actualizar estado de orden
Route::patch('/orders/{id}/status', [OrderController::class, 'updateStatus']);

// Marcar orden como lista
Route::post('/orders/{id}/mark-as-ready', [OrderController::class, 'markAsReady']);
```

---

## PARTE 3: Verificar que la tabla mobile_users tenga fcm_token

### Migración (si no existe la columna)

```bash
php artisan make:migration add_fcm_token_to_mobile_users_table
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
            $table->text('fcm_token')->nullable()->after('device_uuid');
        });
    }

    public function down()
    {
        Schema::table('mobile_users', function (Blueprint $table) {
            $table->dropColumn('fcm_token');
        });
    }
};
```

Ejecutar:
```bash
php artisan migrate
```

---

## PARTE 4: Flujo Completo

```
┌─────────────────────────────────────────────────────────────────┐
│                  1. USUARIO ESCANEA QR                          │
│  - App móvil escanea QR                                         │
│  - App envía token FCM al backend                               │
│  - Backend guarda token en mobile_users.fcm_token               │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│         2. BACKEND CAMBIA ESTADO DE ORDEN A "READY"             │
│  - Admin marca orden como lista                                 │
│  - Laravel ejecuta: $order->status = 'ready'                    │
│  - Model Observer detecta cambio                                │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│          3. LARAVEL ENVÍA NOTIFICACIÓN A FCM                    │
│  - PushNotificationService::sendOrderStatusChange()             │
│  - Obtiene el fcm_token del mobile_user                         │
│  - Envía POST a FCM con el payload                              │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│               4. FCM ENVÍA A DISPOSITIVO                        │
│  - Firebase Cloud Messaging recibe la notificación              │
│  - FCM enruta al dispositivo correcto usando el token           │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│           5. APP MÓVIL RECIBE Y MUESTRA NOTIFICACIÓN            │
│  - NotificationService detecta la notificación                  │
│  - Muestra: "¡Tu orden está lista para recoger!"                │
│  - Actualiza la lista de órdenes automáticamente                │
│  - Usuario toca → Abre detalle de la orden                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## PARTE 5: Probar el Sistema

### Opción 1: Probar desde Postman

```http
POST http://tu-backend.com/api/orders/2/mark-as-ready
Authorization: Bearer tu_token_aqui
Content-Type: application/json
```

### Opción 2: Probar desde tinker

```bash
php artisan tinker
```

```php
$order = Order::find(2);
$mobileUser = $order->mobileUser;

// Cambiar estado manualmente
$order->status = 'ready';
$order->save();

// O enviar notificación manualmente
PushNotificationService::sendOrderStatusChange(
    $mobileUser->fcm_token,
    $order,
    'pending',
    'ready'
);
```

### Opción 3: Probar con el script de Flutter

```powershell
# En la carpeta del proyecto Flutter
.\test_notification.ps1
```

---

## 🔍 Troubleshooting

### Error: "Authentication Error" al enviar notificación

**Causa**: Server Key incorrecto o no habilitado

**Solución**:
1. Verificar que el Server Key sea correcto
2. Habilitar "Firebase Cloud Messaging API" en Google Cloud Console
3. Esperar 5-10 minutos después de habilitar

### Error: "Invalid Registration Token"

**Causa**: Token FCM inválido o expirado

**Solución**:
1. Verificar que el token se guardó correctamente en la base de datos
2. Verificar que el token no tiene espacios o caracteres extraños
3. Reinstalar la app para generar un nuevo token

### Notificación no llega

**Checklist**:
- [ ] Server Key correcto en `.env`
- [ ] Token FCM guardado en `mobile_users.fcm_token`
- [ ] Firebase Cloud Messaging API habilitado
- [ ] App móvil tiene permisos de notificación
- [ ] Dispositivo tiene conexión a internet

### Ver logs en Laravel

```php
// Agregar en PushNotificationService::sendNotification()
Log::info('Enviando notificación', [
    'token' => substr($data['to'], 0, 20) . '...',
    'type' => $data['data']['type'],
    'order_id' => $data['data']['order_id'],
]);
```

Ver logs:
```bash
tail -f storage/logs/laravel.log
```

---

## 📚 Referencias

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FCM HTTP v1 API](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)
- [Laravel HTTP Client](https://laravel.com/docs/http-client)

---

## ✅ Checklist Final

### En Firebase Console:
- [ ] Obtener Server Key de Cloud Messaging
- [ ] Habilitar Firebase Cloud Messaging API
- [ ] (Opcional) Configurar notificaciones de prueba

### En Laravel Backend:
- [ ] Instalar dependencia HTTP de Laravel (ya incluida)
- [ ] Crear `PushNotificationService.php`
- [ ] Agregar `FCM_SERVER_KEY` en `.env`
- [ ] Actualizar modelo `Order` con Observer
- [ ] Verificar que `mobile_users` tenga columna `fcm_token`
- [ ] Probar envío de notificación

### En Flutter App:
- [ ] Ya está implementado ✅
- [ ] Solo probar que reciba las notificaciones

---

**¡Listo!** Con esta configuración, cada vez que cambies el estado de una orden a "ready" en Laravel, automáticamente se enviará una notificación push al dispositivo móvil del cliente.
