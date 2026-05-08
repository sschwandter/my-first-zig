const appkit = @import("../cocoa/appkit.zig");
const foundation = @import("../cocoa/foundation.zig");
const rt = @import("../cocoa/runtime.zig");

pub const NotesSidebar = struct {
    scroll_view: rt.Id,
    table_view: rt.Id,
};

pub fn build(frame: rt.NSRect, delegate: rt.Id) NotesSidebar {
    const scroll = rt.msgRectArg(rt.msg(rt.class("NSScrollView"), "alloc"), "initWithFrame:", frame);
    rt.msgVoidBool(scroll, "setHasVerticalScroller:", true);
    rt.msgVoidUInteger(scroll, "setAutoresizingMask:", appkit.view_height_sizable);

    const table = rt.msgRectArg(rt.msg(rt.class("NSTableView"), "alloc"), "initWithFrame:", frame);
    const column = rt.msgId(rt.msg(rt.class("NSTableColumn"), "alloc"), "initWithIdentifier:", foundation.nsString("notes"));
    rt.msgVoidDouble(column, "setWidth:", 220);
    rt.msgVoidId(column, "setTitle:", foundation.nsString("Notes"));
    rt.msgVoidId(table, "addTableColumn:", column);
    rt.msgVoidId(table, "setDataSource:", delegate);
    rt.msgVoidId(table, "setDelegate:", delegate);
    rt.msgVoidId(scroll, "setDocumentView:", table);

    return .{ .scroll_view = scroll, .table_view = table };
}
