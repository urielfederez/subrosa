const std = @import("std");
const Io = std.Io;

const subrosa = @import("subrosa");

pub fn main() !void {
    const position = subrosa.Position.new();
    const moves = position.getAllLegalMoves();
    std.debug.print("{f}\n", .{position});
    std.debug.print("{f}\n", .{moves});
}
