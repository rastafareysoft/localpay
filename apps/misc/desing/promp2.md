¡Absolutamente! Es el momento perfecto para consolidar todo. Un "snapshot" completo es esencial antes de la siguiente ronda de ~248 cambios.

Aquí tienes el resumen completo y detallado del proyecto, diseñado para ser mi prompt de re-contextualización definitivo. He incluido cada capa de nuestra arquitectura, desde el metal de la tarjeta hasta la estrategia de negocio SaaS.

---

### **Prompt de Re-Contextualización Definitivo (Borrador v1.1)**

**Rol y Objetivo:**
"Actúa como mi arquitecto de seguridad principal y consultor técnico para un proyecto SaaS multi-tenant. A continuación, se detalla el contexto completo del sistema, abarcando desde la arquitectura global distribuida hasta el último bit en la tarjeta del usuario. Tu tarea es asimilar este estado del proyecto para continuar nuestra colaboración, proponiendo mejoras, analizando vulnerabilidades y diseñando soluciones, manteniendo una coherencia total con todas las decisiones tomadas."

---

### **1. Arquitectura Global del Sistema (Plataforma SaaS)**

*   **Modelo de Negocio:** Una plataforma SaaS que proveemos como solución a múltiples clientes (`Tenants` o `Issuers`), quienes a su vez operan sus propios sistemas de monedero.
*   **Aislamiento de Datos:** La arquitectura es de **aislamiento total**. Cada Tenant tiene su propia **base de datos PostgreSQL separada**. Adicionalmente, "Nosotros" (el proveedor del SaaS) tenemos nuestra propia base de datos de gestión, completamente independiente.
*   **Sistema de Descubrimiento y Configuración ("El Cerebro"):**
    *   Se utiliza un servicio central de alta disponibilidad (ej. **Firestore**) como directorio raíz.
    *   Almacena **metadatos de infraestructura**, no datos de negocio. Permite a las aplicaciones cliente y a los terminales descubrir dinámicamente la ruta de conexión a su DB PostgreSQL específica y las URLs para actualizaciones.
*   **Gestión y Notificaciones en Tiempo Real:**
    *   Un broker **MQTT** forma el sistema nervioso central para la comunicación en tiempo real.
    *   Permite la gestión proactiva de la infraestructura, como notificar a las aplicaciones de un cambio de configuración (ej. migración de DB) y, crucialmente, iniciar actualizaciones de firmware **OTA (Over-The-Air)** para los terminales IoT desplegados en campo.

---

### **2. Arquitectura del Producto del Tenant (El Monedero Offline)**

#### **A. Tarjeta y Terminales (Capa Física)**

*   **Tarjeta:** MIFARE Classic 1K. La seguridad nativa se ignora; la seguridad se construye en la capa de aplicación.
*   **Terminales:** Dispositivos IoT de bajos recursos (Arduino/ESP32) que operan mayormente offline.
*   **Mapa de Datos en Tarjeta:**
    *   **Header (3 Bloques):** Contiene metadatos de control: `issuer_id`, `system_version`, `key_version_id`, `card_status`. Protegido por un **`header_mac` de 15 bytes**.
    *   **Wallet (3 Bloques):** Contiene datos transaccionales: `user_ref_id`, `balance`, `tx_counter`. Protegido por un **`wallet_mac` de 15 bytes**.
    *   **Protección Anti-Tearing:** Una **zona de Respaldo** replica la estructura de la Wallet. El `tx_counter` actúa como árbitro para determinar la copia válida en caso de una escritura fallida.

#### **B. Sistemas de Seguridad y Mitigación de Riesgos Offline**

*   **Paradigma Central:** Una tarjeta offline cargada es funcionalmente **"dinero en efectivo digital"**. La posesión permite el gasto en terminales no actualizados. El objetivo no es eliminar el riesgo, sino gestionarlo y limitarlo.
*   **Defensa 1: Listas de Revocación (CRLs):**
    *   Los terminales mantienen una lista negra local de UIDs de tarjetas reportadas como perdidas/robadas.
    *   Se ha validado una capacidad de **~8,000 UIDs** en una EEPROM de 64KB con almacenamiento binario.
    *   Para escalabilidad masiva, la solución a largo plazo es el uso de un **Filtro de Bloom**.
*   **Defensa 2: "Envenenamiento" de Tarjetas:**
    *   Un terminal actualizado que detecta una tarjeta de la CRL tiene la orden de **escribir en ella para cambiar su `card_status`** a un estado de bloqueo permanente, inutilizándola para futuras transacciones offline.
*   **Defensa 3: Límites de Velocidad (Velocity Checks):**
    *   El firmware del terminal impone límites de gasto pre-configurados (monto por transacción, transacciones acumuladas, etc.) para minimizar la pérdida potencial de una tarjeta comprometida.

---

### **3. Arquitectura de la Base de Datos del Tenant**

#### **A. Estándar de Diagramado E-R (Nuestro Método)**
*   Un estándar visual propio ha sido definido para las 3 etapas de diseño (Entidades -> Cardinalidad -> Campos). La cardinalidad se define por la presencia (`N`) o ausencia (`1`) de una flecha al final de la línea de relación.

#### **B. Esquema de Base de Datos (Borrador v1.1 - Post-Modificación #3)**

*   **Entidades Centrales:** `issuers` (config. del tenant), `terminals`.
*   **Estructura de Usuarios (Unificada):**
    *   Una única tabla `users` para usuarios finales y administradores. La diferenciación se realiza mediante roles.
*   **Estructura de Cuentas (Flexible - Modificación #3):**
    *   La relación entre `users` y `accounts` es **1:N**.
    *   La tabla `accounts` incluye un `account_type` ('PRIMARY', 'TEMPORARY_RETENTION') para manejar lógicas de negocio complejas como la retención de saldo por tarjeta perdida y futuras sub-cuentas familiares.
*   **Estructura de Tarjetas:**
    *   La relación entre `users` y `cards` es **1:N** para soportar el caso de uso de múltiples tarjetas por usuario (ej. para familiares).
*   **Contabilidad y Transacciones:**
    *   Se mantiene una única tabla `transactions` que centraliza el registro de valor, relacionando cuentas, tarjetas y terminales. Se ha decidido gestionar la complejidad de esta relación ternaria en la capa de aplicación.
*   **Control de Acceso (RBAC):**
    *   **Entidades:** `users`, `roles`, `modules`, `applications`.
    *   **Permisos:** Gestionados a través de la tabla intermedia `role_module_permissions` con un campo `permission_mask` (SMALLINT, bitmask) para definir granularmente las acciones (Access, Create, Read, Update, Delete, etc.).
    *   **Lógica de Consolidación:** La combinación de permisos para un usuario con múltiples roles (ej. `AND` vs `OR`) es una decisión de negocio abierta a implementar en la aplicación.

---
### **4. Glosario de Términos del Proyecto**
*(Un glosario está en construcción para definir términos clave como `Mermaid`, `RBAC`, `Filtro de Bloom`, `Velocity Checks`, etc., para asegurar un entendimiento común).*

---

Este prompt representa la totalidad de nuestro conocimiento y decisiones hasta este momento. Estoy listo para que lo usemos como base para nuestro próximo ciclo de "ataque" y refinamiento.