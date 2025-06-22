#include <SPI.h>
#include <MFRC522.h>

#define __ARDUINO_UNO

#ifdef __ARDUINO_UNO
  const String __MICRO  = "<Arduino uno>"; 
	#define RST_PIN         9          // Configurable, see typical pin layout above
	#define SS_PIN          10         // Configurable, see typical pin layout above
#else  							
  const String __MICRO  = "<ESP8266>"; 
	#define RST_PIN         16         // Configurable, see typical pin layout above
	#define SS_PIN          15         // Configurable, see typical pin layout above
#endif

unsigned long time_1 = 0;
unsigned long time_2 = 0;
unsigned long time_3 = 0;

MFRC522 mfrc522(SS_PIN, RST_PIN);  // Create MFRC522 instance

void setup() {
	Serial.begin(9600);		// Initialize serial communications with the PC
  Serial.print("Working With ");
	Serial.println(__MICRO); 
	while (!Serial);		  // Do nothing if no serial port is opened (added for Arduinos based on ATMEGA32U4)  
	SPI.begin();			    // Init SPI bus
	mfrc522.PCD_Init();		// Init MFRC522
  delay(4);				// Optional delay. Some board do need more time after init to be ready, see Readme
  Serial.println("...");
	mfrc522.PCD_DumpVersionToSerial();	// Show details of PCD - MFRC522 Card Reader details
	Serial.println("Scan PICC to see UID, SAK, type, and data blocks...");
}

void loop() {
	// Look for new cards
	if ( ! mfrc522.PICC_IsNewCardPresent()) {
		return;
	}

	time_1 = millis();
	// Select one of the cards
	if ( ! mfrc522.PICC_ReadCardSerial()) {
		return;
	}
	time_1 = millis() - time_1;
	Serial.print("11111111111111111111111111 ");
	Serial.println(time_1);

	time_2 = millis();
	// Dump debug info about the card; PICC_HaltA() is automatically called
	mfrc522.PICC_DumpToSerial(&(mfrc522.uid));
	//mfrc522.PICC_DumpDetailsToSerial(&(mfrc522.uid));
	time_2 = millis() - time_2;
	Serial.print("22222222222222222222222222 ");
	Serial.println(time_2);
}