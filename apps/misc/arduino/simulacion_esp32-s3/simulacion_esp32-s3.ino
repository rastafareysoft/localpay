/*
 * SIMULADOR DE TIEMPOS DE TRANSACCIÓN PARA MONEDERO OFFLINE - v1.0 (Teórico)
 * ---------------------------------------------------------------------
 * Este código representa el flujo de trabajo óptimo sin parches de software
 * (sin re-autenticaciones en bucle, sin delays). Se asume un hardware estable.
 * Es la base para medir nuestro rendimiento objetivo.
 */

#include <SPI.h>
#include <MFRC522v2.h>
#include <MFRC522DriverSPI.h>
#include <MFRC522DriverPinSimple.h>
#include <MFRC522Constants.h>

//#define RST_PIN   15  
#define PIN_MOSI  13
#define PIN_MISO  12
#define PIN_SCK   14
#define PIN_CS    11 

MFRC522DriverPinSimple ss_pin(PIN_CS); 

MFRC522DriverSPI driver{ss_pin}; 
MFRC522 mfrc522{driver}; 
                  
void simulateTransaction();
void printDuration(const char* stepName, unsigned long startTime);

void setup() {
  Serial.begin(115200);
  while (!Serial);
  //SPI.begin();
  SPI.begin(PIN_SCK, PIN_MISO, PIN_MOSI, PIN_CS);
  mfrc522.PCD_Init();
  Serial.println("\n");
  Serial.println("===================================================");
  Serial.println("Simulador de Tiempos de Transacción (Modelo Óptimo)");
  Serial.println("Acerque una tarjeta MIFARE Classic 1K formateada...");
  Serial.println("===================================================");
}

void loop() {
  if ( ! mfrc522.PICC_IsNewCardPresent() || ! mfrc522.PICC_ReadCardSerial() ) {
    //Serial.println("No hay tarjeta");
    delay(100);
    return;
  }
  simulateTransaction();
  Serial.println("\nPasados 1/2 segundos, acerque una nueva tarjeta...");
  delay(500); 
}

void simulateTransaction() {
  Serial.println("--- INICIANDO SIMULACIÓN DE TRANSACCIÓN"); 
  
  unsigned long startTime = micros();
  MFRC522::MIFARE_Key key;
  for (byte i = 0; i < 6; i++) 
    key.keyByte[i] = 0xFF;
  byte buffer[18];
  byte size = sizeof(buffer);
  MFRC522::StatusCode status;

  // --- FASE 1 ---
  byte headerBlock = 4;
  status = mfrc522.PCD_Authenticate(MFRC522Constants::PICC_Command::PICC_CMD_MF_AUTH_KEY_A, headerBlock, &key, &(mfrc522.uid));
  if (status != MFRC522Constants::STATUS_OK) { 
    Serial.println("Fallo Autenticación Sector 1"); 
    mfrc522.PICC_HaltA(); 
    mfrc522.PCD_StopCrypto1(); 
    return; 
  }
  for (int i=0; i < 3; i++) {
    status = mfrc522.MIFARE_Read(headerBlock + i, buffer, &size);
    if (status != MFRC522Constants::STATUS_OK) { 
      Serial.print("Fallo lectura bloque ");
      Serial.println(headerBlock + i); 
      mfrc522.PICC_HaltA(); 
      mfrc522.PCD_StopCrypto1(); return; 
    }
  }
  printDuration("Paso  1-3 (Lectura Header)", startTime);

  delay(17); 
  printDuration("Paso    4 (Búsqueda CRL)", startTime);

  // --- FASE 2 ---
  byte wallet1Block = 8;
  status = mfrc522.PCD_Authenticate(MFRC522Constants::PICC_Command::PICC_CMD_MF_AUTH_KEY_A, wallet1Block, &key, &(mfrc522.uid));
  if (status != MFRC522Constants::STATUS_OK) { 
    Serial.println("Fallo Autenticación Sector 2"); 
    mfrc522.PICC_HaltA(); 
    mfrc522.PCD_StopCrypto1(); 
    return; 
  }
  for (int i=0; i < 3; i++) {
    status = mfrc522.MIFARE_Read(wallet1Block + i, buffer, &size);
    if (status != MFRC522Constants::STATUS_OK) { 
      Serial.print("Fallo lectura bloque "); 
      Serial.println(wallet1Block + i); 
      mfrc522.PICC_HaltA(); 
      mfrc522.PCD_StopCrypto1(); 
      return;
    }
  }
  printDuration("Paso  5-7 (Lectura Wallet P.)", startTime);

  byte wallet2Block = 12;
  status = mfrc522.PCD_Authenticate(MFRC522Constants::PICC_Command::PICC_CMD_MF_AUTH_KEY_A, wallet2Block, &key, &(mfrc522.uid));
  if (status != MFRC522Constants::STATUS_OK) { 
    Serial.println("Fallo Autenticación Sector 3"); 
    mfrc522.PICC_HaltA(); 
    mfrc522.PCD_StopCrypto1(); 
    return; 
  }
  for (int i=0; i < 3; i++) {
    status = mfrc522.MIFARE_Read(wallet2Block + i, buffer, &size);
    if (status != MFRC522Constants::STATUS_OK) { 
      Serial.print("Fallo lectura bloque "); 
      Serial.println(wallet2Block + i); 
      mfrc522.PICC_HaltA(); 
      mfrc522.PCD_StopCrypto1(); 
      return; 
    }
  }
  printDuration("Paso 8-10 (Lectura Wallet R.)", startTime);
  
  // --- FASE 3 ---
  delayMicroseconds(100); 
  printDuration("Paso   11 (Cálculo en CPU)", startTime);

  byte dummyData[16] = {0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99};
  
  // PASO 12: Escritura en Wallet Respaldo (Sin fixes)
  for (int i=0; i < 3; i++) {
    status = mfrc522.MIFARE_Write(wallet2Block + i, dummyData, 16);
    if (status != MFRC522Constants::STATUS_OK) { 
      Serial.print("Fallo escritura bloque "); 
      Serial.println(wallet2Block + i); 
      mfrc522.PICC_HaltA(); 
      mfrc522.PCD_StopCrypto1(); 
      return; 
    }
  }
  printDuration("Paso   12 (Escritura Wallet R.)", startTime);

  // PASO 13: Escritura en Wallet Principal (Sin fixes)
  /*for (int i=0; i < 3; i++) {
    status = mfrc522.MIFARE_Write(wallet1Block + i, dummyData, 16);
    if (status != MFRC522Constants::STATUS_OK) { 
      Serial.print("Fallo escritura bloque "); 
      Serial.println(wallet1Block + i); 
      mfrc522.PICC_HaltA(); 
      mfrc522.PCD_StopCrypto1(); 
      return; 
    }
  }*/

  //fix Begin
  // --- LA NUEVA SOLUCIÓN: "GRAN RESET" ---
  Serial.println("Paso 12.1 (Reiniciando el MFRC522) para asegurar estado limpio.");
  mfrc522.PCD_Init(); // Esto reinicia el chip completamente.
  printDuration("Paso 12.2 (Reset MFRC522)", startTime);


  // PASO 13: Escritura en Wallet Principal (3 bloques)
  // Como hemos reiniciado el lector, debemos volver a seleccionar la tarjeta.
  if ( ! mfrc522.PICC_IsNewCardPresent() || ! mfrc522.PICC_ReadCardSerial() ) {
      Serial.println("Fallo al re-seleccionar la tarjeta después del reset.");
      return;
  }
  printDuration("Paso 12.3 (Re-selección Tarjeta)", startTime);

  // Ahora procedemos con la escritura en la Wallet Principal
  // Autenticamos de nuevo porque el reset borró la sesión anterior
  status = mfrc522.PCD_Authenticate(MFRC522Constants::PICC_Command::PICC_CMD_MF_AUTH_KEY_A, wallet1Block, &key, &(mfrc522.uid));
  if (status != MFRC522Constants::STATUS_OK) { 
    Serial.println("Fallo Re-Autenticación Sector 2 Post-Reset"); 
    return; }

  for (int i=0; i < 3; i++) {
    status = mfrc522.MIFARE_Write(wallet1Block + i, dummyData, 16);
    if (status != MFRC522Constants::STATUS_OK) { 
      Serial.print("Fallo escritura bloque "); 
      Serial.println(wallet1Block + i); 
      return;
    }
    
    // La re-autenticación aquí puede ser redundante después del Init, pero no hace daño
    status = mfrc522.PCD_Authenticate(MFRC522Constants::PICC_Command::PICC_CMD_MF_AUTH_KEY_A, wallet1Block, &key, &(mfrc522.uid));
    if (status != MFRC522Constants::STATUS_OK) { 
      Serial.println("Fallo Re-Autenticación en bucle Sector 2"); 
      return; 
    }
  }
  //End Fix

  printDuration("Paso   13 (Escritura Wallet P.)", startTime);

  // --- FASE 4 ---
  status = mfrc522.MIFARE_Read(wallet1Block, buffer, &size);
  if (status != MFRC522Constants::STATUS_OK) { 
    Serial.print("Fallo lectura bloque "); 
    Serial.println(wallet1Block); 
    mfrc522.PICC_HaltA(); 
    mfrc522.PCD_StopCrypto1(); 
    return; 
  }
  printDuration("Paso   14 (Lectura Confirmación)", startTime);

  unsigned long totalDuration = micros() - startTime;
    Serial.print("---          TIEMPO TOTAL DE TRANSACCIÓN: ");
  Serial.print(totalDuration / 1000.0);
  Serial.println(" ms          ---");

  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
}

void printDuration(const char* stepName, unsigned long startTime) {
  Serial.print(stepName);
  Serial.print(" completado en: ");
  Serial.print((micros() - startTime) / 1000.0, 3);
  Serial.println(" ms");
}