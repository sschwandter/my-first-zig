const std = @import("std");

const appkit = @import("cocoa/appkit.zig");
const delegate_class = @import("cocoa/delegate.zig");
const rt = @import("cocoa/runtime.zig");
const NoteStore = @import("notes/note_store.zig").NoteStore;
const AppController = @import("ui/app_controller.zig").AppController;
const controller_callbacks = @import("ui/app_controller.zig");
const menu = @import("ui/menu.zig");
const window = @import("ui/window.zig");

pub fn run(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const store = try NoteStore.openDocuments(allocator, init.io);
    var controller = AppController.init(allocator, store);
    defer controller.deinit();
    controller_callbacks.setCurrent(&controller);

    delegate_class.register(.{
        .new_note = controller_callbacks.newNoteAction,
        .delete_note = controller_callbacks.deleteNoteAction,
        .number_of_rows = controller_callbacks.numberOfRowsInTableView,
        .object_value = controller_callbacks.tableObjectValue,
        .selection_did_change = controller_callbacks.tableSelectionDidChange,
        .text_did_change = controller_callbacks.textDidChange,
    });
    const delegate = delegate_class.create();
    controller.delegate = delegate;

    try controller.loadInitialNotes();

    const app = appkit.sharedApplication();
    rt.msgVoidInteger(app, "setActivationPolicy:", appkit.activation_policy_regular);
    rt.msgVoidId(app, "setDelegate:", delegate);

    menu.build(app, delegate);
    window.build(&controller, delegate);
    controller.selectNote(0);

    appkit.runApplication(app);
}
