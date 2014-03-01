#pragma once

extern void console_put(char c);
extern void console_print_string(const char*);
extern void console_put_hex8(uint16_t v);
extern void console_put_hex16(uint16_t v);
extern void console_put_hex(uint32_t v);
extern void console_put_hex64(uint64_t v);
extern void console_put_dec(uint32_t v);
extern void console_clear_screen();
