Análisis detallado para justificar uso de **ESP8266/ESP32**

---

### **Tabla Comparativa: Arduino Uno vs. ESP8266 (Para Nuestro Proyecto)**

| Característica | Arduino Uno (ATmega328P) | ESP8266 (ESP-12E/F) | Veredicto para el Proyecto |
| :--- | :--- | :--- | :--- |
| **Procesador (Velocidad)** | 16 MHz, 8-bit | 80/160 MHz, 32-bit | **ESP8266 gana por goleada.** Necesitamos velocidad para las operaciones criptográficas (AES, HMAC, Hashes). |
| **RAM (Memoria Volátil)**| **2 KB** | ~50 KB (usable) | **ESP8266 gana. Crítico.** 2KB es extremadamente poco. Apenas cabe el programa y deja casi nada para buffers de datos, la pila de red o TLS. |
| **Flash (Almacenamiento de Programa)** | 32 KB | 4 MB (típico) | **ESP8266 gana. Factor decisivo.** 32KB es muy poco para nuestro código, librerías y la lógica OTA. Para OTA, necesitas espacio para el firmware actual Y el nuevo. |
| **EEPROM (Almacenamiento Persistente para CRL)** | **1 KB** | Emulada en Flash (se pueden reservar **64KB+**) | **ESP8266 gana. El Arduino Uno queda descalificado aquí.** Con 1KB, solo podemos almacenar `1024 / 8 = 128` UIDs. Nuestra necesidad es de ~8,000. |
| **Conectividad a Internet**| Ninguna (requiere un "shield" de WiFi adicional) | **Wi-Fi integrado** | **ESP8266 gana. Esencial.** Toda nuestra arquitectura de MQTT, OTA, y sincronización con el servidor depende de la conectividad a internet nativa. |
| **Lógica de Voltaje**| 5V | 3.3V | **ESP8266 gana.** La mayoría de los módulos modernos (lector MFRC522, EEPROMs externas, etc.) operan a 3.3V. Usar un ESP8266 simplifica el cableado al no necesitar conversores de nivel lógico. |

---

### **Análisis y Recomendación Final**

Aunque el Arduino Uno es una placa fantástica para aprender y para proyectos más simples, para el sistema, se queda corto en todos los aspectos críticos:

1.  **Memoria para la Lista Negra:** El punto más importante. La EEPROM de 1 KB del Uno es **8 veces más pequeña** de lo que necesitamos para nuestro caso base de 8,000 UIDs, y completamente insuficiente para un Filtro de Bloom robusto. El ESP8266, al usar su gran memoria Flash, puede simular una EEPROM del tamaño que necesitemos (64 KB es trivial).

2.  **Conectividad:** Nuestra arquitectura SaaS con MQTT y OTA es el corazón de la gestión del sistema. El ESP8266 fue **diseñado para esto**. Añadirle conectividad a un Arduino Uno es costoso, complejo y consume sus ya limitados recursos.

3.  **Potencia de Cómputo:** Los cálculos para AES, HMAC-SHA256, y los hashes para el Filtro de Bloom se ejecutarán órdenes de magnitud más rápido en el procesador de 32-bit a 80/160 MHz del ESP8266, asegurando que nuestras transacciones se mantengan por debajo del umbral de los ~140 ms.

**En resumen:**

*   Usa el **Arduino Uno** si quieres hacer una prueba de concepto muy básica y aislada de solo leer/escribir en la tarjeta, sin conectividad y sin una CRL real.
*   Usa el **ESP8266** para construir el prototipo real y completo que valida **toda** nuestra arquitectura, incluyendo la seguridad, la conectividad y las actualizaciones remotas. Es la plataforma que te permitirá llevar este proyecto del diseño a la realidad.

**Recomendación, el ESP8266.** Simplificará el desarrollo, te dará el rendimiento que necesitas y es la única de las dos opciones que realmente puede ejecutar el sistema que hemos diseñado.