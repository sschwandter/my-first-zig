const appkit = @import("../cocoa/appkit.zig");
const foundation = @import("../cocoa/foundation.zig");
const rt = @import("../cocoa/runtime.zig");
const AppController = @import("app_controller.zig").AppController;
const editor = @import("editor.zig");
const notes_sidebar = @import("notes_sidebar.zig");

pub fn build(controller: *AppController, delegate: rt.Id) void {
    const style = appkit.window_style_titled |
        appkit.window_style_closable |
        appkit.window_style_miniaturizable |
        appkit.window_style_resizable;
    const frame = rt.NSRect{ .origin = .{ .x = 0, .y = 0 }, .size = .{ .width = 860, .height = 560 } };

    const window = rt.msgWindowInit(
        rt.msg(rt.class("NSWindow"), "alloc"),
        "initWithContentRect:styleMask:backing:defer:",
        frame,
        style,
        appkit.backing_store_buffered,
        false,
    );
    rt.msgVoidId(window, "setTitle:", foundation.nsString("Zig Notes"));
    rt.msgVoid(window, "center");

    const content_view = rt.msg(window, "contentView");
    const bounds = rt.msgRect(content_view, "bounds");
    const split_view = rt.msgRectArg(rt.msg(rt.class("NSSplitView"), "alloc"), "initWithFrame:", bounds);
    rt.msgVoidBool(split_view, "setVertical:", true);
    rt.msgVoidUInteger(split_view, "setAutoresizingMask:", appkit.view_width_sizable | appkit.view_height_sizable);

    const sidebar_frame = rt.NSRect{ .origin = .{ .x = 0, .y = 0 }, .size = .{ .width = 220, .height = bounds.size.height } };
    const editor_frame = rt.NSRect{ .origin = .{ .x = 0, .y = 0 }, .size = .{ .width = bounds.size.width - 220, .height = bounds.size.height } };

    const sidebar = notes_sidebar.build(sidebar_frame, delegate);
    const note_editor = editor.build(editor_frame, delegate);
    controller.setViews(sidebar.table_view, note_editor.text_view);

    rt.msgVoidId(split_view, "addSubview:", sidebar.scroll_view);
    rt.msgVoidId(split_view, "addSubview:", note_editor.scroll_view);
    rt.msgVoidDoubleInteger(split_view, "setPosition:ofDividerAtIndex:", 220, 0);
    rt.msgVoidId(content_view, "addSubview:", split_view);
    rt.msgVoidId(window, "makeKeyAndOrderFront:", window);
}
