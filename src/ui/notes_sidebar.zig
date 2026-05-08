//! Notes sidebar construction.
//!
//! Builds the scroll view and `NSTableView` that lists available note titles.

const appkit = @import("../cocoa/appkit.zig");
const foundation = @import("../cocoa/foundation.zig");
const rt = @import("../cocoa/runtime.zig");

/// AppKit objects that make up the note list sidebar.
pub const NotesSidebar = struct {
    scroll_view: rt.Id,
    table_view: rt.Id,
};

/// Creates a sidebar table and connects its data source and delegate.
pub fn build(frame: rt.NSRect, delegate: rt.Id) NotesSidebar {
    const glass_view = rt.msgRectArg(rt.msg(rt.class("NSGlassEffectView"), "alloc"), "initWithFrame:", frame);
    rt.msgVoidInteger(glass_view, "setStyle:", 0); // NSGlassEffectViewStyleRegular
    rt.msgVoidUInteger(glass_view, "setAutoresizingMask:", appkit.view_height_sizable);

    const scroll = rt.msgRectArg(rt.msg(rt.class("NSScrollView"), "alloc"), "initWithFrame:", frame);
    rt.msgVoidBool(scroll, "setHasVerticalScroller:", true);
    rt.msgVoidInteger(scroll, "setBorderType:", appkit.no_border);
    rt.msgVoidUInteger(scroll, "setAutoresizingMask:", appkit.view_width_sizable | appkit.view_height_sizable);
    rt.msgVoidId(scroll, "setBackgroundColor:", rt.msg(rt.class("NSColor"), "clearColor"));
    rt.msgVoidBool(scroll, "setDrawsBackground:", false);

    const table = rt.msgRectArg(rt.msg(rt.class("NSTableView"), "alloc"), "initWithFrame:", frame);
    const column = rt.msgId(rt.msg(rt.class("NSTableColumn"), "alloc"), "initWithIdentifier:", foundation.nsString("notes"));
    rt.msgVoidDouble(column, "setWidth:", frame.size.width);
    rt.msgVoidId(column, "setTitle:", foundation.nsString("Notes"));
    rt.msgVoidBool(column, "setEditable:", true);
    rt.msgVoidId(table, "addTableColumn:", column);
    rt.msgVoidId(table, "setDataSource:", delegate);
    rt.msgVoidId(table, "setDelegate:", delegate);
    rt.msgVoidId(table, "setHeaderView:", rt.nil);
    rt.msgVoidDouble(table, "setRowHeight:", 42);
    rt.msgVoidBool(table, "setUsesAlternatingRowBackgroundColors:", false);
    rt.msgVoidUInteger(table, "setGridStyleMask:", 0);
    rt.msgVoidInteger(table, "setSelectionHighlightStyle:", appkit.table_selection_highlight_style_source_list);
    rt.msgVoidInteger(table, "setStyle:", appkit.table_style_source_list);
    rt.msgVoidId(table, "setBackgroundColor:", rt.msg(rt.class("NSColor"), "clearColor"));
    rt.msgVoidId(scroll, "setDocumentView:", table);
    rt.msgVoidId(glass_view, "addSubview:", scroll);

    return .{ .scroll_view = glass_view, .table_view = table };
}
