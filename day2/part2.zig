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

pub fn levelSafe(whole_dir: *?Dir, a: isize, b: isize) bool {
    if (@abs(a - b) > 3) return false;
    const dir = changeDir(a, b) orelse return false;
    if (whole_dir.* != null and dir != whole_dir.*) return false;
    whole_dir.* = dir;
    return true;
}

pub fn reportSafe(report: []isize, remove: ?usize) bool {
    var whole_dir: ?Dir = null;
    var i: usize = 0;
    while (i < report.len - 1) : (i += 1) {
        if (remove == i) continue;
        if (remove == i + 1) {
            if (i == report.len - 2) return true;
            if (!levelSafe(&whole_dir, report[i], report[i + 2])) return false;
        } else {
            if (!levelSafe(&whole_dir, report[i], report[i + 1])) return false;
        }
    }
    return true;
}

pub fn solution(allocator: std.mem.Allocator, input: []const u8) !usize {
    std.testing.log_level = .info;
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
        if (reportSafe(report, null)) {
            num_safe_reports += 1;
        } else {
            for (0..report.len) |j| {
                if (reportSafe(report, j)) {
                    num_safe_reports += 1;
                    break;
                }
            }
        }
    }

    return num_safe_reports;
}
