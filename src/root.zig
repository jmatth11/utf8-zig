const std = @import("std");
const testing = std.testing;

const octet_type = enum(c_int) {
    OCT_ONE,
    OCT_TWO,
    OCT_THREE,
    OCT_FOUR,
    OCT_NEXT,
    OCT_INVALID,
};

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

test "utf8 next code point" {
    const code_point_one = utf8_next("a", 1, 0);
    try testing.expect(code_point_one.type == octet_type.OCT_ONE);
    try testing.expect(code_point_one.val == 97);

    const code_point_two = utf8_next("å", 2, 0);
    try testing.expect(code_point_two.type == octet_type.OCT_TWO);
    try testing.expect(code_point_two.val == 229);

    const code_point_three = utf8_next("ࠎ", 3, 0);
    try testing.expect(code_point_three.type == octet_type.OCT_THREE);
    try testing.expect(code_point_three.val == 2062);

    const code_point_four = utf8_next("𐀛", 4, 0);
    try testing.expect(code_point_four.type == octet_type.OCT_FOUR);
    try testing.expect(code_point_four.val == 65563);

    const code_point_wrong_length = utf8_next("𐀛", 4, 5);
    try testing.expect(code_point_wrong_length.type == octet_type.OCT_INVALID);
    try testing.expect(code_point_wrong_length.val == 0);

    var bad_format = [_]u8{ 0b11111111, 0b00011010 };
    const code_point_bad_format = utf8_next(bad_format[0..2 :0], 2, 0);
    try testing.expect(code_point_bad_format.type == octet_type.OCT_INVALID);
    try testing.expect(code_point_bad_format.val == 0);

    bad_format[0] = 0b11100000;
    const code_point_bad_format_2 = utf8_next(bad_format[0..2 :0], 2, 0);
    try testing.expect(code_point_bad_format_2.type == octet_type.OCT_INVALID);
    try testing.expect(code_point_bad_format_2.val == 0);
}
