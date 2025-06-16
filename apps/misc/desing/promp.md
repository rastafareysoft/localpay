Entendido. Acepto el desafío. Es una tarea crucial para la continuidad del proyecto.

Aquí tienes el prompt de re-contextualización definitivo, diseñado para que yo, en el futuro, pueda asimilar instantáneamente la totalidad de nuestra arquitectura, decisiones y metodología. Es un "snapshot" completo de nuestro universo de trabajo.

---

### **Prompt de Re-Contextualización Definitivo para el Proyecto de Monedero Offline y Plataforma SaaS**

**Rol y Objetivo:**
"Actúa como mi arquitecto de seguridad principal y consultor técnico para un proyecto SaaS multi-tenant en desarrollo. A continuación, te proporciono el contexto completo del sistema de monedero electrónico offline y la plataforma de gestión que hemos diseñado juntos. Tu tarea es asimilar este estado final del proyecto, incluyendo la arquitectura del sistema, el diseño de la base de datos, el estándar de diagramado y las decisiones de seguridad, para poder responder a nuevas preguntas, proponer mejoras o analizar problemas específicos manteniendo la coherencia con todo lo acordado."

**Contexto Global del Sistema (Arquitectura SaaS Distribuida):**

1.  **Modelo de Negocio:** Plataforma SaaS que permite a múltiples clientes (`Issuers`) operar sus propios sistemas de monedero offline. Nosotros, como proveedores, gestionamos la plataforma y nuestra propia contabilidad interna.
2.  **Aislamiento de Clientes:** Cada cliente (`Tenant`) tiene su propia **base de datos PostgreSQL separada**, garantizando el aislamiento total de los datos.
3.  **Sistema de Descubrimiento Central (El "Cerebro"):** Se utiliza un servicio de alta disponibilidad como **Firestore** para almacenar metadatos de infraestructura. Actúa como un directorio para que las aplicaciones cliente encuentren la ruta y credenciales de su DB PostgreSQL específica y las URLs para actualizaciones de software.
4.  **Notificaciones y Gestión de Dispositivos en Tiempo Real:** Se utiliza un broker **MQTT** para notificaciones push a las aplicaciones y a los terminales IoT. Esto permite acciones instantáneas como forzar la re-sincronización de configuración o iniciar actualizaciones de firmware **OTA (Over-The-Air)**.

**Contexto del Producto del Tenant (El Sistema de Monedero):**

1.  **Plataforma y Caso de Uso (Tarjeta y Terminales):**
    *   **Tarjeta:** MIFARE Classic 1K, con seguridad de aplicación personalizada.
    *   **Terminales:** Dispositivos IoT de bajos recursos (Arduino/ESP32, Delphi/DCPCrypt) que operan mayormente offline y son "stateless".
    *   **Caso de Uso:** Sistema de pago de alto volumen y baja latencia (ej. transporte público).

2.  **Arquitectura de Datos en Tarjeta:**
    *   **Header (3 Bloques):** Metadatos de control (`issuer_id`, `system_version`, `key_version_id`, `card_status`) protegidos por un `header_mac` de 15 bytes.
    *   **Wallet (3 Bloques):** Datos transaccionales (`user_ref_id`, `balance`, `tx_counter`) protegidos por un `wallet_mac` de 15 bytes.
    *   **Respaldo:** Se replica la estructura de la Wallet en otra área para protección contra escrituras fallidas ("tearing"), usando el `tx_counter` como árbitro.

3.  **Seguridad y Mitigación de Riesgos Offline:**
    *   **Tarjeta Perdida:** Se gestiona como "efectivo digital". La pérdida es asumida por el `Issuer`.
    *   **Listas de Revocación (CRLs):** Los terminales mantienen una lista negra de UIDs de tarjetas revocadas. Para escalar, se recomienda el uso de un **Filtro de Bloom**, aunque un array binario en EEPROM (~8K UIDs en 64KB) es una opción inicial viable.
    *   **"Envenenamiento":** Un terminal actualizado que detecta una tarjeta de la CRL debe escribir en ella para cambiar su `card_status` a un estado de bloqueo permanente.
    *   **Límites de Velocidad (Velocity Checks):** Los terminales imponen límites de gasto (por transacción, acumulado, etc.) para minimizar el daño por fraude.

**Contexto del Diseño de Base de Datos del Tenant:**

1.  **Estándar de Diagramado E-R (Nuestro Estándar No-Estándar):**
    *   **Entidades:** Rectángulos azules (diseño) o morados (implementado).
    *   **Relaciones:** Rombos verdes.
    *   **Cardinalidad:** Definida por la punta de la flecha. **Sin flecha = 1, Con flecha = N**.
    *   **Semántica:** Etiquetas de texto junto a las líneas que refuerzan la cardinalidad (ej. "Puede tener varios" apunta al lado "N").
    *   **Atributos:** Grupos de nodos circulares externos (PK: magenta, UK: rosa, etc.).

2.  **Esquema de Base de Datos (Borrador v1.0):**
    *   **Entidades Principales:** `issuers`, `users` (unificada para administradores y usuarios finales), `accounts` (1 a 1 con `users`), `cards`, `terminals`.
    *   **Contabilidad:** Una tabla `transactions` central que registra todos los movimientos de valor, relacionando cuentas, tarjetas y terminales. Se ha decidido mantener este modelo (a pesar de la relación ternaria) y gestionarlo con lógica de aplicación.
    *   **RBAC (Role-Based Access Control):**
        *   **Entidades:** `users`, `roles`, `modules`, `applications`.
        *   **Permisos:** Se gestionan a través de una tabla intermedia `role_module_permissions` con una columna `permission_mask` (SMALLINT). Esta máscara representa los permisos (ej. Access, Create, Read, Update, Delete) como una máscara de bits (bitmask).
        *   **Lógica de Consolidación:** La forma en que se combinan los permisos de múltiples roles (AND vs OR) es una decisión de negocio abierta, a implementar en la capa de aplicación.

---

Este prompt es mi nuevo "génesis". La próxima vez que me lo proporciones, lo asimilaré y podré retomar cualquier hilo de nuestra compleja discusión con total precisión y coherencia.