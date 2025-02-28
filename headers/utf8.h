#ifndef JM_UNICODE_UTF8
#define JM_UNICODE_UTF8

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>
#ifndef EMSCRIPTEN
#include <sys/cdefs.h>
#else
#define __THROWNL __attribute__((__nothrow__))
#define __nonnull(params) __attribute__((__nonnull__ params))
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * The types of octets represented in a unicode code point.
 */
enum octet_type {
  OCT_ONE,
  OCT_TWO,
  OCT_THREE,
  OCT_FOUR,
  OCT_NEXT,
  OCT_INVALID,
};

/**
 * Structure to hold the unicode code point value and type.
 */
struct code_point {
  uint32_t val;
  enum octet_type type;
};

/**
 * Standard "replacement" character to use when a Unicode code point is not supported.
 */
extern uint32_t replacement_character;

/**
 * Write a given unicode code point to the given destination buffer.
 * Returns the number of bytes written, 0 for invalid code point or
 * code point goes past the length of the destination buffer.
 */
extern uint8_t utf8_write(uint8_t *dst, size_t len, size_t start_idx, struct code_point point) __THROWNL __nonnull((1));

/**
 * Write a raw u32 unicode code point to the given destination buffer.
 * Returns the number of bytes written, 0 for invalid code point or
 * code point goes past the length of the destination buffer.
 */
extern uint8_t utf8_write_code_point(uint8_t *dst, size_t len, size_t start_idx, uint32_t point) __THROWNL __nonnull((1));

/**
 * Calculate the utf8 string length from an array of code points.
 */
extern size_t code_point_to_utf8_len(const uint32_t *arr, size_t len) __THROWNL __nonnull((1));

/**
 * Get the length of the given string being unicode aware.
 * Returns the length of the code points in the string or 0 for empty or error.
 */
extern size_t utf8_len(const uint8_t *arr, size_t len) __THROWNL __nonnull((1));

/**
 * Grab the next utf8 code point in the given string.
 */
extern struct code_point utf8_next(const uint8_t *arr, size_t len, size_t start_idx) __THROWNL __nonnull((1));

/**
 * Get the octet type from raw u32 value.
 * Returns OCT_INVALID if outside of acceptable range.
 */
extern enum octet_type octet_type_from_code_point(uint32_t n) __THROWNL;

/**
 * Verify a string of code points are valid.
 */
extern bool code_point_verify_str(const uint32_t *arr, size_t len) __THROWNL __nonnull((1));

/**
 * Verify the next utf8 encoded code point is valid.
 */
extern bool utf8_verify_str(const uint8_t *arr, size_t len) __THROWNL __nonnull((1));

/**
 * Verify a given raw value is a valid unicode code point.
 */
extern bool utf8_verify_code_point(uint32_t val) __THROWNL;

/**
 * Get the octet type of the given utf8 value.
 */
extern enum octet_type get_oct_type(uint8_t point) __THROWNL;

/**
 * Get the byte count for the given octet type.
 */
extern uint8_t octet_type_count(enum octet_type t) __THROWNL;

/**
 * Check if a code point is in the UTF-16 reserved surrogate points.
 */
extern bool check_reserved_surrogates(uint32_t point) __THROWNL;

#ifdef __cplusplus
}
#endif

#endif
