const std = @import("std");

const testInput =
    \\$ cd /
    \\$ ls
    \\dir a
    \\14848514 b.txt
    \\8504156 c.dat
    \\dir d
    \\$ cd a
    \\$ ls
    \\dir e
    \\29116 f
    \\2557 g
    \\62596 h.lst
    \\$ cd e
    \\$ ls
    \\584 i
    \\$ cd ..
    \\$ cd ..
    \\$ cd d
    \\$ ls
    \\4060174 j
    \\8033020 d.log
    \\5626152 d.ext
    \\7214296 k
;

const FileSystem = struct {
    const Self = @This();

    root: *Directory,
    cwd: *Directory,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Self {
        var root = try allocator.create(Directory);
        root.* = Directory.init("/", root, allocator);
        return .{
            .root = root,
            .cwd = root,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.root.deinit();
        self.allocator.destroy(self.root);
    }

    pub fn chdirParent(self: *Self) void {
        self.cwd = self.cwd.parent;
    }

    pub fn chdirRoot(self: *Self) void {
        self.cwd = self.root;
    }

    pub fn chdir(self: *Self, name: []const u8) !void {
        for (self.cwd.dirs.items) |*dir| {
            if (std.mem.eql(u8, dir.name, name)) {
                self.cwd = dir;
                return;
            }
        }
        return error.DirectoryNotFound;
    }

    pub fn print(self: Self) void {
        self.root.printDirectory();
    }

    pub fn parse(str: []const u8, allocator: std.mem.Allocator) !Self {
        var fs = try Self.init(allocator);
        var lines = std.mem.split(u8, str, "\n");
        while (lines.next()) |line| {
            var fields = std.mem.split(u8, line, " ");
            const first = fields.next().?;
            if (std.mem.eql(u8, first, "$")) {
                const cmd = fields.next().?;
                if (std.mem.eql(u8, cmd, "cd")) {
                    const dir = fields.next().?;
                    if (std.mem.eql(u8, dir, "/")) {
                        fs.chdirRoot();
                    } else if (std.mem.eql(u8, dir, "..")) {
                        fs.chdirParent();
                    } else {
                        try fs.chdir(dir);
                    }
                }
            } else if (std.mem.eql(u8, first, "dir")) {
                const name = fields.next().?;
                try fs.cwd.addDir(name);
            } else {
                const size = try std.fmt.parseInt(u32, first, 10);
                const name = fields.next().?;
                try fs.cwd.addFile(name, size);
            }
        }
        return fs;
    }

    const Directory = struct {
        name: []const u8,
        parent: *Directory,
        dirs: std.ArrayList(Directory),
        files: std.ArrayList(File),
        allocator: std.mem.Allocator,

        pub fn init(name: []const u8, parent: *Directory, allocator: std.mem.Allocator) Directory {
            return .{
                .name = name,
                .parent = parent,
                .dirs = std.ArrayList(Directory).init(allocator),
                .files = std.ArrayList(File).init(allocator),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Directory) void {
            // recursive deallocation
            self.files.deinit();
            for (self.dirs.items) |*dir| {
                dir.deinit();
            }
            self.dirs.deinit();
        }

        pub fn addDir(self: *Directory, name: []const u8) !void {
            try self.dirs.append(Directory.init(name, self, self.allocator));
        }

        pub fn addFile(self: *Directory, name: []const u8, size: u32) !void {
            try self.files.append(File.init(name, size));
        }

        pub fn totalSize(self: Directory) u32 {
            var size: u32 = 0;
            for (self.dirs.items) |dir| {
                size += dir.totalSize();
            }
            for (self.files.items) |file| {
                size += file.size;
            }
            return size;
        }

        pub fn printDirectory(self: Directory) void {
            self.printDirectory_(0);
        }

        fn printDirectory_(self: Directory, level: usize) void {
            var i: usize = 0;
            while (i <= level * 2) : (i += 1) {
                std.debug.print(" ", .{});
            }
            std.debug.print("- {s} (dir, size={})\n", .{ self.name, self.totalSize() });
            for (self.files.items) |file| {
                i = 0;
                while (i <= (level + 1) * 2) : (i += 1) {
                    std.debug.print(" ", .{});
                }
                std.debug.print("- {s} (file, size={d})\n", .{ file.name, file.size });
            }
            for (self.dirs.items) |dir| {
                dir.printDirectory_(level + 1);
            }
        }
    };

    const File = struct {
        name: []const u8,
        size: u32,

        pub fn init(name: []const u8, size: u32) File {
            return .{
                .name = name,
                .size = size,
            };
        }
    };
};

pub fn runAll() !void {
    try part1();
    try part2();
}

pub fn part1() !void {
    var file = try std.fs.cwd().openFile("src/input/day7.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const result = try part1SumOfDirectorySize(reader);
    std.debug.print("Day 7 Part 1: {}\n", .{result});
}

pub fn part2() !void {
    var file = try std.fs.cwd().openFile("src/input/day7.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    const result = try part2SmallestDirSizeToFreeUpSpace(reader);
    std.debug.print("Day 7 Part 2: {}\n", .{result});
}

fn part1SumOfDirectorySize(reader: anytype) !u32 {
    const allocator = std.heap.page_allocator;
    var list = std.ArrayList(FileSystem.Directory).init(allocator);
    defer list.deinit();
    var buf = try reader.readAllAlloc(allocator, 1024 * 1024 * 1024);
    var fs = try FileSystem.parse(buf, allocator);
    defer fs.deinit();
    try getDirList(fs.root.*, 0, 100000, &list);
    var total: u32 = 0;
    for (list.items) |dir| {
        total += dir.totalSize();
    }
    return total;
}

fn part2SmallestDirSizeToFreeUpSpace(reader: anytype) !u32 {
    const allocator = std.heap.page_allocator;
    var list = std.ArrayList(FileSystem.Directory).init(allocator);
    defer list.deinit();
    var buf = try reader.readAllAlloc(allocator, 1024 * 1024 * 1024);
    var fs = try FileSystem.parse(buf, allocator);
    defer fs.deinit();
    try getDirList(fs.root.*, @as(u32, 30000000) - (@as(u32, 70000000) - fs.root.totalSize()), 70000000, &list);
    var min: u32 = 70000000;
    for (list.items) |dir| {
        const size = dir.totalSize();
        if (size < min) {
            min = size;
        }
    }
    return min;
}

fn getDirList(directory: FileSystem.Directory, lowerBound: u32, upperBound: u32, list: *std.ArrayList(FileSystem.Directory)) !void {
    const size = directory.totalSize();
    if (lowerBound <= size and size <= upperBound) {
        try list.append(directory);
    }
    for (directory.dirs.items) |dir| {
        try getDirList(dir, lowerBound, upperBound, list);
    }
}

test "file system struct" {
    const allocator = std.heap.page_allocator;
    var fs = try FileSystem.init(allocator);
    defer fs.deinit();
    try fs.cwd.addDir("a");
    try fs.cwd.addDir("d");
    try fs.cwd.addFile("b.txt", 14848514);
    try fs.cwd.addFile("c.dat", 8504156);
    try fs.chdir("a");
    try fs.cwd.addFile("f", 29116);
    try fs.cwd.addFile("g", 2557);
    try fs.cwd.addFile("h.lst", 62596);
    try fs.cwd.addDir("e");
    try fs.chdir("e");
    try fs.cwd.addFile("i", 584);
    fs.chdirRoot();
    try fs.chdir("d");
    try fs.cwd.addFile("j", 4060174);
    try fs.cwd.addFile("d.log", 8033020);
    try fs.cwd.addFile("d.ext", 5626152);
    try fs.cwd.addFile("k", 7214296);
    fs.chdirParent();
    try std.testing.expectEqual(fs.root, fs.cwd);
    try std.testing.expectEqual(@as(u32, 48381165), fs.root.totalSize());
    // fs.print();
}

test "file system parse" {
    const allocator = std.heap.page_allocator;
    var fs = try FileSystem.parse(testInput, allocator);
    defer fs.deinit();
    // fs.print();
}

test "part 1" {
    const allocator = std.heap.page_allocator;
    _ = allocator;
    var fis = std.io.fixedBufferStream(testInput);
    const reader = fis.reader();
    const ans = try part1SumOfDirectorySize(reader);
    try std.testing.expectEqual(@as(u32, 95437), ans);
}

test "part 2" {
    const allocator = std.heap.page_allocator;
    _ = allocator;
    var fis = std.io.fixedBufferStream(testInput);
    const reader = fis.reader();
    const ans = try part2SmallestDirSizeToFreeUpSpace(reader);
    try std.testing.expectEqual(@as(u32, 24933642), ans);
}
