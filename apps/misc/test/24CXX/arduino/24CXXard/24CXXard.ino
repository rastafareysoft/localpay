#include <Wire.h>

const int __SDA_PIN = A4; // D6
const int __SCL_PIN = A5; // 

void setup() {
  Serial.begin(115200);
  Wire.begin();
}

void loop() {
  verifyComand();
}

void verifyComand() {
  if (Serial.available() > 0) {
    String data = Serial.readStringUntil('\n');
    // ... tu código para parsear ...
    String comand = getComand(data);

    if (comand == "write") {
      uint16_t adress = getAdress(data);
      uint32_t value = getValue(data);
      Serial.println("\nWriting...");

      byte result = write_4_bytes(adress, value);
      if (result == 0) {
        Serial.println("SUCCESS: Write operation completed.");
      } else {
        Serial.print("ERROR: Write failed with error code: ");
        Serial.println(result);
      }

    } else if (comand == "read") {
      uint16_t adress = getAdress(data);
      uint32_t valueRead; // Variable para guardar el resultado
      Serial.println("\nReading...");

      byte result = read_4_bytes(adress, valueRead);
      if (result == 0) {
        Serial.print("SUCCESS: Read value ");
        Serial.println(valueRead);
      } else {
        Serial.print("ERROR: Read failed with error code: ");
        Serial.println(result);
      }
    }
  }
}

/**
 * Escribe un número de 4 bytes (32 bits) en la EEPROM.
 * @param address La dirección de inicio donde se empezará a escribir.
 * @param value El número de 32 bits a escribir.
 * @return 0 si la escritura fue exitosa, o un código de error de la librería Wire si falló.
 */
byte write_4_bytes(uint16_t address, uint32_t value) {
  Wire.beginTransmission(0x50);      // Dirección I2C del chip de memoria
  Wire.write((int)(address >> 8));   // Byte alto de la dirección
  Wire.write((int)(address & 0xFF)); // Byte bajo de la dirección
  
  // Descomponer el número de 32 bits en 4 bytes (Big-Endian)
  Wire.write((value >> 24) & 0xFF);
  Wire.write((value >> 16) & 0xFF);
  Wire.write((value >> 8)  & 0xFF);
  Wire.write(value & 0xFF);
  
  // Wire.endTransmission() devuelve un código de error.
  byte errorCode = Wire.endTransmission();
  
  if (errorCode == 0) {
    delay(5); // Pausa necesaria solo si la escritura fue exitosa
  }
  
  return errorCode;
}

/**
 * Lee un número de 4 bytes (32 bits) desde la EEPROM.
 * @param address La dirección de inicio desde donde se empezará a leer.
 * @param valueRead Un puntero a una variable uint32_t donde se almacenará el valor leído.
 * @return 0 si la lectura fue exitosa, o un código de error si falló.
 */
byte read_4_bytes(uint16_t address, uint32_t &valueRead) {
  // Fase 1: Apuntar a la dirección de memoria
  Wire.beginTransmission(0x50);
  Wire.write((int)(address >> 8));
  Wire.write((int)(address & 0xFF));
  
  byte errorCode = Wire.endTransmission();
  if (errorCode != 0) {
    // No se pudo ni siquiera comunicar con el dispositivo para establecer la dirección
    return errorCode; // Devolvemos el código de error de la fase de direccionamiento
  }

  // Fase 2: Pedir los 4 bytes de datos
  byte bytesRead = Wire.requestFrom(0x50, 4);
  if (bytesRead != 4) {
    // El dispositivo respondió, pero no envió la cantidad de bytes que esperábamos.
    // Creamos un código de error personalizado para esta situación, ya que requestFrom() no devuelve uno.
    // Un valor > 4 es seguro ya que los de Wire son 1, 2, 3, 4.
    return 5; // Error: Número de bytes incorrecto recibido
  }

  // Fase 3: Reconstruir el número (si todo fue bien)
  valueRead = ((uint32_t)Wire.read() << 24) |
              ((uint32_t)Wire.read() << 16) |
              ((uint32_t)Wire.read() << 8)  |
              Wire.read();
              
  return 0; // Éxito
}

// 0: Éxito
// 1: Datos demasiado largos
// 2: NACK en la dirección (dispositivo no responde)
// 3: NACK en los datos
// 4: Otro error
// 5: (Nuestro error personalizado) No se recibió el número de bytes esperado.

String getComand(String aValue) {
  int ind = aValue.indexOf(":");
  String r;
  if (ind > 0) {
    r = aValue.substring(0, ind);
    r.trim();
  }
 return r;
}

uint16_t getAdress(String aValue) {
  int ind = aValue.indexOf(":");
  if (ind > 0) {
    String r = aValue.substring(ind+1, aValue.length());
    r.trim();
    return r.toInt();
  }
  return 0;
}

uint32_t getValue(String aValue) {
  int ind = aValue.indexOf(":");
  if (ind > 0) {
    ind = aValue.indexOf(":", ind+1);
    String r = aValue.substring(ind+1, aValue.length());
    r.trim();
    return r.toInt();
  }
  return 0;
}