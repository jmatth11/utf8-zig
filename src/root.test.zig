const std = @import("std");
const testing = std.testing;

const utf8 = @import("root.zig");

test "octet_type from raw code point" {
    try testing.expect(utf8.octet_type_from_raw(97) == utf8.octet_type.OCT_ONE);
    try testing.expect(utf8.octet_type_from_raw(229) == utf8.octet_type.OCT_TWO);
    try testing.expect(utf8.octet_type_from_raw(2062) == utf8.octet_type.OCT_THREE);
    try testing.expect(utf8.octet_type_from_raw(65563) == utf8.octet_type.OCT_FOUR);
    try testing.expect(utf8.octet_type_from_raw(1114112) == utf8.octet_type.OCT_INVALID);
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

test "utf8 write code point to utf8" {
    const test_buffer: [*:0]u8 = @constCast(&[_:0]u8{ 0, 0, 0, 0, 0 });
    const code_point_one_str: [*:0]const u8 = "a";
    const code_point_one = utf8.utf8_next(code_point_one_str, 4, 0);
    var bytes_written: u8 = utf8.utf8_write(test_buffer, 4, 0, code_point_one);
    try testing.expect(bytes_written == 1);
    try testing.expectEqualSlices(u8, code_point_one_str[0..1], test_buffer[0..1]);

    const code_point_two_str: [*:0]const u8 = "å";
    const code_point_two = utf8.utf8_next(code_point_two_str, 2, 0);
    bytes_written = utf8.utf8_write(test_buffer, 4, 0, code_point_two);
    try testing.expect(bytes_written == 2);
    try testing.expectEqualSlices(u8, code_point_two_str[0..2], test_buffer[0..2]);

    const code_point_three_str: [*:0]const u8 = "ࠎ";
    const code_point_three = utf8.utf8_next(code_point_three_str, 3, 0);
    bytes_written = utf8.utf8_write(test_buffer, 4, 0, code_point_three);
    try testing.expect(bytes_written == 3);
    try testing.expectEqualSlices(u8, code_point_three_str[0..3], test_buffer[0..3]);

    const code_point_four_str: [*:0]const u8 = "𐀛";
    const code_point_four = utf8.utf8_next(code_point_four_str, 4, 0);
    bytes_written = utf8.utf8_write(test_buffer, 4, 0, code_point_four);
    try testing.expect(bytes_written == 4);
    try testing.expectEqualSlices(u8, code_point_four_str[0..4], test_buffer[0..4]);
}

test "utf8 write raw code point to utf8" {
    const test_buffer: [*:0]u8 = @constCast(&[_:0]u8{ 0, 0, 0, 0, 0 });
    const code_point_one_str: [*:0]const u8 = "a";
    const code_point_one = 97;
    var bytes_written: u8 = utf8.utf8_write_raw(test_buffer, 4, 0, code_point_one);
    try testing.expect(bytes_written == 1);
    try testing.expectEqualSlices(u8, code_point_one_str[0..1], test_buffer[0..1]);

    const code_point_two_str: [*:0]const u8 = "å";
    const code_point_two = 229;
    bytes_written = utf8.utf8_write_raw(test_buffer, 4, 0, code_point_two);
    try testing.expect(bytes_written == 2);
    try testing.expectEqualSlices(u8, code_point_two_str[0..2], test_buffer[0..2]);

    const code_point_three_str: [*:0]const u8 = "ࠎ";
    const code_point_three = 2062;
    bytes_written = utf8.utf8_write_raw(test_buffer, 4, 0, code_point_three);
    try testing.expect(bytes_written == 3);
    try testing.expectEqualSlices(u8, code_point_three_str[0..3], test_buffer[0..3]);

    const code_point_four_str: [*:0]const u8 = "𐀛";
    const code_point_four = 65563;
    bytes_written = utf8.utf8_write_raw(test_buffer, 4, 0, code_point_four);
    try testing.expect(bytes_written == 4);
    try testing.expectEqualSlices(u8, code_point_four_str[0..4], test_buffer[0..4]);
}
