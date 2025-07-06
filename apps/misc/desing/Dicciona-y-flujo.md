Comprendido. Procedo a reestructurar la información en un formato más claro y visual, con un diccionario de términos y una tabla resumen para las claves, tal como solicitaste.

---

### Arquitectura de Seguridad: Glosario y Flujos

#### **I. Diccionario de Términos Generales**

*   **Aprovisionamiento:** Proceso único de configuración inicial donde un dispositivo "virgen" se registra en el sistema, genera sus credenciales de identidad y recibe los secretos necesarios para operar.
*   **Activación:** Paso final del aprovisionamiento que marca a un dispositivo como operativo y confiable en el backend del servidor.
*   **Handshake (Acuerdo de Clave):** Proceso criptográfico (usando ECDHE) mediante el cual dos partes (ej. dispositivo y servidor) establecen una clave de sesión secreta y temporal para cifrar su comunicación, garantizando Perfect Forward Secrecy.
*   **KDF (Función de Derivación de Clave):** Un algoritmo (en nuestro caso, **HKDF**) que transforma un secreto inicial (que puede no ser uniforme) en una o más claves criptográficas fuertes y seguras.
*   **SAH (Secreto Anclado al Hardware):** Una "huella digital" única del hardware del dispositivo, compuesta por la concatenación de identificadores como la dirección MAC y el ID del Chip. Es la base para la protección de secretos en el dispositivo.
*   **Salt:** Un número aleatorio que se añade a la entrada de una KDF. Su propósito es asegurar que la derivación de claves sea única y proteger contra ataques precalculados (como rainbow tables).
*   **Lista Negra:** Un registro, mantenido por el servidor y sincronizado con los dispositivos, que contiene los IDs de tarjetas o dispositivos que han sido reportados como robados o comprometidos y que ya no deben ser aceptados.
*   **Píldora de Veneno (Kill Switch):** Una orden remota enviada desde el servidor (ej. vía MQTT) a un dispositivo comprometido para que se bloquee o borre sus secretos de forma permanente.

---

#### **II. Tabla Resumen de Claves y Secretos**

| Término | Significado | Dónde se Origina | Dónde se Usa | Cuándo se Usa |
| :--- | :--- | :--- | :--- | :--- |
| **`K_master`** | **Clave Maestra** | Servidor (una vez) | Servidor | Para derivar la `KDU`. |
| **`KDU`** | **Clave de Diversificación Universal** | Servidor (derivada de `K_master`) | Servidor y Dispositivos | Para derivar la clave de acceso a cada tarjeta MIFARE. |
| **`KCD`** | **Clave de Cifrado de Dispositivo** | Dispositivo (derivada del `SAH`) | Dispositivo (solo en RAM) | En cada arranque, para descifrar secretos (`KDU`) de la flash. |
| **`KCS`** | **Clave de Cifrado para el Salt** | Dispositivo (derivada del `SAH`) | Dispositivo (solo en RAM) | En cada arranque, para descifrar el `salt`. |
| **`K_mifare`**| **Clave de Acceso MIFARE** | Dispositivo/Servidor (derivada de `KDU`) | Dispositivo/Servidor (efímera) | Durante cada transacción con una tarjeta MIFARE. |
| **`K_cifrado`**| **Clave de Cifrado de Datos AES** | Dispositivo/Servidor (derivada de `KDU`) | Dispositivo/Servidor (efímera) | Durante cada transacción, para cifrar/descifrar los datos en la tarjeta. |
| **`Serv_Priv`**| **Clave Privada del Servidor (ECC)** | Servidor (una vez) | Servidor | Para firmar "certificados de identidad" durante el aprovisionamiento. |
| **`Serv_Pub`** | **Clave Pública del Servidor (ECC)** | Servidor (una vez) | Dispositivos | En fábrica, para verificar la firma de los certificados de identidad. |
| **`Disp_Priv`**| **Clave Privada del Dispositivo (ECC)**| Dispositivo (en aprovisionamiento)| Dispositivo | Para firmar cada transacción enviada al servidor. |
| **`Disp_Pub`** | **Clave Pública del Dispositivo (ECC)**| Dispositivo (en aprovisionamiento)| Servidor | Para verificar la firma de las transacciones recibidas del dispositivo. |
| **`EF_Priv`** | **Clave Privada Efímera (ECC)** | Dispositivo/Servidor | Dispositivo/Servidor (efímera)| Al inicio de cada sesión de comunicación, para el handshake ECDHE. |
| **`EF_Pub`** | **Clave Pública Efímera (ECC)** | Dispositivo/Servidor | Dispositivo/Servidor (efímera)| Al inicio de cada sesión, se intercambia para el handshake ECDHE. |
| **`Clave AES`**| **Clave de Sesión Simétrica** | Dispositivo/Servidor (derivada de ECDHE) | Dispositivo/Servidor (efímera)| Durante una sesión de comunicación, para cifrar todo el tráfico. |

---

#### **III. Fases y Flujos de Trabajo Detallados**

**Fase 1: Fabricación**
1.  **Acción:** Preparar el entorno y los dispositivos.
2.  **Pasos:**
    *   El Servidor genera su `K_master` y el par de claves `Servidor_Priv`/`Servidor_Pub`.
    *   Se inyecta la `Servidor_Pub` en la memoria de solo lectura de cada dispositivo.
    *   Se registra el `SAH` (MAC+ChipID) de cada dispositivo en una base de datos central de hardware permitido.

**Fase 2: Aprovisionamiento (en el campo)**
1.  **Acción:** Un operador registra un nuevo dispositivo en el sistema.
2.  **Pasos:**
    1.  **Dispositivo:** Al pulsar un botón, genera su par `Disp_Priv`/`Disp_Pub` y un `PIN_Activacion` temporal. Cifra `Disp_Priv` usando su `KCD` y la guarda en flash.
    2.  **App Operador:** Se conecta al dispositivo usando el `PIN_Activacion` y recibe `Disp_Pub`.
    3.  **App -> Servidor:** Envía `Disp_Pub` y el `SAH` del dispositivo.
    4.  **Servidor:**
        *   Valida que el `SAH` esté pre-registrado.
        *   Genera un `ID_Unico` y lo asocia con `Disp_Pub`.
        *   Deriva la `KDU` a partir de `K_master`.
        *   Crea un "paquete de aprovisionamiento" (`ID_Unico`, `KDU`).
        *   Firma el paquete con `Servidor_Priv` y lo devuelve.
    5.  **App -> Dispositivo:** Entrega el paquete firmado.
    6.  **Dispositivo:** Verifica la firma con `Servidor_Pub`. Si es válida, guarda su `ID_Unico` y la `KDU` (cifrada). El dispositivo queda "aprovisionado" pero pendiente de activación.

**Fase 3: Activación**
1.  **Acción:** Dar el visto bueno final para que el dispositivo opere.
2.  **Pasos:**
    *   El operador, desde la app, envía un comando "Activar" para el `ID_Unico` al servidor.
    *   El servidor marca el dispositivo como "Activo".
    *   El dispositivo puede ahora iniciar comunicaciones operativas.

**Fase 4: Transacción con Tarjeta (Offline)**
1.  **Acción:** Leer o escribir en una tarjeta MIFARE.
2.  **Pasos:**
    1.  El dispositivo lee el `UID_tarjeta`.
    2.  Deriva `K_mifare` y `K_cifrado` usando su `KDU` (previamente descifrada en RAM) y el `UID_tarjeta`.
    3.  Usa `K_mifare` para acceder a la tarjeta.
    4.  Usa `K_cifrado` para cifrar/descifrar los datos del sector.
    5.  Genera un registro de la transacción.
    6.  Firma el registro con `Disp_Priv`.
    7.  Almacena la transacción firmada en una cola de envío.

**Fase 5: Sincronización (Online)**
1.  **Acción:** El dispositivo se conecta a internet para reportar transacciones y recibir actualizaciones.
2.  **Pasos:**
    1.  **Handshake ECDHE:** Dispositivo y servidor establecen un canal seguro con una `Clave AES` de sesión.
    2.  **Envío:** El dispositivo envía su cola de transacciones firmadas a través del canal cifrado.
    3.  **Recepción y Verificación:** El servidor recibe los datos, los descifra, y luego verifica la firma de cada transacción individual con la `Disp_Pub` que tiene registrada.
    4.  **Actualización:** El servidor envía la última lista negra de tarjetas/dispositivos al dispositivo a través del mismo canal seguro.
    5.  El dispositivo actualiza sus políticas y cierra la sesión.