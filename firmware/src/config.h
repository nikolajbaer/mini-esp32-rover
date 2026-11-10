// Everything you are likely to want to change lives here.
#pragma once
#include <Arduino.h>

// ---- Wi-Fi access point the rover creates --------------------------------
#define ROVER_SSID "mini-rover"
#define ROVER_PASS "roverrover" // 8+ characters, or "" for an open network

// ---- DRV8833 wiring (XIAO pin -> driver input) ---------------------------
#define PIN_LEFT_IN1 D0  // -> IN1
#define PIN_LEFT_IN2 D1  // -> IN2
#define PIN_RIGHT_IN1 D2 // -> IN3
#define PIN_RIGHT_IN2 D3 // -> IN4

// Flip these instead of resoldering if a track runs backwards. In the printed
// chassis the two motors face opposite ways, so exactly one of them normally
// needs inverting.
#define LEFT_INVERT false
#define RIGHT_INVERT true
// Set true if steering is mirrored (pushing the stick left turns right).
#define SWAP_SIDES false

// ---- Drive feel ----------------------------------------------------------
#define PWM_FREQ_HZ 20000 // above hearing range
#define MIN_DUTY 70       // 0-255: smallest duty that actually turns the motor
#define MAX_DUTY 255      // 0-255: lower this to cap top speed
#define RAMP_PER_TICK 12  // max change per 5 ms tick; lower = gentler on the battery
#define FAILSAFE_MS 400   // stop if no command arrives for this long

// Radio transmit power. Kept low on purpose: a 300 mAh cell sags when the
// motors start, and a full-power Wi-Fi burst on top of that can brown out
// the ESP32. Raise it if you need more range.
#define WIFI_TX_POWER WIFI_POWER_8_5dBm
