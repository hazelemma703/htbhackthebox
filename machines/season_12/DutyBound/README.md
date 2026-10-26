# DutyBound

- **Platform:** HackTheBox
- **IP:** 10.129.20.177
- **Status:** In Progress


**DutyBound (HTB) – Writeup Inicial**  
*Desde el reconocimiento hasta la identificación de la vulnerabilidad*

---

### 1. Reconocimiento Inicial

Escaneo dirigido:

```bash
nmap --privileged -p22,80,443 -sCV -n -Pn -vvv -oN nmap/targeted.nmap 10.129.20.177
```

Resultados relevantes:

| Puerto | Servicio              | Detalle |
|--------|-----------------------|--------|
| 22/tcp | OpenSSH 8.9p1 Ubuntu  | - |
| 80/tcp | nginx 1.18.0          | Redirige a HTTPS |
| 443/tcp| nginx 1.18.0 + SSL    | **AirSnacks Self-Checkout** |

- Título de la página: `Welcome · AirSnacks Self-Checkout`
- Certificado SSL con CN=`airsnacks.htb`
- Añadimos la entrada al `/etc/hosts`:

```bash
echo "10.129.20.177 airsnacks.htb" | sudo tee -a /etc/hosts
```

---

### 2. Enumeración Web

Se identificaron los siguientes endpoints interesantes:

```
200  /                  → Página principal
200  /browse            → Catálogo de productos
200  /cart              → Carrito
200  /static/app.js     → Lógica del frontend
200  /static/app.css
200  /health
405  /exit
```

Al analizar `/static/app.js` se descubrió el endpoint crítico de verificación de boarding pass:

```js
postJSON("/checkout/boarding-pass/verify", { raw: "" });
```

Además, el flujo de la aplicación requiere tener al menos un producto en el carrito antes de poder hacer checkout.

---

### 3. Interacción con el Carrito

Se creó un carrito válido:

```bash
JAR=/tmp/cookie-dutybound.txt

curl -ks -c "$JAR" -b "$JAR" \
  -H 'Content-Type: application/json' \
  -d '{"sku": "SNK-CRN"}' \
  https://airsnacks.htb/cart/add
```

Respuesta:

```json
{"cart_id":"c_48029c1d96","cart_size":1}
```

Con la cookie de sesión se puede interactuar de forma persistente con el resto de endpoints.

---

### 4. Análisis del Boarding Pass (BCBP)

La aplicación espera un **IATA Bar Coded Boarding Pass (BCBP)** en el campo `raw` del endpoint:

```
POST /checkout/boarding-pass/verify
Content-Type: application/json

{"raw": "<BCBP_STRING>"}
```

#### Estructura básica del BCBP (Formato M – 1 leg)

```
[Sección Fija - 60 caracteres] + [Sección Variable]
```

**Sección Fija (60 chars):**

| Posición | Longitud | Campo                        | Ejemplo     |
|----------|----------|------------------------------|-------------|
| 1        | 1        | Format Code                  | `M`         |
| 2        | 1        | Number of Legs               | `1`         |
| 3-22     | 20       | Passenger Name               | `SMITH/JOHN          ` |
| 23       | 1        | Electronic Ticket Indicator  | `E`         |
| 24-30    | 7        | PNR                          | `ABC123 `   |
| 31-33    | 3        | From Airport                 | `HTB`       |
| 34-36    | 3        | To Airport                   | `JFK`       |
| 37-39    | 3        | Operating Carrier            | `AA `       |
| 40-44    | 5        | Flight Number                | `1234 `     |
| 45-47    | 3        | Date of Flight (Julian)      | `299`       |
| 48       | 1        | Compartment Code             | `Y`         |
| 49-52    | 4        | Seat Number                  | `012A`      |
| 53-57    | 5        | Check-in Sequence            | `0001A`     |
| 58       | 1        | Passenger Status             | `0`         |
| 59-60    | 2        | **Field Size (Item 6)**      | `0F`        |

**Sección Variable:**

```
> [Version] [Item 10] [Unique Data] [Item 17] [Repeated Data] [Airline Use]
```

---

### 5. Construcción de un BCBP Válido (Error-Driven)

La aplicación es extremadamente estricta. A través de prueba y error se identificaron las siguientes restricciones:

| Error | Qué aprendimos |
|-------|----------------|
| `BCBP_ERR_FORMAT_CODE` | Debe empezar por `M` |
| `BCBP_ERR_TRUNCATED` | La sección fija debe tener exactamente 60 caracteres |
| `BCBP_ERR_SEAT_FORMAT` | Seat debe ser formato tipo `012A` |
| `BCBP_ERR_SEQUENCE_FORMAT` | Sequence debe ser tipo `0001A` |
| `BCBP_ERR_CONDITIONAL_REQUIRED` | Debe existir sección condicional |
| `BCBP_ERR_VERSION_MARKER` | La sección condicional debe empezar por `>` |
| `BCBP_ERR_VERSION_UNSUPPORTED` | Versión debe ser **5, 6, 7 u 8** |
| `BCBP_ERR_ITEM10_MISMATCH` | Item 10 **solo** acepta: `0B`, `18`, `25`, `32` |
| `BCBP_ERR_DOC_TYPE` | Document Type (Item 16) debe ser `B` o blank |

#### Payload que superó las validaciones de formato:

```bash
curl -ks -c "$JAR" -b "$JAR" \
  -H 'Content-Type: application/json' \
  -d '{"raw":"M1SMITH/JOHN          EABC123 HTBJFKAA 1234 299Y012A0001A00F>50B0WW0001BAA "}' \
  https://airsnacks.htb/checkout/boarding-pass/verify
```

**Desglose de la sección variable:**

```
>50B0WW0001BAA 
││││└────────── Airline Designator + padding
│││└─────────── Document Type = B (Item 16)
││└──────────── Date of Issue
│└───────────── Source of Check-in / Issuance
└────────────── Version 5 + Item 10 = 0B (valor permitido)
```

---

### 6. Identificación de la Vulnerabilidad

Una vez que el BCBP pasa todas las validaciones de formato, la aplicación registra la información en un **audit log** (mencionado en la propia interfaz como “sales audit log for customs and VAT processing”).

El campo controlable por el atacante dentro de la sección condicional (especialmente la parte de **Airline Individual Use**) se inserta en una consulta SQL mediante **string interpolation insegura**.

Esto permite:

1. Confirmar la inyección con un simple `'` (error de PostgreSQL tipo `unterminated quoted string`).
2. Realizar enumeración error-based.
3. Confirmar que el rol de base de datos tiene el privilegio `pg_execute_server_program`.

**Punto de inyección principal:**  
Datos controlados por el atacante en la sección de *airline-use* / datos condicionales del BCBP → consulta de auditoría construida de forma insegura.

---

### Resumen del estado actual

- Reconocimiento y enumeración completados
- Endpoint de verificación de boarding pass identificado
- Estructura BCBP entendida y payload válido construido
- Vulnerabilidad de SQL Injection localizada en el procesamiento del boarding pass (audit logging)

**Siguiente fase:**  
Explotar la SQLi para obtener ejecución de comandos a través de `pg_execute_server_program` y pivotar hacia el usuario del kiosk.
