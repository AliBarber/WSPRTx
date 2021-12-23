#include <Adafruit_SSD1306.h>
#include <SPI.h>
#include <AD9834.h>
#include <NMEAGPS.h>
#include <TimeLib.h>
#include <wsprlite/WSPRLite.h>

#include "Maidenhead.h"

#define CENTRE_FREQ 14097100
#define PA_RELAY_PIN 21
#define BUTTON_PIN 6

using namespace wsprlite;

SymbolStream encoder;
ChannelSymbols symbols;
ChannelSymbols::iterator _tx_symbol_iterator;

volatile bool check_gps_flag, pps_flag, will_transmit_flag, is_transmitting_flag, valid_clock, advance_symbol_flag;

long last_display_update = 0;

NMEAGPS gps;
gps_fix fix;
Adafruit_SSD1306 disp;

char locator_as_str[10];
AD9834 *dds;
IntervalTimer rtcUpdateTimer, advanceSymbolTimer;
long transmission_base_freq = CENTRE_FREQ;
int tx_count;

bool _mock_pps = false;

// On the centre freq
const uint16_t SYMBOL_FREQ_LUT_CENTRE[4][2] = {
  {3079,9866},
  {3079,9869},
  {3079,9876},
  {3079,9880}
};

// 40M
const uint16_t SYMBOL_FREQ_LUT_CENTRE_40M[4][2] = {
  {1537,15828},
{1537,15831},
{1537,15838},
{1537,15842}
};

inline void updateRTC(){
  check_gps_flag = true;
}

inline void advanceSymbol(){
  advance_symbol_flag = true;
}

void pps_handler(){
  pps_flag = true;
}


void setup() {
  pinMode(PA_RELAY_PIN, OUTPUT);
  digitalWriteFast(PA_RELAY_PIN, HIGH);
  
  dds =  new AD9834(10);
  disp = Adafruit_SSD1306(128, 32, &Wire1, -1);
  disp.begin(SSD1306_SWITCHCAPVCC);
  disp.clearDisplay();
  disp.display();

  disp.setTextSize(2);
  disp.setTextColor(WHITE);
  disp.setCursor(0,0);
  disp.println("OH2XAB");
  disp.display();
  Serial.begin(9600);
  Serial1.begin(9600);

  rtcUpdateTimer.priority(255);
//  rtcUpdateTimer.begin(pps_handler, 1000000);
  rtcUpdateTimer.begin(updateRTC, 5000000);

  advanceSymbolTimer.priority(128);
  check_gps_flag = true;
  locator_as_str[0] = '\0';
//  locator_as_str[0] = 'I';
//  locator_as_str[1] = 'O';
//  locator_as_str[2] = '9';
//  locator_as_str[3] = '4';
//  locator_as_str[4] = '\0';
  attachInterrupt(2,pps_handler,FALLING);

  dds->update_freq(14000000);  
//  setTime(22, 3, 00, 21, 12, 2021);
  valid_clock = false;
}

const uint16_t* wspr_freq_reg_for_symbol(unsigned short symbol){
  return SYMBOL_FREQ_LUT_CENTRE_40M[symbol];
}

void loop() { 
  if(is_transmitting_flag && advance_symbol_flag){
    advance_symbol_flag = false;
    if(++_tx_symbol_iterator != symbols.end()){
        const uint16_t *MSB = wspr_freq_reg_for_symbol(*_tx_symbol_iterator);
        dds->update_freq_reg(*MSB, *(MSB+1));
    }
    else{
      is_transmitting_flag = false;
      digitalWriteFast(PA_RELAY_PIN, HIGH);
      dds->update_freq(140000000);
      advanceSymbolTimer.end();
    }
  }
  
  if(gps.available(Serial1)){
    fix = gps.read();
  }

  if(pps_flag){
    pps_flag = false;
    if(will_transmit_flag){
      will_transmit_flag = false;
      is_transmitting_flag = true;
      // Go!
      digitalWriteFast(PA_RELAY_PIN,LOW);
      const uint16_t *MSB = wspr_freq_reg_for_symbol(*_tx_symbol_iterator);
      dds->update_freq_reg(*MSB, *(MSB+1));
      advanceSymbolTimer.begin(advanceSymbol, 682670);
    }
    time_t time_now = now();
    if(valid_clock && minute(time_now) % 2 == 0 && second(time_now) == 0){
      if(locator_as_str[0] != '\0'){
        encoder << CallSign("OH2XAB") << Locator(locator_as_str) << PowerLevel(30);
        symbols = encoder.encode();
        _tx_symbol_iterator = symbols.begin();
        const uint16_t *MSB = wspr_freq_reg_for_symbol(*_tx_symbol_iterator);
        dds->update_freq_reg(*MSB, *(MSB+1));
        will_transmit_flag = true;
      }
    }
  }

  if(check_gps_flag && !will_transmit_flag && !is_transmitting_flag){
    check_gps_flag = false;
    if(fix.valid.time){
      setTime(fix.dateTime.hours, fix.dateTime.minutes, fix.dateTime.seconds, fix.dateTime.day, fix.dateTime.month, fix.dateTime.year);
      valid_clock = true;
    }
    if(fix.valid.location){
      MaidenheadLocator loc(LatLon(fix.latitude(), fix.longitude()));
      int precision = loc.to_char(locator_as_str);
      locator_as_str[precision] = '\0';

      // We have to clamp it down to 4 chars
      if(precision > 4){
        for(int i = 4; i < precision; i++){
          locator_as_str[i] = '\0';
        }
      }
    }
  }

  if(millis() - last_display_update > 250){
    // This takes 15ms
    last_display_update = millis();
    disp.clearDisplay();
    disp.setCursor(0,0);
    
    time_t time_now = now();
    disp.printf("%02d:%02d:%02d\n",hour(time_now),minute(time_now),second(time_now));
    if(locator_as_str[0] != '\0' && !(will_transmit_flag || is_transmitting_flag)){
      disp.println(locator_as_str);
    }
    else if(will_transmit_flag){
      disp.println(transmission_base_freq);
    }
    else if(is_transmitting_flag){
      disp.printf("TX: %d", transmission_base_freq); 
    }
    else{
      disp.println("Unknown");
    }
    disp.display();
  }
}