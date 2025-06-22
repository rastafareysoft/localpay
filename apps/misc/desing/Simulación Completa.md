Manual de operaciones para el firmware del terminal.

---

### **Simulación Completa y Optimizada de una Transacción Offline (v2.0)**

#### **Fase 1: Validación y Chequeos de Seguridad (El "Portero" Optimizado)**

*   **Paso 1: Presentación y Lectura de Identidad.**
    *   El usuario acerca la tarjeta al lector.
    *   Se lee el **UID** de la tarjeta.

*   **Paso 2: Chequeo Rápido de Estado en Tarjeta.**
    *   Se autentica en el **Sector del Header**.
    *   Se leen los 3 bloques del Header.
    *   Se desencripta el contenido y se **verifica el `header_mac`**.
        *   Si el MAC falla -> **FIN (Error: Tarjeta Corrupta).**
    *   Se lee el byte del `card_status`.
        *   Si `card_status` indica cualquier tipo de bloqueo (`> 2`) -> **FIN (Error: Tarjeta Bloqueada).**

*   **Paso 3: Verificación de Lista Negra (CRL).**
    *   El terminal consulta su **CRL local** con el UID.
    *   Si el UID **ESTÁ** en la lista:
        *   **ACCIÓN: "Envenenar" Tarjeta.** Se detiene el pago. En la memoria del terminal, se cambia `card_status` a `99`, se recalcula el `header_mac`, y se escribe el bloque del Header actualizado en la tarjeta.
        *   Se registra el evento de "envenenamiento" en el log local.
        *   **FIN (Error: Tarjeta Revocada).**

*   **Paso 4: Validación Completa del Header.**
    *   Se verifica que el resto de los datos del Header (leídos en el Paso 2) sean correctos: `issuer_id`, `system_version`, etc.
        *   Si algo no es compatible -> **FIN (Error: Incompatible).**

#### **Fase 2: Verificación de Consistencia y Auto-Reparación**

*   **Paso 5: Lectura de las Wallets.**
    *   Se autentica en el **Sector de la Wallet Principal** y se leen sus 3 bloques.
    *   Se autentica en el **Sector de la Wallet de Respaldo** y se leen sus 3 bloques.

*   **Paso 6: Verificación de Integridad y Sincronización.**
    *   Se desencriptan ambas wallets y se verifican sus respectivos `wallet_mac`.
        *   Si ambos MACs fallan -> **FIN (Error: Datos Irrecuperables).**
    *   Si un MAC falla o si los `tx_counter` son diferentes, se identifica la wallet válida (la que tiene MAC correcto y/o `tx_counter` más alto) y **se usa para sobrescribir y reparar la otra**.
    *   *Resultado de este paso: La tarjeta está garantizadamente en un estado consistente.*

#### **Fase 3: Ejecución de la Lógica de Negocio y Transacción**

*   **Paso 7: Validación de la Operación.**
    *   Se lee el `balance` de la wallet consistente.
        *   Si `balance < monto_transaccion` -> **FIN (Error: Fondos Insuficientes).**
    *   Se verifican los **Límites de Velocidad (Velocity Checks)** configurados en el terminal.
        *   Si se excede algún límite -> **FIN (Error: Límite Offline Excedido).**

*   **Paso 8: Preparación de Nuevos Datos.**
    *   En la memoria del terminal, se calculan `nuevo_balance` y `nuevo_tx_counter` (`= actual + 1`).
    *   Se calcula el `nuevo_wallet_mac` sobre los datos de la nueva wallet.

*   **Paso 9: Escritura Atómica (Commit en 2 Fases).**
    *   Se encripta el nuevo payload de la wallet.
    *   **Primero, se escribe** en la **zona de la Wallet de Respaldo**.
    *   **Segundo, se escribe** lo mismo en la **zona de la Wallet Principal**.

#### **Fase 4: Finalización y Reporte**

*   **Paso 10: Confirmación y Log.**
    *   (Recomendado) Se lee de nuevo el `tx_counter` de la Wallet Principal para confirmar la escritura.
    *   Se guarda un registro completo de la transacción exitosa en el **log local** del terminal para su posterior sincronización.

*   **Paso 11: Notificación al Usuario.**
    *   Se emite la señal de éxito (luz verde, bip, etc.).
    *   Si el `card_status` original era `2` (Notificación), se emite una señal diferente (ej. doble bip) para avisar al usuario.

*   **Paso 12: Sincronización con el Servidor (Cuando se esté online).**
    *   El terminal se conecta al servidor.
    *   Sube su lote de transacciones y cualquier evento de "envenenamiento" de su log local.
    *   El servidor procesa esta información. Al recibir la notificación de que una tarjeta fue "envenenada", la puede **purgar de la CRL activa**, manteniendo la lista eficiente.

Plano completo, unificado y optimizado.