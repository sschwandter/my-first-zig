//! Core note model.
//!
//! This module intentionally has no AppKit dependency, making note ownership
//! and sorting behavior easy to test independently from the UI.

const std = @import("std");

/// In-memory identity for one plain-text note.
pub const Note = struct {
    title: [:0]u8,
    filename: []u8,

    /// Releases allocator-owned title and filename buffers.
    pub fn deinit(self: Note, allocator: std.mem.Allocator) void {
        allocator.free(self.title);
        allocator.free(self.filename);
    }
};

/// Sorts notes case-insensitively by display title.
pub fn sortByTitle(notes: []Note) void {
    std.mem.sort(Note, notes, {}, struct {
        fn lessThan(_: void, a: Note, b: Note) bool {
            return std.ascii.lessThanIgnoreCase(a.title, b.title);
        }
    }.lessThan);
}

test "sortByTitle sorts case-insensitively" {
    const allocator = std.testing.allocator;
    var notes = std.ArrayList(Note).init(allocator);
    defer {
        for (notes.items) |n| n.deinit(allocator);
        notes.deinit();
    }

    try notes.append(.{ .title = try allocator.dupeZ(u8, "Zebra"), .filename = try allocator.dupe(u8, "zebra.txt") });
    try notes.append(.{ .title = try allocator.dupeZ(u8, "apple"), .filename = try allocator.dupe(u8, "apple.txt") });
    try notes.append(.{ .title = try allocator.dupeZ(u8, "Banana"), .filename = try allocator.dupe(u8, "banana.txt") });

    sortByTitle(notes.items);

    try std.testing.expectEqualStrings("apple", notes.items[0].title);
    try std.testing.expectEqualStrings("Banana", notes.items[1].title);
    try std.testing.expectEqualStrings("Zebra", notes.items[2].title);
}
