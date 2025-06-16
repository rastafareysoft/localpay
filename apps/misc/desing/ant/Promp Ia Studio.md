### Prompt de Re-contextualización para el Proyecto de Monedero Offline

**Rol y Objetivo:**
"Actúa como mi arquitecto de seguridad principal y consultor técnico para un proyecto en desarrollo. A continuación, te proporciono el contexto completo de un sistema de monedero electrónico offline que hemos diseñado. Tu tarea es asimilar este estado del proyecto para poder responder a nuevas preguntas, proponer mejoras o analizar problemas específicos manteniendo la coherencia con las decisiones ya tomadas."

**Contexto del Sistema:**

1.  **Plataforma y Caso de Uso:**
    *   **Tarjeta:** MIFARE Classic 1K. Se asume que su seguridad nativa (Crypto1) es insegura. Toda la seguridad se construye en una capa de aplicación por encima.
    *   **Dispositivos:** Terminales de lectura/escritura IoT de bajos recursos (similares a Arduino/ESP32) que pueden operar offline.
    *   **Backend:** Servidor central con base de datos, comunicándose con los terminales vía RSA/TLS cuando están online.
    *   **Caso de Uso Principal:** Sistema de pago de alto volumen y baja latencia (ej. transporte público), donde los terminales son "stateless" (no cachean información de las tarjetas).

2.  **Arquitectura de Datos en la Tarjeta (Estructura de Doble Envoltura):**
    *   **Bloque de Encabezado (1 bloque, ej. S1B0):**
        *   **Seguridad:** Encriptado con `Header_Key`. No hay nada en texto plano.
        *   **Derivación de Clave:** `Header_Key` se deriva rápidamente usando `AES_Encrypt(Clave_Global_Fija, UID)`.
        *   **Contenido:** `system_version` (1 byte), `key_version_id` (1 byte), y un `header_mac` truncado para autoverificación.
    *   **Bloque de Datos (resto de sectores):**
        *   **Seguridad:** Encriptado con `Data_Key`.
        *   **Derivación de Clave:** `Data_Key` se deriva usando un KDF robusto (HKDF) a partir de la `Master_Key` correspondiente (indicada por `key_version_id`) y el `UID`. Se derivan claves separadas para encriptación (AES) y autenticación (HMAC).
        *   **Contenido:** Un único blob de datos que incluye: `balance` (entero 32-bit), `tx_counter` (entero 32-bit), `last_tx_ts` (timestamp Unix 32-bit), `card_status` (1 byte), y un `global_mac` (HMAC-SHA256 completo de 32 bytes) que protege la integridad de todo el blob de datos.

3.  **Flujo de Transacción (Resumen):**
    1.  Leer UID.
    2.  Derivar `Header_Key`, leer y desencriptar el Encabezado. Verificar `header_mac`.
    3.  Extraer `key_version_id` y `system_version`.
    4.  Derivar `Data_Key` y `Data_MAC_Key` usando la `Master_Key` correcta.
    5.  Leer, desencriptar y verificar el Bloque de Datos completo usando el `global_mac`.
    6.  Realizar operación, actualizar el payload, recalcular `global_mac`.
    7.  Encriptar y escribir de vuelta el Bloque de Datos. El Encabezado no se modifica en transacciones normales.

4.  **Pila Tecnológica y Estándares Criptográficos:**
    *   **Cifrado de Datos:** AES-128 en modo CBC con padding PKCS#7 y un IV no reutilizable.
    *   **Integridad:** HMAC-SHA256.
    *   **Derivación de Claves:** HKDF para las claves principales; AES-ECB para la clave del encabezado.
    *   **Comunicación Servidor:** TLS con certificados emitidos por una CA privada propia para autenticar los terminales.
    *   **Almacenamiento de Claves:** En el terminal, idealmente en un TPM/Secure Element. En el servidor, en un HSM.
    *   **Interoperabilidad:** Todos los datos multi-byte se almacenan en formato **Big-Endian (Network Byte Order)**.
