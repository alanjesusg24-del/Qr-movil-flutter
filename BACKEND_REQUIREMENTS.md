# Especificaciones del Backend Laravel para Order QR Mobile App

## Resumen del Sistema
Sistema de gestión de órdenes con código QR que permite a dispositivos móviles registrarse, escanear códigos QR de órdenes y recibir notificaciones en tiempo real sobre el estado de sus órdenes.

---

## Base URL Requerida
```
http://[TU_IP]:8000/api/v1
```

---

## 1. MODELOS Y MIGRACIONES

### 1.1 Tabla: `mobile_users`
Almacena los dispositivos móviles registrados.

```php
Schema::create('mobile_users', function (Blueprint $table) {
    $table->id();
    $table->string('device_id')->unique(); // UUID del dispositivo
    $table->string('fcm_token')->nullable(); // Token para notificaciones push
    $table->string('device_type'); // 'android' o 'ios'
    $table->string('device_model')->nullable(); // Ej: "Samsung Galaxy S21"
    $table->string('os_version')->nullable(); // Ej: "Android 15"
    $table->string('app_version')->nullable(); // Ej: "1.0.0"
    $table->boolean('is_active')->default(true);
    $table->timestamp('last_seen_at')->nullable();
    $table->timestamps();
    $table->softDeletes();
});
```

### 1.2 Tabla: `orders`
Almacena las órdenes del sistema.

```php
Schema::create('orders', function (Blueprint $table) {
    $table->id();
    $table->string('order_number')->unique(); // Ej: "ORD-2024-001"
    $table->string('qr_token')->unique(); // Token único para el QR
    $table->foreignId('mobile_user_id')->nullable()->constrained('mobile_users')->nullOnDelete();
    $table->string('customer_name');
    $table->string('customer_phone')->nullable();
    $table->string('customer_email')->nullable();
    $table->enum('status', ['pending', 'confirmed', 'in_progress', 'ready', 'completed', 'cancelled'])->default('pending');
    $table->text('description')->nullable();
    $table->decimal('total_amount', 10, 2)->nullable();
    $table->timestamp('associated_at')->nullable(); // Cuando se escaneó el QR
    $table->timestamps();
    $table->softDeletes();
});
```

### 1.3 Tabla: `order_items` (Opcional pero recomendado)
Detalles de productos/servicios en cada orden.

```php
Schema::create('order_items', function (Blueprint $table) {
    $table->id();
    $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
    $table->string('item_name');
    $table->text('description')->nullable();
    $table->integer('quantity')->default(1);
    $table->decimal('unit_price', 10, 2);
    $table->decimal('total_price', 10, 2);
    $table->timestamps();
});
```

### 1.4 Tabla: `order_status_history` (Opcional pero recomendado)
Historial de cambios de estado de órdenes.

```php
Schema::create('order_status_history', function (Blueprint $table) {
    $table->id();
    $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
    $table->string('old_status')->nullable();
    $table->string('new_status');
    $table->text('notes')->nullable();
    $table->string('changed_by')->nullable(); // Usuario/sistema que hizo el cambio
    $table->timestamps();
});
```

---

## 2. RUTAS API (routes/api.php)

```php
Route::prefix('v1')->group(function () {
    Route::prefix('mobile')->group(function () {
        // Registro de dispositivo (sin autenticación)
        Route::post('/register', [MobileController::class, 'registerDevice']);

        // Rutas protegidas (requieren X-Device-ID header)
        Route::middleware(['mobile.device'])->group(function () {
            // Asociar orden escaneando QR
            Route::post('/orders/associate', [MobileController::class, 'associateOrder']);

            // Obtener órdenes del dispositivo
            Route::get('/orders', [MobileController::class, 'getOrders']);

            // Obtener detalle de una orden
            Route::get('/orders/{orderId}', [MobileController::class, 'getOrderDetail']);

            // Actualizar FCM Token
            Route::put('/update-token', [MobileController::class, 'updateFcmToken']);
        });
    });
});
```

---

## 3. MIDDLEWARE: `MobileDeviceMiddleware`

Crea un middleware que valide el header `X-Device-ID`:

```php
// app/Http/Middleware/MobileDeviceMiddleware.php

public function handle($request, Closure $next)
{
    $deviceId = $request->header('X-Device-ID');

    if (!$deviceId) {
        return response()->json([
            'success' => false,
            'message' => 'Device ID is required',
        ], 401);
    }

    $mobileUser = MobileUser::where('device_id', $deviceId)->first();

    if (!$mobileUser) {
        return response()->json([
            'success' => false,
            'message' => 'Device not registered',
        ], 404);
    }

    // Actualizar last_seen_at
    $mobileUser->update(['last_seen_at' => now()]);

    // Agregar el usuario al request
    $request->merge(['mobile_user' => $mobileUser]);

    return $next($request);
}
```

Registrar el middleware en `app/Http/Kernel.php`:
```php
protected $middlewareAliases = [
    // ... otros middlewares
    'mobile.device' => \App\Http\Middleware\MobileDeviceMiddleware::class,
];
```

---

## 4. CONTROLADOR: `MobileController`

```php
// app/Http/Controllers/Api/V1/MobileController.php

class MobileController extends Controller
{
    /**
     * Registrar o actualizar un dispositivo móvil
     * POST /api/v1/mobile/register
     */
    public function registerDevice(Request $request)
    {
        $validated = $request->validate([
            'device_id' => 'required|string',
            'fcm_token' => 'nullable|string',
            'device_type' => 'required|in:android,ios',
            'device_model' => 'nullable|string',
            'os_version' => 'nullable|string',
            'app_version' => 'nullable|string',
        ]);

        $mobileUser = MobileUser::updateOrCreate(
            ['device_id' => $validated['device_id']],
            array_merge($validated, ['last_seen_at' => now()])
        );

        return response()->json([
            'success' => true,
            'message' => 'Device registered successfully',
            'data' => $mobileUser,
        ], 200);
    }

    /**
     * Asociar una orden con el dispositivo mediante QR
     * POST /api/v1/mobile/orders/associate
     */
    public function associateOrder(Request $request)
    {
        $validated = $request->validate([
            'qr_token' => 'required|string',
        ]);

        $order = Order::where('qr_token', $validated['qr_token'])->first();

        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'QR code invalid or expired',
            ], 404);
        }

        // Si ya está asociada a otro dispositivo
        if ($order->mobile_user_id && $order->mobile_user_id !== $request->mobile_user->id) {
            return response()->json([
                'success' => false,
                'message' => 'This order is already associated with another device',
            ], 409);
        }

        // Asociar orden con el dispositivo
        $order->update([
            'mobile_user_id' => $request->mobile_user->id,
            'associated_at' => now(),
        ]);

        // Cargar relaciones
        $order->load('items', 'statusHistory');

        return response()->json([
            'success' => true,
            'message' => 'Order associated successfully',
            'data' => [
                'order' => $order,
            ],
        ], 200);
    }

    /**
     * Obtener órdenes del dispositivo
     * GET /api/v1/mobile/orders?status=pending&page=1&per_page=20
     */
    public function getOrders(Request $request)
    {
        $query = Order::where('mobile_user_id', $request->mobile_user->id);

        // Filtrar por estado
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        // Ordenar por más recientes
        $query->orderBy('created_at', 'desc');

        // Paginación
        $perPage = $request->get('per_page', 20);
        $orders = $query->with('items')->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => [
                'orders' => $orders->items(),
                'pagination' => [
                    'current_page' => $orders->currentPage(),
                    'total_pages' => $orders->lastPage(),
                    'total_items' => $orders->total(),
                    'per_page' => $orders->perPage(),
                ],
            ],
        ], 200);
    }

    /**
     * Obtener detalle de una orden
     * GET /api/v1/mobile/orders/{orderId}
     */
    public function getOrderDetail(Request $request, $orderId)
    {
        $order = Order::where('id', $orderId)
                      ->where('mobile_user_id', $request->mobile_user->id)
                      ->with(['items', 'statusHistory'])
                      ->first();

        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'Order not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'order' => $order,
            ],
        ], 200);
    }

    /**
     * Actualizar token FCM del dispositivo
     * PUT /api/v1/mobile/update-token
     */
    public function updateFcmToken(Request $request)
    {
        $validated = $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $request->mobile_user->update([
            'fcm_token' => $validated['fcm_token'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'FCM token updated successfully',
        ], 200);
    }
}
```

---

## 5. MODELOS ELOQUENT

### MobileUser Model
```php
// app/Models/MobileUser.php

class MobileUser extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'device_id',
        'fcm_token',
        'device_type',
        'device_model',
        'os_version',
        'app_version',
        'is_active',
        'last_seen_at',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'last_seen_at' => 'datetime',
    ];

    public function orders()
    {
        return $this->hasMany(Order::class);
    }
}
```

### Order Model
```php
// app/Models/Order.php

class Order extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'order_number',
        'qr_token',
        'mobile_user_id',
        'customer_name',
        'customer_phone',
        'customer_email',
        'status',
        'description',
        'total_amount',
        'associated_at',
    ];

    protected $casts = [
        'total_amount' => 'decimal:2',
        'associated_at' => 'datetime',
    ];

    public function mobileUser()
    {
        return $this->belongsTo(MobileUser::class);
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function statusHistory()
    {
        return $this->hasMany(OrderStatusHistory::class);
    }

    // Generar QR token único al crear orden
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($order) {
            if (!$order->qr_token) {
                $order->qr_token = \Illuminate\Support\Str::random(32);
            }
        });
    }
}
```

### OrderItem Model
```php
// app/Models/OrderItem.php

class OrderItem extends Model
{
    protected $fillable = [
        'order_id',
        'item_name',
        'description',
        'quantity',
        'unit_price',
        'total_price',
    ];

    protected $casts = [
        'quantity' => 'integer',
        'unit_price' => 'decimal:2',
        'total_price' => 'decimal:2',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }
}
```

### OrderStatusHistory Model
```php
// app/Models/OrderStatusHistory.php

class OrderStatusHistory extends Model
{
    protected $table = 'order_status_history';

    protected $fillable = [
        'order_id',
        'old_status',
        'new_status',
        'notes',
        'changed_by',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }
}
```

---

## 6. NOTIFICACIONES PUSH (Opcional pero recomendado)

### Instalar paquete FCM
```bash
composer require kreait/firebase-php
```

### Configurar Firebase
1. Descarga el archivo `firebase_credentials.json` desde Firebase Console
2. Guárdalo en `storage/app/firebase/`
3. Agrega a `.env`:
```
FIREBASE_CREDENTIALS=storage/app/firebase/firebase_credentials.json
```

### Service para enviar notificaciones
```php
// app/Services/FirebaseNotificationService.php

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;

class FirebaseNotificationService
{
    protected $messaging;

    public function __construct()
    {
        $firebase = (new Factory)
            ->withServiceAccount(storage_path('app/firebase/firebase_credentials.json'));

        $this->messaging = $firebase->createMessaging();
    }

    public function sendOrderNotification($fcmToken, $order, $title, $body)
    {
        $message = CloudMessage::withTarget('token', $fcmToken)
            ->withNotification([
                'title' => $title,
                'body' => $body,
            ])
            ->withData([
                'order_id' => (string) $order->id,
                'order_number' => $order->order_number,
                'status' => $order->status,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ]);

        try {
            $this->messaging->send($message);
            return true;
        } catch (\Exception $e) {
            \Log::error('FCM Error: ' . $e->getMessage());
            return false;
        }
    }
}
```

### Observer para Order Model
```php
// app/Observers/OrderObserver.php

class OrderObserver
{
    protected $notificationService;

    public function __construct(FirebaseNotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    public function updated(Order $order)
    {
        // Si cambió el estado
        if ($order->isDirty('status') && $order->mobile_user_id) {
            $mobileUser = $order->mobileUser;

            if ($mobileUser && $mobileUser->fcm_token) {
                $statusMessages = [
                    'confirmed' => 'Tu orden ha sido confirmada',
                    'in_progress' => 'Tu orden está en preparación',
                    'ready' => '¡Tu orden está lista!',
                    'completed' => 'Tu orden ha sido completada',
                    'cancelled' => 'Tu orden ha sido cancelada',
                ];

                $title = "Actualización de Orden #{$order->order_number}";
                $body = $statusMessages[$order->status] ?? 'Estado actualizado';

                $this->notificationService->sendOrderNotification(
                    $mobileUser->fcm_token,
                    $order,
                    $title,
                    $body
                );
            }

            // Guardar en historial
            OrderStatusHistory::create([
                'order_id' => $order->id,
                'old_status' => $order->getOriginal('status'),
                'new_status' => $order->status,
                'changed_by' => auth()->user()->name ?? 'System',
            ]);
        }
    }
}
```

Registrar el observer en `AppServiceProvider`:
```php
public function boot()
{
    Order::observe(OrderObserver::class);
}
```

---

## 7. SEEDER DE EJEMPLO

```php
// database/seeders/OrderSeeder.php

class OrderSeeder extends Seeder
{
    public function run()
    {
        $orders = [
            [
                'order_number' => 'ORD-2024-001',
                'customer_name' => 'Juan Pérez',
                'customer_phone' => '+52 555 1234567',
                'customer_email' => 'juan@example.com',
                'status' => 'pending',
                'description' => 'Pizza grande + Refresco',
                'total_amount' => 250.00,
            ],
            [
                'order_number' => 'ORD-2024-002',
                'customer_name' => 'María García',
                'customer_phone' => '+52 555 7654321',
                'status' => 'in_progress',
                'description' => 'Hamburguesa + Papas',
                'total_amount' => 150.00,
            ],
        ];

        foreach ($orders as $orderData) {
            $order = Order::create($orderData);

            // Crear items de ejemplo
            OrderItem::create([
                'order_id' => $order->id,
                'item_name' => 'Producto ' . $order->order_number,
                'quantity' => 2,
                'unit_price' => $order->total_amount / 2,
                'total_price' => $order->total_amount,
            ]);
        }
    }
}
```

---

## 8. COMANDOS PARA EJECUTAR

```bash
# 1. Crear las migraciones
php artisan make:migration create_mobile_users_table
php artisan make:migration create_orders_table
php artisan make:migration create_order_items_table
php artisan make:migration create_order_status_history_table

# 2. Ejecutar migraciones
php artisan migrate

# 3. Crear modelos
php artisan make:model MobileUser
php artisan make:model Order
php artisan make:model OrderItem
php artisan make:model OrderStatusHistory

# 4. Crear controlador
php artisan make:controller Api/V1/MobileController

# 5. Crear middleware
php artisan make:middleware MobileDeviceMiddleware

# 6. Crear seeder
php artisan make:seeder OrderSeeder
php artisan db:seed --class=OrderSeeder

# 7. Iniciar servidor
php artisan serve --host=0.0.0.0 --port=8000
```

---

## 9. FORMATO DE RESPUESTAS JSON

Todas las respuestas deben seguir este formato:

### Éxito:
```json
{
    "success": true,
    "message": "Mensaje descriptivo",
    "data": {
        // ... datos
    }
}
```

### Error:
```json
{
    "success": false,
    "message": "Descripción del error",
    "errors": {
        // ... detalles de validación (opcional)
    }
}
```

---

## 10. PRUEBAS CON POSTMAN/CURL

### Registrar dispositivo:
```bash
curl -X POST http://192.168.1.66:8000/api/v1/mobile/register \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test-device-123",
    "device_type": "android",
    "device_model": "Samsung Galaxy S21",
    "os_version": "Android 13",
    "app_version": "1.0.0"
  }'
```

### Asociar orden:
```bash
curl -X POST http://192.168.1.66:8000/api/v1/mobile/orders/associate \
  -H "Content-Type: application/json" \
  -H "X-Device-ID: test-device-123" \
  -d '{
    "qr_token": "[QR_TOKEN_DE_LA_ORDEN]"
  }'
```

### Obtener órdenes:
```bash
curl -X GET "http://192.168.1.66:8000/api/v1/mobile/orders?status=pending" \
  -H "X-Device-ID: test-device-123"
```

---

## 11. CONSIDERACIONES DE SEGURIDAD

1. **Rate Limiting**: Agregar throttling a las rutas API
2. **Validación**: Validar todos los inputs
3. **CORS**: Configurar CORS si es necesario
4. **Tokens**: Los QR tokens deben ser únicos y no predecibles
5. **HTTPS**: En producción, usar HTTPS obligatoriamente
6. **Logs**: Implementar logging de todas las operaciones críticas

---

## 12. CONFIGURACIÓN ADICIONAL

### Habilitar CORS (config/cors.php)
```php
'paths' => ['api/*'],
'allowed_methods' => ['*'],
'allowed_origins' => ['*'], // En producción, especificar dominios
'allowed_headers' => ['*'],
```

### Rate Limiting (RouteServiceProvider)
```php
RateLimiter::for('mobile', function (Request $request) {
    return Limit::perMinute(60)->by($request->header('X-Device-ID'));
});
```

---

## NOTAS FINALES

- La app móvil funciona en modo offline-first, así que no crasheará si el servidor no está disponible
- Los códigos QR deben generarse con el campo `qr_token` de cada orden
- Firebase es opcional, pero recomendado para notificaciones push
- Implementar soft deletes en todos los modelos principales
- Agregar índices en campos frecuentemente consultados (device_id, qr_token, order_number)

---

**Fecha de creación**: 2025-11-06
**Versión**: 1.0
**App móvil compatible**: Order QR Mobile v1.0.0
