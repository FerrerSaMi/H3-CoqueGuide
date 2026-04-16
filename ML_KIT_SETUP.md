# Google ML Kit Translate Setup

Para usar la traducción con Google ML Kit, necesitas agregar las siguientes dependencias al proyecto:

## Opción 1: CocoaPods (Recomendado)

Agrega lo siguiente a tu `Podfile`:

```ruby
pod 'MLKitTranslate', '~> 6.0.0'
```

Luego ejecuta:
```bash
pod install
```

## Opción 2: Swift Package Manager

En Xcode:
1. Ve a File > Add Packages...
2. Ingresa la URL: `https://github.com/google/mlkit-ios-sdk.git`
3. Selecciona la versión más reciente
4. Agrega `MLKitTranslate` a tu target

## Configuración

Asegúrate de que los siguientes idiomas estén soportados en tu app:
- Español (Spanish)
- Inglés (English)
- Francés (French)
- Portugués (Portuguese)
- Coreano (Korean)
- Árabe (Arabic)

## Notas

- Los modelos de traducción se descargan automáticamente cuando se necesitan por primera vez
- La traducción funciona tanto online como offline una vez descargado el modelo
- El primer uso puede requerir descarga del modelo correspondiente al idioma