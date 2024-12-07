const std = @import("std");
const utf8 = @import("utf8.zig");

const unicode_error = error{
    alloc_error,
    invalid_format,
    out_of_range,
};

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

    pub fn at(self: *unicode, idx: usize) unicode_error!u32 {
        const bytes_len = self.len();
        if (idx > bytes_len) return unicode_error.out_of_range;
        return self.bytes[idx];
    }

    pub fn write(comptime T: type, self: *unicode, buf: T) unicode_error!usize {
        return switch (T) {
            []u8 => try self.write_at(buf, self.pos),
            u32 => try self.write_raw_at(buf, self.pos),
        };
    }

    pub fn write_at(comptime T: type, self: *unicode, buf: T, idx: usize) unicode_error!usize {
        return switch (T) {
            []u8 => try self.write_at(buf, idx),
            u32 => try self.write_raw_at(buf, idx),
        };
    }

    pub fn insert_raw_at(self: *unicode, point: u32, idx: usize) unicode_error!usize {
        const octet_t = utf8.octet_type_from_raw(point);
        if (octet_t == utf8.octet_type.OCT_INVALID) return unicode_error.invalid_format;
        const point_end_idx = idx + octet_t.count();
        try move_range(idx, point_end_idx);
        if (idx < self.pos) {}
    }

    fn write_raw_at(self: *unicode, point: u32, idx: usize) unicode_error!usize {
        const octet_t = utf8.octet_type_from_raw(point);
        if (octet_t == utf8.octet_type.OCT_INVALID) return unicode_error.invalid_format;
        const point_end_idx = idx + octet_t.count();
        try self.resize(point_end_idx);
        self.bytes[idx] = point;
        if (point_end_idx > self.pos) self.pos = point_end_idx;
        return 1;
    }

    fn write_at_code_points(self: *unicode, buf: []u8, idx: usize) unicode_error!usize {
        // verify the string is valid up front
        if (!utf8.utf8_verify_str(buf, buf.len)) return unicode_error.invalid_format;
        const write_len = idx + utf8.utf8_len(buf, buf.len);
        self.resize(write_len) catch return unicode_error.alloc_error;
        var pos_idx = idx;
        var buf_idx = 0;
        while (pos_idx < buf.len) {
            const code_point = utf8.utf8_next(buf, buf.len, buf_idx);
            self.bytes[pos_idx] = code_point.val;
            buf_idx += code_point.type.count();
            pos_idx += 1;
        }
        if (write_len > self.pos) self.pos = write_len;
        return buf_idx;
    }

    fn move_range(self: *unicode, start_idx: usize, end_idx: usize) unicode_error!void {
        if (end_idx < start_idx) return unicode_error.out_of_range;
        var end_pos = (self.pos + (end_idx - start_idx)) - 1;
        try self.resize(end_pos);
        var beg_pos = self.pos - 1;
        while (beg_pos >= start_idx) {
            self.bytes[end_pos] = self.bytes[beg_pos];
            end_pos -= 1;
            beg_pos -= 1;
        }
    }
};
