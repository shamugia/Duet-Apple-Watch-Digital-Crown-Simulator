#include <Arduino.h>
#include <SPI.h>
#include <boards.h>
#include <RBL_nRF8001.h>
//#include <service.h>
#include <RBL_services.h>

/*
    Rotary Encoder:
    CLK -> A -> 2 :: arduino pin
    DT -> B -> 4 :: arduino pin
    SW (Push button) -> 8 :: arduino pin / VCC Signal
    GND -> C -> GND
    + -> +5v
*/

const int Pin_CLK = 2;
const int Pin_DT = 4;

volatile int vPosition = 0;
volatile int lastCount = 0;

void setup()
{
  Serial.begin(9600);  //For debug only
  
  pinMode(Pin_CLK, INPUT);
  pinMode(Pin_DT, INPUT);
  
  // Turn on pullup resistor
  digitalWrite(Pin_CLK, HIGH);
  digitalWrite(Pin_DT, HIGH);
  
  //ble_set_pins(3, 2);  //Default pins set to 6 and 7 for REQN and RDYN
  ble_set_name("iWatch");
  ble_begin();
  
  //interrupt 0 is always connected to pin 2 on Arduino UNO
  attachInterrupt(0, handleEncoderChange, CHANGE);
  
  Serial.println("Start");
}

void loop()
{
  if(vPosition != lastCount)
  {
    lastCount = vPosition;
    
    sendDataToBLE(vPosition);
    
    Serial.print("Position: ");
    Serial.println(vPosition);
  }
  ble_do_events();
}

void handleEncoderChange()
{
  static unsigned long lastInterruptTime = 0;
  unsigned long interruptTime = millis();
  
  if (interruptTime - lastInterruptTime > 5)   //If interrupts come faster than 5ms, assume it's a bounce and ignore
  {
    if (!digitalRead(Pin_DT)) vPosition = vPosition + 1;
    else vPosition = vPosition - 1;
    if (vPosition > 1) vPosition = 1;
    if (vPosition < -1) vPosition = -1;
  }
  lastInterruptTime = interruptTime;
}

void sendDataToBLE(int pos)
{
  if (ble_connected())
  {
    char buff[10];
    dtostrf(vPosition, 8, 6, buff);
    int index = 0;
    while (buff[index]) {
      ble_write(buff[index++]);
    }
    Serial.println("Data Sent...");
  }
}
