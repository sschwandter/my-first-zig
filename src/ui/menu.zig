//! Main menu construction.
//!
//! Builds the standard application menu and File menu, wiring menu items to
//! either `NSApplication` or the Zig Notes delegate object.

const appkit = @import("../cocoa/appkit.zig");
const foundation = @import("../cocoa/foundation.zig");
const rt = @import("../cocoa/runtime.zig");

/// Creates and installs the app menu bar for Zig Notes.
pub fn build(app: rt.Id, delegate: rt.Id) void {
    const menubar = appkit.allocInit("NSMenu");
    rt.msgVoidId(app, "setMainMenu:", menubar);

    const app_menu_item = appkit.allocInit("NSMenuItem");
    rt.msgVoidId(menubar, "addItem:", app_menu_item);
    const app_menu = initMenu("Zig Notes");
    rt.msgVoidIdId(menubar, "setSubmenu:forItem:", app_menu, app_menu_item);
    _ = menuItem(app_menu, "About Zig Notes", "orderFrontStandardAboutPanel:", "", app);
    rt.msgVoidId(app_menu, "addItem:", rt.msg(rt.class("NSMenuItem"), "separatorItem"));
    _ = menuItem(app_menu, "Hide Zig Notes", "hide:", "h", app);
    _ = menuItem(app_menu, "Quit Zig Notes", "terminate:", "q", app);

    const file_menu_item = appkit.allocInit("NSMenuItem");
    rt.msgVoidId(menubar, "addItem:", file_menu_item);
    const file_menu = initMenu("File");
    rt.msgVoidIdId(menubar, "setSubmenu:forItem:", file_menu, file_menu_item);
    _ = menuItem(file_menu, "New Note", "newNote:", "n", delegate);
    _ = menuItem(file_menu, "Delete Note", "deleteNote:", "", delegate);
}

fn initMenu(title: [:0]const u8) rt.Id {
    return rt.msgId(rt.msg(rt.class("NSMenu"), "alloc"), "initWithTitle:", foundation.nsString(title));
}

fn menuItem(menu: rt.Id, title: [:0]const u8, action: [:0]const u8, key: [:0]const u8, target: rt.Id) rt.Id {
    const item = rt.msgIdSelId(
        rt.msg(rt.class("NSMenuItem"), "alloc"),
        "initWithTitle:action:keyEquivalent:",
        foundation.nsString(title),
        rt.selector(action),
        foundation.nsString(key),
    );
    rt.msgVoidId(item, "setTarget:", target);
    rt.msgVoidId(menu, "addItem:", item);
    return item;
}
