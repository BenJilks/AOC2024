#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#define MAX_MACHINE_COUNT 1024
#define BUTTON_A_COST 3
#define BUTTON_B_COST 1

typedef struct {
    int64_t x;
    int64_t y;
} Vec2;

typedef struct {
    Vec2 button_a;
    Vec2 button_b;
    Vec2 prize;
} Machine;

typedef enum {
    PARSE_STATE_BUTTON_A,
    PARSE_STATE_BUTTON_B,
    PARSE_STATE_PRIZE,
    PARSE_STATE_EMPTY_LINE,
} ParseState;

static Machine s_machines[MAX_MACHINE_COUNT];
static size_t s_machine_count = 0;

bool read_input(char const* file_path) {
    FILE* file = fopen(file_path, "r");
    if (!file) {
        fprintf(stderr, "Failed to open input '%s'", file_path);
        return false;
    }

    ParseState state = PARSE_STATE_BUTTON_A;
    Machine machine = {0};

    char *line = NULL;
    size_t length = 0;
    while (getline(&line, &length, file) >= 0) {
        switch (state) {
        case PARSE_STATE_BUTTON_A:
            sscanf(line, "Button A: X+%d, Y+%d\n",
                &machine.button_a.x, &machine.button_a.y);
            state = PARSE_STATE_BUTTON_B;
            break;
        case PARSE_STATE_BUTTON_B:
            sscanf(line, "Button B: X+%d, Y+%d\n",
                &machine.button_b.x, &machine.button_b.y);
            state = PARSE_STATE_PRIZE;
            break;
        case PARSE_STATE_PRIZE:
            sscanf(line, "Prize: X=%d, Y=%d\n",
                &machine.prize.x, &machine.prize.y);
            state = PARSE_STATE_EMPTY_LINE;

            assert(s_machine_count < MAX_MACHINE_COUNT);
            s_machines[s_machine_count++] = machine;
            memset(&machine, 0, sizeof(machine));
            break;
        case PARSE_STATE_EMPTY_LINE:
            state = PARSE_STATE_BUTTON_A;
            break;
        }
    }

    fclose(file);
    if (line) {
        free(line);
    }

    return true;
}

bool compute_button_presses(Machine const* machine, size_t *out_a_presses, size_t *out_b_presses) {
    // Equations derived from:
    //     A1*x + B1*y = C1
    //     A2*x + B2*y = C2
    //
    // where A1 = button_a.x, A2 = button_a.y
    //       B1 = button_b.x, B2 = button_b.y
    //       C1 = prize.x,    C2 = prize.y

    Vec2 a = machine->button_a;
    Vec2 b = machine->button_b;
    Vec2 c = machine->prize;

    int64_t a_n = c.x * b.y - c.y * b.x;
    int64_t a_d = a.x * b.y - a.y * b.x;
    if (a_n % a_d != 0) {
        return false;
    }

    int64_t b_n = c.y - a.y * (a_n / a_d);
    int64_t b_d = b.y;
    if (b_n % b_d != 0) {
        return false;
    }

    *out_a_presses = a_n / a_d;
    *out_b_presses = b_n / b_d;
    return true;
}

size_t compute_total_tokens() {
    size_t total_tokens = 0;
    for (size_t i = 0; i < s_machine_count; ++i) {
        size_t a_presses = 0;
        size_t b_presses = 0;
        if (compute_button_presses(&s_machines[i], &a_presses, &b_presses)) {
            total_tokens += a_presses * BUTTON_A_COST + b_presses * BUTTON_B_COST;
        }
    }

    return total_tokens;
}

void offset_prizes(size_t offset) {
    for (size_t i = 0; i < s_machine_count; ++i) {
        s_machines[i].prize.x += offset;
        s_machines[i].prize.y += offset;
    }
}

int main() {
    if (!read_input("input.txt")) {
        return 1;
    }

    printf("task1 = %lu\n", compute_total_tokens());
    offset_prizes(10000000000000);
    printf("task2 = %lu\n", compute_total_tokens());
    return 0;
}
