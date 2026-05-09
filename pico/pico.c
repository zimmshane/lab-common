#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/spi.h"
#include "hardware/adc.h"

#define SPI_PORT spi0
#define PIN_MISO 16
#define PIN_CS_FPGA 17
#define PIN_CS_PICO 20
#define PIN_SCK  18
#define PIN_MOSI 19

#define DIP_PORT 11

#define MIN_POTENT 0
#define MAX_POTENT 4070
#define MAX_DELAY 1000 // ms
#define MIN_DELAY 100  // ms

#define LED_0_PIN 12
#define LED_1_PIN 13
#define LED_2_PIN 14
#define LED_3_PIN 15

#define SEQUENCE_NEW(arr) ((sequence){ .pattern = (arr), .length = sizeof(arr) / sizeof((arr)[0]), .current_frame = 0 })

typedef struct {
    const uint16_t *pattern;
    int length;
    int current_frame;
} sequence;

// bits 0-3: master pico, 4-7: pico slave, 8-11: FPGA slave
const uint16_t pattern_1[] = {
    0b000000000000,
    0b000000000001,
    0b000000000011,
    0b000000000111,
    0b000000001111,
    0b000000011111,
    0b000000111111,
    0b000001111111,
    0b000011111111,
    0b000111111111,
    0b001111111111,
    0b011111111111,
    0b111111111111,
};

const uint16_t pattern_2[] = {
    0b101010101010,
    0b010101010101,
};

// splits a 12-bit frame into three nibbles: out[0]=master, out[1]=pico slave, out[2]=fpga slave
void split_frame(uint16_t frame, uint8_t out[3]) {
    out[0] = (uint8_t)(frame & 0x00F);
    out[1] = (uint8_t)((frame >> 4) & 0x00F);
    out[2] = (uint8_t)((frame >> 8) & 0x00F);
}

void write_controller_LEDS(uint8_t nibble) {
    gpio_put(LED_0_PIN, (nibble & 0b0001));
    gpio_put(LED_1_PIN, (nibble & 0b0010) >> 1);
    gpio_put(LED_2_PIN, (nibble & 0b0100) >> 2);
    gpio_put(LED_3_PIN, (nibble & 0b1000) >> 3);
}

long map(long x, long in_min, long in_max, long out_min, long out_max) {
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

long get_frame_delay() {
    uint16_t raw = adc_read();
    return map(raw, MIN_POTENT, MAX_POTENT, MIN_DELAY, MAX_DELAY);
}

void init_spi(void) {
    spi_init(SPI_PORT, 1000 * 1000);
    gpio_set_function(PIN_SCK,  GPIO_FUNC_SPI);
    gpio_set_function(PIN_MOSI, GPIO_FUNC_SPI);
    gpio_init(PIN_CS_FPGA);
    gpio_init(PIN_CS_PICO);
    gpio_set_dir(PIN_CS_FPGA, GPIO_OUT);
    gpio_set_dir(PIN_CS_PICO, GPIO_OUT);
    gpio_put(PIN_CS_FPGA, 1);
    gpio_put(PIN_CS_PICO, 1);
}

void init_adc(){
    adc_init();
    adc_gpio_init(26);
    adc_select_input(0);
}

int main() {

    stdio_init_all();
    init_adc();
    init_spi();

    gpio_init(LED_0_PIN); gpio_set_dir(LED_0_PIN, GPIO_OUT);
    gpio_init(LED_1_PIN); gpio_set_dir(LED_1_PIN, GPIO_OUT);
    gpio_init(LED_2_PIN); gpio_set_dir(LED_2_PIN, GPIO_OUT);
    gpio_init(LED_3_PIN); gpio_set_dir(LED_3_PIN, GPIO_OUT);

    gpio_init(DIP_PORT);
    gpio_set_dir(DIP_PORT, GPIO_IN);
    gpio_pull_up(DIP_PORT);

    sequence sequence_list[2] = {SEQUENCE_NEW(pattern_1), SEQUENCE_NEW(pattern_2)};
    bool last_dip_value = gpio_get(DIP_PORT);
    uint8_t cur_sequence_index = 0;

    while (true) {
        bool cur_dip_value = gpio_get(DIP_PORT);
        if (cur_dip_value != last_dip_value) {
            cur_sequence_index = (cur_sequence_index + 1) % 2;
            sequence_list[cur_sequence_index].current_frame = 0;
            last_dip_value = cur_dip_value;
        }

        sequence *curr_sequence = &sequence_list[cur_sequence_index];
        uint16_t frame = curr_sequence->pattern[curr_sequence->current_frame];
        uint8_t frame_split[3];
        split_frame(frame, frame_split);

        write_controller_LEDS(frame_split[0]);

        gpio_put(PIN_CS_PICO, 0);
        spi_write_blocking(SPI_PORT, &frame_split[1], 1);
        gpio_put(PIN_CS_PICO, 1);

        gpio_put(PIN_CS_FPGA, 0);
        spi_write_blocking(SPI_PORT, &frame_split[2], 1);
        gpio_put(PIN_CS_FPGA, 1);

        curr_sequence->current_frame++;
        if (curr_sequence->current_frame >= curr_sequence->length) {
            curr_sequence->current_frame = 0;
        }

        sleep_ms(get_frame_delay());
    }
}
