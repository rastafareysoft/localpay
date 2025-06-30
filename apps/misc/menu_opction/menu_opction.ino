//Pins IN
  const int __PIN_IN_GREEN  = 8;
  const int __PIN_IN_YELLOW = 7;
  const int __PIN_IN_RED    = 6;
//Pins OUT
#define __ARDUINO_UNO
#ifdef __ARDUINO_UNO
  const int __PIN_OUT_GREEN  = 12;
  const int __PIN_OUT_YELLOW = 11;
  const int __PIN_OUT_RED = 10;
#else     
  const int __PIN_OUT_GREEN  = 14; //D5 
  const int __PIN_OUT_YELLOW = 4;  //D2
  const int __PIN_OUT_RED    = 5;  //D1
#endif
//States
  int state_green_previous  = LOW;  
  int state_yellow_previous = LOW;  
  int state_red_previous    = LOW;  

//Jumper
  int __JUMPER_DELAY = 100;  

//Count temporal
  //int count_green  = 0;
  //int count_yellow = 0;
  //int count_red    = 0;

void setup() {  
  Serial.begin(9600); //En linux maquina virtual solofuncioan con 9600,
  //Pins IN
  pinMode(__PIN_IN_GREEN,  INPUT);
  pinMode(__PIN_IN_YELLOW, INPUT);
  pinMode(__PIN_IN_RED, INPUT);

  //Pins OUT
  pinMode(__PIN_OUT_GREEN, OUTPUT);
  pinMode(__PIN_OUT_YELLOW, OUTPUT);
  pinMode(__PIN_OUT_RED, OUTPUT);
}

void loop() {
  getAction();
  getComand();
  //delay(5);  
}

void getComand() {
  //Green
  int state_green_current = digitalRead(__PIN_IN_GREEN);
  if (state_green_current != state_green_previous && state_green_previous == HIGH) {      
    //count_green++;
    Serial.write("green\n");
    //Serial.print("Green "); Serial.println(count_green);
    //digitalWrite(__PIN_OUT_GREEN, HIGH);
    delay(__JUMPER_DELAY); //Prevent Jumper
    //digitalWrite(__PIN_OUT_GREEN, LOW);
  }
  state_green_previous = state_green_current;
  

  //Yellow
  int state_yellow_current = digitalRead(__PIN_IN_YELLOW);
  if (state_yellow_current != state_yellow_previous && state_yellow_previous == HIGH) {
    //count_yellow++;
    Serial.write("yellow\n");
    //Serial.print("Yellow "); Serial.println(count_yellow); 
    //digitalWrite(__PIN_OUT_YELLOW, HIGH);
    delay(__JUMPER_DELAY); //Prevent Jumper
    //digitalWrite(__PIN_OUT_YELLOW, LOW);
  }
  state_yellow_previous = state_yellow_current;

  //Red
  int state_red_current = digitalRead(__PIN_IN_RED);
  if (state_red_current != state_red_previous && state_red_previous == HIGH) {
    //count_red++;
    Serial.write("red\n");
    //Serial.print("Red "); Serial.println(count_red); 
    //digitalWrite(__PIN_OUT_RED, HIGH);
    delay(__JUMPER_DELAY); //Prevent Jumper
    //digitalWrite(__PIN_OUT_RED, LOW);
  }
  state_red_previous = state_red_current;
}

void getAction() {
  int sl =  Serial.available();
  if (sl > 0){
    String comand = Serial.readStringUntil('\n');
    comand.trim();

    String green_on = "gr_on";
    String green_off = "gr_off";
    String yellow_on = "yl_on";
    String yellow_off = "yl_off";
    String red_on = "rd_on";
    String red_off = "rd_off";
    String ping_test = "ping";
    String pong_test = "pong\n";

    //green
    if (comand == green_on) {
      digitalWrite(__PIN_OUT_GREEN, HIGH); 
      Serial.print(green_on + "_" + sl + "_ok\n");
    } else if (comand == green_off) {
      digitalWrite(__PIN_OUT_GREEN, LOW); 
      Serial.print(green_off + "_" + sl + "_ok\n");
      //yellow
    } else if (comand == yellow_on) {
      digitalWrite(__PIN_OUT_YELLOW, HIGH); 
      Serial.print(yellow_on + "_" + sl + "_ok\n");
    } else if (comand == yellow_off) {
      digitalWrite(__PIN_OUT_YELLOW, LOW); 
      Serial.print(yellow_off + "_" + sl + "_ok\n");
      //red
    } else if (comand == red_on) {
      digitalWrite(__PIN_OUT_RED, HIGH); 
      Serial.print(red_on + "_" + sl + "_ok\n");
    } else if (comand == red_off) {
      digitalWrite(__PIN_OUT_RED, LOW); 
      Serial.print(red_off + "_" + sl + "_ok\n");
    } else if (comand == ping_test) {
      //digitalWrite(__PIN_OUT_RED, LOW); 
      Serial.print(pong_test);
    } 

  }
}