pub const Id = *opaque {};
pub const Class = *opaque {};
pub const Sel = *opaque {};
pub const Imp = *const anyopaque;

pub const NSUInteger = usize;
pub const NSInteger = isize;

pub const NSPoint = extern struct { x: f64, y: f64 };
pub const NSSize = extern struct { width: f64, height: f64 };
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
const MsgVoidUInteger = *const fn (Id, Sel, NSUInteger) callconv(.c) void;
const MsgWindowInit = *const fn (Id, Sel, NSRect, NSUInteger, NSUInteger, bool) callconv(.c) Id;

const objc_msgSend_id = @extern(MsgId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_id = @extern(MsgIdId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_id_id = @extern(MsgIdIdId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_cstring = @extern(MsgIdCString, .{ .name = "objc_msgSend" });
const objc_msgSend_id_rect = @extern(MsgIdRect, .{ .name = "objc_msgSend" });
const objc_msgSend_id_sel_id = @extern(MsgIdSelId, .{ .name = "objc_msgSend" });
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
const objc_msgSend_void_uinteger = @extern(MsgVoidUInteger, .{ .name = "objc_msgSend" });
const objc_msgSend_window_init = @extern(MsgWindowInit, .{ .name = "objc_msgSend" });

pub fn getClass(name: [:0]const u8) Class {
    return objc_getClass(name.ptr) orelse @panic("Objective-C class not found");
}

pub fn maybeClass(name: [:0]const u8) ?Class {
    return objc_getClass(name.ptr);
}

pub fn class(name: [:0]const u8) Id {
    return @ptrCast(getClass(name));
}

pub fn selector(name: [:0]const u8) Sel {
    return sel_registerName(name.ptr);
}

pub fn allocateClassPair(superclass: Class, name: [:0]const u8) Class {
    return objc_allocateClassPair(superclass, name.ptr, 0) orelse @panic("could not allocate Objective-C class");
}

pub fn registerClassPair(cls: Class) void {
    objc_registerClassPair(cls);
}

pub fn addMethod(cls: Class, name: [:0]const u8, imp: Imp, types: [:0]const u8) bool {
    return class_addMethod(cls, selector(name), imp, types.ptr);
}

pub fn msg(receiver: Id, sel: [:0]const u8) Id {
    return objc_msgSend_id(receiver, selector(sel));
}

pub fn msgId(receiver: Id, sel: [:0]const u8, arg: Id) Id {
    return objc_msgSend_id_id(receiver, selector(sel), arg);
}

pub fn msgIdId(receiver: Id, sel: [:0]const u8, a: Id, b: Id) Id {
    return objc_msgSend_id_id_id(receiver, selector(sel), a, b);
}

pub fn msgIdSelId(receiver: Id, sel: [:0]const u8, a: Id, b: Sel, c: Id) Id {
    return objc_msgSend_id_sel_id(receiver, selector(sel), a, b, c);
}

pub fn msgCString(receiver: Id, sel: [:0]const u8, arg: [*:0]const u8) Id {
    return objc_msgSend_id_cstring(receiver, selector(sel), arg);
}

pub fn msgRectArg(receiver: Id, sel: [:0]const u8, arg: NSRect) Id {
    return objc_msgSend_id_rect(receiver, selector(sel), arg);
}

pub fn msgUInteger(receiver: Id, sel: [:0]const u8, arg: NSUInteger) Id {
    return objc_msgSend_id_uinteger(receiver, selector(sel), arg);
}

pub fn msgInteger(receiver: Id, sel: [:0]const u8) NSInteger {
    return objc_msgSend_integer(receiver, selector(sel));
}

pub fn msgRect(receiver: Id, sel: [:0]const u8) NSRect {
    return objc_msgSend_rect(receiver, selector(sel));
}

pub fn msgCStringReturn(receiver: Id, sel: [:0]const u8) [*:0]const u8 {
    return objc_msgSend_cstring_return(receiver, selector(sel));
}

pub fn msgVoid(receiver: Id, sel: [:0]const u8) void {
    objc_msgSend_void(receiver, selector(sel));
}

pub fn msgVoidBool(receiver: Id, sel: [:0]const u8, arg: bool) void {
    objc_msgSend_void_bool(receiver, selector(sel), arg);
}

pub fn msgVoidDouble(receiver: Id, sel: [:0]const u8, arg: f64) void {
    objc_msgSend_void_double(receiver, selector(sel), arg);
}

pub fn msgVoidDoubleInteger(receiver: Id, sel: [:0]const u8, a: f64, b: NSInteger) void {
    objc_msgSend_void_double_integer(receiver, selector(sel), a, b);
}

pub fn msgVoidId(receiver: Id, sel: [:0]const u8, arg: Id) void {
    objc_msgSend_void_id(receiver, selector(sel), arg);
}

pub fn msgVoidIdBool(receiver: Id, sel: [:0]const u8, a: Id, b: bool) void {
    objc_msgSend_void_id_bool(receiver, selector(sel), a, b);
}

pub fn msgVoidIdId(receiver: Id, sel: [:0]const u8, a: Id, b: Id) void {
    objc_msgSend_void_id_id(receiver, selector(sel), a, b);
}

pub fn msgVoidInteger(receiver: Id, sel: [:0]const u8, arg: NSInteger) void {
    objc_msgSend_void_integer(receiver, selector(sel), arg);
}

pub fn msgVoidUInteger(receiver: Id, sel: [:0]const u8, arg: NSUInteger) void {
    objc_msgSend_void_uinteger(receiver, selector(sel), arg);
}

pub fn msgWindowInit(receiver: Id, sel: [:0]const u8, rect: NSRect, style: NSUInteger, backing: NSUInteger, defer_window: bool) Id {
    return objc_msgSend_window_init(receiver, selector(sel), rect, style, backing, defer_window);
}
