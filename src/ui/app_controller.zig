//! Application behavior controller for Zig Notes.
//!
//! This module is the boundary between AppKit callbacks and note-domain logic.
//! It owns the current note list, selected note, view references, and user
//! actions such as create, delete, select, and save.

const std = @import("std");

const foundation = @import("../cocoa/foundation.zig");
const rt = @import("../cocoa/runtime.zig");
const Note = @import("../notes/note.zig").Note;
const note = @import("../notes/note.zig");
const note_title = @import("../notes/note_title.zig");
const NoteStore = @import("../notes/note_store.zig").NoteStore;
const toolbar = @import("toolbar.zig");

/// Coordinates note storage, in-memory selection state, and AppKit view updates.
pub const AppController = struct {
    allocator: std.mem.Allocator,
    store: NoteStore,
    notes: std.ArrayList(Note) = .empty,
    selected_index: ?usize = null,
    table_view: ?rt.Id = null,
    text_view: ?rt.Id = null,
    delegate: ?rt.Id = null,
    suppress_text_change: bool = false,

    /// Creates a controller around an already opened note store.
    pub fn init(allocator: std.mem.Allocator, store: NoteStore) AppController {
        return .{ .allocator = allocator, .store = store };
    }

    /// Releases loaded notes and closes the underlying note store.
    pub fn deinit(self: *AppController) void {
        for (self.notes.items) |item| item.deinit(self.allocator);
        self.notes.deinit(self.allocator);
        self.store.deinit();
    }

    /// Loads notes from disk and creates the welcome note when the directory is empty.
    pub fn loadInitialNotes(self: *AppController) !void {
        try self.store.load(self.allocator, &self.notes);
        note.sortByTitle(self.notes.items);
        if (self.notes.items.len == 0) try self.createNote("Welcome");
    }

    /// Attaches the AppKit views the controller must refresh or read from.
    pub fn setViews(self: *AppController, table_view: rt.Id, text_view: rt.Id) void {
        self.table_view = table_view;
        self.text_view = text_view;
    }

    /// Creates a new empty note using the first available numbered title.
    pub fn createNote(self: *AppController, base_title: []const u8) !void {
        var n: usize = 1;
        while (true) : (n += 1) {
            const title = try note_title.candidateTitle(self.allocator, base_title, n);
            errdefer self.allocator.free(title);

            const filename = try note_title.filenameFromTitle(self.allocator, title);
            errdefer self.allocator.free(filename);

            if (self.indexOfFilename(filename) != null) {
                self.allocator.free(title);
                self.allocator.free(filename);
                continue;
            }

            try self.store.createEmpty(filename);
            try self.notes.append(self.allocator, .{ .title = title, .filename = filename });
            note.sortByTitle(self.notes.items);
            self.reloadSidebar();
            if (self.indexOfTitle(title)) |index| self.selectNote(index);
            return;
        }
    }

    /// Deletes the selected note and selects a neighboring note when possible.
    pub fn deleteSelectedNote(self: *AppController) void {
        const index = self.selected_index orelse return;
        if (index >= self.notes.items.len) return;

        const removed = self.notes.orderedRemove(index);
        self.store.delete(removed);
        removed.deinit(self.allocator);

        self.selected_index = null;
        self.reloadSidebar();

        if (self.notes.items.len == 0) {
            self.createNote("Welcome") catch return;
        } else {
            self.selectNote(@min(index, self.notes.items.len - 1));
        }
    }

    /// Selects a note, updates the sidebar selection, and loads text into the editor.
    pub fn selectNote(self: *AppController, index: usize) void {
        if (index >= self.notes.items.len) return;
        self.selected_index = index;

        if (self.table_view) |table| {
            const index_set = foundation.indexSetWithIndex(index);
            rt.msgVoidIdBool(table, "selectRowIndexes:byExtendingSelection:", index_set, false);
        }

        const contents = self.store.readAlloc(self.allocator, self.notes.items[index]) catch |err| {
            std.log.err("failed to read note: {t}", .{err});
            return;
        };
        defer self.allocator.free(contents);

        if (self.text_view) |text_view| {
            const text_z = self.allocator.dupeZ(u8, contents) catch return;
            defer self.allocator.free(text_z);
            self.suppress_text_change = true;
            rt.msgVoidId(text_view, "setString:", foundation.nsString(text_z));
            self.suppress_text_change = false;
        }
    }

    /// Saves the selected note from the current `NSTextView` contents.
    pub fn saveSelectedNote(self: *AppController) void {
        if (self.suppress_text_change) return;
        const index = self.selected_index orelse return;
        if (index >= self.notes.items.len) return;
        const text_view = self.text_view orelse return;

        const string = rt.msg(text_view, "string");
        const text = std.mem.span(foundation.utf8String(string));
        self.store.save(self.notes.items[index], text) catch |err| {
            std.log.err("failed to save note: {t}", .{err});
        };
    }

    /// Returns the number of rows the sidebar table should display.
    pub fn numberOfRows(self: *AppController) rt.NSInteger {
        return @intCast(self.notes.items.len);
    }

    /// Returns the display title object for a sidebar table row.
    pub fn titleForRow(self: *AppController, row: rt.NSInteger) rt.Id {
        if (row < 0) return foundation.nsString("");
        const index: usize = @intCast(row);
        if (index >= self.notes.items.len) return foundation.nsString("");
        return foundation.nsString(self.notes.items[index].title);
    }

    /// Reads the selected row from `NSTableView` and selects the matching note.
    pub fn selectRowFromTable(self: *AppController) void {
        const table = self.table_view orelse return;
        const row = rt.msgInteger(table, "selectedRow");
        if (row < 0) return;
        self.selectNote(@intCast(row));
    }

    fn reloadSidebar(self: *AppController) void {
        if (self.table_view) |table| rt.msgVoid(table, "reloadData");
    }

    fn indexOfFilename(self: *AppController, filename: []const u8) ?usize {
        for (self.notes.items, 0..) |item, i| {
            if (std.mem.eql(u8, item.filename, filename)) return i;
        }
        return null;
    }

    fn indexOfTitle(self: *AppController, title: []const u8) ?usize {
        for (self.notes.items, 0..) |item, i| {
            if (std.mem.eql(u8, item.title, title)) return i;
        }
        return null;
    }
};

var current_controller: ?*AppController = null;

/// Sets the controller used by Objective-C callback trampolines.
pub fn setCurrent(controller: *AppController) void {
    current_controller = controller;
}

/// Returns the controller currently serving Objective-C callbacks.
pub fn current() ?*AppController {
    return current_controller;
}

/// Objective-C action trampoline for `File > New Note`.
pub fn newNoteAction(_: rt.Id, _: rt.Sel, _: rt.Id) callconv(.c) void {
    if (current()) |controller| controller.createNote("Untitled") catch |err| {
        std.log.err("failed to create note: {t}", .{err});
    };
}

/// Objective-C action trampoline for `File > Delete Note`.
pub fn deleteNoteAction(_: rt.Id, _: rt.Sel, _: rt.Id) callconv(.c) void {
    if (current()) |controller| controller.deleteSelectedNote();
}

/// Objective-C data-source trampoline returning the sidebar row count.
pub fn numberOfRowsInTableView(_: rt.Id, _: rt.Sel, _: rt.Id) callconv(.c) rt.NSInteger {
    const controller = current() orelse return 0;
    return controller.numberOfRows();
}

/// Objective-C data-source trampoline returning a note title for one sidebar row.
pub fn tableObjectValue(_: rt.Id, _: rt.Sel, _: rt.Id, _: rt.Id, row: rt.NSInteger) callconv(.c) rt.Id {
    const controller = current() orelse return foundation.nsString("");
    return controller.titleForRow(row);
}

/// Objective-C delegate trampoline for sidebar selection changes.
pub fn tableSelectionDidChange(_: rt.Id, _: rt.Sel, _: rt.Id) callconv(.c) void {
    if (current()) |controller| controller.selectRowFromTable();
}

/// Objective-C delegate trampoline for editor text changes.
pub fn textDidChange(_: rt.Id, _: rt.Sel, _: rt.Id) callconv(.c) void {
    if (current()) |controller| controller.saveSelectedNote();
}

/// Objective-C toolbar delegate trampoline returning all supported toolbar identifiers.
pub fn toolbarAllowedItemIdentifiers(_: rt.Id, _: rt.Sel, _: rt.Id) callconv(.c) rt.Id {
    return toolbar.itemIdentifiers();
}

/// Objective-C toolbar delegate trampoline returning the default toolbar identifiers.
pub fn toolbarDefaultItemIdentifiers(_: rt.Id, _: rt.Sel, _: rt.Id) callconv(.c) rt.Id {
    return toolbar.itemIdentifiers();
}

/// Objective-C toolbar delegate trampoline creating an item for one identifier.
pub fn toolbarItemForIdentifier(delegate: rt.Id, _: rt.Sel, _: rt.Id, item_identifier: rt.Id, _: bool) callconv(.c) rt.Id {
    return toolbar.itemForIdentifier(delegate, item_identifier);
}
