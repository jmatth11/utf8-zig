# UTF8 support functions.

This is a small library for some utf8 support functions.

Written to be C ABI compatible.

Current functionality:
- `octet_type_count` Get the byte count of the utf8 octet type byte.
- `get_octet_type` Get the octet type of a given u8 byte.
- `utf8_verify_code_point` Verify a given code point is valid unicode.
- `utf8_verify_str` Verify a given u8 array is valid utf8 unicode.
- `code_point_verify_str` Verify a given u32 code point array is valid unicode.
- `octet_type_from_code_point` Get the octet type of a u32 code point.
- `utf8_next` - Get the next unicode code point from a given string.
- `utf8_write` - Write a given unicode code point to a given buffer.
- `utf8_write_code_point` - Write a given u32 unicode code point to a given buffer.
- `utf8_len` - Get the length of the utf-8 encoded string.
- `code_point_to_utf8_len` Get the utf8 byte length of an array of u32 code points.
