const std = @import("std");

const join = std.fs.path.join;

fn exists(d: std.fs.Dir, path: []const u8) bool {
    d.access(path, .{}) catch return false;
    return true;
}

const InputModuleNode = struct {
    name: []const u8,
    module: *std.Build.Module,
};

pub fn build(b: *std.Build) !void {
    var iterate_dir = try b.build_root.handle.openDir(".", .{ .iterate = true });
    defer iterate_dir.close();

    var previous_day_step: ?*std.Build.Step = null;

    var dir = iterate_dir.iterate();
    while (try dir.next()) |entry| {
        if (entry.kind == .directory and std.mem.startsWith(u8, entry.name, "day")) {
            const day_num = try std.fmt.parseInt(usize, entry.name[3..], 10);

            var input_modules = std.ArrayListUnmanaged(InputModuleNode){};
            defer input_modules.deinit(b.allocator);

            for ([_]struct { []const u8, []const u8 }{
                .{ "Example", "example.txt" },
                .{ "Input", "input.txt" },
            }) |input_data| {
                const input_name, const filename = input_data;
                const input_path = try join(b.allocator, &.{ entry.name, filename });
                if (exists(b.build_root.handle, input_path)) {
                    const module = b.createModule(.{
                        .root_source_file = b.path(input_path),
                    });
                    try input_modules.append(b.allocator, .{ .name = input_name, .module = module });
                }
            }

            const day_step = b.step(b.fmt("{}", .{day_num}), b.fmt("Run both the example and input case for day {}", .{day_num}));

            for (0..2) |i| {
                const part_num = i + 1; // 0..2 is inclusive start, exclusive end
                const part_path = try join(b.allocator, &.{ entry.name, b.fmt("part{}.zig", .{part_num}) });
                if (exists(b.build_root.handle, part_path)) {
                    const c = b.createModule(.{
                        .root_source_file = b.path(part_path),
                    });

                    for (input_modules.items) |input_module| {
                        const solve_test = b.addExecutable(.{
                            .name = b.fmt("Day {} (Part {}) {s}", .{ day_num, part_num, input_module.name }),
                            .root_source_file = b.path("./solve_run.zig"),
                            .target = b.graph.host,
                        });
                        solve_test.root_module.addImport("input", input_module.module);
                        solve_test.root_module.addImport("solution", c);

                        const run_solve_part_input = b.addRunArtifact(solve_test);

                        const output = run_solve_part_input.captureStdOut();
                        const install = b.addInstallFile(output, b.fmt("Day-{}-Part-{}-{s}-Answer.txt", .{ day_num, part_num, input_module.name }));
                        install.step.dependOn(&run_solve_part_input.step);
                        day_step.dependOn(&install.step);
                    }
                }
            }
            if (previous_day_step) |step| {
                day_step.dependOn(step);
            }
            previous_day_step = day_step;
        }
    }

    const run_step = b.step("run", "Test all days");
    if (previous_day_step) |step| {
        run_step.dependOn(step);
    }
}
