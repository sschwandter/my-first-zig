const std = @import("std");

pub fn candidateTitle(allocator: std.mem.Allocator, base_title: []const u8, index: usize) ![:0]u8 {
    if (index == 1) return allocator.dupeZ(u8, base_title);
    const formatted = try std.fmt.allocPrint(allocator, "{s} {d}", .{ base_title, index });
    defer allocator.free(formatted);
    return allocator.dupeZ(u8, formatted);
}

pub fn filenameFromTitle(allocator: std.mem.Allocator, title: []const u8) ![]u8 {
    const safe_title = try sanitizeTitle(allocator, title);
    defer allocator.free(safe_title);
    return std.fmt.allocPrint(allocator, "{s}.txt", .{safe_title});
}

pub fn titleFromTextFilename(allocator: std.mem.Allocator, filename: []const u8) ![:0]u8 {
    if (!std.mem.endsWith(u8, filename, ".txt")) return error.NotTextNote;
    return allocator.dupeZ(u8, filename[0 .. filename.len - 4]);
}

fn sanitizeTitle(allocator: std.mem.Allocator, title: []const u8) ![]u8 {
    const trimmed = std.mem.trim(u8, title, " \t\r\n");
    if (trimmed.len == 0) return allocator.dupe(u8, "Untitled");

    const safe = try allocator.dupe(u8, trimmed);
    for (safe) |*byte| {
        switch (byte.*) {
            0, '/', ':' => byte.* = '-',
            else => {},
        }
    }
    return safe;
}

test "candidate titles use plain base title first" {
    const allocator = std.testing.allocator;
    const first = try candidateTitle(allocator, "Untitled", 1);
    defer allocator.free(first);
    const second = try candidateTitle(allocator, "Untitled", 2);
    defer allocator.free(second);

    try std.testing.expectEqualStrings("Untitled", first);
    try std.testing.expectEqualStrings("Untitled 2", second);
}

test "filenames are text files and avoid path separators" {
    const allocator = std.testing.allocator;
    const filename = try filenameFromTitle(allocator, "daily/notes");
    defer allocator.free(filename);

    try std.testing.expectEqualStrings("daily-notes.txt", filename);
}
