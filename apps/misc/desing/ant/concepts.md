Tabla de conceptos.

| Acrónimo/Término | Nombre Completo | Descripción Compacta y Rol en tu Proyecto |
| :--- | :--- | :--- |
| **AES** | Advanced Encryption Standard | **Cifrado Simétrico.** Algoritmo para encriptar los datos en la tarjeta (saldo, etc.). Rápido y seguro, usa la misma clave para cifrar y descifrar. |
| **RSA** | Rivest-Shamir-Adleman | **Cifrado Asimétrico.** Para la comunicación segura terminal-servidor. El terminal cifra con la clave pública del servidor, garantizando la autenticidad y confidencialidad en la red. |
| **MAC** | Message Authentication Code | **Sello de Integridad.** Código que se añade a un mensaje para probar que no ha sido alterado. Si un byte cambia, el MAC se invalida. Es un concepto general. |
| **HMAC** | Hash-based MAC | **Implementación de MAC.** Algoritmo que usarás para generar el MAC, utilizando una función hash (como SHA-256) y una clave secreta. Garantiza **integridad** y **autenticidad**. |
| **KDF** | Key Derivation Function | **Fábrica de Claves (Genérico).** Es un algoritmo que crea una o más claves criptográficas seguras a partir de un secreto maestro. HKDF es una implementación específica de un KDF. |
| **HKDF** | HMAC-based KDF | **Fábrica de Claves (Específico).** Implementación estándar para tomar una Clave Maestra y generar de forma segura claves únicas para diferentes propósitos (una para AES, otra para HMAC). |
| **SHA-256** | Secure Hash Algorithm 256-bit | **Función de Huella Digital.** Algoritmo que convierte cualquier dato en una "huella digital" de tamaño fijo (32 bytes). Es el motor dentro de HMAC y HKDF. Es de una sola vía (no se puede revertir). |
| **TPM** | Trusted Platform Module | **Caja Fuerte de Hardware (Cliente).** Chip físico en el terminal IoT para proteger secretos criptográficos como la Clave Maestra. Realiza operaciones sin que la clave salga del chip. |
| **HSM** | Hardware Security Module | **Caja Fuerte de Hardware (Servidor).** Dispositivo externo de alta seguridad para proteger las Claves Maestras de todo tu sistema en el lado del servidor. |
| **UID** | Unique Identifier | **Matrícula de la Tarjeta.** Número de serie único y físico de la tarjeta MIFARE. No es un secreto, pero lo usarás como "sal" (entropía) para derivar las claves únicas de cada tarjeta. |
| **IV** | Initialization Vector | **Factor de Aleatoriedad.** Un número, de un solo uso, que se utiliza junto con la clave AES para asegurar que encriptar el mismo dato dos veces produzca resultados diferentes. Evita ataques de patrones. |
| **CA** | Certificate Authority | **Notario Digital.** Entidad que emite y firma certificados digitales. En tu caso, crearás tu propia CA privada para emitir los certificados de tus terminales IoT, asegurando que el servidor solo confíe en ellos. |

**Nuevos conceptos añadidos y su importancia:**

*   **KDF (Genérico):** Era importante diferenciar el concepto general de su implementación específica (HKDF).
*   **SHA-256:** Es el motor fundamental de HMAC y HKDF. Merece su propia fila porque es la base de la integridad.
*   **IV (Vector de Inicialización):** Es un componente crítico y no opcional cuando se usa AES en modos como CBC. Omitirlo es una vulnerabilidad grave.
*   **CA (Autoridad Certificadora):** Centraliza la confianza en tus certificados autofirmados, pasando de un modelo de "confianza individual" a un modelo de "confianza gestionada", lo que es mucho más seguro y escalable.

Ahora sí, esta tabla refleja de manera completa y precisa todos los pilares criptográficos y de seguridad que hemos construido para tu sistema.