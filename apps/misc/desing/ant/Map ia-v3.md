¡Perfecto! Aquí tienes el documento final y consolidado para tus notas. Incluye el mapa de memoria definitivo, el desglose detallado del uso de bytes y bloques, y el diagrama lógico actualizado con el `card_status` en el encabezado.

---

### Documentación Final del Mapa de Tarjeta (Versión 1.0)

#### 1. Resumen de Uso de Espacio en Tarjeta MIFARE 1K

| Componente | Descripción | Bytes Usados | Bloques MIFARE Usados |
| :--- | :--- | :--- | :--- |
| **Bloque de Encabezado (HEADER)** | Metadatos de control y estado. | 16 Bytes | 1 Bloque |
| **Payload de Datos (DATA)** | Compuesto por el IV y los datos de la cartera. | 80 Bytes | 5 Bloques |
| | _- IV (Vector de Inicialización)_ | _(16 Bytes)_ | _(1 Bloque)_ |
| | _- Datos Encriptados_ | _(64 Bytes)_ | _(4 Bloques)_ |
| **TOTAL** | **Suma de todos los componentes** | **96 Bytes** | **6 Bloques** |

**Conclusión de uso:** El diseño utiliza solo 6 de los ~48 bloques de datos disponibles, dejando un amplio espacio para futuras expansiones.

---

#### 2. Mapa de Memoria Detallado

##### 2.1. Bloque de Encabezado (HEADER) - 16 Bytes

Este bloque permite un "fallo rápido" para rechazar tarjetas no válidas o bloqueadas con un rendimiento máximo.

*   **Ubicación Fija:** Ej. Sector 1, Bloque 0
*   **Seguridad:** Encriptado con `Header_Key` (derivada rápidamente vía AES)

| Offset | Tamaño | Campo | Descripción |
| :--- | :--- | :--- | :--- |
| **0 - 3** | 4 B | `issuer_id` | ID de la empresa emisora. |
| **4** | 1 B | `system_version` | Versión de la estructura de datos. |
| **5** | 1 B | `key_version_id` | ID de la Clave Maestra a usar. |
| **6** | **1 B** | **`card_status`** | **Estado de la tarjeta (1: Activa, 2: Bloqueada, etc.).** |
| **7 - 15** | **9 B** | `header_mac` | MAC truncado que protege la integridad de los 7 bytes anteriores. |
| **Total** | **16 B** | | |

##### 2.2. Payload de Datos (DATA) - 80 Bytes en Tarjeta

Contiene la información sensible de la cartera del usuario.

*   **Ubicación Fija:** Ej. Comienza en Sector 2, Bloque 0
*   **Seguridad:** IV en texto plano + Datos encriptados con `Data_Key` (derivada de la `Master_Key`).

**Contenido Lógico de los "Datos Encriptados" (64 Bytes antes de encriptar):**

| Offset Lógico | Tamaño | Campo | Descripción |
| :--- | :--- | :--- | :--- |
| **0 - 3** | 4 B | `user_ref_id` | ID del usuario (entero 32-bit, Big-Endian). |
| **4 - 7** | 4 B | `balance` | Saldo actual (entero 32-bit, Big-Endian). |
| **8 - 11** | 4 B | `tx_counter` | Contador de transacciones (entero 32-bit, Big-Endian). |
| **12 - 15** | 4 B | `last_tx_ts` | Timestamp de la última transacción (Unix 32-bit). |
| **16 - 47** | 32 B | `global_mac` | HMAC-SHA256 para la integridad de los datos (bytes 0-15). |
| **48 - 63** | 16 B | `padding` | Relleno PKCS#7 para alinear el total a 64 bytes. |
| **Total** | **64 B** | | |

---

#### 3. Resumen Lógico y Gráfico del Mapa de Tarjeta

```mermaid
graph TD
    subgraph "Tarjeta MIFARE 1K"
        A["<b>Sector 1, Bloque 0</b><br/>(16 Bytes)"]
        B["<b>Sectores 2 y 3</b><br/>(80 Bytes / 5 Bloques)"]
    end

    subgraph "Contenido Lógico Desglosado"
        subgraph "1. Encabezado (HEADER)"
            direction LR
            H1["<b>issuer_id</b><br/>(4B)"]
            H2["<b>system_version</b><br/>(1B)"]
            H3["<b>key_version_id</b><br/>(1B)"]
            H4["<b>card_status</b><br/><b>(1B)</b>"]
            H5["<b>header_mac</b><br/>(9B)"]
        end

        subgraph "2. Payload de Datos (DATA)"
            D1["<b>IV (Vector de Inicialización)</b><br/>(16 Bytes)"]
            D2["<b>Datos Encriptados (64 Bytes)</b>"]
        end
        
        subgraph "Contenido Interno de 'Datos Encriptados'"
            direction TB
            D2_1["<b>user_ref_id</b><br/>(4B)"]
            D2_2["<b>balance</b><br/>(4B)"]
            D2_3["<b>tx_counter</b><br/>(4B)"]
            D2_4["<b>ts</b><br/>(4B)"]
            D2_5["<b>global_mac</b><br/>(32B)"]
            D2_6["<b>padding</b><br/>(16B)"]
        end
    end

    %% Enlaces
    H1 & H2 & H3 & H4 & H5 -->|"Agrupados, encriptados con<br/><b>Header_Key</b> y escritos en"| A
    D1 -->|"Escrito en texto plano en<br/>el primer bloque de datos"| B
    D2_1 & D2_2 & D2_3 & D2_4 & D2_5 & D2_6 -->|"Agrupados, encriptados con<br/><b>Data_Key</b> y escritos en<br/>los siguientes 4 bloques de datos"| D2
    D2 -->|"Añadido después del IV"| B

    %% Estilos
    style A fill:#cde4ff,stroke:#333,stroke-width:2px
    style B fill:#d5fada,stroke:#333,stroke-width:2px
    style H4 fill:#fff59d,stroke:#f57f17,stroke-width:2px
    style H5 fill:#ffcdd2,stroke:#b71c1c
    style D2_5 fill:#ffcdd2,stroke:#b71c1c
```