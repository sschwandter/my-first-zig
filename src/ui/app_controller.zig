const std = @import("std");

const foundation = @import("../cocoa/foundation.zig");
const rt = @import("../cocoa/runtime.zig");
const Note = @import("../notes/note.zig").Note;
const note = @import("../notes/note.zig");
const note_title = @import("../notes/note_title.zig");
const NoteStore = @import("../notes/note_store.zig").NoteStore;

pub const AppController = struct {
    allocator: std.mem.Allocator,
    store: NoteStore,
    notes: std.ArrayList(Note) = .empty,
    selected_index: ?usize = null,
    table_view: ?rt.Id = null,
    text_view: ?rt.Id = null,
    delegate: ?rt.Id = null,
    suppress_text_change: bool = false,

    pub fn init(allocator: std.mem.Allocator, store: NoteStore) AppController {
        return .{ .allocator = allocator, .store = store };
    }

    pub fn deinit(self: *AppController) void {
        for (self.notes.items) |item| item.deinit(self.allocator);
        self.notes.deinit(self.allocator);
        self.store.deinit();
    }

    pub fn loadInitialNotes(self: *AppController) !void {
        try self.store.load(self.allocator, &self.notes);
        note.sortByTitle(self.notes.items);
        if (self.notes.items.len == 0) try self.createNote("Welcome");
    }

    pub fn setViews(self: *AppController, table_view: rt.Id, text_view: rt.Id) void {
        self.table_view = table_view;
        self.text_view = text_view;
    }

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

    pub fn numberOfRows(self: *AppController) rt.NSInteger {
        return @intCast(self.notes.items.len);
    }

    pub fn titleForRow(self: *AppController, row: rt.NSInteger) rt.Id {
        if (row < 0) return foundation.nsString("");
        const index: usize = @intCast(row);
        if (index >= self.notes.items.len) return foundation.nsString("");
        return foundation.nsString(self.notes.items[index].title);
    }

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

pub fn setCurrent(controller: *AppController) void {
    current_controller = controller;
}

pub fn current() ?*AppController {
    return current_controller;
}

pub fn newNoteAction(_: rt.Id, _: rt.Sel, _: rt.Id) callconv(.c) void {
    if (current()) |controller| controller.createNote("Untitled") catch |err| {
        std.log.err("failed to create note: {t}", .{err});
    };
}

pub fn deleteNoteAction(_: rt.Id, _: rt.Sel, _: rt.Id) callconv(.c) void {
    if (current()) |controller| controller.deleteSelectedNote();
}

pub fn numberOfRowsInTableView(_: rt.Id, _: rt.Sel, _: rt.Id) callconv(.c) rt.NSInteger {
    const controller = current() orelse return 0;
    return controller.numberOfRows();
}

pub fn tableObjectValue(_: rt.Id, _: rt.Sel, _: rt.Id, _: rt.Id, row: rt.NSInteger) callconv(.c) rt.Id {
    const controller = current() orelse return foundation.nsString("");
    return controller.titleForRow(row);
}

pub fn tableSelectionDidChange(_: rt.Id, _: rt.Sel, _: rt.Id) callconv(.c) void {
    if (current()) |controller| controller.selectRowFromTable();
}

pub fn textDidChange(_: rt.Id, _: rt.Sel, _: rt.Id) callconv(.c) void {
    if (current()) |controller| controller.saveSelectedNote();
}
