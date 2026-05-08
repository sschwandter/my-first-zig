const rt = @import("runtime.zig");

pub const ActionCallback = *const fn (rt.Id, rt.Sel, rt.Id) callconv(.c) void;
pub const NumberRowsCallback = *const fn (rt.Id, rt.Sel, rt.Id) callconv(.c) rt.NSInteger;
pub const ObjectValueCallback = *const fn (rt.Id, rt.Sel, rt.Id, rt.Id, rt.NSInteger) callconv(.c) rt.Id;

pub const Callbacks = struct {
    new_note: ActionCallback,
    delete_note: ActionCallback,
    number_of_rows: NumberRowsCallback,
    object_value: ObjectValueCallback,
    selection_did_change: ActionCallback,
    text_did_change: ActionCallback,
};

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

pub fn create() rt.Id {
    return rt.msg(rt.class("ZigNotesDelegate"), "new");
}
