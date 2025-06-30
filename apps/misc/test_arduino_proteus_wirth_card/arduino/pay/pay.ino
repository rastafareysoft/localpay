//RFID
  #include <SPI.h>
  #include <MFRC522.h>
  #define RST_PIN 9   // Configurable, see typical pin layout above
  #define SS_PIN  10 // Configurable, see typical pin layout above
  MFRC522 rfid(SS_PIN, RST_PIN); // Create MFRC522 instance  
//LCD
  #include <Wire.h> 
  #include <LiquidCrystal_I2C.h>  
  LiquidCrystal_I2C lcd(0x38, 40, 4);  //0x3F 0x27 0x38 0x20
  //0x38 para 16x2 and 40 4 proteus 
//Defines
  #define DEBUG
  #define ARDUINO_UNO
//PINS  
  #ifdef ARDUINO_UNO
    //Pins IN
    const int __PIN_IN_GREEN  = 4;
    const int __PIN_IN_YELLOW = 3;
    const int __PIN_IN_RED    = 2;
    //Pins OUT
    const int __PIN_OUT_WASH = 6;
    const int __PIN_OUT_FILL = 5;  
  #else //ESP****    
    //Pins IN
    const int __PIN_IN_GREEN  = 7;
    const int __PIN_IN_YELLOW = 6;
    const int __PIN_IN_RED    = 5;
    //Pins OUT
    const int __PIN_OUT_WASH  = 14; //D5 
    const int __PIN_OUT_FILL = 4;   //D2
  #endif
//-----------------------------------------------------------------
#ifndef DEBUG //Real time
  //Jumper
    int __DELAY_OPTIONS = 250;  
    int __DELAY_FINALIZE = 5000;
  //Tiempos de procesos (en milisegundos)
    const unsigned long TIME_WASH = 9000;
    const unsigned long TIME_FILL = 9000;
#else //Simulation    
  //Jumper
    int __DELAY_OPTIONS = 100;  
    int __DELAY_FINALIZE = 4000;
  //Tiempos de procesos (en milisegundos)
    const unsigned long TIME_WASH =  3000;
    const unsigned long TIME_FILL = 3000;
    //#define SIMULATOR //For proteus or any simulator
#endif    

enum TStateMachine {
  stNone,
  stSelection,
  stWaitingForPayment,
  stWaitingForWashing,
  stWashing,
  stWaitingForFilling,
  stFill,
  stFinalized, 
  stError
};

enum TOptions {
  opNone,
  opGreenButton,
  opYellowButton,
  opRedButton
};

//Control systems
  TStateMachine currentState = stSelection;
  TStateMachine lastState = stNone;
  unsigned long processStartTime; //Block time
  bool processStop = false; //Porcess interrup for the users 
  TOptions selectedOption = opNone; 

void setup() {  
  //LCD
  lcd.init();
  lcd.backlight();
  //Serial
  Serial.begin(9600);
  while (!Serial);	// Do nothing if no serial port is opened (added for Arduinos based on ATMEGA32U4)   
  //Pins IN
  pinMode(__PIN_IN_GREEN,  INPUT);
  pinMode(__PIN_IN_YELLOW, INPUT);
  pinMode(__PIN_IN_RED, INPUT);
  //Pins OUT
  pinMode(__PIN_OUT_FILL, OUTPUT);
  pinMode(__PIN_OUT_WASH, OUTPUT);   
  // Asegurarnos que las salidas estén apagadas al iniciar
  digitalWrite(__PIN_OUT_FILL, LOW);
  digitalWrite(__PIN_OUT_WASH, LOW);  
  //RFID  
	SPI.begin();		 // Init SPI bus
	rfid.PCD_Init(); // Init MFRC522
	delay(10);			 // Optional delay. Some board do need more time after init to be ready, see Readme
}

void loop() {
  processState();
  //lcdTest();
  /*int result_rfid = verifyPayment();
  if (result_rfid != -1) {
    Serial.println(result_rfid);
    delay(500);
  }*/
}

void lcdTest() {
  //lcd.clear(); 
  //Serial.println("Hala mundo"); 
  //delay(2000);
}

int verifyPayment() {
  const int __NO_READ = -1;
  const int __OK = 0;
  const int __NO_MIFARE_CLASSIC = 1;
  const int __NO_VALID_CARD = 2;  
  #ifndef SIMULATOR //Real time
    if ( ! rfid.PICC_IsNewCardPresent() || ! rfid.PICC_ReadCardSerial() )
      return __NO_READ;
    //-------------------------------------------------------------------
    MFRC522::PICC_Type piccType = rfid.PICC_GetType(rfid.uid.sak);
    if (piccType != MFRC522::PICC_TYPE_MIFARE_1K && piccType != MFRC522::PICC_TYPE_MIFARE_4K)
      return __NO_MIFARE_CLASSIC; //tag is not of type MIFARE Classic
    //-------------------------------------------------------------------
    MFRC522::MIFARE_Key key;
    //using FFFFFFFFFFFFh which is the default at chip delivery from the factory
    for (byte i = 0; i < 6; i++)
      key.keyByte[i] = 0xFF;
    MFRC522::StatusCode status;
    byte headerBlock = 4;
    status = rfid.PCD_Authenticate(MFRC522::PICC_CMD_MF_AUTH_KEY_A, headerBlock, &key, &(rfid.uid));
    rfid.PICC_HaltA(); 
    rfid.PCD_StopCrypto1();
    if (status != MFRC522::STATUS_OK)
      return __NO_VALID_CARD;
    //Verify all info corresponding for parocess
    return __OK;    
  #else  
    if (Serial.available() > 0){
     String card = Serial.readStringUntil('\n'); card.trim(); card.toUpperCase();
     Serial.println(card);
     if (card == "AA")
       return __OK;
     else 
       return __NO_VALID_CARD;
    }
    return __NO_READ;    
  #endif
}

void processState(){
  switch (currentState) {    
    case stNone: stateNone(); break;
    case stSelection: stateSelection(); break;
    case stWaitingForPayment: stateWaitingForPayment(); break;
    case stWaitingForWashing: stateWaitingForWashing(); break;
    case stWashing: stateWashing(); break;
    case stWaitingForFilling: stateWaitingForFilling(); break;
    case stFill: stateFill(); break;
    case stFinalized: stateFinalize(); break;
    case stError: stateError(); break;
  }   
}

void stateNone(){ 
};

void stateSelection(){ 
  if (currentState != lastState) {
    #ifdef DEBUG
              //1234567890123456789012345678901234567890
      lcdWrite("Seleccione botellon", 
               "[VERDE] 15 lts 3$", 
               "[AMARILLO] 10 lts 2$", 
               "[ROJO] 5 lts 1$");
    #endif
    selectedOption = opNone;
    lastState = currentState; 
  } else {
    //Green Button
    if (digitalRead(__PIN_IN_GREEN) == HIGH) {
      selectedOption = opGreenButton;
      currentState = stWaitingForPayment;
      delay(__DELAY_OPTIONS); //Debe ser bloqueante para evitar doble pulsación (debounce)
    }
    //Yellow Button
    else if (digitalRead(__PIN_IN_YELLOW) == HIGH) {      
      selectedOption = opYellowButton;
      currentState = stWaitingForPayment;
      delay(__DELAY_OPTIONS); //Debe ser bloqueante para debounce
    }
    //Red Button
    else if (digitalRead(__PIN_IN_RED) == HIGH) {
      selectedOption = opRedButton;      
      currentState = stWaitingForPayment;
      delay(__DELAY_OPTIONS); //Debe ser bloqueante para debounce
    }
  } 
};

void stateWaitingForPayment() { 
  if (currentState != lastState) {    
    #ifdef DEBUG 
                //12345678901234567890
        lcdWrite("Presente su TARJETA", 
                 "en el LECTOR", 
                 strSelected(), 
                 "[ROJO] volver a MENU");
    #endif
    lastState = currentState;
  } else {
    if (digitalRead(__PIN_IN_RED) == HIGH) {      
      currentState = stSelection;
      delay(__DELAY_OPTIONS); //Debe ser bloqueante para debounce
    } else {  
      int statusPayment = verifyPayment(); 
      if (statusPayment != -1) {
        if (statusPayment == 0) 
          currentState = stWaitingForWashing;
        else if (statusPayment == 1) {
          #ifdef DEBUG
                    //12345678901234567890
            lcdWrite("Tipo Tarje. invalida", 
                     "Presente TARJETA", 
                     strSelected(), 
                     "[ROJO] volver a MENU");
            delay(500);
          #endif
        } 
        else if (statusPayment == 2) {
          #ifdef DEBUG
            lcdWrite("Tarjeta invalida", 
                     "Presente TARJETA", 
                     strSelected(), 
                     "[ROJO] volver a MENU");
            delay(500);
          #endif
        }  
      }
    }  
  } 
};

String strSelected() {
  String lcSelected = ""; 
  switch (selectedOption) {    
                                      //12345678901234567890      
    case opGreenButton:  lcSelected = "Monto 3$ x 20 lts"; break;
    case opYellowButton: lcSelected = "Monto 2$ x 15 lts"; break;
    case opRedButton:    lcSelected = "Monto 1$ x 10 lts"; break;
  }
  return lcSelected;
}

void stateWaitingForWashing() { 
  if (currentState != lastState) {
    #ifdef DEBUG
              //12345678901234567890
      lcdWrite("Coloque botellon", 
               "para el LAVADO", 
               "[VERDE] iniciar para",
               "el LAVADO");
    #endif
    lastState = currentState;
  } else {
    if (digitalRead(__PIN_IN_GREEN) == HIGH) {      
      currentState = stWashing;
      delay(__DELAY_OPTIONS); //Debe ser bloqueante para debounce
      digitalWrite(__PIN_OUT_WASH, HIGH);
    }
  }
};

void stateWashing() {
    // Esta sección se ejecuta solo una vez, al entrar al estado
    if (currentState != lastState) {
        digitalWrite(__PIN_OUT_WASH, HIGH); // Iniciar lavado
        processStartTime = millis(); //Guardar tiempo de inicio
        lastState = currentState;
        #ifdef DEBUG
                    //12345678901234567890
            lcdWrite("LAVANDO botellon", 
                     "Espere por favor ...", 
                     "[ROJO] Parada de", 
                     "EMERGENCIA");
        #endif
    } else if (!processStop) {
      if (digitalRead(__PIN_IN_RED) == HIGH) {    
          processStartTime = millis(); //Guardar tiempo de parada       
          processStop = true; //evita el avance del contador
          digitalWrite(__PIN_OUT_WASH, LOW); // Detener lavado INMEDIATAMENTE
          #ifdef DEBUG
                      //12345678901234567890
              lcdWrite("LAVADO detenido por", 
                       "el usuario", 
                       "VERDE] reanudar", 
                       "el LAVADO");
          #endif
          delay(__DELAY_OPTIONS);
          return; // Salir de la función para procesar el nuevo estado en el siguiente ciclo
      }
    }  

    if (!processStop) { 
      if (millis() - processStartTime >= TIME_WASH) {
          digitalWrite(__PIN_OUT_WASH, LOW); // Detener lavado
          currentState = stWaitingForFilling; // Pasar al siguiente estado
      }
    } if (digitalRead(__PIN_IN_GREEN) == HIGH) {
          processStop = false;
          digitalWrite(__PIN_OUT_WASH, HIGH);
          delay(__DELAY_OPTIONS);
    }  
}

void stateWaitingForFilling() {
   if (currentState != lastState) {
    #ifdef DEBUG
              //12345678901234567890
      lcdWrite("Coloque botellon",
               "para el LLENADO", 
               "[VERDE] para iniciar",
               "el LLENADO");
    #endif
    lastState = currentState;
  } else {
    if (digitalRead(__PIN_IN_GREEN) == HIGH) {      
      currentState = stFill;
      delay(__DELAY_OPTIONS); //Debe ser bloqueante para debounce
      digitalWrite(__PIN_OUT_FILL, LOW);
    }
  }  
};

void stateFill() {
    // Esta sección se ejecuta solo una vez, al entrar al estado
    if (currentState != lastState) {
        #ifdef DEBUG
                    //12345678901234567890
            lcdWrite("LLENANDO botellon", 
                     "Espere por favor ...", 
                     "[ROJO] Parada de",
                     "EMERGENCIA");
        #endif
        digitalWrite(__PIN_OUT_FILL, HIGH); // Iniciar llenado
        processStartTime = millis();        // Guardar tiempo de inicio
        lastState = currentState;
    } else if (!processStop) {
      if  (digitalRead(__PIN_IN_RED) == HIGH) {
        processStartTime = millis(); //Guardar tiempo de parada       
        processStop = true; //evita el avance del contador
        digitalWrite(__PIN_OUT_FILL, LOW); // Detener llenado INMEDIATAMENTE
        #ifdef DEBUG
                    //12345678901234567890
            lcdWrite("LLENADO detenido",
                     "por el usuario", 
                     "[VERDE] reanudar",
                     "el LLENANO");
        #endif
        delay(__DELAY_OPTIONS);
        return;
      }
    } 

    if (!processStop) { 
      if (millis() - processStartTime >= TIME_FILL) {
          digitalWrite(__PIN_OUT_FILL, LOW); // Detener llenado
          currentState = stFinalized;      // Pasar al siguiente estado
      }
    } if (digitalRead(__PIN_IN_GREEN) == HIGH) {
          processStop = false;
          digitalWrite(__PIN_OUT_FILL, HIGH);
          delay(__DELAY_OPTIONS);
    }
}

void stateFinalize() {
  if (currentState != lastState) {
    #ifdef DEBUG
              //12345678901234567890
      lcdWrite("!!! Gracias !!!", 
                "Por usar nuestros",
                "servicios", 
                "Vuelva pronto");
    #endif
    lastState = currentState;
    delay(__DELAY_FINALIZE);
    currentState = stSelection;
  } 
};


void stateError() {
  if (currentState != lastState) {
    #ifdef DEBUG
      // El mensaje ya se mostró al momento de la parada de emergencia.
      // Aquí podríamos esperar una acción del usuario para reiniciar.
      lcdWrite("PROCESO DETENIDO", "Presione el boton VERDE", "para volver al menu principal", "");
    #endif
    lastState = currentState;
  } else {
    // Esperar a que el usuario presione el botón verde para reiniciar
    if (digitalRead(__PIN_IN_GREEN) == HIGH) {
        currentState = stSelection;
        delay(__DELAY_OPTIONS);
    }
  } 
};

void lcdWrite(String l0, String l1, String l2, String l3) {
  Serial.println("\n");
  Serial.println(centerText(l0));
  Serial.println(centerText(l1));
  Serial.println(centerText(l2));
  Serial.println(centerText(l3));
  lcd.clear();
  lcd.setCursor(0, 0); lcd.print(centerText(l0));
  lcd.setCursor(0, 1); lcd.print(centerText(l1));
  lcd.setCursor(0, 2); lcd.print(centerText(l2));
  lcd.setCursor(0, 3); lcd.print(centerText(l3));
}

String centerText(String aText) {
  const int __MAX_LENGTH = 20;
  int r; int i;
  String rs = aText;
  rs.trim();
  r = __MAX_LENGTH/2 - rs.length()/2;
  for (int i = 0; i < r; i++)
    rs = " " + rs;
  for (int i = rs.length(); i < __MAX_LENGTH; i++)
    rs = rs + " ";
  return rs;
}