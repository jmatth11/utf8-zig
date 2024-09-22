const std = @import("std");
const testing = std.testing;

const utf8 = @import("utf8.zig");

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
    var init_buffer: [5]u8 = [_]u8{ 0, 0, 0, 0, 0 };
    const code_point_one_str: [*:0]const u8 = "a";
    const code_point_one = utf8.utf8_next(code_point_one_str, 4, 0);
    var bytes_written: u8 = utf8.utf8_write(&init_buffer, 4, 0, code_point_one);
    try testing.expect(bytes_written == 1);
    try testing.expect(code_point_one_str[0] == init_buffer[0]);

    const code_point_two_str: [*:0]const u8 = "å";
    const code_point_two = utf8.utf8_next(code_point_two_str, 2, 0);
    bytes_written = utf8.utf8_write(&init_buffer, 4, 0, code_point_two);
    try testing.expect(bytes_written == 2);
    try testing.expect(code_point_two_str[0] == init_buffer[0]);
    try testing.expect(code_point_two_str[1] == init_buffer[1]);

    const code_point_three_str: [*:0]const u8 = "ࠎ";
    const code_point_three = utf8.utf8_next(code_point_three_str, 3, 0);
    bytes_written = utf8.utf8_write(&init_buffer, 4, 0, code_point_three);
    try testing.expect(bytes_written == 3);
    try testing.expect(code_point_three_str[0] == init_buffer[0]);
    try testing.expect(code_point_three_str[1] == init_buffer[1]);
    try testing.expect(code_point_three_str[2] == init_buffer[2]);

    const code_point_four_str: [*:0]const u8 = "𐀛";
    const code_point_four = utf8.utf8_next(code_point_four_str, 4, 0);
    bytes_written = utf8.utf8_write(&init_buffer, 4, 0, code_point_four);
    try testing.expect(bytes_written == 4);
    try testing.expect(code_point_four_str[0] == init_buffer[0]);
    try testing.expect(code_point_four_str[1] == init_buffer[1]);
    try testing.expect(code_point_four_str[2] == init_buffer[2]);
    try testing.expect(code_point_four_str[3] == init_buffer[3]);
}

test "utf8 write raw code point to utf8" {
    var init_buffer: [5]u8 = [_]u8{ 0, 0, 0, 0, 0 };
    const code_point_one_str: [*]const u8 = "a";
    const code_point_one = 97;
    var bytes_written: u8 = utf8.utf8_write_code_point(&init_buffer, 1, 0, code_point_one);
    try testing.expect(bytes_written == 1);
    try testing.expect(code_point_one_str[0] == init_buffer[0]);

    const code_point_two_str: [*]const u8 = "å";
    const code_point_two = 229;
    bytes_written = utf8.utf8_write_code_point(&init_buffer, 2, 0, code_point_two);
    try testing.expect(bytes_written == 2);
    try testing.expect(code_point_two_str[0] == init_buffer[0]);
    try testing.expect(code_point_two_str[1] == init_buffer[1]);

    const code_point_three_str: [*]const u8 = "ࠎ";
    const code_point_three = 2062;
    bytes_written = utf8.utf8_write_code_point(&init_buffer, 3, 0, code_point_three);
    try testing.expect(bytes_written == 3);
    try testing.expect(code_point_three_str[0] == init_buffer[0]);
    try testing.expect(code_point_three_str[1] == init_buffer[1]);
    try testing.expect(code_point_three_str[2] == init_buffer[2]);

    const code_point_four_str: [*]const u8 = "𐀛";
    const code_point_four = 65563;
    bytes_written = utf8.utf8_write_code_point(&init_buffer, 4, 0, code_point_four);
    try testing.expect(bytes_written == 4);
    try testing.expect(code_point_four_str[0] == init_buffer[0]);
    try testing.expect(code_point_four_str[1] == init_buffer[1]);
    try testing.expect(code_point_four_str[2] == init_buffer[2]);
    try testing.expect(code_point_four_str[3] == init_buffer[3]);
}

test "verify code points" {
    try testing.expect(utf8.utf8_verify_code_point(97));
    try testing.expect(utf8.utf8_verify_code_point(229));
    try testing.expect(utf8.utf8_verify_code_point(2062));
    try testing.expect(utf8.utf8_verify_code_point(65563));
    try testing.expect(utf8.utf8_verify_code_point(1114112) == false);
}

test "verify utf8 string" {
    const valid_str: [*:0]const u8 = "Обсуждение";
    try testing.expect(utf8.utf8_verify_str(valid_str, 10));
    const invalid_str: [*:0]const u8 = "\xff\xaa";
    try testing.expect(utf8.utf8_verify_str(invalid_str, 2) == false);
}
