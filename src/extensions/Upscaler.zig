const Descs = @import("../Descs.zig");

const Device = Descs.Device;
const Dim2_t = Descs.Dim2_t;
const Float2_t = Descs.Float2_t;
const Texture = Descs.Texture;
const Descriptor = Descs.Descriptor;
const CommandBuffer = Descs.CommandBuffer;
const Result = Descs.Result;

pub const Upscaler = opaque {};

pub const UpscalerType = enum(u8) {
    /// NVIDIA Image Scaling
    /// sharpener-upscaler, cross vendor
    NIS,
    /// AMD FidelityFX Super Resolution
    /// upscaler, cross vendor
    FSR,
    /// INTEL XeSS Super Resolution
    /// upscaler, cross vendor
    XESS,
    /// NVIDIA Deep Learning Super Resolution
    /// upscaler, NVIDIA only
    DLSR,
    /// NVIDIA Deep Learning Ray Reconstruction
    /// upscaler-denoiser, NVIDIA only
    DLRR,
};

pub const UpscalerMode = enum(u8) {
    // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
    // 1.0x                 8
    NATIVE,
    // 1.3x                 14
    ULTRA_QUALITY,
    // 1.5x                 18
    QUALITY,
    // 1.7x                 23
    BALANCED,
    // 2.0x                 32
    PERFORMANCE,
    // 3.0x                 72
    ULTRA_PERFORMANCE,
};

pub const UpscalerFlags = packed struct(u16) {
    pub const NONE: UpscalerFlags = @bitCast(@as(u16, 0));

    /// "input" uses colors in High-Dynamic Range (HDR)
    hdr: bool = false,
    /// "input" uses Low-Dynamic Range (LDR) colors in sRGB space
    srgb: bool = false,
    /// "exposure" texture is provided (automatic exposure otherwise)
    use_exposure: bool = false,
    /// "reactive" texture is provided
    use_reactive: bool = false,
    /// "depth" is inverted, i.e. the near plane is mapped to 1
    depth_inverted: bool = false,
    /// "depth" uses INF far plane
    depth_infinite: bool = false,
    /// "depth" is linear viewZ (HW otherwise)
    depth_linear: bool = false,
    /// "mv" are rendered at upscale resolution
    mv_upscaled: bool = false,
    /// "mv" include jitter
    mv_jittered: bool = false,
    _padding: u7 = 0,
};

pub const UpscalerBits = enum(u16) {
    NONE = 0,
    HDR = 1 << 0,
    SRGB = 1 << 1,
    USE_EXPOSURE = 1 << 2,
    USE_REACTIVE = 1 << 3,
    DEPTH_INVERTED = 1 << 4,
    DEPTH_INFINITE = 1 << 5,
    DEPTH_LINEAR = 1 << 6,
    MV_UPSCALED = 1 << 7,
    MV_JITTERED = 1 << 8,
};

pub const DispatchUpscaleFlags = packed struct(u8) {
    pub const NONE: DispatchUpscaleFlags = @bitCast(@as(u8, 0));

    /// restart accumulation
    reset_history: bool = false,
    /// ("DLRR" only) if set, "specularMvOrHitT" represents "specular motion" not "hit distance"
    use_specular_motion: bool = false,
    _padding: u6 = 0,
};

pub const DispatchUpscaleBits = enum(u8) {
    NONE = 0,
    RESET_HISTORY = 1 << 0,
    USE_SPECULAR_MOTION = 1 << 1,
};

pub const UpscalerDesc = extern struct {
    /// output resolution
    upscale_resolution: Dim2_t = 0,
    type: UpscalerType = .NIS,
    /// not needed for NIS
    mode: UpscalerMode = .NATIVE,
    flags: UpscalerFlags = .NONE,
    /// preset for DLSR or XESS (0 default, >1 presets A, B, C...)
    preset: u8 = 0,
    /// a non-copy-only command buffer in opened state, submission must be done manually ("wait for idle" executed, if not provided)
    command_buffer: ?*CommandBuffer = null,
};

pub const UpscalerProps = extern struct {
    /// per dimension scaling factor
    scaling_factor: f32 = false,
    /// mip bias for materials textures, computed as "-log2(scalingFactor) - 1" (keep an eye on normal maps)
    mip_bias: f32,
    /// output resolution
    upscale_resolution: Dim2_t,
    //// optimal render resolution
    render_resolution: Dim2_t,
    render_resolution_min: Dim2_t,
    jitter_phase_num: u8,
};

pub const UpscalerResource = extern struct {
    texture: ?*Texture = null,
    descriptor: ?*Descriptor = null,
};

// For FSR, XESS, DLSR
pub const UpscalerGuides = extern struct {
    /// .xy - surface motion
    mv: UpscalerResource,
    // .x - HW depth
    depth: UpscalerResource,
    /// .x - 1x1 exposure
    exposure: UpscalerResource = .{},
    /// .x - bias towards "input"
    reactive: UpscalerResource = .{},
};

/// For DLRR
pub const DenoiserGuides = extern struct {
    /// .xy - surface motion
    mv: UpscalerResource,
    /// .x - HW or linear depth
    depth: UpscalerResource,
    /// .xyz - world-space normal (not encoded), .w - linear roughness
    normal_roughness: UpscalerResource,
    /// .xyz - diffuse albedo (LDR sky color for sky)
    diffuse_albedo: UpscalerResource,
    /// .xyz - specular albedo (environment BRDF)
    specular_albedo: UpscalerResource,
    /// .xy - specular virtual motion of the reflected world, or .x - specular hit distance otherwise
    specular_mv_or_hit_t: UpscalerResource,
    /// .x - 1x1 exposure
    exposure: UpscalerResource = .{},
    /// .x - bias towards "input"
    reactive: UpscalerResource = .{},
    /// .x - subsurface scattering, computed as "Luminance(colorAfterSSS - colorBeforeSSS)"
    sss: UpscalerResource = .{},
};

pub const NISSettings = extern struct {
    /// [0; 1]
    sharpness: f32,
};

pub const FSRSettings = extern struct {
    /// distance to the near plane (units)
    z_near: f32 = 0,
    /// distance to the far plane, unused if "DEPTH_INFINITE" is set (units)
    z_far: f32 = 0,
    /// vertical field of view angle (radians)
    vertical_fov: f32 = 0,
    /// the time elapsed since the last frame (ms)
    frame_time: f32 = 0,
    /// for converting view space units to meters (m/unit)
    view_space_to_meters_factor: f32 = 0,
    /// [0; 1]
    sharpness: f32 = 0,
};

pub const DLRRSettings = extern struct {
    /// {Xx, Yx, Zx, 0, Xy, Yy, Zy, 0, Xz, Yz, Zz, 0, Tx, Ty, Tz, 1}, where {X, Y, Z} - axises, T - translation
    world_to_view_matrix: [16]f32,
    /// {-, -, -, 0, -, -, -, 0, -, -, -, A, -, -, -, B}, where {A; B} = {0; 1} for ortho or {-1/+1; 0} for perspective projections
    view_to_clip_matrix: [16]f32,
};

pub const DispatchUpscaleDesc = extern struct {
    // Output (required "SHADER_RESOURCE_STORAGE" for resource state & descriptor)
    output: UpscalerResource,

    // Input (required "SHADER_RESOURCE" for resource state & descriptor)
    input: UpscalerResource,

    // Guides (required "SHADER_RESOURCE" for resource states & descriptors)
    guides: extern union {
        upscaler: UpscalerGuides,
        denoiser: DenoiserGuides,
    },

    // Settings
    settings: extern union {
        nis: NISSettings,
        fsr: FSRSettings,
        dlrr: DLRRSettings,
    },

    current_resolution: Dim2_t = 0,
    camera_jitter: Float2_t = 0,
    mv_scale: Float2_t = 0,
    flags: DispatchUpscaleFlags = 0,
};

// Threadsafe: yes
pub const UpscalerInterface = extern struct {
    CreateUpscaler: *const fn (device: *Device, upscalerDesc: *const UpscalerDesc, upscaler: *?*Upscaler) callconv(.c) Result,
    DestroyUpscaler: *const fn (upscaler: ?*Upscaler) callconv(.c) void,

    IsUpscalerSupported: *const fn (device: *const Device, @"type": UpscalerType) callconv(.c) bool,
    GetUpscalerProps: *const fn (upscaler: *const Upscaler, upscalerProps: *UpscalerProps) callconv(.c) void,

    // Command buffer
    // zig fmt: off
    // {
        // Dispatch (changes descriptor pool, pipeline layout and pipeline, barriers are externally controlled)
        CmdDispatchUpscale: *const fn (commandBuffer: *CommandBuffer, upscaler: *Upscaler, dispatchUpscaleDesc: *const DispatchUpscaleDesc) callconv(.c) void,
    // }
    // zig fmt: on
};
