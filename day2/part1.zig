const std = @import("std");
const solveRun = @import("solve_run").solveRun;

const Dir = enum {
    asc,
    dsc,
};

pub fn changeDir(a: isize, b: isize) ?Dir {
    if (a == b) return null;
    return if (a < b) .asc else .dsc;
}

pub fn reportSafe(report: []isize) bool {
    if (report.len < 2) return true;
    var whole_dir: ?Dir = null;
    for (0..report.len - 1) |i| {
        const a = report[i];
        const b = report[i + 1];

        const dir = changeDir(a, b) orelse return false;
        if (whole_dir != null and dir != whole_dir) return false;
        whole_dir = dir;
        if (@abs(a - b) > 3) return false;
    }
    return true;
}

pub fn solution(allocator: std.mem.Allocator, input: []const u8) !usize {
    const est_num_reports = std.mem.count(u8, input, "\n") + 1;
    var reports = try std.ArrayListUnmanaged([]isize).initCapacity(allocator, est_num_reports);
    defer reports.deinit(allocator);
    defer for (reports.items) |report| {
        allocator.free(report);
    };

    var tokenise_lines = std.mem.tokenizeAny(u8, input, "\n\r");
    while (tokenise_lines.next()) |line| {
        var tokenise_space = std.mem.tokenizeAny(u8, line, &std.ascii.whitespace);
        const est_num_levels = std.mem.count(u8, input, " ") + 1;

        var levels = try std.ArrayListUnmanaged(isize).initCapacity(allocator, est_num_levels);
        defer levels.deinit(allocator);

        while (tokenise_space.next()) |single| {
            const level = try std.fmt.parseInt(isize, single, 10);
            try levels.append(allocator, level);
        }

        try reports.append(allocator, try levels.toOwnedSlice(allocator));
    }

    var num_safe_reports: usize = 0;
    for (reports.items) |report| {
        if (reportSafe(report)) {
            num_safe_reports += 1;
        }
    }

    return num_safe_reports;
}
