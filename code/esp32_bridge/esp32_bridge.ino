#include <soc/soc.h>
#include <soc/gpio_reg.h>
#include <driver/gpio.h>
#include <driver/dedic_gpio.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/timers.h>

////////////////GPIO map//////////////////
// Data bus
// D[0]: GPIO9
// D[1]: GPIO8
// D[2]: GPIO7
// D[3]: GPIO6
// D[4]: GPIO5
// D[5]: GPIO4
// D[6]: GPIO18
// D[7]: GPIO19
// Address bus
// A[0]: GPIO1
// A[1]: GPIO0
// CLK:  GPIO2
// R_NW: GPIO3

#define ADDR0    1
#define ADDR1    0
#define CLK_PIN  2
#define R_NW_PIN 3

const int data_gpios[] = {9, 8, 7, 6, 5, 4, 18, 19};
dedic_gpio_bundle_handle_t dataDedicHandle = NULL;

SemaphoreHandle_t txQueueHealthTimerSemaphore;
SemaphoreHandle_t timerSemaphore;
QueueHandle_t txQueue, rxQueue;
TimerHandle_t txQueueHealthTimer;
TimerHandle_t timer;

#define TX_Q_LEN 40000
#define RX_Q_LEN 100

typedef struct msg {
  uint8_t data;
  uint8_t r_nw;
  uint8_t node_addr;
} msg_t;

enum BRIDGE_BYTE {
  BR_START = 'A',
  BR_STOP = 'B',
  BR_RD = 'R',
  BR_WR = 'W'
};

enum BRIDGE_STATE {
  BR_S_IDLE, BR_S_RW, BR_S_ADDR, BR_S_DATA, BR_S_STOP
};

void setupPlusBus() {
  // configure GPIO
  // Create dataDedicHandle, input/output
  gpio_config_t io_conf = {
    .mode = GPIO_MODE_INPUT_OUTPUT_OD,
  };
  for (int i = 0; i < sizeof(data_gpios) / sizeof(data_gpios[0]); i++) {
    io_conf.pin_bit_mask = 1ULL << data_gpios[i];
    gpio_config(&io_conf);
  }
  dedic_gpio_bundle_config_t data_dedic_config = {
    .gpio_array = data_gpios,
    .array_size = sizeof(data_gpios) / sizeof(data_gpios[0]),
    .flags = {
      .in_en = 1,
      .out_en = 1,
    },
  };
  ESP_ERROR_CHECK(dedic_gpio_new_bundle(&data_dedic_config, &dataDedicHandle));

  REG_WRITE(GPIO_ENABLE_REG, (1 << ADDR0) | (1 << ADDR1) | (1 << CLK_PIN) | (1 << R_NW_PIN));
}

// Timer callback function
void timerCallback(TimerHandle_t xTimer) {
  xSemaphoreGive(timerSemaphore);
}

void txQueueHealthTimerCallback(TimerHandle_t xTimer) {
  xSemaphoreGive(txQueueHealthTimerSemaphore);
}

// Task function
void clkEventTask(void *pvParameters) {
  (void)pvParameters; // We don't use the task parameter

  uint32_t edgeType;
  setupPlusBus();

  msg_t txMsg, rxMsg;

  uint32_t out;
  while (1) {
    if (xSemaphoreTake(timerSemaphore, portMAX_DELAY) == pdTRUE) {
      edgeType = !((REG_READ(GPIO_IN_REG) >> CLK_PIN) & 1);

      if (edgeType) {
        // Rising Edge
        REG_WRITE(GPIO_OUT_W1TS_REG, 1 << CLK_PIN);
        if (txMsg.r_nw) {
          // Receive data from node
          dedic_gpio_bundle_write(dataDedicHandle, 0xff, 0xff); // setup bus for receiving
        }
        else {
          // Send data to node
          dedic_gpio_bundle_write(dataDedicHandle, 0xff, txMsg.data);
        }
      }
      else if (!edgeType) {
        // Falling Edge
        REG_WRITE(GPIO_OUT_W1TC_REG, 1 << CLK_PIN);

        xTimerStop(timer, 0);
        if (txMsg.r_nw) {
          // Receive data from node
          rxMsg.data = dedic_gpio_bundle_read_in(dataDedicHandle);
          rxMsg.node_addr = txMsg.node_addr;
          xQueueSend(rxQueue, &rxMsg, portMAX_DELAY);
        }

        xQueueReceive(txQueue, &txMsg, portMAX_DELAY);
        xTimerReset(timer, 0);
        // Setup r_nw, node_addr and clk
        out = 0 | (txMsg.r_nw << R_NW_PIN) | ((txMsg.node_addr & 0x1) << ADDR0) | ((txMsg.node_addr >> 1) & 1);
        REG_WRITE(GPIO_OUT_W1TS_REG, out);
        REG_WRITE(GPIO_OUT_W1TC_REG, ~out);
      }
    }
  }
}

void sendMsg(msg_t *msg) {
  Serial.print("Node: ");
  Serial.print(msg->node_addr);
  Serial.print(",\tData: ");
  Serial.println(msg->data, HEX);
}

// Sends number of free spaces

void txQueueHealthCheckTask(void *pvParameters)  {
  (void)pvParameters;
  
  uint32_t txMsgsWaiting;
  while (1) {
    if (xSemaphoreTake(txQueueHealthTimerSemaphore, portMAX_DELAY) == pdTRUE) {
      txMsgsWaiting = uxQueueMessagesWaiting(txQueue);
      Serial.print("txMsgsWaiting: ");
      Serial.println(txMsgsWaiting);
    }
  }
}

void bridgeTask(void *pvParameters) {
  (void)pvParameters; // We don't use the task parameter

  uint8_t c;
  msg_t rxMsg;
  msg_t txMsg;
  enum BRIDGE_STATE state = BR_S_IDLE;
  while (1) {
    if (Serial.available()) {
      c = Serial.read();
      switch (state) {
        case BR_S_IDLE:
          if (c == BR_START) {
            memset(&txMsg, 0, sizeof(msg_t));
            state = BR_S_RW;
          }
          break;
        case BR_S_RW:
          if (c == BR_RD) {
            txMsg.r_nw = 1;
            state = BR_S_ADDR;
          }
          else if (c == BR_WR) {
            txMsg.r_nw = 0;
            state = BR_S_ADDR;
          }
          else
            state = BR_S_IDLE;
          break;
        case BR_S_ADDR:
          if (c > '3' || c < '0') {
            state = BR_S_IDLE;
          }
          else {
            txMsg.node_addr = c - '0';
            state = BR_S_DATA;
          }
          break;
        case BR_S_DATA:
          txMsg.data = c;
          state = BR_S_STOP;
          break;
        case BR_S_STOP:
          if (c == BR_STOP) {
            xQueueSend(txQueue, &txMsg, portMAX_DELAY);
          }
          state = BR_S_IDLE;
          break;
        default:
          state = BR_S_IDLE;
      }
    }

    if (xQueueReceive(rxQueue, &rxMsg, 0) == pdTRUE)
      sendMsg(&rxMsg);
  }
}

void setup() {
  // Create a timer semaphore
  timerSemaphore = xSemaphoreCreateBinary();
  txQueueHealthTimerSemaphore = xSemaphoreCreateBinary();

  txQueue = xQueueCreate(TX_Q_LEN, sizeof(msg_t));
  rxQueue = xQueueCreate(RX_Q_LEN, sizeof(msg_t));

  // Create a FreeRTOS task
  xTaskCreate(
    bridgeTask,        // Function that implements the task
    "bridgeTask",      // Name for the task (not required)
    10000,            // Stack size (words, not bytes)
    NULL,             // Task parameter (not used)
    1,                // Priority (0 is idle priority)
    NULL              // Task handle (not used)
  );

  // Create a FreeRTOS task
  xTaskCreate(
    clkEventTask,        // Function that implements the task
    "clkEventTask",      // Name for the task (not required)
    10000,            // Stack size (words, not bytes)
    NULL,             // Task parameter (not used)
    1,                // Priority (1 is the highest priority)
    NULL              // Task handle (not used)
  );

  // Creates the task for sending data back to orchestrator

  // Create a FreeRTOS task
  xTaskCreate(
    txQueueHealthCheckTask,
    "txQueueHealthCheckTask",
    1000,
    NULL,
    1,
    NULL
  );

  // Create a timer to trigger the semaphore every second
  timer = xTimerCreate(
            "Timer",                    // Timer name (not required)
            1,         // Timer period in ticks
            pdTRUE,                      // Auto-reload timer
            0,                          // Timer ID (not required)
            timerCallback               // Timer callback function
          );

  // Create a timer to trigger the semaphore every second
  txQueueHealthTimer = xTimerCreate(
               "Timer",                    // Timer name (not required)
               100,         // Timer period in ticks
               pdTRUE,                      // Auto-reload timer
               0,                          // Timer ID (not required)
               txQueueHealthTimerCallback               // Timer callback function
             );

  // Start the timer
  xTimerStart(timer, 0);
  xTimerStart(txQueueHealthTimer, 0);


  Serial.begin(115200);
}

void loop() {
  // Your code here (if any)
}

void app_main() {
  // Empty app_main() function required by ESP-IDF
}
