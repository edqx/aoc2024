const std = @import("std");

const solveRun = @import("solve_run").solveRun;

pub fn solution(allocator: std.mem.Allocator, input: []const u8) !usize {
    const num_lines = std.mem.count(u8, input, "\n");

    var l_numbers = try std.ArrayListUnmanaged(isize).initCapacity(allocator, num_lines);
    defer l_numbers.deinit(allocator);
    var r_numbers = try std.ArrayListUnmanaged(isize).initCapacity(allocator, num_lines);
    defer r_numbers.deinit(allocator);

    var tokenise_lines = std.mem.tokenizeAny(u8, input, "\n\r");
    while (tokenise_lines.next()) |line| {
        var tokenise_space = std.mem.tokenizeAny(u8, line, &std.ascii.whitespace);
        const l = tokenise_space.next().?;
        const r = tokenise_space.next().?;

        try l_numbers.append(allocator, try std.fmt.parseInt(isize, l, 10));
        try r_numbers.append(allocator, try std.fmt.parseInt(isize, r, 10));
    }

    std.mem.sort(isize, l_numbers.items, {}, std.sort.asc(isize));
    std.mem.sort(isize, r_numbers.items, {}, std.sort.asc(isize));

    var total_dist: usize = 0;
    for (l_numbers.items, r_numbers.items) |l, r| {
        total_dist += @abs(l - r);
    }

    return total_dist;
}
