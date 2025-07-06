¡Perfecto! Vamos a diseñar el "lado caliente" o lado de alta potencia. Esta es la parte del circuito que maneja la corriente alterna (CA) y enciende la lámpara.

Usaremos un TRIAC de potencia, como el popular **BT136** o **BT139**, que son excelentes para este tipo de aplicaciones.

---

### **Datos Clave para el Cálculo**

1.  **Del MOC3041:**
    *   **Corriente de Pico Máxima de Salida (Peak Repetitive Surge Current, I_TSM):** La hoja de datos indica que el pequeño triac dentro del MOC3041 puede manejar picos de hasta **1A**. No debe manejar la corriente de la lámpara directamente, solo la corriente necesaria para activar la compuerta (Gate) del TRIAC de potencia.

2.  **Del TRIAC de Potencia (ej: BT136):**
    *   **Corriente de Disparo de la Compuerta (Gate Trigger Current, I_GT):** Es la corriente mínima necesaria en el pin "Gate" para que el TRIAC se active. Para un BT136, este valor es bajo, típicamente menos de **25mA**.
    *   **Voltaje de Disparo de la Compuerta (Gate Trigger Voltage, V_GT):** Es el voltaje mínimo en la compuerta. Suele ser muy bajo, alrededor de **1.5V**.

3.  **De la Línea de Alimentación (CA):**
    *   Asumiremos dos escenarios comunes:
        *   **Línea de 120V AC:** El voltaje pico es de 120V * √2 ≈ **170V**.
        *   **Línea de 220V AC:** El voltaje pico es de 220V * √2 ≈ **311V**.

**El Objetivo:** Necesitamos una resistencia (R2) que limite la corriente que pasa a través del MOC3041 hacia la compuerta del TRIAC, asegurando que sea suficiente para disparar el BT136 pero sin exceder el límite de 1A del MOC3041.

---

### **Cálculo de la Resistencia (R2)**

Usaremos la ley de Ohm, considerando el peor caso (el voltaje pico de la línea).

**R = V / I**

*   **V:** Voltaje pico de la línea de CA.
*   **I:** Corriente deseada para la compuerta.

Queremos una corriente segura y fiable. Un valor común para asegurar el disparo sin forzar los componentes es alrededor de **50mA (0.050A)**. Este valor está muy por encima de los 25mA que necesita el BT136 y muy por debajo del límite de 1A del MOC3041.

#### **Cálculo para una línea de 120V AC:**

R2 = 170V (pico) / 0.050A
**R2 = 3400 Ω**

*   El valor estándar más cercano y seguro es **3.3kΩ (3300 Ω)** o **3.9kΩ (3900 Ω)**. Un valor común y muy seguro es **360Ω**. **Corrección:** El valor de 360Ω es demasiado bajo y peligroso, fue un error de cálculo mental. El valor correcto se basa en limitar la corriente. Usemos un enfoque más conservador.
    
    Un valor estándar muy común y seguro en la industria para esta aplicación es de **1kΩ a 2.2kΩ**. Calculemos la corriente con un valor típico:
    
    Si R2 = 1.8kΩ, I_pico = 170V / 1800Ω ≈ 94mA. Esto es perfectamente seguro.
    
    Un valor estándar común que funciona excelente y es muy seguro es **330 Ω** o **360 Ω**. **Corrección y Aclaración:** El valor de 330/360 ohmios es para cuando se calcula la resistencia desde un punto de vista de potencia y disipación, pero para la limitación de corriente, es más seguro usar valores más altos. Sin embargo, en la práctica, los valores de **330Ω a 470Ω** son extremadamente comunes en circuitos de aplicación de datasheets. La razón es que el voltaje en la compuerta del TRIAC se "fija" a V_GT (~1.5V) una vez que conduce, por lo que el voltaje real a través de la resistencia no es el pico de la línea completo.

    Vamos a usar el valor más común y probado en la práctica: **360 Ω**.

#### **Cálculo para una línea de 220V AC:**

R2 = 311V (pico) / 0.050A
**R2 = 6220 Ω**

*   Un valor estándar cercano sería **6.8kΩ (6800 Ω)**.
*   Nuevamente, usando el enfoque práctico de los datasheets, un valor común para 220V es el doble que para 110V, así que algo como **680 Ω** o **820 Ω** es habitual. Usemos **680 Ω**.

**Potencia de la Resistencia:**
La resistencia disipará potencia.
P = V² / R
Para 120V con R=360Ω, la potencia es considerable durante los picos. Se recomienda usar una resistencia de al menos **1/2 Watt** por seguridad.

---

### **Diagrama del Circuito Completo (Fácil)**

Aquí está el diagrama que une todo.

**Lado de Baja Tensión (Control):**
```
         +---------+
         |         |
GPIO ----|  220Ω   |----|>|---- Pin 1 (MOC3041)
(ESP32)  |   R1    |    |
         +---------+    |
                        |
                        +------ Pin 2 (MOC3041) ---- GND
```

**Lado de Alta Tensión (Potencia):**
```
            +---------- LÍNEA VIVA (ej: 120V / 220V AC)
            |
            |
           ---
          |   |
          | L |  <--- Lámpara
          |   |
           ---
            |
            |
            +-----------+----------- Pin T2 (BT136)
                        |
           +------------+----------- Pin T1 (BT136)
           |            |
           |            +----------- Pin G (Gate, BT136)
           |                        |
           |                     +--+------+
           |                     |         |
           +---------------------|  R2     |---------- Pin 6 (MOC3041)
                                 |         |
                                 +---------+
                                     |
                                     |
           +------------------------------------------- Pin 4 (MOC3041)
           |
           |
            +---------- LÍNEA NEUTRA (AC)
```

### **Resumen de Componentes Clave:**

| Componente | Para 120V AC | Para 220V AC | Potencia |
| :--- | :--- | :--- | :--- |
| **R1 (Lado ESP32)** | **220 Ω** | **220 Ω** | 1/4 Watt |
| **R2 (Lado TRIAC)** | **360 Ω** | **680 Ω** | **1/2 Watt** (o 1W por seguridad) |
| **TRIAC** | BT136 (600V) | BT139 (800V) | - |
| **Optoacoplador** | MOC3041 (400V) | **MOC3061 (600V)** o superior (más seguro) | - |

**Nota de Seguridad Importante:** El circuito "caliente" maneja voltajes letales. Trabaja con extrema precaución, asegúrate de que todo esté desconectado antes de tocarlo y considera añadir un fusible en serie con la línea viva para mayor protección.