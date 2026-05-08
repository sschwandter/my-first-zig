//! Runtime registration for the Objective-C delegate class.
//!
//! AppKit calls Objective-C selectors for menu actions, table data source
//! methods, selection changes, and text changes. This module creates a small
//! NSObject subclass and maps those selectors to Zig callback functions.

const rt = @import("runtime.zig");

/// Callback shape for action and notification selectors that pass one object.
pub const ActionCallback = *const fn (rt.Id, rt.Sel, rt.Id) callconv(.c) void;
/// Callback shape for `numberOfRowsInTableView:`.
pub const NumberRowsCallback = *const fn (rt.Id, rt.Sel, rt.Id) callconv(.c) rt.NSInteger;
/// Callback shape for `tableView:objectValueForTableColumn:row:`.
pub const ObjectValueCallback = *const fn (rt.Id, rt.Sel, rt.Id, rt.Id, rt.NSInteger) callconv(.c) rt.Id;

/// Complete callback table required by the Zig Notes Objective-C delegate.
pub const Callbacks = struct {
    new_note: ActionCallback,
    delete_note: ActionCallback,
    number_of_rows: NumberRowsCallback,
    object_value: ObjectValueCallback,
    selection_did_change: ActionCallback,
    text_did_change: ActionCallback,
};

/// Registers the `ZigNotesDelegate` class if it has not been registered yet.
pub fn register(callbacks: Callbacks) void {
    if (rt.maybeClass("ZigNotesDelegate") != null) return;

    const cls = rt.allocateClassPair(rt.getClass("NSObject"), "ZigNotesDelegate");
    _ = rt.addMethod(cls, "newNote:", @ptrCast(callbacks.new_note), "v@:@");
    _ = rt.addMethod(cls, "deleteNote:", @ptrCast(callbacks.delete_note), "v@:@");
    _ = rt.addMethod(cls, "numberOfRowsInTableView:", @ptrCast(callbacks.number_of_rows), "q@:@");
    _ = rt.addMethod(cls, "tableView:objectValueForTableColumn:row:", @ptrCast(callbacks.object_value), "@@:@@q");
    _ = rt.addMethod(cls, "tableViewSelectionDidChange:", @ptrCast(callbacks.selection_did_change), "v@:@");
    _ = rt.addMethod(cls, "textDidChange:", @ptrCast(callbacks.text_did_change), "v@:@");
    rt.registerClassPair(cls);
}

/// Creates an instance of the registered `ZigNotesDelegate` class.
pub fn create() rt.Id {
    return rt.msg(rt.class("ZigNotesDelegate"), "new");
}
