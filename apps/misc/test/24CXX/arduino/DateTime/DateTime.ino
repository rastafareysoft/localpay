#include <TimeLib.h> // Incluir la librería de tiempo

void setup() {
  Serial.begin(115200);

  Serial.println("--- Conversión de Fecha a Timestamp Unix ---");

  // --- 1. CONVERTIR DE FECHA HUMANA A TIMESTAMP ---

  // Definimos los componentes de una fecha y hora
  int anio = 2024;
  int mes = 5;
  int dia = 29;
  int hora = 10;
  int minuto = 30;
  int segundo = 54;

  // Creamos un objeto 'tmElements_t' para almacenar estos componentes
  tmElements_t tm;
  tm.Year = anio - 1970; // Años desde 1970
  tm.Month = mes;
  tm.Day = dia;
  tm.Hour = hora;
  tm.Minute = minuto;
  tm.Second = segundo;

  // La función mágica: makeTime() convierte la estructura a un timestamp Unix
  uint32_t mi_timestamp = makeTime(tm);

  Serial.print("Fecha: ");
  Serial.print(anio); Serial.print("/"); Serial.print(mes); Serial.print("/"); Serial.print(dia); Serial.print(" "); 
  Serial.print(hora); Serial.print(":"); Serial.print(minuto); Serial.print(":"); Serial.println(segundo);
  
  Serial.print("Timestamp Unix resultante (uint32_t): ");
  Serial.println(mi_timestamp);
  Serial.println("-------------------------------------------");


  // --- 2. CONVERTIR DE TIMESTAMP DE VUELTA A FECHA HUMANA ---

  Serial.println("--- Conversión de Timestamp de vuelta a Fecha ---");
  
  uint32_t timestamp_leido_de_memoria = mi_timestamp; // Simulamos que leímos este valor
  
  // Usamos la función breakTime() para descomponer el timestamp
  breakTime(timestamp_leido_de_memoria, tm); // Rellena la estructura 'tm'

  Serial.print("Timestamp a convertir: ");
  Serial.println(timestamp_leido_de_memoria);

  Serial.print("Fecha reconstruida: ");
  Serial.print(tm.Day);
  Serial.print("/");
  Serial.print(tm.Month);
  Serial.print("/");
  Serial.print(tm.Year + 1970); // Recordar sumar 1970 para obtener el año real
  Serial.print(" ");
  Serial.print(tm.Hour);
  Serial.print(":");
  Serial.print(tm.Minute);
  Serial.print(":");
  Serial.println(tm.Second);
}

void loop() {
  // no-op
}