#include "led.h"
#include "led.const.cpp"  

void led_init(){ 
  pinMode(__LED_PIN, OUTPUT);    
}

void led_on(){ 
  digitalWrite(__LED_PIN, HIGH);  
  delay(__LED_TIME);
}

void led_off() { 
  digitalWrite(__LED_PIN, LOW);
  delay(__LED_TIME);
}

void led_blink(){ 
  led_on();
  led_off();
}