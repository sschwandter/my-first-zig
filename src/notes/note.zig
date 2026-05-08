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
