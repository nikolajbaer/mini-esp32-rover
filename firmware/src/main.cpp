// Mini ESP32 rover: Wi-Fi access point + phone joystick -> DRV8833 -> two tracks.
//
// Join the rover's Wi-Fi network, open http://192.168.4.1/ and drive.
// The page streams "left,right" speeds (-255..255) over a WebSocket; if they
// stop arriving the motors are cut.

#include <Arduino.h>
#include <WiFi.h>
#include <esp_http_server.h>

#include "config.h"
#include "index_html.h"

struct Motor {
  uint8_t in1, in2;
  bool invert;
  int current; // last speed written, -255..255
};

static Motor leftMotor = {PIN_LEFT_IN1, PIN_LEFT_IN2, LEFT_INVERT, 0};
static Motor rightMotor = {PIN_RIGHT_IN1, PIN_RIGHT_IN2, RIGHT_INVERT, 0};

// Written by the HTTP server task, read by loop().
static volatile int16_t targetLeft = 0, targetRight = 0;
static volatile uint32_t lastCommandMs = 0;

static void motorWrite(const Motor &m, int speed) {
  if (m.invert) speed = -speed;
  int mag = min(abs(speed), 255);
  if (mag == 0) { // coast
    ledcWrite(m.in1, 0);
    ledcWrite(m.in2, 0);
    return;
  }
  // Stretch 1..255 onto MIN_DUTY..MAX_DUTY so small stick movements still move.
  int duty = map(mag, 1, 255, MIN_DUTY, MAX_DUTY);
  // Slow-decay drive: hold one input high and PWM the other low. Gives better
  // low-speed torque than PWMing against coast.
  if (speed > 0) {
    ledcWrite(m.in1, 255);
    ledcWrite(m.in2, 255 - duty);
  } else {
    ledcWrite(m.in2, 255);
    ledcWrite(m.in1, 255 - duty);
  }
}

// Move a motor toward its target by at most RAMP_PER_TICK, so the battery
// never sees a stall-current step.
static void motorRamp(Motor &m, int target) {
  int next = m.current + constrain(target - m.current, -RAMP_PER_TICK, RAMP_PER_TICK);
  if (next != m.current) {
    m.current = next;
    motorWrite(m, next);
  }
}

static esp_err_t handleIndex(httpd_req_t *req) {
  httpd_resp_set_type(req, "text/html");
  return httpd_resp_send(req, INDEX_HTML, HTTPD_RESP_USE_STRLEN);
}

static esp_err_t handleWs(httpd_req_t *req) {
  if (req->method == HTTP_GET) return ESP_OK; // WebSocket handshake

  uint8_t buf[24];
  httpd_ws_frame_t frame = {};
  frame.payload = buf;
  esp_err_t err = httpd_ws_recv_frame(req, &frame, sizeof(buf) - 1);
  if (err != ESP_OK) return err;
  if (frame.type != HTTPD_WS_TYPE_TEXT) return ESP_OK;

  buf[frame.len] = 0;
  int l, r;
  if (sscanf((const char *)buf, "%d,%d", &l, &r) == 2) {
    l = constrain(l, -255, 255);
    r = constrain(r, -255, 255);
    targetLeft = SWAP_SIDES ? r : l;
    targetRight = SWAP_SIDES ? l : r;
    lastCommandMs = millis();
  }
  return ESP_OK;
}

static void startServer() {
  httpd_config_t config = HTTPD_DEFAULT_CONFIG();
  config.lru_purge_enable = true; // a reconnecting phone must not run us out of sockets
  httpd_handle_t server = nullptr;
  if (httpd_start(&server, &config) != ESP_OK) {
    Serial.println("HTTP server failed to start");
    return;
  }
  httpd_uri_t index = {};
  index.uri = "/";
  index.method = HTTP_GET;
  index.handler = handleIndex;
  httpd_register_uri_handler(server, &index);

  httpd_uri_t ws = {};
  ws.uri = "/ws";
  ws.method = HTTP_GET;
  ws.handler = handleWs;
  ws.is_websocket = true;
  httpd_register_uri_handler(server, &ws);
}

void setup() {
  Serial.begin(115200);

  for (uint8_t pin : {leftMotor.in1, leftMotor.in2, rightMotor.in1, rightMotor.in2}) {
    ledcAttach(pin, PWM_FREQ_HZ, 8);
    ledcWrite(pin, 0);
  }

#if defined(WIFI_ENABLE) && defined(WIFI_ANT_CONFIG)
  // XIAO ESP32-C6: power the RF switch and select the on-board ceramic antenna.
  pinMode(WIFI_ENABLE, OUTPUT);
  digitalWrite(WIFI_ENABLE, LOW);
  pinMode(WIFI_ANT_CONFIG, OUTPUT);
  digitalWrite(WIFI_ANT_CONFIG, LOW);
#endif

  WiFi.mode(WIFI_AP);
  WiFi.softAP(ROVER_SSID, ROVER_PASS);
  WiFi.setTxPower(WIFI_TX_POWER);
  Serial.printf("AP \"%s\" up, open http://%s/\n", ROVER_SSID, WiFi.softAPIP().toString().c_str());

  startServer();
}

void loop() {
  bool stale = millis() - lastCommandMs > FAILSAFE_MS;
  motorRamp(leftMotor, stale ? 0 : targetLeft);
  motorRamp(rightMotor, stale ? 0 : targetRight);
  delay(5);
}
