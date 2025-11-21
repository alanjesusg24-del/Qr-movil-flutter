# Guía Paso a Paso: Configurar Google Sign-In con Firebase

Esta guía te llevará paso a paso por la configuración completa de Google Sign-In para tu app Flutter usando Firebase.

## IMPORTANTE: ¿Por qué no funciona Google Sign-In?

Tu archivo `google-services.json` tiene la sección `oauth_client` **vacía**:
```json
"oauth_client": []  // ← ESTO ESTÁ VACÍO
```

Esto es necesario para que Google Sign-In funcione. Vamos a arreglarlo.

---

## Parte 1: Configurar Firebase Console

### Paso 1: Acceder a Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Inicia sesión con tu cuenta de Google
3. Busca y selecciona tu proyecto **focus-qr**
   - Si no lo ves, haz clic en el menú desplegable en la parte superior

### Paso 2: Habilitar Google Sign-In en Authentication

1. En el menú lateral izquierdo, haz clic en **Build** → **Authentication**
2. Haz clic en la pestaña **Sign-in method**
3. En la lista de proveedores, busca **Google**
4. Haz clic en **Google** para expandirlo
5. Activa el interruptor para **Enable** (Habilitar)
6. Verás dos campos:
   - **Project support email**: Selecciona tu email del menú desplegable
   - **Project public-facing name**: Déjalo como "focus-qr" o cámbialo si quieres
7. Haz clic en **Save** (Guardar)

**Captura de referencia:**
```
┌─────────────────────────────────────────┐
│ Google                        [Enabled] │
│                                         │
│ Project support email:                  │
│ [tu-email@gmail.com         ▼]         │
│                                         │
│ Project public-facing name:             │
│ [focus-qr                   ]          │
│                                         │
│          [Cancel]    [Save]             │
└─────────────────────────────────────────┘
```

---

## Parte 2: Configurar Google Cloud Console

### Paso 3: Acceder a Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. En la parte superior, haz clic en el menú desplegable del proyecto
3. Selecciona tu proyecto **focus-qr** (Project ID: `focus-qr`)
   - Si no aparece, asegúrate de que estás usando la misma cuenta de Google

### Paso 4: Habilitar Google Sign-In API

1. En el menú lateral, ve a **APIs & Services** → **Library**
2. En el buscador, escribe: `Google Sign-In`
3. Haz clic en **Google Sign-In for Android**
4. Si aparece un botón **Enable**, haz clic en él
5. Espera a que se habilite (puede tardar unos segundos)

### Paso 5: Obtener SHA-1 Certificate Fingerprint

Este es **CRÍTICO** para que Google Sign-In funcione en Android.

#### En Windows (PowerShell):

1. Abre PowerShell como administrador
2. Ejecuta este comando para ir a la carpeta de Android:
```powershell
cd $env:USERPROFILE\.android
```

3. Lista los archivos para verificar que existe `debug.keystore`:
```powershell
dir
```

4. Si existe el archivo, ejecuta:
```powershell
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

5. Si **NO existe** el archivo, créalo primero:
```powershell
keytool -genkey -v -keystore debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000
```
   - Te pedirá información (nombre, organización, etc.)
   - Puedes presionar Enter en todas para usar valores por defecto
   - Luego ejecuta el comando del paso 4

6. Busca en la salida esta línea:
```
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
```

7. **COPIA COMPLETO** ese SHA1 (incluyendo los dos puntos)

**Ejemplo de salida completa:**
```
Certificate fingerprints:
         SHA1: 3B:4F:C9:0C:45:89:A0:23:1B:6E:78:9D:44:B5:C1:23:45:67:89:0A
         SHA256: 1A:2B:3C:4D:5E:6F:7A:8B:9C:0D:1E:2F:3A:4B:5C:6D:...
```

Copia el SHA1: `3B:4F:C9:0C:45:89:A0:23:1B:6E:78:9D:44:B5:C1:23:45:67:89:0A`

### Paso 6: Agregar SHA-1 a Firebase

1. Regresa a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto **focus-qr**
3. Haz clic en el ícono de **engranaje** (⚙️) junto a "Project Overview"
4. Selecciona **Project settings**
5. Baja hasta la sección **Your apps**
6. Encuentra tu app Android con el package name `com.orderqr.mobile`
7. Haz clic en **Add fingerprint**
8. Pega el SHA-1 que copiaste
9. Haz clic en **Save**

**Si no ves tu app Android:**
1. Haz clic en el botón **Add app** → **Android**
2. Ingresa el package name: `com.orderqr.mobile`
3. Ingresa un nickname (opcional): "Order QR Mobile"
4. Pega el SHA-1 certificate fingerprint
5. Haz clic en **Register app**
6. **IMPORTANTE:** Descarga el nuevo `google-services.json`
7. Completa el asistente

### Paso 7: Crear OAuth 2.0 Client ID en Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Asegúrate de que estés en el proyecto **focus-qr**
3. En el menú lateral, ve a **APIs & Services** → **Credentials**
4. Haz clic en **+ CREATE CREDENTIALS** en la parte superior
5. Selecciona **OAuth client ID**

#### Si te pide configurar OAuth consent screen:
1. Haz clic en **CONFIGURE CONSENT SCREEN**
2. Selecciona **External** (para testing)
3. Haz clic en **CREATE**
4. Llena los campos requeridos:
   - **App name**: Order QR Mobile
   - **User support email**: tu email
   - **Developer contact information**: tu email
5. Haz clic en **SAVE AND CONTINUE**
6. En **Scopes**, haz clic en **ADD OR REMOVE SCOPES**
7. Selecciona:
   - `../auth/userinfo.email`
   - `../auth/userinfo.profile`
   - `openid`
8. Haz clic en **UPDATE** → **SAVE AND CONTINUE**
9. En **Test users**, agrega tu email de Google
10. Haz clic en **SAVE AND CONTINUE**
11. Revisa y haz clic en **BACK TO DASHBOARD**

#### Ahora crea el OAuth Client ID:

1. Ve nuevamente a **APIs & Services** → **Credentials**
2. Haz clic en **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Selecciona **Application type**: **Android**
4. Llena los campos:
   - **Name**: `Order QR Mobile - Android`
   - **Package name**: `com.orderqr.mobile`
   - **SHA-1 certificate fingerprint**: Pega el SHA-1 que copiaste antes
5. Haz clic en **CREATE**
6. Aparecerá un modal diciendo "OAuth client created"
7. Haz clic en **OK**

**IMPORTANTE:** También necesitas crear un Web Client (para el backend):

1. Haz clic nuevamente en **+ CREATE CREDENTIALS** → **OAuth client ID**
2. Selecciona **Application type**: **Web application**
3. **Name**: `Order QR Mobile - Web`
4. **Authorized redirect URIs**: (déjalo vacío por ahora, o agrega tu backend URL)
5. Haz clic en **CREATE**
6. **GUARDA** el Client ID que aparece (lo necesitarás para el backend)
7. Haz clic en **OK**

### Paso 8: Verificar las Credenciales Creadas

En **APIs & Services** → **Credentials**, deberías ver:

```
OAuth 2.0 Client IDs
┌────────────────────────────────────────────────────────┐
│ Name                        Type        Creation date  │
├────────────────────────────────────────────────────────┤
│ Order QR Mobile - Android   Android     2025-XX-XX     │
│ Order QR Mobile - Web       Web app     2025-XX-XX     │
│ Web client (auto...)        Web app     2025-XX-XX     │ ← Creado por Firebase
└────────────────────────────────────────────────────────┘
```

---

## Parte 3: Descargar y Actualizar google-services.json

### Paso 9: Descargar el nuevo google-services.json

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto **focus-qr**
3. Haz clic en el ícono de engranaje (⚙️) → **Project settings**
4. Baja hasta **Your apps**
5. Encuentra tu app Android `com.orderqr.mobile`
6. Haz clic en el botón de descarga **google-services.json**
7. Guarda el archivo

### Paso 10: Reemplazar google-services.json en tu proyecto

1. En tu proyecto Flutter, ve a la carpeta:
   ```
   android/app/
   ```

2. **Reemplaza** el archivo `google-services.json` existente con el que acabas de descargar

3. Abre el nuevo archivo y **verifica** que ahora tenga `oauth_client` con datos:

```json
{
  "project_info": {
    "project_number": "473319249019",
    "project_id": "focus-qr"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:473319249019:android:a4839cbb67473560653ede",
        "android_client_info": {
          "package_name": "com.orderqr.mobile"
        }
      },
      "oauth_client": [
        {
          "client_id": "473319249019-xxxxxxxxxxxxxxxxx.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.orderqr.mobile",
            "certificate_hash": "3b4fc90c4589a0231b6e789d44b5c123456789aa"
          }
        },
        {
          "client_id": "473319249019-yyyyyyyyyyyyyyyy.apps.googleusercontent.com",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "AIzaSyBkfZXYARz9a2uMU4lHKvOsPxQjwqFT9Nk"
        }
      ]
    }
  ]
}
```

**SI TODAVÍA ESTÁ VACÍO** (`"oauth_client": []`):
- Espera 5-10 minutos (a veces Google tarda en propagarse)
- Intenta descargar de nuevo
- Verifica que hayas agregado el SHA-1 correctamente

---

## Parte 4: Configurar el Código Flutter (Opcional)

### Paso 11: Actualizar AuthService (si es necesario)

Si el Google Sign-In sigue fallando, puedes especificar el Server Client ID manualmente.

1. Abre `lib/services/auth_service.dart`

2. Busca la línea donde se inicializa `GoogleSignIn`:
```dart
static final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
);
```

3. Agrégale el `serverClientId` (usa el Web Client ID):
```dart
static final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId: '473319249019-xxxxxxxxxx.apps.googleusercontent.com', // Web Client ID
);
```

Para obtener el Web Client ID:
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. **APIs & Services** → **Credentials**
3. Busca el OAuth 2.0 Client ID de tipo **Web application**
4. Haz clic en él
5. Copia el **Client ID** (termina en `.apps.googleusercontent.com`)

---

## Parte 5: Probar y Solucionar Problemas

### Paso 12: Limpiar y Reconstruir

```bash
# Limpiar el proyecto
flutter clean

# Ir a Android y limpiar Gradle
cd android
./gradlew clean
cd ..

# Reinstalar dependencias
flutter pub get

# Reconstruir
flutter run
```

### Paso 13: Verificar en Logs

```bash
# Ver logs en tiempo real
flutter logs
```

Si Google Sign-In falla, busca en los logs:
- `PlatformException`
- `SIGN_IN_FAILED`
- `ApiException`
- Códigos de error como `10` (common), `12500` (need update), etc.

### Errores Comunes y Soluciones

#### Error: `sign_in_failed: com.google.android.gms.common.api.ApiException: 10:`

**Causa:** SHA-1 no coincide o no está configurado

**Solución:**
1. Verifica que el SHA-1 en Firebase sea el correcto
2. Asegúrate de usar el debug.keystore correcto
3. Espera 5 minutos y vuelve a intentar

#### Error: `sign_in_canceled`

**Causa:** Usuario canceló el login o la app de Google no está configurada

**Solución:**
1. Intenta de nuevo
2. Verifica que tengas la app de Google instalada
3. Verifica que tengas una cuenta de Google agregada al dispositivo

#### Error: `network_error`

**Causa:** Sin conexión a internet

**Solución:**
- Verifica tu conexión
- Intenta con WiFi en lugar de datos móviles

#### Error: `developer_error` o `12500`

**Causa:** Package name no coincide o SHA-1 incorrecto

**Solución:**
1. Verifica el package name en `android/app/build.gradle`:
   ```gradle
   defaultConfig {
       applicationId "com.orderqr.mobile"  // ← Debe coincidir
   }
   ```
2. Verifica el SHA-1 nuevamente
3. Descarga nuevamente el `google-services.json`

---

## Parte 6: Verificación Final

### Checklist Completo:

#### Firebase Console
- [ ] Proyecto focus-qr seleccionado
- [ ] Google Sign-In habilitado en Authentication
- [ ] App Android registrada con package name `com.orderqr.mobile`
- [ ] SHA-1 fingerprint agregado
- [ ] Nuevo `google-services.json` descargado

#### Google Cloud Console
- [ ] Proyecto focus-qr seleccionado
- [ ] OAuth consent screen configurado
- [ ] OAuth Client ID para Android creado
- [ ] OAuth Client ID para Web creado (opcional, para backend)
- [ ] Package name y SHA-1 correctos

#### Proyecto Flutter
- [ ] `google-services.json` reemplazado en `android/app/`
- [ ] Archivo tiene `oauth_client` con datos (no vacío)
- [ ] `flutter clean` ejecutado
- [ ] Proyecto reconstruido

#### Testing
- [ ] App compila sin errores
- [ ] Google Sign-In muestra selector de cuentas
- [ ] Login exitoso sin `PlatformException`
- [ ] Token recibido del backend

---

## Paso 14: Probar Google Sign-In

1. Ejecuta la app en modo debug:
```bash
flutter run --debug
```

2. Ve a la pantalla de Login

3. Toca el botón "Continuar con Google"

4. Deberías ver:
   - Selector de cuentas de Google
   - Selecciona tu cuenta
   - Acepta permisos (si es la primera vez)
   - La app te lleva a la pantalla principal

5. Si todo funciona, verás en los logs:
```
I/flutter (12345): Google Sign-In successful
I/flutter (12345): Token: ya29.xxxxx...
```

---

## Recursos Adicionales

- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Documentación de Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [Troubleshooting Google Sign-In](https://developers.google.com/identity/sign-in/android/troubleshooting)

---

## ¿Necesitas Ayuda?

Si sigues teniendo problemas:

1. Comparte los logs completos del error
2. Verifica que todos los pasos estén completados
3. Espera 10-15 minutos después de hacer cambios en Firebase/Google Cloud
4. Intenta con un dispositivo físico en lugar de emulador
5. Verifica que tu dispositivo tenga Google Play Services actualizados

---

**¡Importante!** Los cambios en Firebase y Google Cloud pueden tardar **5-15 minutos** en propagarse. Si algo no funciona inmediatamente, espera un poco y vuelve a intentar.
