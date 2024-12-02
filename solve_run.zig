const std = @import("std");

const options = @import("solution_info");
const solution = @import("solution").solution;

const Input = enum {
    example,
    actual,
};

pub fn solveRun(input: Input) !void {
    const input_name = switch (input) {
        .example => "example",
        .actual => "actual",
    };

    const input_data = switch (input) {
        .example => @embedFile("example_input"),
        .actual => @embedFile("input"),
    };

    const result = try solution(std.testing.allocator, input_data);
    std.debug.print("[Day {}] Part {} ({s} input) => {}\n", .{ options.day, options.part, input_name, result });
}

test "Example" {
    try solveRun(.example);
}

test "Actual" {
    try solveRun(.actual);
}
