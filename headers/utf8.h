#ifndef JM_UNICODE_UTF8
#define JM_UNICODE_UTF8

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>
#include <sys/cdefs.h>

__BEGIN_DECLS

enum octet_type {
  OCT_ONE,
  OCT_TWO,
  OCT_THREE,
  OCT_FOUR,
  OCT_NEXT,
  OCT_INVALID,
};

struct code_point {
  uint32_t val;
  enum octet_type type;
};

extern uint8_t utf8_write(uint8_t *dst, size_t len, size_t start_idx, struct code_point point) __THROWNL __nonnull((1));
extern uint8_t utf8_write_code_point(uint8_t *dst, size_t len, size_t start_idx, uint32_t point) __THROWNL __nonnull((1));
extern size_t code_point_to_utf8_len(uint32_t *const arr, size_t len) __THROWNL __nonnull((1));
extern size_t utf8_len(uint8_t *const arr, size_t len) __THROWNL __nonnull((1));
extern struct code_point utf8_next(uint8_t *const arr, size_t len, size_t start_idx) __THROWNL __nonnull((1));
extern enum octet_type octet_type_from_code_point(uint32_t n) __THROWNL;
extern bool code_point_verify_str(uint32_t *const arr, size_t len) __THROWNL __nonnull((1));
extern bool utf8_verify_str(uint8_t *const arr, size_t len) __THROWNL __nonnull((1));
extern bool utf8_verify_code_point(uint32_t val) __THROWNL;
extern enum octet_type get_oct_type(uint8_t point) __THROWNL;
extern uint8_t octet_type_count(enum octet_type t) __THROWNL;

__END_DECLS

#endif
