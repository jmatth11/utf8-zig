# UTF8 support functions.

This is a small library for some utf8 support functions.

Written to be C ABI compatible.

Current functionality:
- `utf8_next` - Get the next unicode code point from a given string.
- `utf8_write[_raw]` - Write a given unicode code point to a given buffer.
- `utf8_len` - Get the length of the utf-8 encoded string.
