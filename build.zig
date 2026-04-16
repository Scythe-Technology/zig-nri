const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep_nri = b.dependency("nvidia_nri", .{});

    const NRI_STATIC_LIBRARY = b.option(bool, "static_library", "Build NRI as a static library") orelse false;
    const NRI_ENABLE_NVTX_SUPPORT = b.option(bool, "enable_nvtx_support", "Annotations for NVIDIA Nsight Systems") orelse true;
    const NRI_ENABLE_DEBUG_NAMES_AND_ANNOTATIONS = b.option(bool, "enable_debug_names_and_annotations", "Enable debug names, host and device annotations") orelse true;
    const NRI_ENABLE_NONE_SUPPORT = b.option(bool, "enable_none_support", "Enable NONE backend") orelse true;
    const NRI_ENABLE_VK_SUPPORT = b.option(bool, "enable_vk_support", "Enable VULKAN support") orelse true;
    const NRI_ENABLE_VALIDATION_SUPPORT = b.option(bool, "enable_validation_support", "Enable Validation backend (otherwise 'enableNRIValidation' is ignored)") orelse true;
    const NRI_ENABLE_NIS_SDK = b.option(bool, "enable_nis_sdk", "Enable NVIDIA Image Sharpening SDK") orelse false;
    const NRI_ENABLE_IMGUI_EXTENSIONS = b.option(bool, "enable_imgui_extensions", "Enable 'NRIImgui' extension") orelse false;
    const NRI_STREAMER_THREAD_SAFE = b.option(bool, "enable_streamer_thread_safe", "'NRIStreamer' thread safety (OFF is faster)") orelse true;
    const NRI_ENABLE_D3D11_SUPPORT = b.option(bool, "enable_d3d11_support", "Enable D3D11 support") orelse (target.result.os.tag == .windows);
    const NRI_ENABLE_D3D12_SUPPORT = b.option(bool, "enable_d3d12_support", "Enable D3D12 support") orelse (target.result.os.tag == .windows);
    const NRI_ENABLE_AMDAGS = b.option(bool, "enable_amdags_support", "Enable AMD AGS library for D3D") orelse (NRI_ENABLE_D3D11_SUPPORT or NRI_ENABLE_D3D12_SUPPORT);
    const NRI_ENABLE_NVAPI = b.option(bool, "enable_nvapi_support", "Enable NVAPI library for D3D") orelse (NRI_ENABLE_D3D11_SUPPORT or NRI_ENABLE_D3D12_SUPPORT);
    const NRI_ENABLE_AGILITY_SDK_SUPPORT = b.option(bool, "enable_agility_sdk_support", "Enable Agility SDK support to unlock access to latest D3D12 features") orelse NRI_ENABLE_D3D12_SUPPORT;
    const NRI_ENABLE_XLIB_SUPPORT = b.option(bool, "enable_xlib_support", "Enable X11 support") orelse true;
    const NRI_ENABLE_WAYLAND_SUPPORT = b.option(bool, "enable_wayland_support", "Enable Wayland support") orelse true;

    // NVIDIA NGX SDK
    const NRI_ENABLE_NGX_SDK = b.option(bool, "enable_ngx_sdk", "Enable NVIDIA NGX (DLSS) SDK") orelse false;
    // AMD FidelityFX SDK
    const NRI_ENABLE_FFX_SDK = b.option(bool, "enable_ffx_sdk", "Enable AMD FidelityFX SDK") orelse false;
    // INTEL XeSS SDK
    const NRI_ENABLE_XESS_SDK = b.option(bool, "enable_xess_sdk", "Enable INTEL XeSS SDK") orelse false;

    const NRI_ENABLE_SHADERMAKE = NRI_ENABLE_NIS_SDK;

    var FLAGS: std.ArrayList([]const u8) = .empty;
    defer FLAGS.deinit(b.allocator);

    // try FLAGS.append(b.allocator, "-std=c++17");

    if (NRI_STATIC_LIBRARY) try FLAGS.append(b.allocator, "-DNRI_STATIC_LIBRARY=1");
    if (NRI_ENABLE_NVTX_SUPPORT) try FLAGS.append(b.allocator, "-DNRI_ENABLE_NVTX_SUPPORT=1");
    if (NRI_ENABLE_DEBUG_NAMES_AND_ANNOTATIONS) try FLAGS.append(b.allocator, "-DNRI_ENABLE_DEBUG_NAMES_AND_ANNOTATIONS=1");
    if (NRI_ENABLE_NONE_SUPPORT) try FLAGS.append(b.allocator, "-DNRI_ENABLE_NONE_SUPPORT=1");
    if (NRI_ENABLE_VK_SUPPORT) try FLAGS.append(b.allocator, "-DNRI_ENABLE_VK_SUPPORT=1");
    if (NRI_ENABLE_VALIDATION_SUPPORT) try FLAGS.append(b.allocator, "-DNRI_ENABLE_VALIDATION_SUPPORT=1");
    if (NRI_ENABLE_NIS_SDK) try FLAGS.append(b.allocator, "-DNRI_ENABLE_NIS_SDK=1");
    if (NRI_ENABLE_IMGUI_EXTENSIONS) try FLAGS.append(b.allocator, "-DNRI_ENABLE_IMGUI_EXTENSIONS=1");
    if (NRI_ENABLE_D3D11_SUPPORT) try FLAGS.append(b.allocator, "-DNRI_ENABLE_D3D11_SUPPORT=1");
    if (NRI_ENABLE_D3D12_SUPPORT) try FLAGS.append(b.allocator, "-DNRI_ENABLE_D3D12_SUPPORT=1");
    if (NRI_ENABLE_AMDAGS) try FLAGS.append(b.allocator, "-DNRI_ENABLE_AMDAGS=1");
    if (NRI_ENABLE_NVAPI) try FLAGS.append(b.allocator, "-DNRI_ENABLE_NVAPI=1");
    if (NRI_ENABLE_AGILITY_SDK_SUPPORT) try FLAGS.append(b.allocator, "-DNRI_ENABLE_AGILITY_SDK_SUPPORT=1");
    if (NRI_ENABLE_XLIB_SUPPORT) try FLAGS.append(b.allocator, "-DNRI_ENABLE_XLIB_SUPPORT=1");
    if (NRI_ENABLE_WAYLAND_SUPPORT) try FLAGS.append(b.allocator, "-DNRI_ENABLE_WAYLAND_SUPPORT=1");
    if (NRI_ENABLE_NGX_SDK) try FLAGS.append(b.allocator, "-DNRI_ENABLE_NGX_SDK=1");
    if (NRI_ENABLE_FFX_SDK) try FLAGS.append(b.allocator, "-DNRI_ENABLE_FFX_SDK=1");
    if (NRI_ENABLE_XESS_SDK) try FLAGS.append(b.allocator, "-DNRI_ENABLE_XESS_SDK=1");
    if (NRI_ENABLE_SHADERMAKE) try FLAGS.append(b.allocator, "-DNRI_ENABLE_SHADERMAKE=1");
    if (NRI_STREAMER_THREAD_SAFE) try FLAGS.append(b.allocator, "-DNRI_STREAMER_THREAD_SAFE=1");

    // try c_flags.appendSlice(&.{"-Wno-everything"});

    const mod_NRI_Shared = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    const libNRI_Shared = b.addLibrary(.{
        .linkage = .static,
        .name = "NRI_Shared",
        .root_module = mod_NRI_Shared,
    });

    if (NRI_ENABLE_AGILITY_SDK_SUPPORT) {
        // TODO: Add Agility SDK dependency
    }

    const lazy = struct {
        pub var value = false;
        pub fn set() void {
            @This().value = true;
        }
    };

    var NVAPI_HEADERS_PATH: ?std.Build.LazyPath = null;
    var NVAPI_LIB_PATH: ?std.Build.LazyPath = null;
    if (NRI_ENABLE_NVAPI) blk: {
        if (target.result.os.tag != .windows)
            @panic("NVAPI is only supported on Windows");

        const dep_nvapi = b.lazyDependency("nvidia_nvapi", .{}) orelse break :blk lazy.set();

        NVAPI_HEADERS_PATH = dep_nvapi.path("");

        switch (target.result.cpu.arch) {
            .x86_64 => NVAPI_LIB_PATH = dep_nvapi.path("amd64/nvapi64.lib"),
            .x86 => NVAPI_LIB_PATH = dep_nvapi.path("x86/nvapi.lib"),
            else => @panic("NVAPI: Unsupported architecture"),
        }
    }

    var AMDAGS_HEADERS_PATH: ?std.Build.LazyPath = null;
    var AMDAGS_LIB_PATH: ?std.Build.LazyPath = null;
    if (NRI_ENABLE_AMDAGS) blk: {
        if (target.result.os.tag != .windows)
            @panic("AMDAGS is only supported on Windows");

        const dep_amdags = b.lazyDependency("amd_ags", .{}) orelse break :blk lazy.set();

        AMDAGS_HEADERS_PATH = dep_amdags.path("ags_lib/inc");

        switch (target.result.cpu.arch) {
            .x86_64 => AMDAGS_LIB_PATH = dep_amdags.path("ags_lib/lib/amd_ags_x64.lib"),
            .x86 => AMDAGS_LIB_PATH = dep_amdags.path("ags_lib/lib/amd_ags_x86.lib"),
            else => @panic("AMDAGS: Unsupported architecture"),
        }
    }

    var NGX_SDK_HEADERS_PATH: ?std.Build.LazyPath = null;
    var NGX_SDK_LIB_PATH: ?std.Build.LazyPath = null;
    if (NRI_ENABLE_NGX_SDK) blk: {
        const dep_ngx = b.lazyDependency("nvidia_ngx", .{}) orelse break :blk lazy.set();
        NGX_SDK_HEADERS_PATH = dep_ngx.path("include");
        switch (target.result.os.tag) {
            .windows => {
                if (target.result.cpu.arch != .x86_64)
                    @panic("NGX SDK on Windows is only supported on x86_64");
                NGX_SDK_LIB_PATH = dep_ngx.path(b.pathJoin(&[_][]const u8{
                    "lib/Windows_x86_64/x64",
                    switch (optimize) {
                        .Debug => "nvsdk_ngx_s_dbg.lib",
                        else => "nvsdk_ngx_s.lib",
                    },
                }));
            },
            .linux => {
                if (target.result.cpu.arch != .x86_64)
                    @panic("NGX SDK on Linux is only supported on x86_64");
                NGX_SDK_LIB_PATH = dep_ngx.path("lib/Linux_x86_64/libnvsdk_ngx.a");
            },
            else => @panic("NGX SDK: Unsupported OS"),
        }
    }

    var FFX_SDK_LIB_PATH: ?std.Build.LazyPath = null;
    if (NRI_ENABLE_XESS_SDK) blk: {
        if (target.result.os.tag != .windows)
            @panic("XeSS SDK is only supported on Windows");
        const dep_xess = b.lazyDependency("intel_xess", .{}) orelse break :blk lazy.set();

        FFX_SDK_LIB_PATH = dep_xess.path("lib/libxess.lib");
    }

    if (NRI_ENABLE_NVTX_SUPPORT) {
        _ = b.lazyDependency("nvidia_nvtx", .{}) orelse lazy.set();
    }

    if (NRI_ENABLE_D3D11_SUPPORT or NRI_ENABLE_D3D12_SUPPORT) {
        if (target.result.os.tag != .windows)
            @panic("DirectX support is only available on Windows");
        try FLAGS.append(b.allocator, "-DD3D12_ERROR_INVALID_REDIST=_HRESULT_TYPEDEF_(0x887A0009L)");
        _ = b.lazyDependency("directx_headers", .{}) orelse lazy.set();
    }
    if (NRI_ENABLE_D3D12_SUPPORT) {
        if (target.result.os.tag != .windows)
            @panic("D3D12 support is only available on Windows");
        _ = b.lazyDependency("d3d12_ma", .{}) orelse lazy.set();
    }

    if (NRI_ENABLE_VK_SUPPORT) {
        _ = b.lazyDependency("vulkan_ma", .{}) orelse lazy.set();
        _ = b.lazyDependency("vulkan_headers", .{}) orelse lazy.set();
    }

    if (lazy.value)
        return;

    try FLAGS.append(b.allocator, "-DWIN32_LEAN_AND_MEAN=1");
    try FLAGS.append(b.allocator, "-DNOMINMAX=1");
    try FLAGS.append(b.allocator, "-D_CRT_SECURE_NO_WARNINGS=1");

    try FLAGS.append(b.allocator, "-Wno-missing-field-initializers");
    try FLAGS.append(b.allocator, "-Wno-nullability-completeness");

    mod_NRI_Shared.addCSourceFiles(.{
        .root = dep_nri.path(""),
        .files = &[_][]const u8{
            "Source/Shared/Shared.cpp",
        },
        .flags = FLAGS.items,
    });

    mod_NRI_Shared.addIncludePath(dep_nri.path("Include"));
    mod_NRI_Shared.addIncludePath(dep_nri.path("Source/Shared"));

    if (NRI_ENABLE_NGX_SDK) {
        mod_NRI_Shared.addIncludePath(NGX_SDK_HEADERS_PATH.?);
        mod_NRI_Shared.addObjectFile(NGX_SDK_LIB_PATH.?);
    }

    if (NRI_ENABLE_XESS_SDK) {
        mod_NRI_Shared.addObjectFile(FFX_SDK_LIB_PATH.?);
    }

    if (NRI_ENABLE_VK_SUPPORT) {
        const dep_vulkan_headers = b.lazyDependency("vulkan_headers", .{}) orelse @panic("missing Vulkan Headers");
        mod_NRI_Shared.addIncludePath(dep_vulkan_headers.path("include"));
    }

    if (NRI_ENABLE_D3D11_SUPPORT or NRI_ENABLE_D3D12_SUPPORT) {
        const dep_directx_headers = b.lazyDependency("directx_headers", .{}) orelse @panic("missing DirectX Headers");
        mod_NRI_Shared.addIncludePath(dep_directx_headers.path("include"));
        // mod_NRI_Shared.addIncludePath(b.path("src/windows/pix"));
    }

    _ = FLAGS.pop();
    _ = FLAGS.pop();

    _ = FLAGS.pop();
    _ = FLAGS.pop();
    _ = FLAGS.pop();

    b.installArtifact(libNRI_Shared);

    var libNRI_NONE: ?*std.Build.Step.Compile = null;
    if (NRI_ENABLE_NONE_SUPPORT) {
        const mod_NRI_None = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
            .sanitize_c = .off,
        });
        libNRI_NONE = b.addLibrary(.{
            .linkage = .static,
            .name = "NRI_NONE",
            .root_module = mod_NRI_None,
        });
        mod_NRI_None.addIncludePath(dep_nri.path("Include"));
        mod_NRI_None.addIncludePath(dep_nri.path("Source/Shared"));

        mod_NRI_None.addCSourceFiles(.{
            .root = dep_nri.path(""),
            .files = &[_][]const u8{
                "Source/NONE/ImplNONE.cpp",
            },
            .flags = FLAGS.items,
        });
        mod_NRI_None.linkLibrary(libNRI_Shared);

        b.installArtifact(libNRI_NONE.?);
    }

    var libNRI_D3D11: ?*std.Build.Step.Compile = null;
    if (NRI_ENABLE_D3D11_SUPPORT) {
        const dep_directx_headers = b.lazyDependency("directx_headers", .{}) orelse @panic("missing DirectX Headers");

        const mod_NRI_D3D11 = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
            .sanitize_c = .off,
        });
        libNRI_D3D11 = b.addLibrary(.{
            .linkage = .static,
            .name = "NRI_D3D11",
            .root_module = mod_NRI_D3D11,
        });
        mod_NRI_D3D11.addIncludePath(dep_nri.path("Include"));
        mod_NRI_D3D11.addIncludePath(dep_nri.path("Source/Shared"));

        mod_NRI_D3D11.addIncludePath(dep_directx_headers.path("include"));

        // mod_NRI_D3D11.addIncludePath(b.path("src/windows/pix"));

        mod_NRI_D3D11.addCSourceFiles(.{
            .root = dep_nri.path(""),
            .files = &[_][]const u8{
                "Source/D3D11/ImplD3D11.cpp",
            },
            .flags = FLAGS.items,
        });
        mod_NRI_D3D11.linkLibrary(libNRI_Shared);
        mod_NRI_D3D11.linkSystemLibrary("d3d11", .{ .needed = true });
        mod_NRI_D3D11.linkSystemLibrary("dxgi", .{ .needed = true });
        mod_NRI_D3D11.linkSystemLibrary("dxguid", .{ .needed = true });

        if (NRI_ENABLE_NVAPI) {
            mod_NRI_D3D11.addIncludePath(NVAPI_HEADERS_PATH.?);
            mod_NRI_D3D11.addObjectFile(NVAPI_LIB_PATH.?);
        }

        if (NRI_ENABLE_AMDAGS) {
            mod_NRI_D3D11.addIncludePath(AMDAGS_HEADERS_PATH.?);
        }

        b.installArtifact(libNRI_D3D11.?);
    }

    var libNRI_D3D12: ?*std.Build.Step.Compile = null;
    if (NRI_ENABLE_D3D12_SUPPORT) {
        const dep_directx_headers = b.lazyDependency("directx_headers", .{}) orelse @panic("missing DirectX Headers");
        const dep_d3d12_ma = b.lazyDependency("d3d12_ma", .{}) orelse @panic("missing D3D12 Memory Allocator");

        const mod_NRI_D3D12 = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
            .sanitize_c = .off,
        });
        libNRI_D3D12 = b.addLibrary(.{
            .linkage = .static,
            .name = "NRI_D3D12",
            .root_module = mod_NRI_D3D12,
        });
        mod_NRI_D3D12.addIncludePath(dep_nri.path("Include"));
        mod_NRI_D3D12.addIncludePath(dep_nri.path("Source/Shared"));

        mod_NRI_D3D12.addIncludePath(dep_directx_headers.path("include"));
        mod_NRI_D3D12.addIncludePath(dep_d3d12_ma.path("include"));

        // mod_NRI_D3D12.addIncludePath(b.path("src/windows/pix"));

        mod_NRI_D3D12.addCSourceFiles(.{
            .root = dep_nri.path(""),
            .files = &[_][]const u8{
                "Source/D3D12/ImplD3D12.cpp",
            },
            .flags = FLAGS.items,
        });
        mod_NRI_D3D12.addCSourceFiles(.{
            .root = dep_d3d12_ma.path(""),
            .files = &[_][]const u8{
                "src/D3D12MemAlloc.cpp",
            },
            .flags = FLAGS.items,
        });
        mod_NRI_D3D12.linkLibrary(libNRI_Shared);
        mod_NRI_D3D12.linkSystemLibrary("d3d12", .{ .needed = true });
        mod_NRI_D3D12.linkSystemLibrary("dxgi", .{ .needed = true });
        mod_NRI_D3D12.linkSystemLibrary("dxguid", .{ .needed = true });

        mod_NRI_D3D12.addIncludePath(dep_d3d12_ma.path("include"));
        mod_NRI_D3D12.addIncludePath(dep_d3d12_ma.path("src"));

        if (NRI_ENABLE_NVAPI) {
            mod_NRI_D3D12.addIncludePath(NVAPI_HEADERS_PATH.?);
            mod_NRI_D3D12.addObjectFile(NVAPI_LIB_PATH.?);
        }

        if (NRI_ENABLE_AMDAGS) {
            mod_NRI_D3D12.addIncludePath(AMDAGS_HEADERS_PATH.?);
        }

        // if (NRI_ENABLE_AGILITY_SDK_SUPPORT) {}
    }

    var libNRI_VK: ?*std.Build.Step.Compile = null;
    if (NRI_ENABLE_VK_SUPPORT) {
        const dep_vulkan_ma = b.lazyDependency("vulkan_ma", .{}) orelse @panic("missing Vulkan Memory Allocator");
        const dep_vulkan_headers = b.lazyDependency("vulkan_headers", .{}) orelse @panic("missing Vulkan Headers");

        const mod_NRI_VK = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
            .sanitize_c = .off,
        });
        libNRI_VK = b.addLibrary(.{
            .linkage = .static,
            .name = "NRI_VK",
            .root_module = mod_NRI_VK,
        });
        mod_NRI_VK.addIncludePath(dep_nri.path("Include"));
        mod_NRI_VK.addIncludePath(dep_nri.path("Source/Shared"));

        mod_NRI_VK.addIncludePath(dep_vulkan_ma.path("include"));
        mod_NRI_VK.addIncludePath(dep_vulkan_headers.path("include"));

        var VK_FLAGS: std.ArrayList([]const u8) = try FLAGS.clone(b.allocator);
        defer VK_FLAGS.deinit(b.allocator);
        switch (target.result.os.tag) {
            .windows => try VK_FLAGS.append(b.allocator, "-DVK_USE_PLATFORM_WIN32_KHR=1"),
            .driverkit, .ios, .macos, .tvos, .visionos, .watchos => {
                try VK_FLAGS.append(b.allocator, "-DVK_USE_PLATFORM_METAL_EXT=1");
                try VK_FLAGS.append(b.allocator, "-DVK_ENABLE_BETA_EXTENSIONS=1");
            },
            .linux => {
                if (NRI_ENABLE_XLIB_SUPPORT)
                    try VK_FLAGS.append(b.allocator, "-DVK_USE_PLATFORM_XLIB_KHR=1");
                if (NRI_ENABLE_WAYLAND_SUPPORT)
                    try VK_FLAGS.append(b.allocator, "-DVK_USE_PLATFORM_WAYLAND_KHR=1");
            },
            else => @panic("Unsupported OS for Vulkan"),
        }

        mod_NRI_VK.addCSourceFiles(.{
            .root = dep_nri.path(""),
            .files = &[_][]const u8{
                "Source/VK/ImplVK.cpp",
            },
            .flags = VK_FLAGS.items,
        });
        mod_NRI_VK.linkLibrary(libNRI_Shared);

        if (target.result.os.tag.isDarwin()) {
            mod_NRI_VK.linkSystemLibrary("vulkan", .{ .needed = true });
        }

        b.installArtifact(libNRI_VK.?);
    }

    var libNRI_Validation: ?*std.Build.Step.Compile = null;
    if (NRI_ENABLE_VALIDATION_SUPPORT) {
        const mod_NRI_Validation = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
            .sanitize_c = .off,
        });
        libNRI_Validation = b.addLibrary(.{
            .linkage = .static,
            .name = "NRI_Validation",
            .root_module = mod_NRI_Validation,
        });
        mod_NRI_Validation.addCSourceFiles(.{
            .root = dep_nri.path(""),
            .files = &[_][]const u8{
                "Source/Validation/ImplVal.cpp",
            },
            .flags = FLAGS.items,
        });
        mod_NRI_Validation.addIncludePath(dep_nri.path("Include"));
        mod_NRI_Validation.addIncludePath(dep_nri.path("Source/Shared"));

        mod_NRI_Validation.linkLibrary(libNRI_Shared);

        b.installArtifact(libNRI_Validation.?);
    }

    const mod_NRI = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
        .sanitize_c = .off,
    });
    const libNRI = b.addLibrary(.{
        .linkage = if (NRI_STATIC_LIBRARY) .static else .dynamic,
        .name = "NRI",
        .root_module = mod_NRI,
    });

    if (!NRI_STATIC_LIBRARY) {
        switch (target.result.os.tag) {
            .windows => try FLAGS.append(b.allocator, "-DNRI_API=extern \"C\" __declspec(dllexport)"),
            else => try FLAGS.append(b.allocator, "-DNRI_API=extern \"C\" __attribute__((visibility(\"default\")))"),
        }
    }

    mod_NRI.addCSourceFiles(.{
        .root = dep_nri.path(""),
        .files = &[_][]const u8{
            "Source/Creation/Creation.cpp",
        },
        .flags = FLAGS.items,
    });

    if (!NRI_STATIC_LIBRARY)
        _ = FLAGS.pop();

    mod_NRI.addIncludePath(dep_nri.path("Include"));
    mod_NRI.addIncludePath(dep_nri.path("Source/Shared"));

    if (NRI_ENABLE_NVTX_SUPPORT) {
        const dep_nvidia_nvtx = b.lazyDependency("nvidia_nvtx", .{}) orelse @panic("missing NVTX");
        mod_NRI.addIncludePath(dep_nvidia_nvtx.path("c/include"));
    }

    mod_NRI.linkLibrary(libNRI_Shared);

    if (NRI_ENABLE_NONE_SUPPORT)
        mod_NRI.linkLibrary(libNRI_NONE.?);
    if (NRI_ENABLE_D3D11_SUPPORT)
        mod_NRI.linkLibrary(libNRI_D3D11.?);
    if (NRI_ENABLE_D3D12_SUPPORT)
        mod_NRI.linkLibrary(libNRI_D3D12.?);
    if (NRI_ENABLE_VK_SUPPORT) {
        const dep_vulkan_headers = b.lazyDependency("vulkan_headers", .{}) orelse @panic("missing Vulkan Headers");
        mod_NRI.addIncludePath(dep_vulkan_headers.path("include"));

        mod_NRI.linkLibrary(libNRI_VK.?);
    }
    if (NRI_ENABLE_VALIDATION_SUPPORT)
        mod_NRI.linkLibrary(libNRI_Validation.?);

    b.installArtifact(libNRI);
}
