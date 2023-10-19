#include <soc/gpio_sig_map.h>
#include <driver/gpio.h>
#include <driver/dedic_gpio.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/timers.h>

#define ADDR_GPIO_PIN_L GPIO_NUM_2 // GPIO2
#define ADDR_GPIO_PIN_H GPIO_NUM_3 // GPIO3
#define RW_GPIO_PIN     GPIO_NUM_4 // GPIO4

const int dedic_gpios[] = {4, 5};
dedic_gpio_bundle_handle_t dedicHandle = NULL;

SemaphoreHandle_t timerSemaphore;

void setupPlusBus() {
// configure GPIO
    gpio_config_t io_conf = {
        .mode = GPIO_MODE_OUTPUT,
    };
    for (int i = 0; i < sizeof(dedic_gpios) / sizeof(dedic_gpios[0]); i++) {
        io_conf.pin_bit_mask = 1ULL << dedic_gpios[i];
        gpio_config(&io_conf);
    }
    // Create dedic_, output only
    dedic_gpio_bundle_config_t dedic_config = {
        .gpio_array = dedic_gpios,
        .array_size = sizeof(dedic_gpios) / sizeof(dedic_gpios[0]),
        .flags = {
            .out_en = 1,
        },
    };
    ESP_ERROR_CHECK(dedic_gpio_new_bundle(&dedic_config, &dedicHandle));
}

// Timer callback function
void timerCallback(TimerHandle_t xTimer) {
    xSemaphoreGive(timerSemaphore);
}

// Task function
void clkEventTask(void *pvParameters) {
    (void)pvParameters; // We don't use the task parameter

    setupPlusBus();
    uint32_t dedicMask;
    while (1) {
        if (xSemaphoreTake(timerSemaphore, portMAX_DELAY) == pdTRUE) {
            //GPIO.out_w1ts = (uint32_t)((1u<<2) | (1u<<4));
            dedic_gpio_get_out_mask(dedicHandle, &dedicMask);
            dedic_gpio_bundle_write(dedicHandle, dedicMask, 0xff);
        }
    }
}

void setup() {
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
