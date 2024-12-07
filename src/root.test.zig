const std = @import("std");
const testing = std.testing;

const utf8 = @import("root.zig");

test "check octet markers" {
    try testing.expect(utf8.oct_one_marker(0b00000001) == true);
    try testing.expect(utf8.oct_one_marker(0b10000000) == false);

    try testing.expect(utf8.oct_next_marker(0b10000000) == true);
    try testing.expect(utf8.oct_next_marker(0b11000000) == false);

    try testing.expect(utf8.oct_two_marker(0b11000010) == true);
    try testing.expect(utf8.oct_two_marker(0b11100000) == false);

    try testing.expect(utf8.oct_three_marker(0b11100001) == true);
    try testing.expect(utf8.oct_three_marker(0b11110000) == false);

    try testing.expect(utf8.oct_four_marker(0b11110001) == true);
    try testing.expect(utf8.oct_four_marker(0b11000000) == false);
}

test "get octet type" {
    try testing.expect(utf8.get_oct_type(0b00000000) == utf8.octet_type.OCT_ONE);
    try testing.expect(utf8.get_oct_type(0b10000000) == utf8.octet_type.OCT_NEXT);
    try testing.expect(utf8.get_oct_type(0b11000000) == utf8.octet_type.OCT_TWO);
    try testing.expect(utf8.get_oct_type(0b11100000) == utf8.octet_type.OCT_THREE);
    try testing.expect(utf8.get_oct_type(0b11110000) == utf8.octet_type.OCT_FOUR);
    try testing.expect(utf8.get_oct_type(0b11111111) == utf8.octet_type.OCT_INVALID);
}

test "utf8 next code point" {
    const code_point_one = utf8.utf8_next("a", 1, 0);
    try testing.expect(code_point_one.type == utf8.octet_type.OCT_ONE);
    try testing.expect(code_point_one.val == 97);

    const code_point_two = utf8.utf8_next("å", 2, 0);
    try testing.expect(code_point_two.type == utf8.octet_type.OCT_TWO);
    try testing.expect(code_point_two.val == 229);

    const code_point_three = utf8.utf8_next("ࠎ", 3, 0);
    try testing.expect(code_point_three.type == utf8.octet_type.OCT_THREE);
    try testing.expect(code_point_three.val == 2062);

    const code_point_four = utf8.utf8_next("𐀛", 4, 0);
    try testing.expect(code_point_four.type == utf8.octet_type.OCT_FOUR);
    try testing.expect(code_point_four.val == 65563);

    const code_point_wrong_length = utf8.utf8_next("𐀛", 4, 5);
    try testing.expect(code_point_wrong_length.type == utf8.octet_type.OCT_INVALID);
    try testing.expect(code_point_wrong_length.val == 0);

    var bad_format = [_]u8{ 0b11111111, 0b00011010, 0 };
    const code_point_bad_format = utf8.utf8_next(bad_format[0..2 :0], 2, 0);
    try testing.expect(code_point_bad_format.type == utf8.octet_type.OCT_INVALID);
    try testing.expect(code_point_bad_format.val == 0);

    bad_format[0] = 0b11100000;
    const code_point_bad_format_2 = utf8.utf8_next(bad_format[0..2 :0], 2, 0);
    try testing.expect(code_point_bad_format_2.type == utf8.octet_type.OCT_INVALID);
    try testing.expect(code_point_bad_format_2.val == 0);
}

test "utf8 length of string" {
    var test_len: usize = utf8.utf8_len("test", 4);
    try testing.expect(test_len == 4);

    test_len = utf8.utf8_len("åࠎ", 5);
    try testing.expect(test_len == 2);

    // invalid strings return 0 length
    var bad_format = [_]u8{ 0b11111111, 0b00011010, 0 };
    test_len = utf8.utf8_len(bad_format[0..2 :0], 2);
    try testing.expect(test_len == 0);

    bad_format[0] = 0b11100000;
    test_len = utf8.utf8_len(bad_format[0..2 :0], 2);
    try testing.expect(test_len == 0);
}

test "utf8 write code point to utf8" {}
