const std = @import("std");

const solution = @import("solution").solution;

const Input = enum {
    example,
    actual,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const writer = std.io.getStdOut().writer();
    const result = try solution(allocator, @embedFile("input"));
    try writer.print("{}\n", .{result});
}
