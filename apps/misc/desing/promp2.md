Absolutamente. Tienes toda la razón. El proyecto ha evolucionado significativamente desde el último punto de guardado. Un nuevo prompt de re-contextualización es esencial para asegurar que podamos retomar el hilo con toda la nueva arquitectura y decisiones.

Aquí tienes el prompt actualizado y definitivo. Es más completo y refleja todas las decisiones finales que hemos tomado.

---

### Prompt de Re-contextualización Definitivo para el Proyecto de Monedero Offline

**Rol y Objetivo:**
"Actúa como mi arquitecto de seguridad principal y consultor técnico para un proyecto en desarrollo. A continuación, te proporciono el contexto completo de un sistema de monedero electrónico offline que hemos diseñado juntos. Tu tarea es asimilar este estado final del proyecto para poder responder a nuevas preguntas, proponer mejoras o analizar problemas específicos manteniendo la coherencia con todas las decisiones tomadas."

**Contexto del Sistema:**

**1. Plataforma y Caso de Uso:**
*   **Tarjeta:** MIFARE Classic 1K, con su seguridad nativa ignorada. La seguridad se construye en la capa de aplicación.
*   **Dispositivos:** Terminales de lectura/escritura IoT de bajos recursos (similares a Arduino/ESP32 con DCPCrypt) que operan offline.
*   **Backend:** Servidor central con base de datos PostgreSQL (`BIGINT` para user IDs).
*   **Caso de Uso Principal:** Sistema de pago de alto volumen y baja latencia (ej. transporte público), donde los terminales son "stateless".

**2. Arquitectura de Datos en la Tarjeta (Diseño de "Paquetes Separados"):**
*   **Total Usado:** 6 bloques de datos (96 bytes).
*   **Zona de Metadatos (3 bloques / 48 bytes):**
    *   **Bloque 1:** IV para Metadatos (16 bytes, público).
    *   **Bloques 2-3:** Ciphertext de Metadatos (32 bytes).
    *   **Contenido Lógico (antes de encriptar):** Un payload de 32 bytes compuesto por:
        *   Datos (16B): `issuer_id`(4), `versions`(2), `status`(1), relleno interno(9).
        *   MAC (16B): `header_mac` (HMAC-SHA256 truncado a 128 bits).
    *   **Clave:** Encriptado con `Header_Key` (derivada de una clave fija + UID).
*   **Zona de Wallet (3 bloques / 48 bytes):**
    *   **Bloque 1:** IV para Wallet (16 bytes, público).
    *   **Bloques 2-3:** Ciphertext de Wallet (32 bytes).
    *   **Contenido Lógico (antes de encriptar):** Un payload de 32 bytes compuesto por:
        *   Datos (16B): `user_ref_id`(4), `balance`(4), `tx_counter`(4), `ts`(4).
        *   MAC (16B): `global_mac` (HMAC-SHA256 truncado a 128 bits).
    *   **Clave:** Encriptado con `Data_Key` (derivada de la `Master_Key` + UID).
*   **Diseño de Respaldo (Opcional pero recomendado):** Replicar la estructura de la Zona de Wallet en otra área de la tarjeta y usar el `tx_counter` para determinar la copia válida, proporcionando protección contra escrituras fallidas ("tearing").

**3. Pila Tecnológica y Estándares Criptográficos:**
*   **Librería de Cifrado (Terminal):** `DCPCrypt` (`TDCP_rijndael`).
*   **Librería de Hash/HMAC (Terminal):** `System.Hash` (nativa de Delphi) para `THashSHA2.GetHMACAsBytes`.
*   **Cifrado de Datos en Tarjeta:** AES-128 en modo CBC.
*   **Padding:** Implementación manual de PKCS#7 dentro de la unidad de criptografía.
*   **Derivación de Claves (KDF):** Implementación manual de HKDF usando `System.Hash`.
*   **Interoperabilidad:** Todos los datos multi-byte se almacenan en formato **Big-Endian**.
*   **Comunicación Terminal-Servidor:** TLS 1.2/1.3. La autenticación y el intercambio de claves se basan en **Criptografía de Curva Elíptica (ECC)** por su eficiencia en dispositivos IoT.
    *   **Algoritmo de Firma:** ECDSA.
    *   **Curva Recomendada:** P-256 (`prime256v1`).
    *   **Gestión de Certificados:** Una **CA privada** propia para firmar los certificados ECC de los terminales y del servidor.

**4. Flujo de Transacción Simplificado:**
1.  Leer UID.
2.  Derivar `Header_Key`. Leer IV de metadatos. Desencriptar y verificar `header_mac`.
3.  Validar `issuer_id` y `card_status` (fallo rápido).
4.  Derivar `Data_Key`. Leer IV de la wallet. Desencriptar y verificar `global_mac`.
5.  Ejecutar lógica de negocio.
6.  Reconstruir y re-encriptar el paquete de la wallet.

---

Este prompt es un "snapshot" completo de nuestro trabajo. La próxima vez que lo uses, podré retomar la conversación con total precisión sobre la arquitectura final.