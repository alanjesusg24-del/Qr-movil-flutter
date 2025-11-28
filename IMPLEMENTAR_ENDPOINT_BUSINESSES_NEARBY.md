# Implementación del Endpoint /businesses/nearby

## 📌 Contexto

El endpoint `/api/v1/businesses/nearby` está retornando el error:
```
400 Bad Request - "Parámetros de ubicación inválidos"
```

## 🎯 Objetivo

Implementar correctamente el endpoint `/businesses/nearby` en Laravel para que funcione con la aplicación Flutter.

---

## 📤 Parámetros que envía Flutter

La aplicación Flutter está enviando los siguientes parámetros vía **GET** (query parameters):

```json
{
  "latitude": 19.432847,    // double (número decimal)
  "longitude": -99.133208,  // double (número decimal)
  "radius": 10.0            // double (número decimal, en kilómetros)
}
```

### Código Flutter actual:
```dart
static Future<List<Business>> getNearbyBusinesses({
  required double latitude,
  required double longitude,
  double radius = 10.0,
}) async {
  try {
    final response = await _dio.get(
      ApiConfig.getNearbyBusinesses, // '/businesses/nearby'
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      },
      options: Options(
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> businessesJson = response.data['data']['businesses'] ?? response.data['data'];
      return businessesJson.map((json) => Business.fromJson(json)).toList();
    } else {
      throw Exception(response.data['message'] ?? 'Error al obtener negocios cercanos');
    }
  } on DioException catch (e) {
    throw _handleError(e);
  }
}
```

### Headers enviados:
```
Content-Type: application/json
Accept: application/json
ngrok-skip-browser-warning: true
X-Device-ID: [device-id]
Authorization: Bearer [token] (si el usuario está autenticado)
```

---

## 📥 Respuesta esperada por Flutter

Flutter espera recibir una respuesta en el siguiente formato:

```json
{
  "success": true,
  "data": {
    "businesses": [
      {
        "business_id": 1,
        "business_name": "Nombre del Negocio",
        "phone": "1234567890",
        "address": "Dirección completa",
        "address_details": "Detalles adicionales",
        "city": "Ciudad",
        "state": "Estado",
        "postal_code": "12345",
        "latitude": 19.432608,
        "longitude": -99.133209,
        "distance_km": 0.5,           // Distancia en kilómetros
        "is_open": true,
        "rating": 4.5,                 // Puede ser null
        "total_reviews": 10            // Puede ser null
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total": 3,
      "last_page": 1,
      "from": 1,
      "to": 3
    },
    "user_location": {
      "latitude": 19.432847,
      "longitude": -99.133208
    },
    "search_radius_km": "10"
  },
  "message": "Negocios cercanos obtenidos exitosamente"
}
```

**Nota**: Flutter puede manejar también si `data` es directamente el array de negocios:
```json
{
  "success": true,
  "data": [ /* array de businesses */ ],
  "message": "..."
}
```

---

## 🛠️ Información necesaria del Backend Laravel

Por favor, comparte la siguiente información para poder implementar correctamente el endpoint:

### 1. **Definición de la Ruta** (`routes/api.php`)
```php
// ¿Cómo está definida la ruta?
// Ejemplo:
Route::get('/businesses/nearby', [BusinessController::class, 'nearby']);

// O si está en un grupo:
Route::prefix('businesses')->group(function () {
    Route::get('/nearby', [BusinessController::class, 'nearby']);
});
```

### 2. **Controlador** (`app/Http/Controllers/BusinessController.php`)
```php
// El método completo que maneja el endpoint
public function nearby(Request $request) {
    // TODO: Implementar o compartir el código actual
}
```

### 3. **Validación de Parámetros**
```php
// ¿Qué validaciones se están aplicando?
// Ejemplo usando Request:
$validated = $request->validate([
    'latitude' => 'required|numeric|between:-90,90',
    'longitude' => 'required|numeric|between:-180,180',
    'radius' => 'nullable|numeric|min:0.1|max:100',
]);

// O si existe un FormRequest:
// app/Http/Requests/NearbyBusinessesRequest.php
```

### 4. **Modelo Business** (`app/Models/Business.php`)
```php
// Estructura de la tabla businesses
// Campos relevantes:
// - business_id (o id)
// - business_name
// - latitude
// - longitude
// - etc.

// ¿Tiene scopes o métodos para búsqueda geográfica?
// Ejemplo:
public function scopeNearby($query, $latitude, $longitude, $radius) {
    // Implementación con Haversine o PostGIS
}
```

### 5. **Consulta de Base de Datos**
```php
// ¿Cómo se obtienen los negocios cercanos?
// Opciones:

// Opción A: Fórmula Haversine (SQL estándar)
$businesses = Business::select('*')
    ->selectRaw('
        (6371 * acos(cos(radians(?))
        * cos(radians(latitude))
        * cos(radians(longitude) - radians(?))
        + sin(radians(?))
        * sin(radians(latitude)))) AS distance_km
    ', [$latitude, $longitude, $latitude])
    ->having('distance_km', '<=', $radius)
    ->orderBy('distance_km', 'asc')
    ->get();

// Opción B: PostGIS (si está disponible)
// Implementación con ST_Distance_Sphere o similar

// Opción C: Otra implementación
```

---

## ✅ Prueba exitosa con curl

El endpoint debe funcionar correctamente con esta prueba:

```bash
curl -X GET "https://tu-backend.ngrok-free.dev/api/v1/businesses/nearby?latitude=19.432847&longitude=-99.133208&radius=10" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "ngrok-skip-browser-warning: true"
```

**Respuesta esperada**: Status 200 con el JSON de negocios cercanos

---

## 📝 Implementación sugerida (si no existe)

Si el endpoint no está implementado, aquí hay una sugerencia completa:

### Ruta (`routes/api.php`)
```php
Route::prefix('v1')->group(function () {
    Route::prefix('businesses')->group(function () {
        Route::get('/', [BusinessController::class, 'index']);
        Route::get('/nearby', [BusinessController::class, 'nearby']);
        Route::get('/{id}', [BusinessController::class, 'show']);
    });
});
```

### Controlador (`app/Http/Controllers/BusinessController.php`)
```php
public function nearby(Request $request)
{
    // Validar parámetros
    $validated = $request->validate([
        'latitude' => 'required|numeric|between:-90,90',
        'longitude' => 'required|numeric|between:-180,180',
        'radius' => 'nullable|numeric|min:0.1|max:100',
        'limit' => 'nullable|integer|min:1|max:100',
    ]);

    $latitude = $validated['latitude'];
    $longitude = $validated['longitude'];
    $radius = $validated['radius'] ?? 10; // Default 10km
    $limit = $validated['limit'] ?? 20;   // Default 20 resultados

    // Consulta con fórmula Haversine
    $businesses = Business::select('*')
        ->selectRaw('
            (6371 * acos(
                cos(radians(?))
                * cos(radians(latitude))
                * cos(radians(longitude) - radians(?))
                + sin(radians(?))
                * sin(radians(latitude))
            )) AS distance_km
        ', [$latitude, $longitude, $latitude])
        ->whereNotNull('latitude')
        ->whereNotNull('longitude')
        ->having('distance_km', '<=', $radius)
        ->orderBy('distance_km', 'asc')
        ->limit($limit)
        ->get();

    return response()->json([
        'success' => true,
        'data' => [
            'businesses' => $businesses,
            'pagination' => [
                'current_page' => 1,
                'per_page' => $limit,
                'total' => $businesses->count(),
                'last_page' => 1,
                'from' => 1,
                'to' => $businesses->count(),
            ],
            'user_location' => [
                'latitude' => $latitude,
                'longitude' => $longitude,
            ],
            'search_radius_km' => (string)$radius,
        ],
        'message' => 'Negocios cercanos obtenidos exitosamente',
    ]);
}
```

### Asegúrate de que la tabla `businesses` tenga estos campos:
```sql
CREATE TABLE businesses (
    business_id INT PRIMARY KEY AUTO_INCREMENT,
    business_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    address_details TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(10),
    latitude DECIMAL(10, 8),  -- Importante: permitir valores decimales
    longitude DECIMAL(11, 8), -- Importante: permitir valores decimales
    is_open BOOLEAN DEFAULT true,
    rating DECIMAL(3, 2),
    total_reviews INT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Crear índice para mejorar rendimiento de búsquedas geográficas
CREATE INDEX idx_location ON businesses(latitude, longitude);
```

---

## 🔍 Posibles causas del error "Parámetros de ubicación inválidos"

1. ✅ **Validación muy estricta**: El backend podría estar rechazando números decimales si espera otro formato
2. ✅ **Nombres incorrectos**: Quizás espera `lat` y `lng` en lugar de `latitude` y `longitude`
3. ✅ **Tipos de datos**: Podría estar esperando strings en lugar de numbers
4. ✅ **Parámetros faltantes**: Tal vez requiere parámetros adicionales obligatorios
5. ✅ **Middleware de autenticación**: Podría requerir token de autenticación

---

## 📋 Checklist de verificación

Por favor, verifica lo siguiente en el backend Laravel:

- [ ] La ruta `/api/v1/businesses/nearby` está correctamente definida
- [ ] El controlador y método existen
- [ ] La validación acepta `latitude`, `longitude` y `radius` como números decimales
- [ ] La tabla `businesses` tiene columnas `latitude` y `longitude` con tipo DECIMAL
- [ ] Hay datos de prueba con coordenadas válidas en la base de datos
- [ ] El endpoint NO requiere autenticación (o si la requiere, el token es válido)
- [ ] La consulta SQL funciona correctamente
- [ ] La respuesta tiene el formato JSON esperado con `success: true`

---

## 🚀 Próximos pasos

1. Implementa o verifica el endpoint en Laravel siguiendo las especificaciones
2. Prueba con curl para confirmar que funciona
3. Comparte el resultado aquí
4. Ajustaremos Flutter si es necesario

---

**Generado desde**: order_qr_mobile (Flutter App)
**Para**: Backend Laravel
**Fecha**: 2025-11-28
