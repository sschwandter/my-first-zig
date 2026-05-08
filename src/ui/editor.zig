const appkit = @import("../cocoa/appkit.zig");
const rt = @import("../cocoa/runtime.zig");

pub const Editor = struct {
    scroll_view: rt.Id,
    text_view: rt.Id,
};

pub fn build(frame: rt.NSRect, delegate: rt.Id) Editor {
    const scroll = rt.msgRectArg(rt.msg(rt.class("NSScrollView"), "alloc"), "initWithFrame:", frame);
    rt.msgVoidBool(scroll, "setHasVerticalScroller:", true);
    rt.msgVoidUInteger(scroll, "setAutoresizingMask:", appkit.view_width_sizable | appkit.view_height_sizable);

    const text = rt.msgRectArg(rt.msg(rt.class("NSTextView"), "alloc"), "initWithFrame:", frame);
    rt.msgVoidBool(text, "setRichText:", false);
    rt.msgVoidBool(text, "setUsesFontPanel:", false);
    rt.msgVoidBool(text, "setAutomaticQuoteSubstitutionEnabled:", false);
    rt.msgVoidBool(text, "setAutomaticDashSubstitutionEnabled:", false);
    rt.msgVoidId(text, "setDelegate:", delegate);
    rt.msgVoidId(scroll, "setDocumentView:", text);

    return .{ .scroll_view = scroll, .text_view = text };
}
