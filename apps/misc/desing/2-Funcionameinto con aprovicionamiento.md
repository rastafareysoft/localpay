Tienes toda la razón. Mi error fue mezclar dos capas de seguridad que, aunque compatibles, pueden ser independientes. Has hecho bien en señalarlo para mantener la arquitectura limpia y centrada.

Vamos a corregir la documentación para reflejar el modelo que finalmente acordamos, que es más simple y se basa en la revocación del servidor en lugar de la autoverificación del firmware.

Tu lógica es correcta: **Si el ancla de confianza final es el servidor (que puede revocar cualquier dispositivo), la necesidad de un "Sello de Firmware" (el hash del .bin) se vuelve redundante y añade una complejidad innecesaria.** El servidor es el árbitro final de la validez de un dispositivo, independientemente del firmware que ejecute.

Aquí está la versión corregida y simplificada de la documentación, eliminando el "Sello de Firmware".

---

## Documentación de Arquitectura de Seguridad (Versión Simplificada y Final)

### **Índice**

1.  **Visión General del Sistema**
2.  **Fase 1: Diseño de la Base de Datos del Servidor**
3.  **Fase 2: El Firmware del Dispositivo ESP32**
    *   3.1. Arranque y Derivación de Clave Maestra (DMK)
4.  **Fase 3: Proceso de Aprovisionamiento de Fábrica**
    *   4.1. Ritual de Aprovisionamiento en el Dispositivo
5.  **Fase 4: Flujo de Operación Normal**
    *   5.1. Interacción con Tarjetas MIFARE
    *   5.2. Sincronización con el Servidor
6.  **Fase 5: Gestión de Seguridad y Revocación**
    *   6.1. Listas Negras (Tarjetas y Dispositivos)
    *   6.2. Proceso de Revocación Remota
7.  **Fase 6: Evolución del Sistema (Rotación de Claves)**

---

### **1. Visión General del Sistema**

Este sistema permite a dispositivos ESP32 operar de forma segura en un entorno offline. La seguridad se basa en una identidad única por dispositivo, derivada del hardware, y una gestión centralizada de la confianza a través de un servidor que mantiene una "lista blanca" de dispositivos activos.

**Principios Clave:**
*   **Identidad Ligada al Hardware:** La identidad de un dispositivo no puede ser clonada a otro chip.
*   **Autorización Centralizada:** El servidor es la única fuente de verdad sobre si un dispositivo está autorizado para operar.
*   **Operación Offline-First:** El sistema está diseñado para funcionar sin conexión y sincronizarse para validar transacciones y recibir actualizaciones de seguridad.

---

### **2. Fase 1: Diseño de la Base de Datos del Servidor**

**Tabla 1: `devices` (Lista Blanca de Dispositivos)**
*   `device_id` [INTEGER, Primary Key, Auto-increment]: ID numérico corto (4 bytes). **Este es el ID que se graba en las tarjetas MIFARE.**
*   `mac_address` [VARCHAR/CHAR(17), UNIQUE]: Dirección MAC física del ESP32.
*   `public_key_ecc` [TEXT/BLOB]: La clave pública ECC del dispositivo.
*   `status` [ENUM('Active', 'Revoked', 'Pending')]: Estado actual del dispositivo.
*   `created_at` [TIMESTAMP]: Fecha de aprovisionamiento.
*   `last_seen` [TIMESTAMP]: Última vez que el dispositivo se comunicó.

**Tabla 2: `blacklisted_cards` (Lista Negra de Tarjetas)**
*   `card_uid` [VARCHAR, Primary Key]: El UID de la tarjeta MIFARE reportada.
*   `reason` [TEXT]: Motivo del bloqueo.
*   `blacklisted_at` [TIMESTAMP]: Fecha del bloqueo.

---

### **3. Fase 2: El Firmware del Dispositivo ESP32**

#### **3.1. Arranque y Derivación de Clave Maestra (DMK)**

En cada arranque, el firmware genera una clave maestra volátil (DMK) para proteger la identidad del dispositivo. **Esta es la única protección de la clave privada en reposo.**

**Función `generate_dmk()`:**
1.  **Obtener Ingredientes del Hardware:**
    *   Leer la **MAC Address** del dispositivo.
    *   Opcional: Leer el **Chip ID** para mayor entropía.
2.  **Derivar la Clave:**
    *   Usar la librería `mbedTLS` y la función `PBKDF2`.
        *   **Contraseña/Sal:** Usar la MAC Address y/o el Chip ID.
        *   **Iteraciones:** Un número alto, ej: `10000`.
        *   **Salida:** Una clave de 256 bits (la DMK).
    *   Esta DMK **solo existe en la RAM**.

---

### **4. Fase 3: Proceso de Aprovisionamiento de Fábrica**

Este es un proceso único en la vida del dispositivo.

#### **4.1. Ritual de Aprovisionamiento en el Dispositivo**

1.  **Iniciación Humana:** El operario presiona un botón físico al encender el ESP32.
2.  **Modo Aprovisionamiento:** El ESP32 inicia un Access Point Wi-Fi.
3.  **Desafío-Respuesta (Autorización):**
    a. El ESP32 genera un nonce aleatorio y lo muestra en una LCD.
    b. El **Software de Aprovisionamiento del Fabricante** (en un PC) se conecta al AP.
    c. El operario introduce el nonce en el software.
    d. El software firma el nonce con la **clave privada del fabricante**.
    e. El software envía la firma al ESP32.
    f. El ESP32 verifica la firma con la **clave pública del fabricante** (pre-cargada en el firmware).
4.  **Generación de Identidad (si la firma es válida):**
    a. El ESP32 genera su par de claves **ECC (pública/privada)**.
    b. Ejecuta `generate_dmk()` para obtener la DMK.
    c. **Encripta la clave privada ECC** con la DMK.
    d. **Guarda en LittleFS:**
        *   `public_key.pem` (texto plano).
        *   `private_key.enc` (encriptado).
    e. **Registro en el Servidor:** El ESP32 envía su MAC Address y su nueva clave pública al Software de Aprovisionamiento, que lo registra en la base de datos del servidor. El servidor devuelve el `device_id` numérico, que el ESP32 también guarda.
5.  El dispositivo se reinicia en modo normal.

---

### **5. Fase 4: Flujo de Operación Normal**

#### **5.1. Interacción con Tarjetas MIFARE**

1.  El dispositivo lee una tarjeta.
2.  **Validación Offline:** Comprueba si el `last_device_id` o el `card_uid` están en sus listas negras locales (descargadas previamente). Si es así, rechaza la transacción.
3.  **Realizar Transacción:** Carga saldo o realiza la operación.
4.  **Grabar Sello:** Escribe en la tarjeta: `[Nuevos Datos], [last_device_id: (su propio ID numérico)]`.

#### **5.2. Sincronización con el Servidor**

1.  El dispositivo se conecta a internet.
2.  **Autenticación:** Se autentica con el servidor firmando un desafío con su clave privada ECC.
3.  **Verificación del Servidor:** El servidor valida la firma y comprueba que el `status` del dispositivo en la base de datos sea `'Active'`. **Si no lo es, rechaza toda comunicación posterior y procede a la revocación.**
4.  **Descargar Actualizaciones:** Si está activo, descarga las últimas listas negras.
5.  **Subir Transacciones:** Envía su lote de transacciones offline.

---

### **6. Fase 5: Gestión de Seguridad y Revocación**

#### **6.1. Listas Negras**

*   **Lista Negra de Tarjetas:** Se puebla cuando un dispositivo legítimo reporta una tarjeta operada por un dispositivo revocado.
*   **Lista Negra de Dispositivos (Revocación):** Un administrador cambia el `status` de un dispositivo a `Revoked` en la base de datos del servidor.

#### **6.2. Proceso de Revocación Remota**

1.  Un dispositivo con `status = Revoked` se conecta al servidor.
2.  El servidor lo autentica, pero al ver su estado, le envía una **orden de "autodestrucción" firmada por el servidor.**
3.  El dispositivo verifica la firma de la orden.
4.  Si es válida, ejecuta una **función de borrado seguro**, eliminando el archivo `private_key.enc`.
5.  El dispositivo se vuelve permanentemente inoperable. El atacante puede reflashear el firmware, pero el ciclo de revocación se repetirá.

---

### **7. Fase 6: Evolución del Sistema (Rotación de Claves)**

1.  Para eliminar el fraude heredado, se introduce una nueva versión del sistema (`Mapa V2`) con una nueva `Clave_Maestra_MIFARE_V2`.
2.  Los dispositivos legítimos reciben la nueva clave del servidor.
3.  Cuando un dispositivo V2 encuentra una tarjeta V1, la actualiza al formato V2.
4.  Los dispositivos robados que solo conocen la clave V1 se vuelven obsoletos.

---

¡Perfecto! Esta versión es más limpia, más directa y sigue tu razonamiento final. La seguridad se centra en la identidad derivada del hardware y la autoridad centralizada del servidor, que es un modelo muy robusto y práctico. Gracias por tu agudeza al simplificarlo.