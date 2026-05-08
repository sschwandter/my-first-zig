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
/// Window style bit allowing the content view to expand into the title bar area.
pub const window_style_full_size_content_view: rt.NSUInteger = 1 << 15;

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
/// Compact unified window toolbar style.
pub const window_toolbar_style_unified_compact: rt.NSInteger = 2;

/// Title visibility state that hides the window title while keeping it in menus.
pub const window_title_visibility_hidden: rt.NSInteger = 1;

/// Source-list table style for sidebar-like lists.
pub const table_style_source_list: rt.NSInteger = 1;
/// Source-list selection highlight style for sidebar rows.
pub const table_selection_highlight_style_source_list: rt.NSInteger = 1;

/// Sidebar visual effect material for translucent backgrounds.
pub const visual_effect_material_sidebar: rt.NSInteger = 3;
/// Modern refractive glass material introduced in macOS 26.
pub const visual_effect_material_glass: rt.NSInteger = 30;
/// Behind-window blending mode for visual effect views.
pub const visual_effect_blending_mode_behind_window: rt.NSInteger = 0;
/// Within-window blending mode for visual effect views.
pub const visual_effect_blending_mode_within_window: rt.NSInteger = 1;

/// Visual effect state that follows the window's active/inactive state.
pub const visual_effect_state_follows_window: rt.NSInteger = 0;

/// Thin divider style for split views.
pub const split_view_divider_style_thin: rt.NSInteger = 2;

/// Standard bezel style for buttons.
pub const bezel_style_rounded: rt.NSInteger = 1;
/// Modern glass bezel style for buttons.
pub const bezel_style_glass: rt.NSInteger = 15;

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
