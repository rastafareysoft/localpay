¡Absolutamente! Pido disculpas por el error de formato anterior. Aquí tienes la versión corregida y bien formateada de la documentación final del mapa de memoria, con el `user_ref_id` optimizado a 4 bytes.

---

### Mapa de Memoria Detallado (Versión Optimizada Final)

#### 1. Bloque de Encabezado (HEADER) - 16 Bytes (Sin Cambios)

*   **Ubicación Fija:** Ej. Sector 1, Bloque 0
*   **Seguridad:** Encriptado con `Header_Key` (derivada rápidamente vía AES)

| Offset | Tamaño | Campo | Descripción |
| :--- | :--- | :--- | :--- |
| **0 - 3** | 4 B | `issuer_id` | ID de la empresa emisora (para "fallo rápido"). |
| **4** | 1 B | `system_version` | Versión de la estructura de datos. |
| **5** | 1 B | `key_version_id` | ID de la Clave Maestra a usar. |
| **6 - 15** | 10 B | `header_mac` | MAC truncado para la integridad del encabezado. |
| **Total** | **16 B** | | |

#### 2. Payload de Datos (DATA) - 80 Bytes en Tarjeta (Estructura Interna Optimizada)

*   **Ubicación Fija:** Ej. Comienza en Sector 2, Bloque 0
*   **Seguridad:** IV en texto plano + Datos encriptados con `Data_Key` (derivada de la `Master_Key`).

**Contenido Lógico de los "Datos Encriptados" (64 Bytes antes de encriptar):**

| Offset Lógico | Tamaño | Campo | Descripción |
| :--- | :--- | :--- | :--- |
| **0 - 3** | **4 B** | **`user_ref_id`** | **ID del usuario (entero 32-bit, Big-Endian).** |
| **4 - 7** | 4 B | `balance` | Saldo actual (entero 32-bit, Big-Endian). |
| **8 - 11** | 4 B | `tx_counter` | Contador de transacciones (entero 32-bit, Big-Endian). |
| **12 - 15** | 4 B | `last_tx_ts` | Timestamp de la última transacción (Unix 32-bit). |
| **16** | 1 B | `card_status` | Estado de la tarjeta (Activa, Bloqueada, etc.). |
| **17 - 48** | 32 B | `global_mac` | HMAC-SHA256 para la integridad de los datos (bytes 0-16). |
| **49 - 63** | 15 B | `padding` | Relleno PKCS#7 para alinear a 64 bytes. |
| **Total** | **64 B** | | |

---

### Resumen Lógico y Gráfico del Mapa de Tarjeta (Versión Optimizada Final)

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
            H4["<b>header_mac</b><br/>(10B)"]
        end

        subgraph "2. Payload de Datos (DATA)"
            D1["<b>IV (Vector de Inicialización)</b><br/>(16 Bytes)"]
            D2["<b>Datos Encriptados (64 Bytes)</b>"]
        end
        
        subgraph "Contenido Interno de 'Datos Encriptados' (ACTUALIZADO)"
            direction TB
            D2_1["<b>user_ref_id</b><br/><b>(4B)</b>"]
            D2_2["<b>balance</b><br/>(4B)"]
            D2_3["<b>tx_counter</b><br/>(4B)"]
            D2_4["<b>ts</b><br/>(4B)"]
            D2_5["<b>status</b><br/>(1B)"]
            D2_6["<b>global_mac</b><br/>(32B)"]
            D2_7["<b>padding</b><br/>(15B)"]
        end
    end

    %% Enlaces de Flujo
    H1 & H2 & H3 & H4 -->|"Agrupados, encriptados con<br/><b>Header_Key</b> y escritos en"| A

    D1 -->|"Escrito en texto plano en<br/>el primer bloque de datos"| B
    D2_1 & D2_2 & D2_3 & D2_4 & D2_5 & D2_6 & D2_7 -->|"Agrupados, encriptados con<br/><b>Data_Key</b> y escritos en<br/>los siguientes 4 bloques de datos"| D2
    D2 -->|"Añadido después del IV"| B

    %% Estilos para claridad
    style A fill:#cde4ff,stroke:#333,stroke-width:2px
    style B fill:#d5fada,stroke:#333,stroke-width:2px
    style H1 fill:#fff,stroke:#333
    style H2 fill:#fff,stroke:#333
    style H3 fill:#fff,stroke:#333
    style H4 fill:#ffcdd2,stroke:#b71c1c
    style D1 fill:#e1e1e1,stroke:#333
    style D2_1 fill:#fff59d,stroke:#f57f17,stroke-width:2px
    style D2_6 fill:#ffcdd2,stroke:#b71c1c
    
```

**Explicación de los Cambios en el Diagrama:**

1.  **Encabezado (HEADER):** Permanece **idéntico**. La lógica de control no ha cambiado.
2.  **Payload de Datos (DATA):**
    *   **IV y Datos Encriptados:** La estructura general se mantiene, pero el contenido interno ha sido optimizado.
    *   **`user_ref_id`:** Ahora se muestra claramente con un tamaño de **4 Bytes** (resaltado en amarillo y con borde grueso).
    *   **`padding`:** Como resultado, el padding ha aumentado a 15 bytes para seguir llenando un total de 64 bytes.
    *   **`global_mac`:** Su función es la misma, pero ahora protege un subconjunto de datos ligeramente más pequeño (17 bytes en lugar de 21).

Este documento ahora refleja la decisión de diseño más reciente y eficiente, manteniendo toda la estructura de seguridad intacta y en un formato claro.

¡Excelente pregunta! Es fundamental tener claro el "presupuesto" de espacio que estamos utilizando en la tarjeta.

Aquí está el desglose exacto:

**En total, se han usado 96 bytes, que ocupan 6 bloques de datos MIFARE.**

---

### Desglose Detallado

| Componente | Descripción | Bytes Usados | Bloques MIFARE Usados |
| :--- | :--- | :--- | :--- |
| **Bloque de Encabezado (HEADER)** | `issuer_id`, `versions`, `header_mac` | 16 Bytes | 1 Bloque |
| **Payload de Datos (DATA)** | Compuesto por el IV y los datos encriptados | 80 Bytes | 5 Bloques |
| | _- IV (Vector de Inicialización)_ | _(16 Bytes)_ | _(1 Bloque)_ |
| | _- Datos Encriptados_ | _(64 Bytes)_ | _(4 Bloques)_ |
| **TOTAL** | **Suma de todos los componentes** | **96 Bytes** | **6 Bloques** |

<br/>

**Consideraciones:**

Una tarjeta MIFARE Classic 1K tiene 16 sectores, y cada sector (excepto el 0) tiene 3 bloques de datos disponibles (48 bytes por sector).

*   **Total de bloques de datos disponibles:** Aproximadamente 48 bloques (dependiendo de cómo se use el sector 0).
*   **Bloques usados por nuestro diseño:** 6 bloques.

**Conclusión:** Nuestro diseño es extremadamente eficiente en cuanto a espacio, utilizando solo una pequeña fracción de la capacidad total de la tarjeta. Esto te deja una enorme cantidad de espacio libre para futuras funcionalidades si alguna vez las necesitaras, como por ejemplo:

*   Almacenar un log de las últimas transacciones directamente en la tarjeta.
*   Añadir un segundo monedero (ej. puntos de lealtad).
*   Guardar otro tipo de credenciales.