# Configuración del Icono de la App - Focus

## 📱 Estado Actual

Se ha configurado la app para usar un icono de QR personalizado. Para completar la configuración, sigue estos pasos:

## 🎨 Generar Iconos

### Opción 1: Usar un generador online (Recomendado)

1. **Visita:** https://icon.kitchen/
2. **Configuración:**
   - Icon Type: Clipart
   - Clipart: Busca "QR Code" o "QR Scanner"
   - Background: Color → `#2196F3` (azul de la app)
   - Foreground: Color → `#FFFFFF` (blanco)
   - Shape: Circle o Square según prefieras
3. **Descarga el icono generado**
4. **Copia los archivos:**
   - Extrae el ZIP descargado
   - Los iconos de Android irán directamente a `android/app/src/main/res/`

### Opción 2: Crear icono personalizado y usar flutter_launcher_icons

1. **Crear imagen del icono:**
   - Tamaño: 1024x1024 px (mínimo 512x512)
   - Formato: PNG con fondo transparente o de color
   - Diseño: Un código QR estilizado o icono de escáner

2. **Guardar imágenes:**
   ```
   order_qr_mobile/
   ├── assets/
   │   └── icon/
   │       ├── app_icon.png         (icono completo 1024x1024)
   │       └── foreground_icon.png  (solo el icono QR sin fondo, 432x432 centrado en 1024x1024)
   ```

3. **Ejecutar comandos:**
   ```bash
   # Instalar dependencias
   flutter pub get

   # Generar iconos
   flutter pub run flutter_launcher_icons
   ```

## 📋 Configuración Actual (pubspec.yaml)

```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#2196F3"  # Color azul de Focus
  adaptive_icon_foreground: "assets/icon/foreground_icon.png"
```

## 🎯 Iconos Recomendados

Para mantener consistencia con el tema de "Focus" y QR:

- **Icono principal:** Un código QR estilizado en blanco sobre fondo azul (#2196F3)
- **Adaptive icon:** QR blanco en primer plano con fondo azul
- **Forma:** Circular o cuadrada con esquinas redondeadas

## 🔧 Alternativa Rápida: Usar Material Icons

Si quieres probar rápidamente sin crear imágenes personalizadas:

1. Crea una imagen de 1024x1024 con:
   - Fondo azul #2196F3
   - Icono de QR blanco centrado
   - Usa cualquier editor de imágenes o Canva

2. Guárdala en `assets/icon/app_icon.png`

3. Ejecuta:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

## ✅ Verificar Cambios

Después de generar los iconos:

1. **Reconstruir la app:**
   ```bash
   flutter clean
   flutter build apk
   ```

2. **Instalar en dispositivo:**
   ```bash
   flutter install
   ```

3. **Verificar:**
   - El icono debe aparecer en el launcher de Android
   - El nombre debe ser "Focus"
   - Al abrir, la pantalla de splash debe mostrar "Focus"

## 📝 Archivos Modificados

- ✅ `pubspec.yaml` - Agregado flutter_launcher_icons
- ✅ `android/app/src/main/AndroidManifest.xml` - Cambiado label a "Focus"
- ✅ `lib/main.dart` - Cambiado title a "Focus"
- ✅ `lib/screens/splash_screen.dart` - Actualizado nombre a "Focus"

## 🎨 Recursos Útiles

- **Icon Kitchen:** https://icon.kitchen/
- **Canva:** https://www.canva.com/
- **Figma:** https://www.figma.com/
- **Flutter Launcher Icons:** https://pub.dev/packages/flutter_launcher_icons

---

**Nota:** Por el momento, el icono predeterminado de Flutter seguirá mostrándose hasta que generes y apliques los iconos personalizados siguiendo los pasos anteriores.
