//! Convenience wrappers for the small Foundation API surface Zig Notes uses.
//!
//! Higher-level code should use this module instead of sending raw Foundation
//! Objective-C messages for common conversions such as `NSString` creation.

const rt = @import("runtime.zig");

/// Creates an autoreleased `NSString` from a null-terminated UTF-8 string.
pub fn nsString(text: [:0]const u8) rt.Id {
    return rt.msgCString(rt.class("NSString"), "stringWithUTF8String:", text.ptr);
}

/// Creates an `NSIndexSet` containing one row index for table selection.
pub fn indexSetWithIndex(index: usize) rt.Id {
    return rt.msgUInteger(rt.class("NSIndexSet"), "indexSetWithIndex:", index);
}

/// Returns Foundation's UTF-8 view of an `NSString`.
pub fn utf8String(string: rt.Id) [*:0]const u8 {
    return rt.msgCStringReturn(string, "UTF8String");
}
