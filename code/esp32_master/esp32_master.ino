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

SemaphoreHandle_t timerSemaphore;

// Protocol control variables
uint32_t data;
uint32_t r_nw;
uint32_t node_addr;

void setupPlusBus() {
    // configure GPIO
    // Create dataDedicHandle, input/output
    gpio_config_t io_conf = {
        .mode = GPIO_MODE_INPUT_OUTPUT,
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

    REG_WRITE(GPIO_ENABLE_REG, (1<<ADDR0) | (1<<ADDR1) | (1<<CLK_PIN) | (1<<R_NW_PIN));
}

// Timer callback function
void timerCallback(TimerHandle_t xTimer) {
    xSemaphoreGive(timerSemaphore);
}

// Task function
void clkEventTask(void *pvParameters) {
    (void)pvParameters; // We don't use the task parameter

    uint32_t edgeType;
    setupPlusBus();
    while (1) {
        if (xSemaphoreTake(timerSemaphore, portMAX_DELAY) == pdTRUE) {
            edgeType = !((REG_READ(GPIO_IN_REG)>>CLK_PIN)&1);
            if (edgeType) { // Rising Edge
                REG_WRITE(GPIO_OUT_W1TS_REG, 1<<CLK_PIN);
            }
            else { // Falling Edge
                REG_WRITE(GPIO_OUT_W1TC_REG, 1<<CLK_PIN);
                //dedic_gpio_bundle_write(dataDedicHandle, 0xff, data);
            }
        }
    }
}

void setup() {
    Serial.begin(112500);
    // Create a timer semaphore
    timerSemaphore = xSemaphoreCreateBinary();

    // Create a FreeRTOS task
    xTaskCreate(
            clkEventTask,        // Function that implements the task
            "clkEventTask",      // Name for the task (not required)
            10000,            // Stack size (words, not bytes)
            NULL,             // Task parameter (not used)
            1,                // Priority (1 is the highest priority)
            NULL              // Task handle (not used)
            );

    // Create a timer to trigger the semaphore every second
    TimerHandle_t timer = xTimerCreate(
            "Timer",                    // Timer name (not required)
            pdMS_TO_TICKS(1000),         // Timer period in milliseconds
            pdTRUE,                      // Auto-reload timer
            0,                          // Timer ID (not required)
            timerCallback               // Timer callback function
            );

    // Start the timer
    xTimerStart(timer, 0);
}

void loop() {
    // Your code here (if any)
}

void app_main() {
    // Empty app_main() function required by ESP-IDF
}
