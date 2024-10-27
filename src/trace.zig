const std = @import("std");
const assert = std.debug.assert;
const c = @cImport({
    @cInclude("sqlite3ext.h");
});

export fn sqlite3_trace_init(db: *c.sqlite3, pzErrMsg: **c_char, pApi: *c.sqlite3_api_routines) i32 {
    return sqlite3_extension_init(db, pzErrMsg, pApi);
}

const Collector = struct {
    calls: u64 = 0,

    pub fn incr(self: *Collector) void {
        self.calls = self.calls + 1;
    }
};

test "collector_incr" {
    var coll: Collector = Collector{};
    coll.incr();
    try std.testing.expect(coll.calls == 1);
}

export fn sqlite3_extension_init(db: *c.sqlite3, pzErrMsg: **c_char, pApi: *c.sqlite3_api_routines) i32 {
    _ = pzErrMsg;
    _ = pApi;

    var ctx: i32 = 42;
    _ = c.sqlite3_trace_v2(db, c.SQLITE_TRACE_PROFILE | c.SQLITE_TRACE_STMT, callback, @ptrCast(&ctx));

    std.log.info("hello from init", .{});
    return c.SQLITE_OK;
}


// TODO: make decorator to inject a collector
fn callback(t: c_uint, ctx: ?*anyopaque, p: ?*anyopaque, x: ?*anyopaque) callconv(.C) c_int {
    const context: *i32 = @ptrCast(@alignCast(ctx));
    switch (t) {
        c.SQLITE_TRACE_PROFILE => {
            const duration: *i64 = @ptrCast(@alignCast(x));
            const stmt: *c.sqlite3_stmt = @ptrCast(@alignCast(p));
            std.log.info("profile: {d}, ctx: {d}, nanoseconds: {d}, stmt: {s}", .{ t, context.*, duration.*, c.sqlite3_sql(stmt) });
        },
        c.SQLITE_TRACE_STMT => {
            std.log.info("stmt: {d}, ctx: {d}", .{ t, context.* });
        },
        else => unreachable,
    }
    return c.SQLITE_OK;
}
