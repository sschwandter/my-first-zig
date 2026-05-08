//! Thin Objective-C runtime bridge used by the AppKit UI layer.
//!
//! Zig cannot call Objective-C methods directly, so this module centralizes the
//! small set of typed `objc_msgSend` shims used by the app. Every wrapper name
//! describes the shape of the call so higher-level modules do not need to cast
//! Objective-C messages themselves.

/// Opaque Objective-C object pointer (`id`).
pub const Id = *allowzero opaque {};
/// Null Objective-C object pointer for APIs that accept `nil`.
pub const nil: Id = @ptrFromInt(0);
/// Opaque Objective-C class pointer (`Class`).
pub const Class = *opaque {};
/// Opaque Objective-C selector pointer (`SEL`).
pub const Sel = *opaque {};
/// Opaque Objective-C method implementation pointer (`IMP`).
pub const Imp = *const anyopaque;

/// AppKit/Foundation unsigned integer ABI type.
pub const NSUInteger = usize;
/// AppKit/Foundation signed integer ABI type.
pub const NSInteger = isize;

/// C-compatible representation of `NSPoint` for AppKit calls.
pub const NSPoint = extern struct { x: f64, y: f64 };
/// C-compatible representation of `NSSize` for AppKit calls.
pub const NSSize = extern struct { width: f64, height: f64 };
/// C-compatible representation of `NSRect` for AppKit calls.
pub const NSRect = extern struct { origin: NSPoint, size: NSSize };

extern fn objc_getClass(name: [*:0]const u8) ?Class;
extern fn objc_allocateClassPair(superclass: Class, name: [*:0]const u8, extra_bytes: usize) ?Class;
extern fn objc_registerClassPair(cls: Class) void;
extern fn class_addMethod(cls: Class, name: Sel, imp: Imp, types: [*:0]const u8) bool;
extern fn sel_registerName(name: [*:0]const u8) Sel;

const MsgId = *const fn (Id, Sel) callconv(.c) Id;
const MsgIdId = *const fn (Id, Sel, Id) callconv(.c) Id;
const MsgIdIdId = *const fn (Id, Sel, Id, Id) callconv(.c) Id;
const MsgIdCString = *const fn (Id, Sel, [*:0]const u8) callconv(.c) Id;
const MsgIdRect = *const fn (Id, Sel, NSRect) callconv(.c) Id;
const MsgIdSelId = *const fn (Id, Sel, Id, Sel, Id) callconv(.c) Id;
const MsgIdDouble = *const fn (Id, Sel, f64) callconv(.c) Id;
const MsgIdUInteger = *const fn (Id, Sel, NSUInteger) callconv(.c) Id;
const MsgInteger = *const fn (Id, Sel) callconv(.c) NSInteger;
const MsgRect = *const fn (Id, Sel) callconv(.c) NSRect;
const MsgCStringReturn = *const fn (Id, Sel) callconv(.c) [*:0]const u8;
const MsgVoid = *const fn (Id, Sel) callconv(.c) void;
const MsgVoidBool = *const fn (Id, Sel, bool) callconv(.c) void;
const MsgVoidDouble = *const fn (Id, Sel, f64) callconv(.c) void;
const MsgVoidDoubleInteger = *const fn (Id, Sel, f64, NSInteger) callconv(.c) void;
const MsgVoidId = *const fn (Id, Sel, Id) callconv(.c) void;
const MsgVoidIdBool = *const fn (Id, Sel, Id, bool) callconv(.c) void;
const MsgVoidIdId = *const fn (Id, Sel, Id, Id) callconv(.c) void;
const MsgVoidInteger = *const fn (Id, Sel, NSInteger) callconv(.c) void;
const MsgVoidSel = *const fn (Id, Sel, Sel) callconv(.c) void;
const MsgVoidSize = *const fn (Id, Sel, NSSize) callconv(.c) void;
const MsgVoidUInteger = *const fn (Id, Sel, NSUInteger) callconv(.c) void;
const MsgWindowInit = *const fn (Id, Sel, NSRect, NSUInteger, NSUInteger, bool) callconv(.c) Id;

const objc_msgSend_id = @extern(MsgId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_id = @extern(MsgIdId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_id_id = @extern(MsgIdIdId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_cstring = @extern(MsgIdCString, .{ .name = "objc_msgSend" });
const objc_msgSend_id_rect = @extern(MsgIdRect, .{ .name = "objc_msgSend" });
const objc_msgSend_id_sel_id = @extern(MsgIdSelId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_double = @extern(MsgIdDouble, .{ .name = "objc_msgSend" });
const objc_msgSend_id_uinteger = @extern(MsgIdUInteger, .{ .name = "objc_msgSend" });
const objc_msgSend_integer = @extern(MsgInteger, .{ .name = "objc_msgSend" });
const objc_msgSend_rect = @extern(MsgRect, .{ .name = "objc_msgSend" });
const objc_msgSend_cstring_return = @extern(MsgCStringReturn, .{ .name = "objc_msgSend" });
const objc_msgSend_void = @extern(MsgVoid, .{ .name = "objc_msgSend" });
const objc_msgSend_void_bool = @extern(MsgVoidBool, .{ .name = "objc_msgSend" });
const objc_msgSend_void_double = @extern(MsgVoidDouble, .{ .name = "objc_msgSend" });
const objc_msgSend_void_double_integer = @extern(MsgVoidDoubleInteger, .{ .name = "objc_msgSend" });
const objc_msgSend_void_id = @extern(MsgVoidId, .{ .name = "objc_msgSend" });
const objc_msgSend_void_id_bool = @extern(MsgVoidIdBool, .{ .name = "objc_msgSend" });
const objc_msgSend_void_id_id = @extern(MsgVoidIdId, .{ .name = "objc_msgSend" });
const objc_msgSend_void_integer = @extern(MsgVoidInteger, .{ .name = "objc_msgSend" });
const objc_msgSend_void_sel = @extern(MsgVoidSel, .{ .name = "objc_msgSend" });
const objc_msgSend_void_size = @extern(MsgVoidSize, .{ .name = "objc_msgSend" });
const objc_msgSend_void_uinteger = @extern(MsgVoidUInteger, .{ .name = "objc_msgSend" });
const objc_msgSend_window_init = @extern(MsgWindowInit, .{ .name = "objc_msgSend" });

/// Returns an Objective-C class by name or panics if the class is unavailable.
pub fn getClass(name: [:0]const u8) Class {
    return objc_getClass(name.ptr) orelse @panic("Objective-C class not found");
}

/// Returns an Objective-C class by name, or null when it has not been registered.
pub fn maybeClass(name: [:0]const u8) ?Class {
    return objc_getClass(name.ptr);
}

/// Returns an Objective-C class pointer cast to `Id` for class-method sends.
pub fn class(name: [:0]const u8) Id {
    return @ptrCast(getClass(name));
}

/// Registers or retrieves a selector for an Objective-C method name.
pub fn selector(name: [:0]const u8) Sel {
    return sel_registerName(name.ptr);
}

/// Allocates a runtime subclass with no extra instance storage.
pub fn allocateClassPair(superclass: Class, name: [:0]const u8) Class {
    return objc_allocateClassPair(superclass, name.ptr, 0) orelse @panic("could not allocate Objective-C class");
}

/// Makes a dynamically allocated class visible to the Objective-C runtime.
pub fn registerClassPair(cls: Class) void {
    objc_registerClassPair(cls);
}

/// Adds one method implementation to a runtime class.
pub fn addMethod(cls: Class, name: [:0]const u8, imp: Imp, types: [:0]const u8) bool {
    return class_addMethod(cls, selector(name), imp, types.ptr);
}

/// Sends a no-argument Objective-C message returning an object.
pub fn msg(receiver: Id, sel: [:0]const u8) Id {
    return objc_msgSend_id(receiver, selector(sel));
}

/// Sends a one-object-argument Objective-C message returning an object.
pub fn msgId(receiver: Id, sel: [:0]const u8, arg: Id) Id {
    return objc_msgSend_id_id(receiver, selector(sel), arg);
}

/// Sends a two-object-argument Objective-C message returning an object.
pub fn msgIdId(receiver: Id, sel: [:0]const u8, a: Id, b: Id) Id {
    return objc_msgSend_id_id_id(receiver, selector(sel), a, b);
}

/// Sends an object, selector, object message returning an object.
pub fn msgIdSelId(receiver: Id, sel: [:0]const u8, a: Id, b: Sel, c: Id) Id {
    return objc_msgSend_id_sel_id(receiver, selector(sel), a, b, c);
}

/// Sends one double argument returning an object.
pub fn msgDouble(receiver: Id, sel: [:0]const u8, arg: f64) Id {
    return objc_msgSend_id_double(receiver, selector(sel), arg);
}

/// Sends a null-terminated UTF-8 C string argument returning an object.
pub fn msgCString(receiver: Id, sel: [:0]const u8, arg: [*:0]const u8) Id {
    return objc_msgSend_id_cstring(receiver, selector(sel), arg);
}

/// Sends an `NSRect` argument returning an object.
pub fn msgRectArg(receiver: Id, sel: [:0]const u8, arg: NSRect) Id {
    return objc_msgSend_id_rect(receiver, selector(sel), arg);
}

/// Sends an `NSUInteger` argument returning an object.
pub fn msgUInteger(receiver: Id, sel: [:0]const u8, arg: NSUInteger) Id {
    return objc_msgSend_id_uinteger(receiver, selector(sel), arg);
}

/// Sends a no-argument Objective-C message returning an `NSInteger`.
pub fn msgInteger(receiver: Id, sel: [:0]const u8) NSInteger {
    return objc_msgSend_integer(receiver, selector(sel));
}

/// Sends a no-argument Objective-C message returning an `NSRect`.
pub fn msgRect(receiver: Id, sel: [:0]const u8) NSRect {
    return objc_msgSend_rect(receiver, selector(sel));
}

/// Sends a no-argument Objective-C message returning a UTF-8 C string pointer.
pub fn msgCStringReturn(receiver: Id, sel: [:0]const u8) [*:0]const u8 {
    return objc_msgSend_cstring_return(receiver, selector(sel));
}

/// Sends a no-argument Objective-C message returning void.
pub fn msgVoid(receiver: Id, sel: [:0]const u8) void {
    objc_msgSend_void(receiver, selector(sel));
}

/// Sends a boolean argument returning void.
pub fn msgVoidBool(receiver: Id, sel: [:0]const u8, arg: bool) void {
    objc_msgSend_void_bool(receiver, selector(sel), arg);
}

/// Sends a double argument returning void.
pub fn msgVoidDouble(receiver: Id, sel: [:0]const u8, arg: f64) void {
    objc_msgSend_void_double(receiver, selector(sel), arg);
}

/// Sends a double and `NSInteger` argument pair returning void.
pub fn msgVoidDoubleInteger(receiver: Id, sel: [:0]const u8, a: f64, b: NSInteger) void {
    objc_msgSend_void_double_integer(receiver, selector(sel), a, b);
}

/// Sends one object argument returning void.
pub fn msgVoidId(receiver: Id, sel: [:0]const u8, arg: Id) void {
    objc_msgSend_void_id(receiver, selector(sel), arg);
}

/// Sends an object and boolean argument pair returning void.
pub fn msgVoidIdBool(receiver: Id, sel: [:0]const u8, a: Id, b: bool) void {
    objc_msgSend_void_id_bool(receiver, selector(sel), a, b);
}

/// Sends two object arguments returning void.
pub fn msgVoidIdId(receiver: Id, sel: [:0]const u8, a: Id, b: Id) void {
    objc_msgSend_void_id_id(receiver, selector(sel), a, b);
}

/// Sends one `NSInteger` argument returning void.
pub fn msgVoidInteger(receiver: Id, sel: [:0]const u8, arg: NSInteger) void {
    objc_msgSend_void_integer(receiver, selector(sel), arg);
}

/// Sends one selector argument returning void.
pub fn msgVoidSel(receiver: Id, sel: [:0]const u8, arg: Sel) void {
    objc_msgSend_void_sel(receiver, selector(sel), arg);
}

/// Sends one `NSSize` argument returning void.
pub fn msgVoidSize(receiver: Id, sel: [:0]const u8, arg: NSSize) void {
    objc_msgSend_void_size(receiver, selector(sel), arg);
}

/// Sends one `NSUInteger` argument returning void.
pub fn msgVoidUInteger(receiver: Id, sel: [:0]const u8, arg: NSUInteger) void {
    objc_msgSend_void_uinteger(receiver, selector(sel), arg);
}

/// Sends `-[NSWindow initWithContentRect:styleMask:backing:defer:]`.
pub fn msgWindowInit(receiver: Id, sel: [:0]const u8, rect: NSRect, style: NSUInteger, backing: NSUInteger, defer_window: bool) Id {
    return objc_msgSend_window_init(receiver, selector(sel), rect, style, backing, defer_window);
}
