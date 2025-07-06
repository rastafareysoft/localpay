#include <Wire.h>

// --- Constantes de la Memoria ---
const uint8_t EEPROM_I2C_ADDR = 0x50;
const uint16_t EEPROM_SIZE_BYTES = 8192; // Para una 24FC64 (64 Kbit / 8)
const uint8_t PAGE_SIZE = 32; // Tamaño de página de escritura para 24FC64

/**
 * @brief Inicializa (limpia) la memoria EEPROM completa, escribiendo ceros en todas las direcciones.
 *        Muestra el progreso en el Monitor Serial.
 */
void initialize_eeprom() {
  Serial.println("Iniciando formateo completo de la EEPROM...");
  Serial.println("Esto puede tardar varios segundos...");

  // Recorremos la memoria en bloques del tamaño de la página
  for (uint16_t address = 0; address < EEPROM_SIZE_BYTES; address += PAGE_SIZE) {
    Wire.beginTransmission(EEPROM_I2C_ADDR);
    Wire.write((int)(address >> 8));   // Byte alto de la dirección
    Wire.write((int)(address & 0xFF)); // Byte bajo de la dirección

    // Escribimos una página completa de ceros
    for (uint8_t i = 0; i < PAGE_SIZE; i++) {
      Wire.write((byte)0);
    }
    
    Wire.endTransmission();
    delay(5); // Pausa crucial después de cada escritura de página

    // Imprimir el progreso cada cierto número de bloques para no saturar el serial
    if (address % 256 == 0) {
      int percent_complete = (int)(((float)address / EEPROM_SIZE_BYTES) * 100);
      Serial.print("Progreso: ");
      Serial.print(percent_complete);
      Serial.println("%");
    }
  }
  
  Serial.println("Progreso: 100%");
  Serial.println("¡Formateo de EEPROM completado!");
}


// --- Ejemplo de Uso ---

void setup() {
  Serial.begin(115200);
  Wire.begin();
  
  Serial.println("Presiona 'f' y envía para formatear la EEPROM.");
}

void loop() {
  if (Serial.available() > 0) {
    char command = Serial.read();
    if (command == 'f' || command == 'F') {
      initialize_eeprom();
    }
  }
}