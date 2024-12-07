const std = @import("std");

/// The types of octets represented in a unicode code point.
const octet_type = enum(c_int) {
    OCT_ONE,
    OCT_TWO,
    OCT_THREE,
    OCT_FOUR,
    OCT_NEXT,
    OCT_INVALID,

    /// Get the byte count of the given code point.
    pub fn count(t: octet_type) u8 {
        return switch (t) {
            octet_type.OCT_ONE => 1,
            octet_type.OCT_TWO => 2,
            octet_type.OCT_THREE => 3,
            octet_type.OCT_FOUR => 4,
            else => 0,
        };
    }
};

/// Structure to hold the unicode code point value and type.
const code_point = extern struct {
    val: u32,
    type: octet_type,
};

/// Check if code point has ONE marker.
inline fn oct_one_marker(point: u8) bool {
    return ((point >> 7) & 1) == 0;
}
/// Check if code point has NEXT marker.
inline fn oct_next_marker(point: u8) bool {
    return ((point >> 6) & 0b11) == 0b10;
}
/// Check if code point has TWO marker.
inline fn oct_two_marker(point: u8) bool {
    return ((point >> 5) & 0b111) == 0b110;
}
/// Check if code point has THREE marker.
inline fn oct_three_marker(point: u8) bool {
    return ((point >> 4) & 0b1111) == 0b1110;
}
/// Check if code point has FOUR marker.
inline fn oct_four_marker(point: u8) bool {
    return ((point >> 3) & 0b11111) == 0b11110;
}
/// Get the octet type of the given code point.
inline fn get_oct_type(point: u8) octet_type {
    if (oct_one_marker(point)) return octet_type.OCT_ONE;
    if (oct_next_marker(point)) return octet_type.OCT_NEXT;
    if (oct_two_marker(point)) return octet_type.OCT_TWO;
    if (oct_three_marker(point)) return octet_type.OCT_THREE;
    if (oct_four_marker(point)) return octet_type.OCT_FOUR;
    return octet_type.OCT_INVALID;
}
inline fn gen_next_marker(point: u32) u8 {
    return (point & 0b00111111) | 0b10000000;
}
inline fn gen_one_marker(point: u32) u8 {
    return (point & 0b01111111);
}
inline fn gen_two_marker(point: u32) u8 {
    return (point & 0b00011111) | 0b11000000;
}
inline fn gen_three_marker(point: u32) u8 {
    return (point & 0b00001111) | 0b11100000;
}
inline fn gen_four_marker(point: u32) u8 {
    return (point & 0b00000111) | 0b11110000;
}

/// Verify the next code point is valid.
fn verify_octets(arr: [*:0]const u8, start_idx: usize, t: octet_type) bool {
    return switch (t) {
        octet_type.OCT_TWO => oct_two_marker(arr[start_idx]) and
            oct_next_marker(arr[start_idx + 1]),
        octet_type.OCT_THREE => (oct_three_marker(arr[start_idx]) and
            oct_next_marker(arr[start_idx + 1]) and
            oct_next_marker(arr[start_idx + 2])),
        octet_type.OCT_FOUR => (oct_four_marker(arr[start_idx]) and
            oct_next_marker(arr[start_idx + 1]) and
            oct_next_marker(arr[start_idx + 2]) and
            oct_next_marker(arr[start_idx + 3])),
        else => false,
    };
}

/// Get the octet type from raw u32 value.
/// Returns OCT_INVALID if outside of acceptable range.
export fn octet_type_from_raw(n: u32) octet_type {
    if (n <= 127) return octet_type.OCT_ONE;
    if (n <= 2047) return octet_type.OCT_TWO;
    if (n <= 65535) return octet_type.OCT_THREE;
    if (n <= 1114111) return octet_type.OCT_FOUR;
    return octet_type.OCT_INVALID;
}

/// Grab the next utf8 code point in the given string.
export fn utf8_next(arr: [*:0]const u8, len: usize, start_idx: usize) code_point {
    const invalid_point: code_point = .{
        .type = octet_type.OCT_INVALID,
        .val = 0,
    };
    if (start_idx >= len) {
        return invalid_point;
    }
    var result: code_point = .{
        .type = get_oct_type(arr[start_idx]),
        .val = 0,
    };
    switch (result.type) {
        octet_type.OCT_INVALID, octet_type.OCT_NEXT => {
            result.type = octet_type.OCT_INVALID;
        },
        octet_type.OCT_ONE => {
            result.val = arr[start_idx];
        },
        octet_type.OCT_TWO => {
            if ((start_idx + 1) >= len) return invalid_point;
            if (!verify_octets(arr, start_idx, octet_type.OCT_TWO)) return invalid_point;
            const n1: u32 = arr[start_idx] & 0b11111;
            const n2: u32 = arr[start_idx + 1] & 0b111111;
            result.val = (n1 << 6) | n2;
        },
        octet_type.OCT_THREE => {
            if ((start_idx + 2) >= len) return invalid_point;
            if (!verify_octets(arr, start_idx, octet_type.OCT_THREE)) return invalid_point;
            const n1: u32 = arr[start_idx] & 0b1111;
            const n2: u32 = arr[start_idx + 1] & 0b111111;
            const n3: u32 = arr[start_idx + 2] & 0b111111;
            result.val = (n1 << 12) | (n2 << 6) | n3;
        },
        octet_type.OCT_FOUR => {
            if ((start_idx + 3) >= len) return invalid_point;
            if (!verify_octets(arr, start_idx, octet_type.OCT_FOUR)) return invalid_point;
            const n1: u32 = arr[start_idx] & 0b111;
            const n2: u32 = arr[start_idx + 1] & 0b111111;
            const n3: u32 = arr[start_idx + 2] & 0b111111;
            const n4: u32 = arr[start_idx + 3] & 0b111111;
            result.val = (n1 << 18) | (n2 << 12) | (n3 << 6) | n4;
        },
    }
    return result;
}

/// Get the length of the given string being unicode aware.
/// Returns the length of the code points in the string or 0 for empty or error.
export fn utf8_len(arr: [*:0]const u8, len: usize) usize {
    var cur_idx: usize = 0;
    var code_point_len: usize = 0;
    while (cur_idx < len) {
        const point = utf8_next(arr, len, cur_idx);
        if (point.type == octet_type.OCT_INVALID) return 0;
        cur_idx += point.type.count();
        code_point_len += 1;
    }
    return code_point_len;
}

/// Write a raw u32 unicode code point to the given destination buffer.
/// Returns the number of bytes written, 0 for invalid code point or
/// code point goes past the length of the destination buffer..
export fn utf8_write_raw(dst: [*:0]u8, len: usize, start_idx: usize, point: u32) u8 {
    const local_code_point: code_point = .{
        .type = octet_type_from_raw(point),
        .val = point,
    };
    return utf8_write(dst, len, start_idx, local_code_point);
}

/// Write a given unicode code point to the given destination buffer.
/// Returns the number of bytes written, 0 for invalid code point or
/// code point goes past the length of the destination buffer..
export fn utf8_write(dst: [*:0]u8, len: usize, start_idx: usize, point: code_point) u8 {
    if (start_idx >= len) return 0;
    var result: u8 = 0;
    switch (point.type) {
        octet_type.OCT_ONE => {
            result = 1;
            dst[start_idx] = gen_one_marker(point.value);
        },
        octet_type.OCT_TWO => {
            if ((start_idx + 1) >= len) return 0;
            result = 2;
            dst[start_idx] = gen_next_marker(point.value);
            dst[start_idx + 1] = gen_two_marker(point.value >> 6);
        },
        octet_type.OCT_THREE => {
            if ((start_idx + 2) >= len) return 0;
            result = 3;
            dst[start_idx] = gen_next_marker(point.value);
            dst[start_idx + 1] = gen_next_marker(point.value >> 6);
            dst[start_idx + 2] = gen_three_marker(point.value >> 12);
        },
        octet_type.OCT_FOUR => {
            if ((start_idx + 3) >= len) return 0;
            result = 4;
            dst[start_idx] = gen_next_marker(point.value);
            dst[start_idx + 1] = gen_next_marker(point.value >> 6);
            dst[start_idx + 2] = gen_next_marker(point.value >> 12);
            dst[start_idx + 3] = gen_four_marker(point.value >> 18);
        },
        else => {
            return 0;
        },
    }
    return result;
}
