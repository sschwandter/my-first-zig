//! AppKit constants and lifecycle helpers used by Zig Notes.
//!
//! Keeping these names in one place avoids scattering raw macOS numeric flags
//! through the UI construction modules.

const rt = @import("runtime.zig");

/// `NSApplicationActivationPolicyRegular` for a normal Dock/menu-bar app.
pub const activation_policy_regular: rt.NSInteger = 0;
/// `NSBackingStoreBuffered`, the standard backing store for windows.
pub const backing_store_buffered: rt.NSUInteger = 2;

/// Window style bit for a titled window.
pub const window_style_titled: rt.NSUInteger = 1 << 0;
/// Window style bit for a close button.
pub const window_style_closable: rt.NSUInteger = 1 << 1;
/// Window style bit for a minimize button.
pub const window_style_miniaturizable: rt.NSUInteger = 1 << 2;
/// Window style bit for user resizing.
pub const window_style_resizable: rt.NSUInteger = 1 << 3;

/// Autoresizing mask bit allowing width changes with the parent view.
pub const view_width_sizable: rt.NSUInteger = 1 << 1;
/// Autoresizing mask bit allowing height changes with the parent view.
pub const view_height_sizable: rt.NSUInteger = 1 << 4;
/// Border type for views that should visually merge with the window.
pub const no_border: rt.NSInteger = 0;
/// Toolbar display mode showing both SF Symbol icons and labels.
pub const toolbar_display_mode_icon_and_label: rt.NSInteger = 1;
/// Unified window toolbar style used by modern document-style apps.
pub const window_toolbar_style_unified: rt.NSInteger = 1;
/// Source-list table style for sidebar-like lists.
pub const table_style_source_list: rt.NSInteger = 1;
/// Source-list selection highlight style for sidebar rows.
pub const table_selection_highlight_style_source_list: rt.NSInteger = 1;

/// Returns the singleton `NSApplication` instance.
pub fn sharedApplication() rt.Id {
    return rt.msg(rt.class("NSApplication"), "sharedApplication");
}

/// Allocates and initializes an AppKit class using `+new`.
pub fn allocInit(comptime class_name: [:0]const u8) rt.Id {
    return rt.msg(rt.class(class_name), "new");
}

/// Finalizes launch activation and enters AppKit's run loop.
pub fn runApplication(app: rt.Id) void {
    rt.msgVoid(app, "finishLaunching");
    rt.msgVoidBool(app, "activateIgnoringOtherApps:", true);
    rt.msgVoid(app, "run");
}
