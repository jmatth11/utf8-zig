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
        if ((self.pos + incoming_len) >= self.bytes.len) {
            const result = self.alloc.resize(self.bytes, self.pos + incoming_len + 20);
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

    pub fn write(self: *unicode, buf: []u8) usize {
        return try self.write_at(buf, self.pos);
    }

    pub fn write_raw(self: *unicode, point: u32) usize {
        return try self.write_raw_at(point, self.pos);
    }

    pub fn write_raw_at(self: *unicode, point: u32, idx: usize) unicode_error!usize {
        const octet_t = utf8.octet_type_from_raw(point);
        if (octet_t == utf8.octet_type.OCT_INVALID) return unicode_error.invalid_format;
        const point_len = idx + octet_t.count();
        try self.resize(point_len);
        self.bytes[idx] = point;
        if (point_len > self.pos) self.pos = point_len;
        return 1;
    }

    pub fn write_at(self: *unicode, buf: []u8, idx: usize) unicode_error!usize {
        // TODO check if we need to push the next bytes to make room for this write
        if (!utf8.utf8_verify_str(buf, buf.len)) return unicode_error.invalid_format;
        const write_len = idx + buf.len;
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

    pub fn len(self: *unicode) usize {
        return self.bytes.len;
    }

    pub fn at(self: *unicode, idx: usize) unicode_error!u32 {
        const bytes_len = self.len();
        if (idx > bytes_len) return unicode_error.out_of_range;
        return self.bytes[idx];
    }
};
