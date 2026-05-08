const rt = @import("runtime.zig");

pub fn nsString(text: [:0]const u8) rt.Id {
    return rt.msgCString(rt.class("NSString"), "stringWithUTF8String:", text.ptr);
}

pub fn indexSetWithIndex(index: usize) rt.Id {
    return rt.msgUInteger(rt.class("NSIndexSet"), "indexSetWithIndex:", index);
}

pub fn utf8String(string: rt.Id) [*:0]const u8 {
    return rt.msgCStringReturn(string, "UTF8String");
}
