//! Toolbar construction and item factories.
//!
//! The `NSToolbar` delegate callbacks live in `app_controller.zig`, but this
//! module owns item identifiers and the native toolbar item configuration.

const std = @import("std");

const appkit = @import("../cocoa/appkit.zig");
const foundation = @import("../cocoa/foundation.zig");
const rt = @import("../cocoa/runtime.zig");

const new_note_identifier = "zig-notes-new-note";
const delete_note_identifier = "zig-notes-delete-note";
const toggle_sidebar_identifier = "zig-notes-toggle-sidebar";

/// Creates and attaches the main window toolbar.
pub fn attach(window: rt.Id, delegate: rt.Id) void {
    const toolbar = rt.msgId(rt.msg(rt.class("NSToolbar"), "alloc"), "initWithIdentifier:", foundation.nsString("ZigNotesToolbar"));
    rt.msgVoidId(toolbar, "setDelegate:", delegate);
    rt.msgVoidBool(toolbar, "setAllowsUserCustomization:", false);
    rt.msgVoidBool(toolbar, "setAutosavesConfiguration:", false);
    rt.msgVoidInteger(toolbar, "setDisplayMode:", appkit.toolbar_display_mode_icon_and_label);
    rt.msgVoidId(window, "setToolbar:", toolbar);
}

/// Returns the toolbar identifiers that Zig Notes supports.
pub fn itemIdentifiers() rt.Id {
    const identifiers = rt.msg(rt.class("NSMutableArray"), "new");
    rt.msgVoidId(identifiers, "addObject:", foundation.nsString(toggle_sidebar_identifier));
    rt.msgVoidId(identifiers, "addObject:", foundation.nsString("NSToolbarFlexibleSpaceItem"));
    rt.msgVoidId(identifiers, "addObject:", foundation.nsString(new_note_identifier));
    rt.msgVoidId(identifiers, "addObject:", foundation.nsString(delete_note_identifier));
    return identifiers;
}

/// Builds a configured `NSToolbarItem` for an identifier requested by AppKit.
pub fn itemForIdentifier(delegate: rt.Id, item_identifier: rt.Id) rt.Id {
    const identifier = std.mem.span(foundation.utf8String(item_identifier));
    if (std.mem.eql(u8, identifier, toggle_sidebar_identifier)) {
        return toolbarItem(item_identifier, delegate, .{
            .label = "Sidebar",
            .palette_label = "Toggle Sidebar",
            .tool_tip = "Hide or show the notes list",
            .symbol = "sidebar.left",
            .action = "toggleSidebar:",
        });
    }
    if (std.mem.eql(u8, identifier, new_note_identifier)) {
        return toolbarItem(item_identifier, delegate, .{
            .label = "New",
            .palette_label = "New Note",
            .tool_tip = "Create a new note",
            .symbol = "square.and.pencil",
            .action = "newNote:",
        });
    }
    if (std.mem.eql(u8, identifier, delete_note_identifier)) {
        return toolbarItem(item_identifier, delegate, .{
            .label = "Delete",
            .palette_label = "Delete Note",
            .tool_tip = "Delete the selected note",
            .symbol = "trash",
            .action = "deleteNote:",
        });
    }
    return toolbarItem(item_identifier, delegate, .{
        .label = "Note",
        .palette_label = "Note",
        .tool_tip = "Note action",
        .symbol = "doc.text",
        .action = "newNote:",
    });
}

const ToolbarItemOptions = struct {
    label: [:0]const u8,
    palette_label: [:0]const u8,
    tool_tip: [:0]const u8,
    symbol: [:0]const u8,
    action: [:0]const u8,
};

fn toolbarItem(identifier: rt.Id, target: rt.Id, options: ToolbarItemOptions) rt.Id {
    const item = rt.msgId(rt.msg(rt.class("NSToolbarItem"), "alloc"), "initWithItemIdentifier:", identifier);
    rt.msgVoidId(item, "setLabel:", foundation.nsString(options.label));
    rt.msgVoidId(item, "setPaletteLabel:", foundation.nsString(options.palette_label));
    rt.msgVoidId(item, "setToolTip:", foundation.nsString(options.tool_tip));
    rt.msgVoidId(item, "setTarget:", target);
    rt.msgVoidSel(item, "setAction:", rt.selector(options.action));

    const image = rt.msgIdId(
        rt.class("NSImage"),
        "imageWithSystemSymbolName:accessibilityDescription:",
        foundation.nsString(options.symbol),
        foundation.nsString(options.palette_label),
    );
    rt.msgVoidId(item, "setImage:", image);
    return item;
}
