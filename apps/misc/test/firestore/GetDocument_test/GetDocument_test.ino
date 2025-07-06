
#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>

/* 1. Define the WiFi credentials */
#define WIFI_SSID "RBuscando..."
#define WIFI_PASSWORD "ross.1228"

/* 2. Define the API Key */
#define API_KEY "AIzaSyALSvi8aS1F5IY9ZUrlP66Gana9cOYMF-M"

/* 3. Define the project ID */
#define FIREBASE_PROJECT_ID "test-24-03-2025"

/* 4. Define the user Email and password that alreadey registerd or added in your project */
#define USER_EMAIL "local@local.local"
#define USER_PASSWORD "123456"

// Define Firebase Data object
FirebaseData fbdo;

FirebaseAuth auth;
FirebaseConfig config;

bool taskCompleted = false;

unsigned long dataMillis = 0;

int __MODE_IN_BUTTON = 16;
int __MODE_OUT_LED = 15;

void setup()
{

    pinMode(__MODE_IN_BUTTON, INPUT);
    pinMode(__MODE_OUT_LED, OUTPUT);

    Serial.begin(115200);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    Serial.print("\nConnecting to Wi-Fi");
    unsigned long ms = millis();
    while (WiFi.status() != WL_CONNECTED)
    {
        Serial.print(".");
        delay(300);
    }
    Serial.println();
    Serial.print("Connected with IP: ");
    Serial.println(WiFi.localIP());
    Serial.println();
    Serial.printf("Firebase Client v%s\n\n", FIREBASE_CLIENT_VERSION);
    config.api_key = API_KEY;
    auth.user.email = USER_EMAIL;
    auth.user.password = USER_PASSWORD;
    config.token_status_callback = tokenStatusCallback;
    Firebase.reconnectNetwork(true);
    fbdo.setBSSLBufferSize(4096, 1024);
    fbdo.setResponseSize(2048);
    Firebase.begin(&config, &auth);
}

void loop() {
  int stateButton = digitalRead(__MODE_IN_BUTTON);
  if (stateButton == HIGH) { 
    if (Firebase.ready() && (millis() - dataMillis > 500 || dataMillis == 0))
    {
        dataMillis = millis();

        String documentPath = "info/countries";
        String mask = "";
        //String mask = "Singapore";

        Serial.print("Get a document... ");

        if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentPath.c_str(), mask.c_str()))
            Serial.printf("ok\n%s\n\n", fbdo.payload().c_str());
        else
            Serial.println(fbdo.errorReason());
    }
  }  
}
