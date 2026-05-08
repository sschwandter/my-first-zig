const Id = *opaque {};
const Class = *opaque {};
const Sel = *opaque {};

const NSPoint = extern struct {
    x: f64,
    y: f64,
};

const NSSize = extern struct {
    width: f64,
    height: f64,
};

const NSRect = extern struct {
    origin: NSPoint,
    size: NSSize,
};

const NSUInteger = usize;
const NSInteger = isize;

const NSApplicationActivationPolicyRegular: NSInteger = 0;
const NSBackingStoreBuffered: NSUInteger = 2;

const NSWindowStyleMaskTitled: NSUInteger = 1 << 0;
const NSWindowStyleMaskClosable: NSUInteger = 1 << 1;
const NSWindowStyleMaskMiniaturizable: NSUInteger = 1 << 2;
const NSWindowStyleMaskResizable: NSUInteger = 1 << 3;

extern fn objc_getClass(name: [*:0]const u8) ?Class;
extern fn sel_registerName(name: [*:0]const u8) Sel;

const MsgId = *const fn (Id, Sel) callconv(.c) Id;
const MsgIdId = *const fn (Id, Sel, Id) callconv(.c) Id;
const MsgIdIdId = *const fn (Id, Sel, Id, Id) callconv(.c) Id;
const MsgIdIdIdId = *const fn (Id, Sel, Id, Id, Id) callconv(.c) Id;
const MsgIdCString = *const fn (Id, Sel, [*:0]const u8) callconv(.c) Id;
const MsgIdSelId = *const fn (Id, Sel, Id, Sel, Id) callconv(.c) Id;
const MsgVoid = *const fn (Id, Sel) callconv(.c) void;
const MsgVoidBool = *const fn (Id, Sel, bool) callconv(.c) void;
const MsgVoidId = *const fn (Id, Sel, Id) callconv(.c) void;
const MsgVoidInteger = *const fn (Id, Sel, NSInteger) callconv(.c) void;
const MsgWindowInit = *const fn (Id, Sel, NSRect, NSUInteger, NSUInteger, bool) callconv(.c) Id;

const objc_msgSend_id = @extern(MsgId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_id = @extern(MsgIdId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_id_id = @extern(MsgIdIdId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_id_id_id = @extern(MsgIdIdIdId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_cstring = @extern(MsgIdCString, .{ .name = "objc_msgSend" });
const objc_msgSend_id_sel_id = @extern(MsgIdSelId, .{ .name = "objc_msgSend" });
const objc_msgSend_void = @extern(MsgVoid, .{ .name = "objc_msgSend" });
const objc_msgSend_void_bool = @extern(MsgVoidBool, .{ .name = "objc_msgSend" });
const objc_msgSend_void_id = @extern(MsgVoidId, .{ .name = "objc_msgSend" });
const objc_msgSend_void_integer = @extern(MsgVoidInteger, .{ .name = "objc_msgSend" });
const objc_msgSend_window_init = @extern(MsgWindowInit, .{ .name = "objc_msgSend" });

pub fn main() !void {
    comptime if (!builtinTargetIsDarwin()) {
        @compileError("This example uses AppKit and only builds for macOS.");
    };

    const app = msg(class("NSApplication"), "sharedApplication");
    msgVoidInteger(app, "setActivationPolicy:", NSApplicationActivationPolicyRegular);

    buildMenuBar(app);
    buildMainWindow();

    msgVoid(app, "finishLaunching");
    msgVoidBool(app, "activateIgnoringOtherApps:", true);
    msgVoid(app, "run");
}

fn buildMenuBar(app: Id) void {
    const menubar = allocInit("NSMenu");
    const app_menu_item = allocInit("NSMenuItem");
    msgVoidId(menubar, "addItem:", app_menu_item);
    msgVoidId(app, "setMainMenu:", menubar);

    const app_menu = initMenu("My First Zig");
    msgVoidIdId(menubar, "setSubmenu:forItem:", app_menu, app_menu_item);

    _ = menuItem(app_menu, "About My First Zig", "orderFrontStandardAboutPanel:", "");
    msgVoidId(app_menu, "addItem:", msg(class("NSMenuItem"), "separatorItem"));
    _ = menuItem(app_menu, "Hide My First Zig", "hide:", "h");
    _ = menuItem(app_menu, "Quit My First Zig", "terminate:", "q");
}

fn buildMainWindow() void {
    const style =
        NSWindowStyleMaskTitled |
        NSWindowStyleMaskClosable |
        NSWindowStyleMaskMiniaturizable |
        NSWindowStyleMaskResizable;

    const frame = NSRect{
        .origin = .{ .x = 0, .y = 0 },
        .size = .{ .width = 640, .height = 420 },
    };

    const window = msgWindowInit(
        msg(class("NSWindow"), "alloc"),
        "initWithContentRect:styleMask:backing:defer:",
        frame,
        style,
        NSBackingStoreBuffered,
        false,
    );

    msgVoidId(window, "setTitle:", nsString("My First Zig"));
    msgVoid(window, "center");
    msgVoidId(window, "makeKeyAndOrderFront:", window);
}

fn menuItem(menu: Id, title: [:0]const u8, action: [:0]const u8, key: [:0]const u8) Id {
    const item = msgIdSelId(
        msg(class("NSMenuItem"), "alloc"),
        "initWithTitle:action:keyEquivalent:",
        nsString(title),
        sel_registerName(action.ptr),
        nsString(key),
    );
    msgVoidId(menu, "addItem:", item);
    return item;
}

fn initMenu(title: [:0]const u8) Id {
    return msgId(msg(class("NSMenu"), "alloc"), "initWithTitle:", nsString(title));
}

fn allocInit(comptime class_name: [:0]const u8) Id {
    return msg(class(class_name), "new");
}

fn nsString(text: [:0]const u8) Id {
    return msgCString(msg(class("NSString"), "alloc"), "initWithUTF8String:", text.ptr);
}

fn class(name: [:0]const u8) Id {
    return @ptrCast(objc_getClass(name.ptr) orelse @panic("Objective-C class not found"));
}

fn msg(receiver: Id, selector: [:0]const u8) Id {
    return objc_msgSend_id(receiver, sel_registerName(selector.ptr));
}

fn msgId(receiver: Id, selector: [:0]const u8, arg: Id) Id {
    return objc_msgSend_id_id(receiver, sel_registerName(selector.ptr), arg);
}

fn msgIdIdId(receiver: Id, selector: [:0]const u8, a: Id, b: Id, c: Id) Id {
    return objc_msgSend_id_id_id_id(receiver, sel_registerName(selector.ptr), a, b, c);
}

fn msgCString(receiver: Id, selector: [:0]const u8, arg: [*:0]const u8) Id {
    return objc_msgSend_id_cstring(receiver, sel_registerName(selector.ptr), arg);
}

fn msgIdSelId(receiver: Id, selector: [:0]const u8, a: Id, b: Sel, c: Id) Id {
    return objc_msgSend_id_sel_id(receiver, sel_registerName(selector.ptr), a, b, c);
}

fn msgVoid(receiver: Id, selector: [:0]const u8) void {
    objc_msgSend_void(receiver, sel_registerName(selector.ptr));
}

fn msgVoidBool(receiver: Id, selector: [:0]const u8, arg: bool) void {
    objc_msgSend_void_bool(receiver, sel_registerName(selector.ptr), arg);
}

fn msgVoidId(receiver: Id, selector: [:0]const u8, arg: Id) void {
    objc_msgSend_void_id(receiver, sel_registerName(selector.ptr), arg);
}

fn msgVoidIdId(receiver: Id, selector: [:0]const u8, a: Id, b: Id) void {
    _ = objc_msgSend_id_id_id(receiver, sel_registerName(selector.ptr), a, b);
}

fn msgVoidInteger(receiver: Id, selector: [:0]const u8, arg: NSInteger) void {
    objc_msgSend_void_integer(receiver, sel_registerName(selector.ptr), arg);
}

fn msgWindowInit(receiver: Id, selector: [:0]const u8, rect: NSRect, style: NSUInteger, backing: NSUInteger, defer_window: bool) Id {
    return objc_msgSend_window_init(receiver, sel_registerName(selector.ptr), rect, style, backing, defer_window);
}

fn builtinTargetIsDarwin() bool {
    return @import("builtin").target.os.tag.isDarwin();
}
