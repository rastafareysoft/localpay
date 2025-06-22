Flujo de Trabajo Detallado y Cuantificado, incluidos si su impacto en el tiempo es despreciable a nivel de CPU.

---
### **Flujo de Trabajo Detallado y Cuantificado (Versión Completa y Realista)**

| Paso | Operación | Detalle | Tiempo (ms) | Acumulado (ms) | Notas |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | Autenticación Sector 1 | Para acceder al `Header`. | 4 | **4** | Autenticación #1 |
| **2** | Lectura: `Header` | Lee 3 bloques. | 15 | **19** | |
| **3** | **Procesamiento: `Header`** | Desencripta, verifica MAC y lee `card_status`. | ε | **19** | |
| **4** | **Búsqueda en CRL** | Búsqueda lineal en 8K UIDs (peor caso). | 17 | **36** | **Paso de seguridad añadido** |
| **5** | Autenticación Sector 2 | Para acceder a la `Wallet Principal`. | 4 | **40** | Autenticación #2 |
| **6** | Lectura: `Wallet Principal` | Lee 3 bloques. | 15 | **55** | |
| **7** | **Procesamiento: `Wallet P.`** | Desencripta, verifica MAC, obtiene `tx_counter`. | ε | **55** | |
| **8** | Autenticación Sector 3 | Para acceder a la `Wallet Respaldo`. | 4 | **59** | Autenticación #3 |
| **9** | Lectura: `Wallet Respaldo` | Lee 3 bloques. | 15 | **74** | |
| **10**| **Procesamiento: `Wallets`** | Desencripta, verifica MAC, compara `tx_counters`. Inicia auto-reparación si es necesario. | ε | **74** | |
| **11**| **Procesamiento: Transacción** | Valida fondos, `Velocity Checks`, y calcula el nuevo `Wallet` en memoria (nuevo balance, `tx_counter`, MAC). | ε | **74** | |
| **12**| Escritura: `Wallet Respaldo` | Escribe 3 bloques en el Sector 3. | 30 | **104**| Commit Fase 1 |
| **13**| Escritura: `Wallet Principal` | Escribe 3 bloques en el Sector 2. | 30 | **134**| Commit Fase 2 |
| **14**| Confirmación Opcional | Leer 1 bloque de la `Wallet Principal` para verificar la escritura. | 5 | **139**| |
| **15**| Señal de Éxito | Bip/LED verde. | | **~139 ms** | Fin de la Interacción |

---

### **Conclusión del Análisis de Rendimiento**

El tiempo total estimado para el "camino feliz", incluyendo todos los pasos lógicos y la consulta a la lista negra en el peor de los casos, es de **~139 milisegundos**.

Este desglose ahora es completo, preciso y sirve como una excelente especificación para el desarrollo del firmware, ya que detalla cada una de las operaciones lógicas y de I/O que deben ocurrir en secuencia.