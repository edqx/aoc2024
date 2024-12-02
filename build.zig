const std = @import("std");

const join = std.fs.path.join;

fn exists(d: std.fs.Dir, path: []const u8) bool {
    d.access(path, .{}) catch return false;
    return true;
}

pub fn build(b: *std.Build) !void {
    var iterate_dir = try b.build_root.handle.openDir(".", .{ .iterate = true });
    defer iterate_dir.close();

    var all_parts = std.ArrayListUnmanaged(*std.Build.Step){};
    defer all_parts.deinit(b.allocator);

    var dir = iterate_dir.iterate();
    while (try dir.next()) |entry| {
        if (entry.kind == .directory and std.mem.startsWith(u8, entry.name, "day")) {
            const day_num = try std.fmt.parseInt(usize, entry.name[3..], 10);
            const example = b.createModule(.{
                .root_source_file = b.path(try join(b.allocator, &.{ entry.name, "example.txt" })),
            });
            const input = b.createModule(.{
                .root_source_file = b.path(try join(b.allocator, &.{ entry.name, "input.txt" })),
            });
            var day_parts = std.ArrayListUnmanaged(*std.Build.Step){};
            defer day_parts.deinit(b.allocator);

            for (0..2) |i| {
                const part_num = i + 1; // 0..2 is inclusive start, exclusive end
                const part_path = try join(b.allocator, &.{ entry.name, b.fmt("part{}.zig", .{part_num}) });
                if (exists(b.build_root.handle, part_path)) {
                    const options = b.addOptions();
                    options.addOption(usize, "day", day_num);
                    options.addOption(usize, "part", part_num);

                    const c = b.createModule(.{
                        .root_source_file = b.path(part_path),
                    });

                    const solve_test = b.addTest(.{
                        .name = b.fmt("Day {} (Part {})", .{ day_num, part_num }),
                        .root_source_file = b.path("./solve_run.zig"),
                    });
                    solve_test.root_module.addImport("example_input", example);
                    solve_test.root_module.addImport("input", input);
                    solve_test.root_module.addImport("solution_info", options.createModule());
                    solve_test.root_module.addImport("solution", c);

                    const run_solve_day = b.addRunArtifact(solve_test);
                    const run_solve_all = b.addRunArtifact(solve_test);
                    try day_parts.append(b.allocator, &run_solve_day.step);
                    try all_parts.append(b.allocator, &run_solve_all.step);
                }
            }
            try all_parts.appendSlice(b.allocator, day_parts.items);
            const run_step = b.step(b.fmt("{}", .{day_num}), b.fmt("Run both the example and input case for day {}", .{day_num}));
            for (0..day_parts.items.len - 1) |i| {
                day_parts.items[i + 1].dependOn(day_parts.items[i]);
            }
            run_step.dependOn(day_parts.items[day_parts.items.len - 1]);
        }
    }

    const run_step = b.step("run", "Test all days");
    for (0..all_parts.items.len - 1) |i| {
        all_parts.items[i + 1].dependOn(all_parts.items[i]);
    }
    run_step.dependOn(all_parts.items[all_parts.items.len - 1]);
}
