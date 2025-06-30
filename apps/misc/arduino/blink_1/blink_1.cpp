#include "blink_1.cpp.h"
//#include "blink_1.const.h"

//const byte ledPin = 13;

//const byte __LED = 13;

#define __LED  13

void test_init(){
  pinMode(__LED, OUTPUT);
};

void test_led(){
  digitalWrite(__LED, HIGH);
  delay(1000);             
  digitalWrite(__LED, LOW);
  delay(1000);
};