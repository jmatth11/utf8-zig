const std = @import("std");
const testing = std.testing;

/// The types of octets represented in a unicode code point.
pub const octet_type = enum(c_int) {
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
pub const code_point = extern struct {
    val: u32,
    type: octet_type,
};

/// Check if code point has ONE marker.
inline fn oct_one_marker(point: u8) bool {
    return (point & 0b10000000) == 0;
}
/// Check if code point has NEXT marker.
inline fn oct_next_marker(point: u8) bool {
    return (point & 0b11000000) == 0b10000000;
}
/// Check if code point has TWO marker.
inline fn oct_two_marker(point: u8) bool {
    return (point & 0b11100000) == 0b11000000;
}
/// Check if code point has THREE marker.
inline fn oct_three_marker(point: u8) bool {
    return (point & 0b11110000) == 0b11100000;
}
/// Check if code point has FOUR marker.
inline fn oct_four_marker(point: u8) bool {
    return (point & 0b11111000) == 0b11110000;
}
inline fn gen_next_marker(point: u32) u8 {
    return @intCast((point & 0b00111111) | 0b10000000);
}
inline fn gen_one_marker(point: u32) u8 {
    return @intCast((point & 0b01111111));
}
inline fn gen_two_marker(point: u32) u8 {
    return @intCast((point & 0b00011111) | 0b11000000);
}
inline fn gen_three_marker(point: u32) u8 {
    return @intCast((point & 0b00001111) | 0b11100000);
}
inline fn gen_four_marker(point: u32) u8 {
    return @intCast((point & 0b00000111) | 0b11110000);
}

/// Check if a code point is in the UTF-16 reserved surrogate points.
pub export fn check_reserved_surrogates(point: u32) bool {
    return point >= 55296 and point <= 57343;
}

/// Verify the next code point is valid.
fn verify_octets(arr: [*]const u8, start_idx: usize, t: octet_type) bool {
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

/// Write a given Unicode code point to the dst array at the given starting point.
/// Returns the number of bytes written.
pub fn write(dst: []u8, start_idx: usize, point: code_point) u8 {
    if (start_idx >= dst.len) return 0;
    var result: u8 = 0;
    switch (point.type) {
        octet_type.OCT_ONE => {
            result = 1;
            dst[start_idx] = gen_one_marker(point.val);
        },
        octet_type.OCT_TWO => {
            if ((start_idx + 1) >= dst.len) return 0;
            result = 2;
            dst[start_idx + 1] = gen_next_marker(point.val);
            dst[start_idx] = gen_two_marker(point.val >> 6);
        },
        octet_type.OCT_THREE => {
            if ((start_idx + 2) >= dst.len) return 0;
            result = 3;
            dst[start_idx + 2] = gen_next_marker(point.val);
            dst[start_idx + 1] = gen_next_marker(point.val >> 6);
            dst[start_idx] = gen_three_marker(point.val >> 12);
        },
        octet_type.OCT_FOUR => {
            if ((start_idx + 3) >= dst.len) return 0;
            result = 4;
            dst[start_idx + 3] = gen_next_marker(point.val);
            dst[start_idx + 2] = gen_next_marker(point.val >> 6);
            dst[start_idx + 1] = gen_next_marker(point.val >> 12);
            dst[start_idx] = gen_four_marker(point.val >> 18);
        },
        else => {
            return 0;
        },
    }
    return result;
}

/// Get the byte count for the given octet type.
pub export fn octet_type_count(t: octet_type) u8 {
    return t.count();
}

/// Get the octet type of the given utf8 value.
pub export fn get_oct_type(point: u8) octet_type {
    if (oct_one_marker(point)) return octet_type.OCT_ONE;
    if (oct_next_marker(point)) return octet_type.OCT_NEXT;
    if (oct_two_marker(point)) return octet_type.OCT_TWO;
    if (oct_three_marker(point)) return octet_type.OCT_THREE;
    if (oct_four_marker(point)) return octet_type.OCT_FOUR;
    return octet_type.OCT_INVALID;
}
/// Verify a given raw value is a valid unicode code point.
pub export fn utf8_verify_code_point(val: u32) bool {
    const oct_t = octet_type_from_code_point(val);
    return oct_t.count() != 0;
}

// Verify the next utf8 encoded code point is valid.
pub export fn utf8_verify_str(arr: [*]const u8, len: usize) bool {
    var idx: usize = 0;
    while (idx < len) {
        const b = arr[idx];
        const oct_t = get_oct_type(b);
        if (oct_t.count() == 0) return false;
        if ((oct_t.count() + idx) > len) return false;
        if (!verify_octets(arr, idx, oct_t)) return false;
        idx += oct_t.count();
    }
    return true;
}

/// Verify a string of code points are valid.
pub export fn code_point_verify_str(arr: [*]const u32, len: usize) bool {
    var idx: usize = 0;
    while (idx < len) : (idx += 1) {
        if (!utf8_verify_code_point(arr[idx])) return false;
    }
    return true;
}

/// Get the octet type from raw u32 value.
/// Returns OCT_INVALID if outside of acceptable range.
pub export fn octet_type_from_code_point(n: u32) octet_type {
    if (n <= 127) return octet_type.OCT_ONE;
    if (n <= 2047) return octet_type.OCT_TWO;
    if (n <= 65535) return octet_type.OCT_THREE;
    if (n <= 1114111) return octet_type.OCT_FOUR;
    return octet_type.OCT_INVALID;
}

/// Grab the next utf8 code point in the given string.
pub export fn utf8_next(arr: [*]const u8, len: usize, start_idx: usize) code_point {
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
pub export fn utf8_len(arr: [*]const u8, len: usize) usize {
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

/// Calculate the utf8 string length from an array of code points.
pub export fn code_point_to_utf8_len(arr: [*]const u32, len: usize) usize {
    var idx: usize = 0;
    var sum: usize = 0;
    while (idx < len) : (idx += 1) {
        const octet_t = octet_type_from_code_point(arr[idx]);
        if (octet_t == octet_type.OCT_INVALID) return 0;
        sum += octet_t.count();
    }
    return sum;
}

/// Write a raw u32 unicode code point to the given destination buffer.
/// Returns the number of bytes written, 0 for invalid code point or
/// code point goes past the length of the destination buffer..
pub export fn utf8_write_code_point(dst: [*]u8, len: usize, start_idx: usize, point: u32) u8 {
    const local_code_point: code_point = .{
        .type = octet_type_from_code_point(point),
        .val = point,
    };
    return utf8_write(dst, len, start_idx, local_code_point);
}

/// Write a given unicode code point to the given destination buffer.
/// Returns the number of bytes written, 0 for invalid code point or
/// code point goes past the length of the destination buffer..
pub export fn utf8_write(dst: [*]u8, len: usize, start_idx: usize, point: code_point) u8 {
    if (start_idx >= len) return 0;
    const dst_slice: []u8 = dst[0..len];
    return write(dst_slice, start_idx, point);
}

test "check octet markers" {
    try testing.expect(oct_one_marker(0b00000001) == true);
    try testing.expect(oct_one_marker(0b10000000) == false);

    try testing.expect(oct_next_marker(0b10000000) == true);
    try testing.expect(oct_next_marker(0b11000000) == false);

    try testing.expect(oct_two_marker(0b11000010) == true);
    try testing.expect(oct_two_marker(0b11100000) == false);

    try testing.expect(oct_three_marker(0b11100001) == true);
    try testing.expect(oct_three_marker(0b11110000) == false);

    try testing.expect(oct_four_marker(0b11110001) == true);
    try testing.expect(oct_four_marker(0b11000000) == false);
}

test "get octet type" {
    try testing.expect(get_oct_type(0b00000000) == octet_type.OCT_ONE);
    try testing.expect(get_oct_type(0b10000000) == octet_type.OCT_NEXT);
    try testing.expect(get_oct_type(0b11000000) == octet_type.OCT_TWO);
    try testing.expect(get_oct_type(0b11100000) == octet_type.OCT_THREE);
    try testing.expect(get_oct_type(0b11110000) == octet_type.OCT_FOUR);
    try testing.expect(get_oct_type(0b11111111) == octet_type.OCT_INVALID);
}

test "octet_type from raw code point" {
    try testing.expect(octet_type_from_code_point(97) == octet_type.OCT_ONE);
    try testing.expect(octet_type_from_code_point(229) == octet_type.OCT_TWO);
    try testing.expect(octet_type_from_code_point(2062) == octet_type.OCT_THREE);
    try testing.expect(octet_type_from_code_point(65563) == octet_type.OCT_FOUR);
    try testing.expect(octet_type_from_code_point(1114112) == octet_type.OCT_INVALID);
}

test "code point to utf8 len" {
    // TODO test
}
