#include "Arduino.h"

//#define __ARDUINO_UNO

#ifdef __ARDUINO_UNO
  const byte  __LED_PIN = 13;
#else
  const byte  __LED_PIN = 2;
#endif

const int   __LED_TIME = 1000;