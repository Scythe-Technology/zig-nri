const Descs = @import("../Descs.zig");

const Texture = Descs.Texture;
const Queue = Descs.Queue;
const Fence = Descs.Fence;
const Device = Descs.Device;
const Dim_t = Descs.Dim_t;
const Result = Descs.Result;

pub const SwapChain = opaque {};

/// Special "initialValue" for "CreateFence" needed to create swap chain related semaphores
pub const SWAPCHAIN_SEMAPHORE: u64 = @as(u64, @bitCast(@as(i64, -1)));

/// Color space:
///  - BT.709 - LDR https://en.wikipedia.org/wiki/Rec._709
///  - BT.2020 - HDR https://en.wikipedia.org/wiki/Rec._2020
/// Transfer function:
///  - G10 - linear (gamma 1.0)
///  - G22 - sRGB (gamma ~2.2)
///  - G2084 - SMPTE ST.2084 (Perceptual Quantization)
/// Bits per channel:
///  - 8, 10, 16 (float)
pub const SwapChainFormat = enum(u8) {
    BT709_G10_16BIT,
    BT709_G22_8BIT,
    BT709_G22_10BIT,
    BT2020_G2084_10BIT,
};

/// https://registry.khronos.org/vulkan/specs/latest/man/html/VkPresentScalingFlagBitsKHR.html
pub const Scaling = enum(u8) {
    ONE_TO_ONE, // no scaling, 1:1 pixel mapping
    STRETCH, // minified or magnified stretching
};

/// https://registry.khronos.org/vulkan/specs/latest/man/html/VkPresentGravityFlagBitsKHR.html
pub const Gravity = enum(u8) {
    MIN, // pixels will gravitate towards the top or left side of the surface (Windows style)
    MAX, // VK: pixels will gravitate towards the bottom or right side of the surface
    CENTERED, // VK: pixels will be centered in the surface
};

pub const SwapChainFlags = packed struct(u8) {
    pub const NONE: SwapChainFlags = @bitCast(@as(u8, 0));

    vsync: bool, // cap framerate to the monitor refresh rate
    waitable: bool, // unlock "WaitForPresent" reducing latency (requires "features.waitableSwapChain")
    allow_tearing: bool, // allow screen tearing if possible
    allow_low_latency: bool, // allow "NRILowLatency" functionality (requires "features.lowLatency")

    _: u4 = 0,
};

pub const SwapChainBits = enum(u8) {
    NONE = 0,
    VSYNC = 1 << 0, // cap framerate to the monitor refresh rate
    WAITABLE = 1 << 1, // unlock "WaitForPresent" reducing latency (requires "features.waitableSwapChain")
    ALLOW_TEARING = 1 << 2, // allow screen tearing if possible
    ALLOW_LOW_LATENCY = 1 << 3, // allow "NRILowLatency" functionality (requires "features.lowLatency")
};

pub const WindowsWindow = extern struct { // Expects "WIN32" platform macro
    /// HWND
    hwnd: ?*anyopaque,
};

pub const X11Window = extern struct { // Expects "NRI_ENABLE_XLIB_SUPPORT"
    /// Display
    dpy: ?*anyopaque,
    /// Window
    window: u64,
};

pub const WaylandWindow = extern struct { // Expects "NRI_ENABLE_WAYLAND_SUPPORT"
    /// wl_display
    display: ?*anyopaque,
    /// wl_surface
    surface: ?*anyopaque,
};

pub const MetalWindow = extern struct { // Expects "APPLE" platform macro
    /// CAMetalLayer
    ca_metal_layer: ?*anyopaque,
};

pub const Window = extern struct {
    // Only one entity must be initialized
    windows: WindowsWindow,
    x11: X11Window,
    wayland: WaylandWindow,
    metal: MetalWindow,
};

// SwapChain textures will be created as "color attachment" resources
// queuedFrameNum = 0 - auto-selection between 1 (for waitable) or 2 (otherwise)
// queuedFrameNum = 2 - recommended if the GPU frame time is less than the desired frame time, but the sum of 2 frames is greater
pub const SwapChainDesc = extern struct {
    window: Window,
    /// GRAPHICS or COMPUTE (requires "features.presentFromCompute")
    queue: *const Queue,
    width: Dim_t = 0,
    height: Dim_t = 0,
    /// desired value, real value must be queried using "GetSwapChainTextures"
    texture_num: u8 = 0,
    /// desired format, real value must be queried using "GetTextureDesc" for one of the swap chain textures
    format: SwapChainFormat = .BT709_G10_16BIT,
    flags: SwapChainFlags = .NONE,
    /// aka "max frame latency", aka "number of frames in flight" (mostly for D3D11)
    queued_frame_num: u8 = 0,

    // Present scaling and positioning, silently ignored if "features.resizableSwapChain" is not supported or not supported by the implicitly choosen present mode
    /// VK: if scaling is not supported, "OUT_OF_DATE" error is triggered on resizing
    scaling: Scaling = .ONE_TO_ONE,
    gravity_x: Gravity = .MIN,
    gravity_y: Gravity = .MIN,
};

pub const ChromaticityCoords = extern struct {
    pub const ZEROS: ChromaticityCoords = .{ .x = 0, .y = 0 };

    x: f32 = 0, // [0; 1]
    y: f32 = 0, // [0; 1]
};

/// Describes color settings and capabilities of the closest display:
///  - Luminance provided in nits (cd/m2)
///  - SDR = standard dynamic range
///  - LDR = low dynamic range (in many cases LDR == SDR)
///  - HDR = high dynamic range, assumes G2084:
///      - BT709_G10_16BIT: HDR gets enabled and applied implicitly if Windows HDR is enabled
///      - BT2020_G2084_10BIT: HDR requires explicit color conversions and enabled HDR in Windows
///  - "SDR scale in HDR mode" = sdrLuminance / 80
pub const DisplayDesc = extern struct {
    red_primary: ChromaticityCoords = .ZEROS,
    green_primary: ChromaticityCoords = .ZEROS,
    blue_primary: ChromaticityCoords = .ZEROS,
    white_point: ChromaticityCoords = .ZEROS,
    min_luminance: f32 = 0,
    max_luminance: f32 = 0,
    max_full_frame_luminance: f32 = 0,
    sdr_luminance: f32 = 0,
    is_hdr: bool = false,
};

// Threadsafe: yes
pub const SwapChainInterface = extern struct {
    CreateSwapChain: *const fn (device: *Device, swapChainDesc: *const SwapChainDesc, swapChain: *?*SwapChain) callconv(.c) Result,
    DestroySwapChain: *const fn (swapChain: *SwapChain) callconv(.c) void,
    GetSwapChainTextures: *const fn (swapChain: *const SwapChain, textureNum: *u32) callconv(.c) ?[*]?*Texture,

    // Returns "FAILURE" if swap chain's window is outside of all monitors
    GetDisplayDesc: *const fn (swapChain: *SwapChain, displayDesc: *DisplayDesc) callconv(.c) Result, // Returns "FAILURE" if swap chain's window is outside of all monitors

    // VK only: may return "OUT_OF_DATE", fences must be created with "SWAPCHAIN_SEMAPHORE" initial value
    AcquireNextTexture: *const fn (swapChain: *SwapChain, acquireSemaphore: *Fence, textureIndex: *u32) callconv(.c) Result,
    WaitForPresent: *const fn (swapChain: *SwapChain) callconv(.c) Result, // call once right before input sampling (must be called starting from the 1st frame)
    QueuePresent: *const fn (swapChain: *SwapChain, releaseSemaphore: *Fence) callconv(.c) Result,
};
