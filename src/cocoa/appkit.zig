const rt = @import("runtime.zig");

pub const activation_policy_regular: rt.NSInteger = 0;
pub const backing_store_buffered: rt.NSUInteger = 2;

pub const window_style_titled: rt.NSUInteger = 1 << 0;
pub const window_style_closable: rt.NSUInteger = 1 << 1;
pub const window_style_miniaturizable: rt.NSUInteger = 1 << 2;
pub const window_style_resizable: rt.NSUInteger = 1 << 3;

pub const view_width_sizable: rt.NSUInteger = 1 << 1;
pub const view_height_sizable: rt.NSUInteger = 1 << 4;

pub fn sharedApplication() rt.Id {
    return rt.msg(rt.class("NSApplication"), "sharedApplication");
}

pub fn allocInit(comptime class_name: [:0]const u8) rt.Id {
    return rt.msg(rt.class(class_name), "new");
}

pub fn runApplication(app: rt.Id) void {
    rt.msgVoid(app, "finishLaunching");
    rt.msgVoidBool(app, "activateIgnoringOtherApps:", true);
    rt.msgVoid(app, "run");
}
