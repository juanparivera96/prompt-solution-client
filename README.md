# Banco Inteligente Javeriana — app de pagos con QR

MVP en Flutter del proyecto Prompt Solution Client (Grupo 6). El comprador escanea el QR de un comercio y la app le sugiere con qué medio pagar. La sugerencia la da el modelo de IA del equipo a través de una API; el comprador siempre decide.

## Cómo se conecta con el modelo

```
App ──► POST /v1/recomendacion ──► Capa 1 (XGBoost) ──► Capa 2 (utilidad + factibilidad)
```

- La API vive en el repositorio `prompt-solution-client-g6`, carpeta `api/`.
- La API elige el **medio** (crédito, débito o transferencia). La app elige el **producto** dentro de ese medio con las reglas de beneficios de `lib/services/recommendation_service.dart`.
- Si la API no cubre la categoría del comercio, la app usa solo las reglas de beneficios y lo indica en pantalla («Recomendación por reglas»).
- Si la API no responde en 4 segundos, la app no cambia a las reglas en silencio: muestra «Despertando la IA…», espera hasta 90 segundos a que la API despierte y le pregunta una vez más. Mientras tanto el comprador puede tocar **No esperar: usar reglas**. Si la API no despierta, la app usa las reglas, lo dice y ofrece **Reintentar con IA**.

El código de la integración está en `lib/services/api_recommendation_service.dart`, el estado de la API (dormida, despertando, lista) en `lib/services/api_status.dart` y la URL y los plazos en `lib/core/config/api_config.dart`.

## ¿Por qué esta sugerencia?

En una recomendación de la IA, el enlace **¿Por qué esta sugerencia?** abre el desglose de la decisión:

- Una frase con los números, por ejemplo «Transferencia: probabilidad 19 % + incentivo $14.500 → utilidad 0,58, frente a 0,33 de crédito».
- Por cada medio, la probabilidad (Capa 1), el incentivo, la utilidad (Capa 2) y la suma que la produce: `0,5 × 0,187 + 0,5 × 0,967 = 0,577`.
- Los medios descartados por factibilidad y el motivo, aunque su utilidad fuera la mayor.
- Los datos con los que decidió la API: monto, saldo, incentivo, día y hora de Bogotá, versión del modelo y tiempo de respuesta.

Todos los números salen de la respuesta de la API. La fórmula y sus pesos se leen de `GET /v1/meta`; la app solo muestra la suma si reproduce la utilidad que devolvió la API, así que un cambio de fórmula en el modelo no deja una explicación falsa en pantalla. El código está en `lib/screens/explanation/recommendation_explanation_screen.dart`.

## Correr la demo

1. Levantar la API (desde la raíz de `prompt-solution-client-g6`):

```bash
python -m uvicorn app.main:app --app-dir api --host 127.0.0.1 --port 8000
```

2. Correr la app en el emulador de Android:

```bash
flutter run
```

En el emulador la app llama a `http://10.0.2.2:8000`, que es el computador donde corre la API. En web y escritorio usa `http://localhost:8000`.

Para usar la API desplegada en la nube (Render, plan gratuito) en lugar de la local:

```bash
flutter run --dart-define=API_BASE_URL=https://prompt-solution-client-api.onrender.com
```

Así la app funciona sin levantar nada en el computador, también en un celular físico con datos o Wi-Fi. El plan gratuito apaga la API tras 15 minutos sin uso y tarda unos 40 segundos en volver (medición del 14-nov-2026). La app la despierta al abrirse y al abrir **Simular QR (demo)**, donde un aviso muestra «Despertando la IA…» con los segundos que lleva y cambia a «IA lista» cuando responde. Antes de presentar, abrir el simulador y esperar «IA lista».

Con un celular físico y la API en el computador, levantar la API con `--host 0.0.0.0` y usar la IP del computador, por ejemplo `--dart-define=API_BASE_URL=http://192.168.1.20:8000`. El tráfico HTTP sin cifrar solo está permitido en compilaciones de depuración.

## Recorrido sugerido

En la pantalla de la cámara, **Simular QR (demo)** permite elegir un perfil de comprador y un comercio. En los tres primeros casos, **¿Por qué esta sugerencia?** muestra los números de la decisión:

| Perfil | Comercio | Qué muestra |
|---|---|---|
| Saldo ajustado | Restaurante El Portal | La IA sugiere transferencia por el incentivo de $14.500, aunque lo más probable era crédito |
| Saldo holgado | Café La Candelaria | El incentivo de $4.800 no alcanza: se mantiene débito, el medio más probable |
| Saldo ajustado | Moda Andina | El saldo no cubre la compra: sugiere crédito y bloquea débito y transferencia |
| Cualquiera | Aerolínea Andes | Categoría fuera del modelo: la app usa las reglas de beneficios |

La hora y el día de la compra son variables del modelo, así que un caso reñido puede cambiar según cuándo se pruebe. Estos cuatro dan la misma recomendación a cualquier hora y día. Uno que sí cambia: «Saldo ajustado» en Café La Candelaria.

Los perfiles y comercios son datos sintéticos de demostración.

## Pruebas

```bash
flutter analyze
```

```bash
flutter test
```
