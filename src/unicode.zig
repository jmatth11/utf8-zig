const std = @import("std");
const utf8 = @import("utf8.zig");

pub const unicode_error = error{
    alloc_error,
    invalid_format,
    out_of_range,
    not_supported,
};

pub const unicode_code_point = u32;
pub const unicode_str = []u32;
pub const unicode_utf8 = []u8;

pub const unicode = struct {
    bytes: []u32,
    pos: usize,
    alloc: std.mem.Allocator,

    fn resize(self: *unicode, incoming_len: usize) unicode_error!void {
        if (incoming_len >= self.bytes.len) {
            const result = self.alloc.resize(self.bytes, incoming_len + 20);
            if (!result) return unicode_error.alloc_error;
        }
    }

    pub fn init(self: *unicode, n: usize, alloc: std.mem.Allocator) void {
        self.alloc = alloc;
        self.bytes = alloc.alloc(u32, n);
        self.pos = 0;
    }

    pub fn deinit(self: *unicode) void {
        self.alloc.free(self.bytes);
        self.pos = 0;
    }

    pub fn len(self: *unicode) usize {
        return self.bytes.len;
    }

    pub fn utf8_len(self: *unicode) usize {
        return utf8.code_point_to_utf8_len(self.bytes.ptr);
    }

    pub fn at(self: *unicode, idx: usize) unicode_error!u32 {
        const bytes_len = self.len();
        if (idx > bytes_len) return unicode_error.out_of_range;
        return self.bytes[idx];
    }

    pub fn write(comptime T: type, self: *unicode, buf: T) unicode_error!usize {
        return switch (T) {
            unicode_utf8 => try self.write_utf8_at(buf, self.pos, true),
            unicode_code_point => try self.write_code_point_at(buf, self.pos, true),
            unicode_str => try self.write_code_point_str_at(buf, self.pos, true),
            else => unicode_error.not_supported,
        };
    }

    pub fn write_at(comptime T: type, self: *unicode, buf: T, idx: usize) unicode_error!usize {
        return switch (T) {
            unicode_utf8 => try self.write_utf8_at(buf, idx, true),
            unicode_code_point => try self.write_code_point_at(buf, idx, true),
            unicode_str => try self.write_code_point_str_at(buf, idx, true),
            else => unicode_error.not_supported,
        };
    }

    pub fn insert(comptime T: type, self: *unicode, buf: T) unicode_error!usize {
        return switch (T) {
            unicode_utf8 => try self.insert_at_utf8(buf, self.pos, false),
            unicode_code_point => try self.insert_code_point_at(buf, self.pos, false),
            unicode_str => try self.write_code_point_str_at(buf, self.pos, false),
            else => unicode_error.not_supported,
        };
    }

    pub fn insert_at(comptime T: type, self: *unicode, buf: T, idx: usize) unicode_error!usize {
        return switch (T) {
            unicode_utf8 => try self.insert_at_utf8(buf, idx, false),
            unicode_code_point => try self.insert_code_point_at(buf, idx, false),
            unicode_str => try self.write_code_point_str_at(buf, idx, false),
            else => unicode_error.not_supported,
        };
    }

    pub fn to_utf8(self: *unicode, alloc: std.mem.Allocator) []u8 {
        const new_len = utf8.code_point_to_utf8_len(self.bytes.ptr, self.bytes.len);
        const result: []u8 = alloc.alloc(u8, new_len);
        var buf_idx: usize = 0;
        for (self.bytes) |b| {
            buf_idx += utf8.utf8_write_code_point(result.ptr, new_len, buf_idx, b);
        }
        return result;
    }

    pub fn remove_range(self: *unicode, start_idx: usize, end_idx: usize) unicode_error!void {
        if (start_idx > end_idx or start_idx >= self.pos) return unicode_error.out_of_range;
        var beg_pos = start_idx;
        var end_pos = end_idx;
        while (end_pos < self.pos) {
            self.bytes[beg_pos] = self.bytes[end_pos];
            beg_pos += 1;
            end_pos += 1;
        }
        self.pos = beg_pos;
    }

    fn write_code_point_str_at(self: *unicode, buf: []u32, idx: usize, overwrite: bool) unicode_error!usize {
        if (!utf8.code_point_verify_str(buf.ptr, buf.len)) return unicode_error.invalid_format;
        var write_len: usize = 0;
        var start_pos = idx;
        if (overwrite) {
            try self.resize(idx + buf.len);
        } else {
            try self.move_range(idx, buf.len);
        }
        for (buf) |b| {
            const point = utf8.octet_type_from_code_point(b);
            write_len += try self.write_octet_type_at(point, start_pos);
            start_pos += 1;
        }
        return write_len;
    }

    fn write_code_point_at(self: *unicode, point: u32, idx: usize, overwrite: bool) unicode_error!usize {
        const octet_t = try self.validate_code_point(point);
        if (!overwrite) {
            try self.move_range(idx, idx + 1);
        }
        return self.write_octet_type_at(octet_t, idx);
    }

    fn write_utf8_at(self: *unicode, buf: []u8, idx: usize, overwrite: bool) unicode_error!usize {
        // verify the string is valid up front
        const buf_len = try self.validate_utf8_str(buf);
        const write_len = idx + buf_len;
        if (overwrite) {
            try self.resize(write_len);
            if (write_len > self.pos) self.pos = write_len;
        } else {
            try self.move_range(idx, write_len);
        }
        var pos_idx = idx;
        var buf_idx = 0;
        while (buf_idx < buf.len) {
            const code_point = utf8.utf8_next(buf, buf.len, buf_idx);
            self.bytes[pos_idx] = code_point.val;
            buf_idx += code_point.type.count();
            pos_idx += 1;
        }
        return buf_idx;
    }

    fn write_octet_type_at(self: *unicode, point: utf8.octet_type, idx: usize) usize {
        const point_end_idx = idx + point.count();
        try self.resize(point_end_idx);
        self.bytes[idx] = point;
        if (point_end_idx > self.pos) self.pos = point_end_idx;
        return 1;
    }

    fn move_range(self: *unicode, start_idx: usize, end_idx: usize) unicode_error!void {
        if (end_idx < start_idx or start_idx > self.pos) return unicode_error.out_of_range;
        var end_pos = (self.pos + (end_idx - start_idx));
        self.pos = end_pos;
        try self.resize(end_pos);
        if (start_idx >= self.pos) return;
        var beg_pos = self.pos;
        while (beg_pos >= start_idx) {
            self.bytes[end_pos] = self.bytes[beg_pos];
            end_pos -= 1;
            beg_pos -= 1;
        }
    }
    inline fn validate_code_point(n: u32) unicode_error!utf8.octet_type {
        const octet_t = utf8.octet_type_from_code_point(n);
        if (octet_t == utf8.octet_type.OCT_INVALID) return unicode_error.invalid_format;
        return octet_t;
    }
    inline fn validate_utf8_str(buf: []u8) unicode_error!usize {
        if (!utf8.utf8_verify_str(buf, buf.len)) return unicode_error.invalid_format;
        return utf8.utf8_len(buf, buf.len);
    }
};
