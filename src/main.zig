const std = @import("std");
const Io = std.Io;

const Id = *opaque {};
const Class = *opaque {};
const Sel = *opaque {};
const Imp = *const anyopaque;

const NSPoint = extern struct { x: f64, y: f64 };
const NSSize = extern struct { width: f64, height: f64 };
const NSRect = extern struct { origin: NSPoint, size: NSSize };

const NSUInteger = usize;
const NSInteger = isize;

const NSApplicationActivationPolicyRegular: NSInteger = 0;
const NSBackingStoreBuffered: NSUInteger = 2;
const NSWindowStyleMaskTitled: NSUInteger = 1 << 0;
const NSWindowStyleMaskClosable: NSUInteger = 1 << 1;
const NSWindowStyleMaskMiniaturizable: NSUInteger = 1 << 2;
const NSWindowStyleMaskResizable: NSUInteger = 1 << 3;
const NSViewWidthSizable: NSUInteger = 1 << 1;
const NSViewHeightSizable: NSUInteger = 1 << 4;

extern fn objc_getClass(name: [*:0]const u8) ?Class;
extern fn objc_allocateClassPair(superclass: Class, name: [*:0]const u8, extra_bytes: usize) ?Class;
extern fn objc_registerClassPair(cls: Class) void;
extern fn class_addMethod(cls: Class, name: Sel, imp: Imp, types: [*:0]const u8) bool;
extern fn sel_registerName(name: [*:0]const u8) Sel;

const MsgId = *const fn (Id, Sel) callconv(.c) Id;
const MsgIdId = *const fn (Id, Sel, Id) callconv(.c) Id;
const MsgIdIdId = *const fn (Id, Sel, Id, Id) callconv(.c) Id;
const MsgIdIdIdId = *const fn (Id, Sel, Id, Id, Id) callconv(.c) Id;
const MsgIdCString = *const fn (Id, Sel, [*:0]const u8) callconv(.c) Id;
const MsgIdRect = *const fn (Id, Sel, NSRect) callconv(.c) Id;
const MsgIdSelId = *const fn (Id, Sel, Id, Sel, Id) callconv(.c) Id;
const MsgIdUInteger = *const fn (Id, Sel, NSUInteger) callconv(.c) Id;
const MsgInteger = *const fn (Id, Sel) callconv(.c) NSInteger;
const MsgRect = *const fn (Id, Sel) callconv(.c) NSRect;
const MsgCStringReturn = *const fn (Id, Sel) callconv(.c) [*:0]const u8;
const MsgVoid = *const fn (Id, Sel) callconv(.c) void;
const MsgVoidBool = *const fn (Id, Sel, bool) callconv(.c) void;
const MsgVoidDouble = *const fn (Id, Sel, f64) callconv(.c) void;
const MsgVoidDoubleInteger = *const fn (Id, Sel, f64, NSInteger) callconv(.c) void;
const MsgVoidId = *const fn (Id, Sel, Id) callconv(.c) void;
const MsgVoidIdBool = *const fn (Id, Sel, Id, bool) callconv(.c) void;
const MsgVoidIdId = *const fn (Id, Sel, Id, Id) callconv(.c) void;
const MsgVoidInteger = *const fn (Id, Sel, NSInteger) callconv(.c) void;
const MsgVoidUInteger = *const fn (Id, Sel, NSUInteger) callconv(.c) void;
const MsgWindowInit = *const fn (Id, Sel, NSRect, NSUInteger, NSUInteger, bool) callconv(.c) Id;

const objc_msgSend_id = @extern(MsgId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_id = @extern(MsgIdId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_id_id = @extern(MsgIdIdId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_id_id_id = @extern(MsgIdIdIdId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_cstring = @extern(MsgIdCString, .{ .name = "objc_msgSend" });
const objc_msgSend_id_rect = @extern(MsgIdRect, .{ .name = "objc_msgSend" });
const objc_msgSend_id_sel_id = @extern(MsgIdSelId, .{ .name = "objc_msgSend" });
const objc_msgSend_id_uinteger = @extern(MsgIdUInteger, .{ .name = "objc_msgSend" });
const objc_msgSend_integer = @extern(MsgInteger, .{ .name = "objc_msgSend" });
const objc_msgSend_rect = @extern(MsgRect, .{ .name = "objc_msgSend" });
const objc_msgSend_cstring_return = @extern(MsgCStringReturn, .{ .name = "objc_msgSend" });
const objc_msgSend_void = @extern(MsgVoid, .{ .name = "objc_msgSend" });
const objc_msgSend_void_bool = @extern(MsgVoidBool, .{ .name = "objc_msgSend" });
const objc_msgSend_void_double = @extern(MsgVoidDouble, .{ .name = "objc_msgSend" });
const objc_msgSend_void_double_integer = @extern(MsgVoidDoubleInteger, .{ .name = "objc_msgSend" });
const objc_msgSend_void_id = @extern(MsgVoidId, .{ .name = "objc_msgSend" });
const objc_msgSend_void_id_bool = @extern(MsgVoidIdBool, .{ .name = "objc_msgSend" });
const objc_msgSend_void_id_id = @extern(MsgVoidIdId, .{ .name = "objc_msgSend" });
const objc_msgSend_void_integer = @extern(MsgVoidInteger, .{ .name = "objc_msgSend" });
const objc_msgSend_void_uinteger = @extern(MsgVoidUInteger, .{ .name = "objc_msgSend" });
const objc_msgSend_window_init = @extern(MsgWindowInit, .{ .name = "objc_msgSend" });

const Note = struct {
    title: [:0]u8,
    filename: []u8,
};

const AppState = struct {
    allocator: std.mem.Allocator,
    io: Io,
    notes_dir: Io.Dir,
    notes_dir_path: []u8,
    notes: std.ArrayList(Note) = .empty,
    selected_index: ?usize = null,
    table_view: ?Id = null,
    text_view: ?Id = null,
    delegate: ?Id = null,
    suppress_text_change: bool = false,

    fn deinit(self: *AppState) void {
        for (self.notes.items) |note| {
            self.allocator.free(note.title);
            self.allocator.free(note.filename);
        }
        self.notes.deinit(self.allocator);
        self.allocator.free(self.notes_dir_path);
        self.notes_dir.close(self.io);
    }
};

var global_state: ?*AppState = null;

pub fn main(init: std.process.Init) !void {
    comptime if (!@import("builtin").target.os.tag.isDarwin()) {
        @compileError("Zig Notes uses AppKit and only builds for macOS.");
    };

    var state = try createAppState(init.arena.allocator(), init.io);
    defer state.deinit();
    global_state = &state;

    registerDelegateClass();
    const delegate = msg(class("ZigNotesDelegate"), "new");
    state.delegate = delegate;

    try loadNotes(&state);
    if (state.notes.items.len == 0) try createNote(&state, "Welcome");

    const app = msg(class("NSApplication"), "sharedApplication");
    msgVoidInteger(app, "setActivationPolicy:", NSApplicationActivationPolicyRegular);
    msgVoidId(app, "setDelegate:", delegate);

    buildMenuBar(app, delegate);
    buildMainWindow(&state, delegate);
    selectNote(&state, 0);

    msgVoid(app, "finishLaunching");
    msgVoidBool(app, "activateIgnoringOtherApps:", true);
    msgVoid(app, "run");
}

fn createAppState(allocator: std.mem.Allocator, io: Io) !AppState {
    const home_z = std.c.getenv("HOME") orelse return error.HomeNotFound;
    const home = std.mem.span(home_z);
    const notes_dir_path = try std.mem.concat(allocator, u8, &.{ home, "/Documents/Zig Notes" });
    try Io.Dir.createDirPath(.cwd(), io, notes_dir_path);
    const notes_dir = try Io.Dir.openDirAbsolute(io, notes_dir_path, .{ .iterate = true });
    return .{ .allocator = allocator, .io = io, .notes_dir = notes_dir, .notes_dir_path = notes_dir_path };
}

fn loadNotes(state: *AppState) !void {
    var it = state.notes_dir.iterate();
    while (try it.next(state.io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".txt")) continue;
        const filename = try state.allocator.dupe(u8, entry.name);
        const title = try state.allocator.dupeZ(u8, entry.name[0 .. entry.name.len - 4]);
        try state.notes.append(state.allocator, .{ .title = title, .filename = filename });
    }
    sortNotes(state);
}

fn sortNotes(state: *AppState) void {
    std.mem.sort(Note, state.notes.items, {}, struct {
        fn lessThan(_: void, a: Note, b: Note) bool {
            return std.ascii.lessThanIgnoreCase(a.title, b.title);
        }
    }.lessThan);
}

fn createNote(state: *AppState, base_title: []const u8) !void {
    var n: usize = 1;
    while (true) : (n += 1) {
        const title = if (n == 1) title: {
            break :title try state.allocator.dupeZ(u8, base_title);
        } else title: {
            const formatted = try std.fmt.allocPrint(state.allocator, "{s} {d}", .{ base_title, n });
            defer state.allocator.free(formatted);
            break :title try state.allocator.dupeZ(u8, formatted);
        };
        errdefer state.allocator.free(title);

        const filename = try std.fmt.allocPrint(state.allocator, "{s}.txt", .{title});
        errdefer state.allocator.free(filename);

        if (noteWithFilename(state, filename) != null) {
            state.allocator.free(title);
            state.allocator.free(filename);
            continue;
        }

        try Io.Dir.writeFile(state.notes_dir, state.io, .{ .sub_path = filename, .data = "" });
        try state.notes.append(state.allocator, .{ .title = title, .filename = filename });
        sortNotes(state);
        if (state.table_view) |table| msgVoid(table, "reloadData");
        if (indexOfTitle(state, title)) |index| selectNote(state, index);
        return;
    }
}

fn deleteSelectedNote(state: *AppState) void {
    const index = state.selected_index orelse return;
    if (index >= state.notes.items.len) return;

    const note = state.notes.orderedRemove(index);
    Io.Dir.deleteFile(state.notes_dir, state.io, note.filename) catch {};
    state.allocator.free(note.title);
    state.allocator.free(note.filename);

    state.selected_index = null;
    if (state.table_view) |table| msgVoid(table, "reloadData");

    if (state.notes.items.len == 0) {
        createNote(state, "Welcome") catch return;
    } else {
        selectNote(state, @min(index, state.notes.items.len - 1));
    }
}

fn selectNote(state: *AppState, index: usize) void {
    if (index >= state.notes.items.len) return;
    state.selected_index = index;

    if (state.table_view) |table| {
        const index_set = msgUInteger(class("NSIndexSet"), "indexSetWithIndex:", index);
        msgVoidIdBool(table, "selectRowIndexes:byExtendingSelection:", index_set, false);
    }

    const note = state.notes.items[index];
    const contents = Io.Dir.readFileAlloc(state.notes_dir, state.io, note.filename, state.allocator, .limited(1024 * 1024)) catch "";
    defer if (contents.len > 0) state.allocator.free(contents);

    if (state.text_view) |text_view| {
        const text_z = state.allocator.dupeZ(u8, contents) catch return;
        defer state.allocator.free(text_z);
        state.suppress_text_change = true;
        msgVoidId(text_view, "setString:", nsString(text_z));
        state.suppress_text_change = false;
    }
}

fn saveSelectedNote(state: *AppState) void {
    if (state.suppress_text_change) return;
    const index = state.selected_index orelse return;
    if (index >= state.notes.items.len) return;
    const text_view = state.text_view orelse return;

    const string = msg(text_view, "string");
    const text = std.mem.span(msgCStringReturn(string, "UTF8String"));
    Io.Dir.writeFile(state.notes_dir, state.io, .{ .sub_path = state.notes.items[index].filename, .data = text }) catch |err| {
        std.log.err("failed to save note: {t}", .{err});
    };
}

fn noteWithFilename(state: *AppState, filename: []const u8) ?usize {
    for (state.notes.items, 0..) |note, i| {
        if (std.mem.eql(u8, note.filename, filename)) return i;
    }
    return null;
}

fn indexOfTitle(state: *AppState, title: []const u8) ?usize {
    for (state.notes.items, 0..) |note, i| {
        if (std.mem.eql(u8, note.title, title)) return i;
    }
    return null;
}

fn buildMenuBar(app: Id, delegate: Id) void {
    const menubar = allocInit("NSMenu");
    msgVoidId(app, "setMainMenu:", menubar);

    const app_menu_item = allocInit("NSMenuItem");
    msgVoidId(menubar, "addItem:", app_menu_item);
    const app_menu = initMenu("Zig Notes");
    msgVoidIdId(menubar, "setSubmenu:forItem:", app_menu, app_menu_item);
    _ = menuItem(app_menu, "About Zig Notes", "orderFrontStandardAboutPanel:", "", app);
    msgVoidId(app_menu, "addItem:", msg(class("NSMenuItem"), "separatorItem"));
    _ = menuItem(app_menu, "Hide Zig Notes", "hide:", "h", app);
    _ = menuItem(app_menu, "Quit Zig Notes", "terminate:", "q", app);

    const file_menu_item = allocInit("NSMenuItem");
    msgVoidId(menubar, "addItem:", file_menu_item);
    const file_menu = initMenu("File");
    msgVoidIdId(menubar, "setSubmenu:forItem:", file_menu, file_menu_item);
    _ = menuItem(file_menu, "New Note", "newNote:", "n", delegate);
    _ = menuItem(file_menu, "Delete Note", "deleteNote:", "", delegate);
}

fn buildMainWindow(state: *AppState, delegate: Id) void {
    const style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;
    const frame = NSRect{ .origin = .{ .x = 0, .y = 0 }, .size = .{ .width = 860, .height = 560 } };

    const window = msgWindowInit(msg(class("NSWindow"), "alloc"), "initWithContentRect:styleMask:backing:defer:", frame, style, NSBackingStoreBuffered, false);
    msgVoidId(window, "setTitle:", nsString("Zig Notes"));
    msgVoid(window, "center");

    const content_view = msg(window, "contentView");
    const bounds = msgRect(content_view, "bounds");
    const split_view = msgRectArg(msg(class("NSSplitView"), "alloc"), "initWithFrame:", bounds);
    msgVoidBool(split_view, "setVertical:", true);
    msgVoidUInteger(split_view, "setAutoresizingMask:", NSViewWidthSizable | NSViewHeightSizable);

    const sidebar_frame = NSRect{ .origin = .{ .x = 0, .y = 0 }, .size = .{ .width = 220, .height = bounds.size.height } };
    const editor_frame = NSRect{ .origin = .{ .x = 0, .y = 0 }, .size = .{ .width = bounds.size.width - 220, .height = bounds.size.height } };

    const table = buildNotesTable(sidebar_frame, delegate);
    const editor = buildEditor(editor_frame, delegate);
    state.table_view = table.table_view;
    state.text_view = editor.text_view;

    msgVoidId(split_view, "addSubview:", table.scroll_view);
    msgVoidId(split_view, "addSubview:", editor.scroll_view);
    msgVoidDoubleInteger(split_view, "setPosition:ofDividerAtIndex:", 220, 0);
    msgVoidId(content_view, "addSubview:", split_view);
    msgVoidId(window, "makeKeyAndOrderFront:", window);
}

fn buildNotesTable(frame: NSRect, delegate: Id) struct { scroll_view: Id, table_view: Id } {
    const scroll = msgRectArg(msg(class("NSScrollView"), "alloc"), "initWithFrame:", frame);
    msgVoidBool(scroll, "setHasVerticalScroller:", true);
    msgVoidUInteger(scroll, "setAutoresizingMask:", NSViewHeightSizable);

    const table = msgRectArg(msg(class("NSTableView"), "alloc"), "initWithFrame:", frame);
    const column = msgId(msg(class("NSTableColumn"), "alloc"), "initWithIdentifier:", nsString("notes"));
    msgVoidDouble(column, "setWidth:", 220);
    msgVoidId(column, "setTitle:", nsString("Notes"));
    msgVoidId(table, "addTableColumn:", column);
    msgVoidId(table, "setDataSource:", delegate);
    msgVoidId(table, "setDelegate:", delegate);
    msgVoidId(scroll, "setDocumentView:", table);

    return .{ .scroll_view = scroll, .table_view = table };
}

fn buildEditor(frame: NSRect, delegate: Id) struct { scroll_view: Id, text_view: Id } {
    const scroll = msgRectArg(msg(class("NSScrollView"), "alloc"), "initWithFrame:", frame);
    msgVoidBool(scroll, "setHasVerticalScroller:", true);
    msgVoidUInteger(scroll, "setAutoresizingMask:", NSViewWidthSizable | NSViewHeightSizable);

    const text = msgRectArg(msg(class("NSTextView"), "alloc"), "initWithFrame:", frame);
    msgVoidBool(text, "setRichText:", false);
    msgVoidBool(text, "setUsesFontPanel:", false);
    msgVoidBool(text, "setAutomaticQuoteSubstitutionEnabled:", false);
    msgVoidBool(text, "setAutomaticDashSubstitutionEnabled:", false);
    msgVoidId(text, "setDelegate:", delegate);
    msgVoidId(scroll, "setDocumentView:", text);

    return .{ .scroll_view = scroll, .text_view = text };
}

fn registerDelegateClass() void {
    const superclass = objc_getClass("NSObject") orelse @panic("NSObject not found");
    if (objc_getClass("ZigNotesDelegate") != null) return;
    const cls = objc_allocateClassPair(superclass, "ZigNotesDelegate", 0) orelse @panic("could not allocate delegate class");

    _ = class_addMethod(cls, sel_registerName("newNote:"), @ptrCast(&newNoteAction), "v@:@");
    _ = class_addMethod(cls, sel_registerName("deleteNote:"), @ptrCast(&deleteNoteAction), "v@:@");
    _ = class_addMethod(cls, sel_registerName("numberOfRowsInTableView:"), @ptrCast(&numberOfRowsInTableView), "q@:@");
    _ = class_addMethod(cls, sel_registerName("tableView:objectValueForTableColumn:row:"), @ptrCast(&tableObjectValue), "@@:@@q");
    _ = class_addMethod(cls, sel_registerName("tableViewSelectionDidChange:"), @ptrCast(&tableSelectionDidChange), "v@:@");
    _ = class_addMethod(cls, sel_registerName("textDidChange:"), @ptrCast(&textDidChange), "v@:@");

    objc_registerClassPair(cls);
}

fn newNoteAction(_: Id, _: Sel, _: Id) callconv(.c) void {
    if (global_state) |state| createNote(state, "Untitled") catch |err| std.log.err("failed to create note: {t}", .{err});
}

fn deleteNoteAction(_: Id, _: Sel, _: Id) callconv(.c) void {
    if (global_state) |state| deleteSelectedNote(state);
}

fn numberOfRowsInTableView(_: Id, _: Sel, _: Id) callconv(.c) NSInteger {
    const state = global_state orelse return 0;
    return @intCast(state.notes.items.len);
}

fn tableObjectValue(_: Id, _: Sel, _: Id, _: Id, row: NSInteger) callconv(.c) Id {
    const state = global_state orelse return nsString("");
    if (row < 0 or row >= state.notes.items.len) return nsString("");
    return nsString(state.notes.items[@intCast(row)].title);
}

fn tableSelectionDidChange(_: Id, _: Sel, _: Id) callconv(.c) void {
    const state = global_state orelse return;
    const table = state.table_view orelse return;
    const row = msgInteger(table, "selectedRow");
    if (row < 0) return;
    selectNote(state, @intCast(row));
}

fn textDidChange(_: Id, _: Sel, _: Id) callconv(.c) void {
    if (global_state) |state| saveSelectedNote(state);
}

fn menuItem(menu: Id, title: [:0]const u8, action: [:0]const u8, key: [:0]const u8, target: Id) Id {
    const item = msgIdSelId(msg(class("NSMenuItem"), "alloc"), "initWithTitle:action:keyEquivalent:", nsString(title), sel_registerName(action.ptr), nsString(key));
    msgVoidId(item, "setTarget:", target);
    msgVoidId(menu, "addItem:", item);
    return item;
}

fn initMenu(title: [:0]const u8) Id {
    return msgId(msg(class("NSMenu"), "alloc"), "initWithTitle:", nsString(title));
}

fn allocInit(comptime class_name: [:0]const u8) Id {
    return msg(class(class_name), "new");
}

fn nsString(text: [:0]const u8) Id {
    return msgCString(msg(class("NSString"), "alloc"), "initWithUTF8String:", text.ptr);
}

fn class(name: [:0]const u8) Id {
    return @ptrCast(objc_getClass(name.ptr) orelse @panic("Objective-C class not found"));
}

fn msg(receiver: Id, selector: [:0]const u8) Id {
    return objc_msgSend_id(receiver, sel_registerName(selector.ptr));
}

fn msgId(receiver: Id, selector: [:0]const u8, arg: Id) Id {
    return objc_msgSend_id_id(receiver, sel_registerName(selector.ptr), arg);
}

fn msgIdSelId(receiver: Id, selector: [:0]const u8, a: Id, b: Sel, c: Id) Id {
    return objc_msgSend_id_sel_id(receiver, sel_registerName(selector.ptr), a, b, c);
}

fn msgCString(receiver: Id, selector: [:0]const u8, arg: [*:0]const u8) Id {
    return objc_msgSend_id_cstring(receiver, sel_registerName(selector.ptr), arg);
}

fn msgRectArg(receiver: Id, selector: [:0]const u8, arg: NSRect) Id {
    return objc_msgSend_id_rect(receiver, sel_registerName(selector.ptr), arg);
}

fn msgUInteger(receiver: Id, selector: [:0]const u8, arg: NSUInteger) Id {
    return objc_msgSend_id_uinteger(receiver, sel_registerName(selector.ptr), arg);
}

fn msgInteger(receiver: Id, selector: [:0]const u8) NSInteger {
    return objc_msgSend_integer(receiver, sel_registerName(selector.ptr));
}

fn msgRect(receiver: Id, selector: [:0]const u8) NSRect {
    return objc_msgSend_rect(receiver, sel_registerName(selector.ptr));
}

fn msgCStringReturn(receiver: Id, selector: [:0]const u8) [*:0]const u8 {
    return objc_msgSend_cstring_return(receiver, sel_registerName(selector.ptr));
}

fn msgVoid(receiver: Id, selector: [:0]const u8) void {
    objc_msgSend_void(receiver, sel_registerName(selector.ptr));
}

fn msgVoidBool(receiver: Id, selector: [:0]const u8, arg: bool) void {
    objc_msgSend_void_bool(receiver, sel_registerName(selector.ptr), arg);
}

fn msgVoidDouble(receiver: Id, selector: [:0]const u8, arg: f64) void {
    objc_msgSend_void_double(receiver, sel_registerName(selector.ptr), arg);
}

fn msgVoidDoubleInteger(receiver: Id, selector: [:0]const u8, a: f64, b: NSInteger) void {
    objc_msgSend_void_double_integer(receiver, sel_registerName(selector.ptr), a, b);
}

fn msgVoidId(receiver: Id, selector: [:0]const u8, arg: Id) void {
    objc_msgSend_void_id(receiver, sel_registerName(selector.ptr), arg);
}

fn msgVoidIdBool(receiver: Id, selector: [:0]const u8, a: Id, b: bool) void {
    objc_msgSend_void_id_bool(receiver, sel_registerName(selector.ptr), a, b);
}

fn msgVoidIdId(receiver: Id, selector: [:0]const u8, a: Id, b: Id) void {
    objc_msgSend_void_id_id(receiver, sel_registerName(selector.ptr), a, b);
}

fn msgVoidInteger(receiver: Id, selector: [:0]const u8, arg: NSInteger) void {
    objc_msgSend_void_integer(receiver, sel_registerName(selector.ptr), arg);
}

fn msgVoidUInteger(receiver: Id, selector: [:0]const u8, arg: NSUInteger) void {
    objc_msgSend_void_uinteger(receiver, sel_registerName(selector.ptr), arg);
}

fn msgWindowInit(receiver: Id, selector: [:0]const u8, rect: NSRect, style: NSUInteger, backing: NSUInteger, defer_window: bool) Id {
    return objc_msgSend_window_init(receiver, sel_registerName(selector.ptr), rect, style, backing, defer_window);
}
