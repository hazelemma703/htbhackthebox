Para esta máquina de HTB, empezaría con `ffuf` para descubrir rutas y endpoints ocultos, complementándolo con `curl` y `whatweb`. Como estás frente a una API web que expone información de un gateway, el objetivo no es solamente encontrar directorios, sino identificar las rutas, los métodos HTTP y las posibles relaciones entre los servicios internos.

## 1. ¿Qué herramientas utilizar?

[#8 Subdomain Enumeration —How to find Subdomains of any Domain | by Uttam Gupta | Medium](https://images.openai.com/static-rsc-4/3eIgUIjxlh3n4h0m2tfxDefyCEOvb-3XQaqnC9gqns3-H78gmNm9g6cqGRm0K-gA6qLREE98-pQ7l1lO3w_tNhkS1ayh4bvlqw_mW6jKJVBdYfhKDRWn0qKgfipueAQEouc2aVXF4_MCT5cYX91A0CsL65DiSszdzq9SM6o-7eI?purpose=inline)

1\. `ffuf` — Descubrimiento de endpoints

Prioridad alta

Busca rutas como `/api`, `/docs`, `/openapi.json`, `/admin` o endpoints de servicios.

```
ffuf -u http://TARGET/FUZZ \
  -w /usr/share/seclists/Discovery/Web-Content/common.txt \
  -fc 404
```

Sustituye `TARGET` por la IP de la máquina. Si la respuesta para las rutas inexistentes no es un 404 real, ajusta los filtros según el tamaño y contenido de las respuestas.

[CURL Logo PNG Vector (SVG) Free Download](https://images.openai.com/static-rsc-4/-zCFFP4Pdm9EUy1tbTWESj95YuJ0bIYbYrHxSKY1A3Edpc81zGKyqeCuid4fQyRLRiXFWDeQndw6rViSbVzezUYrUZT8PTefVBtPj5QwzdNw6UafCAC2RBVptQoh9672ao_pGT-PB02iXjxpwrsGHsZ3ZFtiqc9ZqP6UbH43ZTg?purpose=inline)

2\. `curl` — Inspección de la API

Permite revisar cabeceras, códigos HTTP y métodos permitidos.

```
curl -i http://TARGET/
curl -i -X OPTIONS http://TARGET/
curl -i http://TARGET/openapi.json
```

Busca cabeceras interesantes, redirecciones, métodos habilitados y documentación de la API.

[How to Fingerprint Websites With WhatWeb - A Practical, Hands-On Guide](https://images.openai.com/static-rsc-4/7TXIJ505CfgEkHruGQ8P5KrgbXtqyGJAEfzdsQadFMYJMzD5c-XTa0DinaoW9gA2wDTHHUn3aPGazVA2Om09NEOjlSouIWct-a4WJJCpISBIj1qcR8Dmnv3p2MHJfdN7ivRf5I4o1km2FUrMa4r-71c2xLlN4RRTxANrzO-Tu5Y?purpose=inline)

3\. `whatweb` — Identificación tecnológica

```
whatweb http://TARGET/
```

Ayuda a identificar tecnologías, servidores web, frameworks y otras huellas visibles.

[How to Install GoBuster with Basic Usage on Ubuntu | GoLinuxCloud](https://images.openai.com/static-rsc-4/Yibom-kBXm3Aj08rUdLOEWWeXCev-c3W8VavoWnAFivwXrtgkou2pjlrKu5PmWbMQkh97lynCN68GDo6MCzzZNiTCttGEJhU74iwQoM0cl2mGCWqdneNXtNZXxNwER0NGF0vs_ImbxSLEEf1_KYngijOhh88iQdsDECFWJRksgA?purpose=inline)

4\. `gobuster` — Alternativa para enumeración

```
gobuster dir \
  -u http://TARGET/ \
  -w /usr/share/seclists/Discovery/Web-Content/common.txt
```

Cumple una función similar a `ffuf`. No necesitas ejecutar ambos inicialmente; elegiría `ffuf` por su flexibilidad con filtros y cabeceras.

## 2. Lo importante de esta respuesta JSON

La respuesta inicial revela varios datos que conviene convertir en hipótesis de enumeración.

| Dato observado          | Qué investigar                                                      |
| ----------------------- | ------------------------------------------------------------------- |
| `terminal-edge-gateway` | Rutas relacionadas con el gateway y su estado                       |
| `flight-data-service`   | Posibles endpoints de datos de vuelos                               |
| `boarding-control`      | Rutas de embarque y control                                         |
| `gate-assignment`       | Asignación de puertas                                               |
| `passenger-manifest`    | Rutas relacionadas con manifiestos de pasajeros                     |
| `version: 1.0.0`        | Posible documentación, versionado o rutas `/api/v1/`                |
| `eu-central-1`          | Contexto de despliegue; no demuestra por sí solo una vulnerabilidad |

Los nombres de los servicios no demuestran que existan endpoints públicos con esos nombres. Son pistas para orientar la búsqueda, no vulnerabilidades confirmadas.

## 3. Mi metodología recomendada

Ejecutaría los pasos en este orden:

Paso 1 — Reconocimiento HTTP

```
whatweb http://TARGET
curl -i http://TARGET/
```

Identifica cabeceras, comportamiento y tecnología.

Paso 2 — Enumeración de contenido

```
ffuf -u http://TARGET/FUZZ \
  -w /usr/share/seclists/Discovery/Web-Content/common.txt \
  -fc 404
```

Registra las rutas que respondan con códigos o contenidos distintos de los errores habituales.

Paso 3 — Buscar documentación de API

Comprueba manualmente rutas habituales:

```
/docs
/redoc
/openapi.json
/swagger
/swagger-ui
/api
/api/v1
/health
/status
```

Si encuentras un esquema OpenAPI, podrás identificar rutas y parámetros con mucha más precisión.

Paso 4 — Enumeración específica de API

Cuando descubras un prefijo válido, como `/api/v1/`, vuelve a ejecutar `ffuf` sobre ese prefijo. Prueba métodos HTTP y parámetros únicamente dentro del alcance autorizado de la máquina.

## 4. Un detalle que puede marcar la diferencia

Si todas las rutas inexistentes devuelven el mismo JSON o un código `200`, el filtrado por `404` no será suficiente. Primero compara una ruta real con una aleatoria:

```
curl -i http://TARGET/
curl -i http://TARGET/ruta-que-no-existe-73921
```

Compara el código HTTP, el tamaño de la respuesta y el contenido. Después ajusta `ffuf` con `-fs`, `-fw`, `-fl` o `-fr`, según lo que observes.

Mi elección para empezar: `curl` para entender el comportamiento y después `ffuf` para enumerar. En una API, descubrir un esquema OpenAPI o un endpoint funcional puede ser mucho más valioso que encontrar decenas de directorios genéricos.

Si me compartes la salida de `whatweb http://TARGET` y las cabeceras de `curl -i http://TARGET/`, podemos determinar qué estrategia de enumeración conviene aplicar a continuación.
