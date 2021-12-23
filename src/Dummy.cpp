#include <Arduino.h>
void setup() {
	pinMode(22, OUTPUT);
}

void loop(){
	delay(200);
	digitalWrite(22, HIGH);
	delay(200);
	digitalWrite(22, LOW);
}
