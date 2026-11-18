# Banco Inteligente Javeriana — app de pagos con QR

MVP en Flutter del proyecto Prompt Solution Client (Grupo 6). El comprador escanea el QR de un comercio y la app le sugiere con qué medio pagar. La sugerencia la da el modelo de IA del equipo a través de una API; el comprador siempre decide.

## Cómo se conecta con el modelo

```
App ──► POST /v1/recomendacion ──► Capa 1 (XGBoost) ──► Capa 2 (utilidad + factibilidad)
```

- La API vive en el repositorio `prompt-solution-client-g6`, carpeta `api/`.
- La app le envía a la API la compra y los datos del cliente: saldo, uso del cupo de crédito y medios de pago que tiene. Los toma de los productos del cliente; nadie los escribe.
- La API elige el **medio** (crédito, débito o transferencia) entre los que el cliente tiene y puede pagar. La app elige el **producto** dentro de ese medio con las reglas de beneficios de `lib/services/recommendation_service.dart`.
- Si la API no cubre la categoría del comercio, la app usa solo las reglas de beneficios y lo indica en pantalla («Recomendación por reglas»).
- Si la API no responde en 4 segundos, la app no cambia a las reglas en silencio: muestra «Despertando la IA…», espera hasta 90 segundos a que la API despierte y le pregunta una vez más. Mientras tanto el comprador puede tocar **No esperar: usar reglas**. Si la API no despierta, la app usa las reglas, lo dice y ofrece **Reintentar con IA**.

El código de la integración está en `lib/services/api_recommendation_service.dart`, el estado de la API (dormida, despertando, lista) en `lib/services/api_status.dart` y la URL y los plazos en `lib/core/config/api_config.dart`.

## Datos del cliente

En un banco real, la app conoce los productos del cliente en cuanto inicia sesión. En este MVP ese papel lo hace `lib/data/mock_repository.dart`, un banco simulado con cuatro clientes de demo. Cada producto lleva su dinero: saldo en la cuenta y en la tarjeta débito, cupo total y usado en las tarjetas de crédito.

Con esos productos la app arma el bloque `cliente` de cada petición (`lib/models/customer_context.dart`):

| Campo | Cómo se calcula |
|---|---|
| `saldo_cop` | El saldo de la cuenta. La tarjeta débito gasta de esa misma cuenta. |
| `uso_cupo` | Lo que debe en todas sus tarjetas de crédito dividido por el cupo total. Si no tiene tarjeta de crédito se envía 1. |
| `medios` | Los medios para los que tiene un producto. |

Lo que la app no conoce es el comportamiento del cliente (ticket medio y sensibilidad al cashback). Esas dos variables del modelo las guarda la API por `user_id`.

El saldo y el uso de cupo de los tres primeros clientes son los mismos del catálogo de la API, así que el modelo recibe exactamente lo mismo que antes de enviar el bloque. El cuarto cliente no tiene tarjeta de crédito: el modelo lo trata como a alguien con el cupo copado, porque nunca vio un caso «sin tarjeta».

Límites del MVP: los datos son sintéticos, el inicio de sesión es simulado y la API cree el saldo que envía la app. Con usuarios reales, el saldo debe salir del banco con el usuario autenticado.

## ¿Por qué esta sugerencia?

En una recomendación de la IA, el enlace **¿Por qué esta sugerencia?** abre el desglose de la decisión:

- Una frase con los números, por ejemplo «Transferencia: probabilidad 19 % + incentivo $14.500 → utilidad 0,58, frente a 0,33 de crédito».
- Por cada medio, la probabilidad (Capa 1), el incentivo, la utilidad (Capa 2) y la suma que la produce: `0,5 × 0,187 + 0,5 × 0,967 = 0,577`.
- Los medios descartados y el motivo (no lo tiene, saldo insuficiente o cupo agotado), aunque su utilidad fuera la mayor.
- Los datos con los que decidió la API: monto, saldo, uso del cupo y medios del cliente, si esos datos los envió la app, incentivo, día y hora de Bogotá, versión del modelo y tiempo de respuesta.

Todos los números salen de la respuesta de la API. La fórmula y sus pesos se leen de `GET /v1/meta`; la app solo muestra la suma si reproduce la utilidad que devolvió la API, así que un cambio de fórmula en el modelo no deja una explicación falsa en pantalla. El código está en `lib/screens/explanation/recommendation_explanation_screen.dart`.

## Correr la demo

La app usa por defecto la API desplegada en Render (`https://prompt-solution-client-api.onrender.com`), así que no hay que levantar nada en el computador ni pasar opciones:

```bash
flutter run
```

Lo mismo vale para el APK que se instala en un celular físico:

```bash
flutter build apk --release
```

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`.

El plan gratuito de Render apaga la API tras 15 minutos sin uso y tarda unos 40 segundos en volver (medición del 14-nov-2026). La app la despierta al abrirse y al abrir **Simular QR (demo)**, donde un aviso muestra «Despertando la IA…» con los segundos que lleva y cambia a «IA lista» cuando responde. Antes de presentar, abrir el simulador y esperar «IA lista».

Los avisos muestran el servidor al que llama la app (por ejemplo «Servidor: prompt-solution-client-api.onrender.com»). En el celular y en escritorio, si la dirección no existe o no hay red, la app lo dice en unos 10 segundos («La IA no responde») en vez de esperar como si la API estuviera dormida.

### Con la API en el computador

Para probar cambios de la API sin desplegarlos, levantarla desde la raíz de `prompt-solution-client-g6`:

```bash
python -m uvicorn app.main:app --app-dir api --host 0.0.0.0 --port 8000
```

Y pasarle a la app la dirección según dónde corre:

| Dónde corre la app | Opción |
|---|---|
| Emulador de Android | `--dart-define=API_BASE_URL=http://10.0.2.2:8000` |
| Web o escritorio | `--dart-define=API_BASE_URL=http://localhost:8000` |
| Celular físico en la misma Wi-Fi | `--dart-define=API_BASE_URL=http://<IP del computador>:8000` |

`10.0.2.2` solo existe dentro del emulador: un APK compilado con esa dirección no funciona en un celular. El tráfico HTTP sin cifrar solo está permitido en compilaciones de depuración.

## Recorrido sugerido

En la pantalla de la cámara, **Simular QR (demo)** permite elegir un cliente y un comercio. En los cuatro primeros casos, **¿Por qué esta sugerencia?** muestra los números de la decisión:

| Cliente | Comercio | Qué muestra |
|---|---|---|
| Saldo ajustado | Restaurante El Portal | La IA sugiere transferencia por el incentivo de $14.500, aunque lo más probable era crédito |
| Saldo holgado | Café La Candelaria | El incentivo de $4.800 no alcanza: se mantiene débito, el medio más probable |
| Saldo ajustado | Moda Andina | El saldo no cubre la compra: sugiere crédito y bloquea débito y transferencia |
| Sin tarjeta de crédito | Supermercado Central | El modelo le da a crédito entre 34 % y 55 % de probabilidad según la hora, pero el cliente no tiene tarjeta: la IA lo descarta, sugiere transferencia y la app solo ofrece débito y cuenta |
| Cualquiera | Aerolínea Andes | Categoría fuera del modelo: la app usa las reglas de beneficios |

La hora y el día de la compra son variables del modelo, así que un caso reñido puede cambiar según cuándo se pruebe. Estos cinco dan la misma recomendación a cualquier hora y día. Uno que sí cambia: «Saldo ajustado» en Café La Candelaria.

Los clientes y comercios son datos sintéticos de demostración.

## Pruebas

```bash
flutter analyze
```

```bash
flutter test
```
