const std = @import("std");

// Entities
/// a synchronization primitive that can be used to insert a dependency between queue operations or between a queue operation and the host
pub const Fence = opaque {};
/// a logical queue, providing access to a HW queue
pub const Queue = opaque {};
/// a memory blob allocated on DEVICE or HOST
pub const Memory = opaque {};
/// a buffer object: linear arrays of data
pub const Buffer = opaque {};
/// a logical device
pub const Device = opaque {};
/// a texture object: multidimensional arrays of data
pub const Texture = opaque {};
/// a collection of state needed for rendering: shaders + fixed
pub const Pipeline = opaque {};
/// an array of presentable images that are associated with a surface
pub const SwapChain = opaque {};
/// a collection of queries of the same type
pub const QueryPool = opaque {};
/// a handle or pointer to a resource (potentially with a header)
pub const Descriptor = opaque {};
/// used to record commands which can be subsequently submitted to a device queue for execution (aka command list)
pub const CommandBuffer = opaque {};
/// a continuous set of descriptors
pub const DescriptorSet = opaque {};
/// maintains a pool of descriptors, descriptor sets are allocated from (aka descriptor heap)
pub const DescriptorPool = opaque {};
/// determines the interface between shader stages and shader resources (aka root signature)
pub const PipelineLayout = opaque {};
/// an object that command buffer memory is allocated from
pub const CommandAllocator = opaque {};

// Basic types
pub const Sample_t = u8;
pub const Dim_t = u16;
pub const Object = void;

pub const Uid_t = extern struct {
    low: u64,
    high: u64,
};

pub const Dim2_t = extern struct {
    w: Dim_t,
    h: Dim_t,
};

pub const Float2_t = extern struct {
    x: f32,
    y: f32,
};

// Aliases
pub const BGRA_UNUSED: u32 = 0;
pub const ALL: u32 = 0;
pub const WHOLE_SIZE: Dim_t = 0;
pub const REMAINING: Dim_t = 0;

// // Readability
// #define NriOptional // i.e. can be 0 (keep an eye on comments)
// #define NriOut      // highlights an output argument

// // Implicit memory heaps for "CreatePlacedX"
// #define NriDeviceHeap 0, 0
// #define NriDeviceUploadHeap 0, 1
// #define NriHostUploadHeap 0, 2
// #define NriHostReadbackHeap 0, 3

pub const GraphicsAPI = enum(u8) {
    /// Supports everything, does nothing, returns dummy non-NULL objects and ~0-filled descs, available if "NRI_ENABLE_NONE_SUPPORT = ON" in CMake
    NONE,
    /// Direct3D 11 (feature set 11.1), available if "NRI_ENABLE_D3D11_SUPPORT = ON" in CMake (https://microsoft.github.io/DirectX-Specs/d3d/archive/D3D11_3_FunctionalSpec.htm)
    D3D11,
    /// Direct3D 12 (D3D12_SDK_VERSION 4 or 618+), available if "NRI_ENABLE_D3D12_SUPPORT = ON" in CMake (https://microsoft.github.io/DirectX-Specs/)
    D3D12,
    /// Vulkan 1.4, 1.3 or 1.2+ (can be used on MacOS via MoltenVK), available if "NRI_ENABLE_VK_SUPPORT = ON" in CMake (https://registry.khronos.org/vulkan/specs/latest/html/vkspec.html)
    VK,
};

pub const Result = enum(i8) {
    // All bad, but optionally require an action ("callbackInterface.AbortExecution" is not triggered)
    /// may be returned by "QueueSubmit*", "*WaitIdle", "AcquireNextTexture", "QueuePresent", "WaitForPresent"
    DEVICE_LOST = -3,
    /// VK: swap chain is out of date, can be triggered if "features.resizableSwapChain" is not supported
    OUT_OF_DATE = -2,
    /// D3D: some interfaces are missing (potential reasons: unable to load "D3D12Core.dll", version or SDK mismatch)
    INVALID_SDK = -1,

    // All good
    SUCCESS = 0,

    // All bad, most likely a crash or a validation error will happen next ("callbackInterface.AbortExecution" is triggered)
    FAILURE = 1,
    INVALID_ARGUMENT = 2,
    OUT_OF_MEMORY = 3,
    /// if enabled, NRI validation can promote some to "INVALID_ARGUMENT"
    UNSUPPORTED = 4,

    pub fn success(result: Result) !void {
        return switch (result) {
            .DEVICE_LOST => return error.DeviceLost,
            .OUT_OF_DATE => return error.OutOfDate,
            .INVALID_SDK => return error.InvalidSDK,
            .SUCCESS => {},
            .FAILURE => return error.Failure,
            .INVALID_ARGUMENT => return error.InvalidArgument,
            .OUT_OF_MEMORY => return error.OutOfMemory,
            .UNSUPPORTED => return error.Unsupported,
        };
    }
};

/// The viewport origin is top-left (D3D native) by default, but can be changed to bottom-left (VK native)
/// https://docs.vulkan.org/refpages/latest/refpages/source/VkViewport.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_viewport
pub const Viewport = extern struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    depth_min: f32,
    depth_max: f32,
    /// expects "features.viewportOriginBottomLeft"
    origin_bottom_left: bool,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkRect2D.html
pub const Rect = extern struct {
    x: i16,
    y: i16,
    width: Dim_t,
    height: Dim_t,
};

pub const Color32f = extern struct {
    pub const zeros: Color32f = .{ .x = 0, .y = 0, .z = 0, .w = 0 };

    x: f32,
    y: f32,
    z: f32,
    w: f32,
};

pub const Color32ui = extern struct {
    pub const zeros: Color32ui = .{ .x = 0, .y = 0, .z = 0, .w = 0 };

    x: u32,
    y: u32,
    z: u32,
    w: u32,
};

pub const Color32i = extern struct {
    pub const zeros: Color32i = .{ .x = 0, .y = 0, .z = 0, .w = 0 };

    x: i32,
    y: i32,
    z: i32,
    w: i32,
};

pub const DepthStencil = extern struct {
    depth: f32 = 0,
    stencil: u8 = 0,
};

pub const Color = extern union {
    f: Color32f,
    ui: Color32ui,
    i: Color32i,
};

pub const ClearValue = extern union {
    depth_stencil: DepthStencil,
    color: Color,
};

pub const SampleLocation = extern struct {
    /// [-8; 7]
    x: i8,
    /// [-8; 7]
    y: i8,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkFormat.html
/// https://learn.microsoft.com/en-us/windows/win32/api/dxgiformat/ne-dxgiformat-dxgi_format
/// left -> right : low -> high bits
/// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
/// To demote sRGB use the previous format, i.e. "format - 1"
///                                            STORAGE_WRITE_WITHOUT_FORMAT
///                                           STORAGE_READ_WITHOUT_FORMAT |
///                                                       VERTEX_BUFFER | |
///                                            STORAGE_BUFFER_ATOMICS | | |
///                                                  STORAGE_BUFFER | | | |
///                                                        BUFFER | | | | |
///                                         MULTISAMPLE_RESOLVE | | | | | |
///                                            MULTISAMPLE_8X | | | | | | |
///                                          MULTISAMPLE_4X | | | | | | | |
///                                        MULTISAMPLE_2X | | | | | | | | |
///                                               BLEND | | | | | | | | | |
///                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
///                                COLOR_ATTACHMENT | | | | | | | | | | | |
///                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
///                             STORAGE_TEXTURE | | | | | | | | | | | | | |
///                                   TEXTURE | | | | | | | | | | | | | | |
///                                         | | | | | | | | | | | | | | | |
pub const Format = enum(u8) {
    //  |      FormatSupportBits      |
    /// . . . . . . . . . . . . . . . .
    UNKNOWN,

    // Plain: 8 bits per channel
    /// + + . + . + + + + + + + . + + +
    R8_UNORM,
    /// + + . + . + + + + + + + . + + +
    R8_SNORM,
    /// + + . + . . + + + . + + . + + +  // SHADING_RATE compatible, see NRI_SHADING_RATE macro
    R8_UINT,
    /// + + . + . . + + + . + + . + + +
    R8_SINT,

    /// + + . + . + + + + + + + . + + +  // "AccelerationStructure" compatible (requires "tiers.rayTracing >= 2")
    RG8_UNORM,
    /// + + . + . + + + + + + + . + + +  // "AccelerationStructure" compatible (requires "tiers.rayTracing >= 2")
    RG8_SNORM,
    /// + + . + . . + + + . + + . + + +
    RG8_UINT,
    /// + + . + . . + + + . + + . + + +
    RG8_SINT,

    /// + + . + . + + + + + + + . + + +
    BGRA8_UNORM,
    /// + . . + . + + + + + . . . . . .
    BGRA8_SRGB,

    /// + + . + . + + + + + + + . + + +  // "AccelerationStructure" compatible (requires "tiers.rayTracing >= 2")
    RGBA8_UNORM,
    /// + . . + . + + + + + . . . . . .
    RGBA8_SRGB,
    /// + + . + . + + + + + + + . + + +  // "AccelerationStructure" compatible (requires "tiers.rayTracing >= 2")
    RGBA8_SNORM,
    /// + + . + . . + + + . + + . + + +
    RGBA8_UINT,
    /// + + . + . . + + + . + + . + + +
    RGBA8_SINT,

    // Plain: 16 bits per channel
    /// + + . + . + + + + + + + . + + +
    R16_UNORM,
    /// + + . + . + + + + + + + . + + +
    R16_SNORM,
    /// + + . + . . + + + . + + . + + +
    R16_UINT,
    /// + + . + . . + + + . + + . + + +
    R16_SINT,
    /// + + . + . + + + + + + + . + + +
    R16_SFLOAT,

    /// + + . + . + + + + + + + . + + +  // "AccelerationStructure" compatible (requires "tiers.rayTracing >= 2")
    RG16_UNORM,
    /// + + . + . + + + + + + + . + + +  // "AccelerationStructure" compatible
    RG16_SNORM,
    /// + + . + . . + + + . + + . + + +
    RG16_UINT,
    /// + + . + . . + + + . + + . + + +
    RG16_SINT,
    /// + + . + . + + + + + + + . + + +  // "AccelerationStructure" compatible
    RG16_SFLOAT,

    /// + + . + . + + + + + + + . + + +  // "AccelerationStructure" compatible (requires "tiers.rayTracing >= 2")
    RGBA16_UNORM,
    /// + + . + . + + + + + + + . + + +  // "AccelerationStructure" compatible
    RGBA16_SNORM,
    /// + + . + . . + + + . + + . + + +
    RGBA16_UINT,
    /// + + . + . . + + + . + + . + + +
    RGBA16_SINT,
    /// + + . + . + + + + + + + . + + +  // "AccelerationStructure" compatible
    RGBA16_SFLOAT,

    // Plain: 32 bits per channel
    /// + + + + . . + + + . + + + + + +
    R32_UINT,
    /// + + + + . . + + + . + + + + + +
    R32_SINT,
    /// + + + + . + + + + + + + + + + +
    R32_SFLOAT,

    /// + + . + . . + + + . + + . + + +
    RG32_UINT,
    /// + + . + . . + + + . + + . + + +
    RG32_SINT,
    /// + + . + . + + + + + + + . + + +  // "AccelerationStructure" compatible
    RG32_SFLOAT,

    /// + . . . . . . . . . + . . + . .
    RGB32_UINT,
    /// + . . . . . . . . . + . . + . .
    RGB32_SINT,
    /// + . . . . . . . . + + . . + . .
    RGB32_SFLOAT,

    /// + + . + . . + + + . + + . + + +
    RGBA32_UINT,
    /// + + . + . . + + + . + + . + + +
    RGBA32_SINT,
    /// + + . + . + + + + + + + . + + +  // "AccelerationStructure" compatible
    RGBA32_SFLOAT,

    // Packed: 16 bits per pixel
    /// + . . + . + + + + + . . . . . .
    B5_G6_R5_UNORM,
    /// + . . + . + + + + + . . . . . .
    B5_G5_R5_A1_UNORM,
    /// + . . . . . . . . + . . . . . .
    B4_G4_R4_A4_UNORM,

    // Packed: 32 bits per pixel
    /// + + . + . + + + + + + + . + + +  // "AccelerationStructure" compatible (requires "tiers.rayTracing >= 2")
    R10_G10_B10_A2_UNORM,
    /// + + . + . . + + + . + + . + + +
    R10_G10_B10_A2_UINT,
    /// + + . + . + + + + + + + . + + +
    R11_G11_B10_UFLOAT,
    /// + . . . . . . . . . . . . . . .
    R9_G9_B9_E5_UFLOAT,

    // Block-compressed
    /// + . . . . . . . . . . . . . . .
    BC1_RGBA_UNORM,
    /// + . . . . . . . . . . . . . . .
    BC1_RGBA_SRGB,
    /// + . . . . . . . . . . . . . . .
    BC2_RGBA_UNORM,
    /// + . . . . . . . . . . . . . . .
    BC2_RGBA_SRGB,
    /// + . . . . . . . . . . . . . . .
    BC3_RGBA_UNORM,
    /// + . . . . . . . . . . . . . . .
    BC3_RGBA_SRGB,
    /// + . . . . . . . . . . . . . . .
    BC4_R_UNORM,
    /// + . . . . . . . . . . . . . . .
    BC4_R_SNORM,
    /// + . . . . . . . . . . . . . . .
    BC5_RG_UNORM,
    /// + . . . . . . . . . . . . . . .
    BC5_RG_SNORM,
    /// + . . . . . . . . . . . . . . .
    BC6H_RGB_UFLOAT,
    /// + . . . . . . . . . . . . . . .
    BC6H_RGB_SFLOAT,
    /// + . . . . . . . . . . . . . . .
    BC7_RGBA_UNORM,
    /// + . . . . . . . . . . . . . . .
    BC7_RGBA_SRGB,

    // Depth-stencil
    /// . . . . + . + + + . . . . . . .
    D16_UNORM,
    /// . . . . + . + + + . . . . . . .
    D24_UNORM_S8_UINT,
    /// . . . . + . + + + . . . . . . .
    D32_SFLOAT,
    /// . . . . + . + + + . . . . . . .
    D32_SFLOAT_S8_UINT_X24,

    // Depth-stencil (as a shader resource view)
    /// + . . . . . . . . . . . . . . .  // .x - depth
    R24_UNORM_X8,
    /// + . . . . . . . . . . . . . . .  // .y - stencil
    X24_G8_UINT,
    /// + . . . . . . . . . . . . . . .  // .x - depth
    R32_SFLOAT_X8_X24,
    /// + . . . . . . . . . . . . . . .  // .y - stencil
    X32_G8_UINT_X24,
};

/// https://learn.microsoft.com/en-us/windows/win32/direct3d12/subresources#plane-slice
/// https://docs.vulkan.org/refpages/latest/refpages/source/VkImageAspectFlagBits.html
pub const PlaneFlags = packed struct(u8) {
    pub const ALL: PlaneFlags = @bitCast(@as(u8, 0));

    /// indicates "color" plane (same as "ALL" for color formats)
    color: bool = false,

    // D3D11: can't be addressed individually in "copy" and "resolve" operations
    /// indicates "depth" plane (same as "ALL" for depth-only formats)
    depth: bool = false,
    /// indicates "stencil" plane in depth-stencil formats
    stencil: bool = false,

    _: u5 = 0,

    pub fn bits(self: PlaneFlags) u8 {
        return @bitCast(self);
    }
};

/// https://learn.microsoft.com/en-us/windows/win32/direct3d12/subresources#plane-slice
/// https://docs.vulkan.org/refpages/latest/refpages/source/VkImageAspectFlagBits.html
pub const PlaneBits = enum(u8) {
    ALL = 0,
    /// indicates "color" plane (same as "ALL" for color formats)
    COLOR = 1 << 0,

    // D3D11: can't be addressed individually in "copy" and "resolve" operations
    /// indicates "depth" plane (same as "ALL" for depth-only formats)
    DEPTH = 1 << 1,
    /// indicates "stencil" plane in depth-stencil formats
    STENCIL = 1 << 2,
};

/// A bit represents a feature, supported by a format
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_feature_data_format_support
/// https://docs.vulkan.org/refpages/latest/refpages/source/VkFormatFeatureFlagBits2.html
pub const FormatSupportFlags = packed struct(u16) {
    pub const UNSUPPORTED: FormatSupportFlags = @bitCast(@as(u16, 0));

    texture: bool = false,
    storage_texture: bool = false,
    /// other than Load / Store
    storage_texture_atomics: bool = false,
    color_attachment: bool = false,
    depth_stencil_attachment: bool = false,
    blend: bool = false,
    multisample_2x: bool = false,
    multisample_4x: bool = false,
    multisample_8x: bool = false,
    multisample_resolve: bool = false,

    /// Buffer
    buffer: bool = false,
    storage_buffer: bool = false,
    /// other than Load / Store
    storage_buffer_atomics: bool = false,
    vertex_buffer: bool = false,

    /// Texture / buffer
    storage_read_without_format: bool = false,
    storage_write_without_format: bool = false,

    pub fn bits(self: FormatSupportFlags) u16 {
        return @bitCast(self);
    }
};

/// A bit represents a feature, supported by a format
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_feature_data_format_support
/// https://docs.vulkan.org/refpages/latest/refpages/source/VkFormatFeatureFlagBits2.html
pub const FormatSupportBits = enum(u16) {
    UNSUPPORTED = 0,

    // Texture
    TEXTURE = 1 << 0,
    STORAGE_TEXTURE = 1 << 1,
    /// other than Load / Store
    STORAGE_TEXTURE_ATOMICS = 1 << 2,
    COLOR_ATTACHMENT = 1 << 3,
    DEPTH_STENCIL_ATTACHMENT = 1 << 4,
    BLEND = 1 << 5,
    MULTISAMPLE_2X = 1 << 6,
    MULTISAMPLE_4X = 1 << 7,
    MULTISAMPLE_8X = 1 << 8,
    MULTISAMPLE_RESOLVE = 1 << 9,

    // Buffer
    BUFFER = 1 << 10,
    STORAGE_BUFFER = 1 << 11,
    /// other than Load / Store
    STORAGE_BUFFER_ATOMICS = 1 << 12,
    VERTEX_BUFFER = 1 << 13,

    // Texture / buffer
    STORAGE_READ_WITHOUT_FORMAT = 1 << 14,
    STORAGE_WRITE_WITHOUT_FORMAT = 1 << 15,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineStageFlagBits2.html
/// https://microsoft.github.io/DirectX-Specs/d3d/D3D12EnhancedBarriers.html#d3d12_barrier_sync
pub const StageFlags = packed struct(u32) {
    pub const ALL: StageFlags = @bitCast(@as(u32, 0));
    pub const NONE: StageFlags = @bitCast(@as(u32, 0x7FFFFFFF));

    // Umbrella stages
    /// Tessellation control + evaluation shaders
    pub const TESSELLATION_SHADERS: StageFlags = .{ .tess_control_shader = true, .tess_evaluation_shader = true };
    /// Task + mesh shaders
    pub const MESH_SHADERS: StageFlags = .{ .task_shader = true, .mesh_shader = true };
    /// All graphics stages (index input, all shaders and attachments)
    pub const GRAPHICS_SHADERS: StageFlags = .{
        .vertex_shader = true,
        .tess_control_shader = true,
        .tess_evaluation_shader = true,
        .geometry_shader = true,
        .task_shader = true,
        .mesh_shader = true,
        .fragment_shader = true,
    };
    /// All ray tracing stages (all shaders)
    pub const RAY_TRACING_SHADERS: StageFlags = .{
        .raygen_shader = true,
        .miss_shader = true,
        .intersection_shader = true,
        .closest_hit_shader = true,
        .any_hit_shader = true,
        .callable_shader = true,
    };
    /// All shaders (graphics, compute and ray tracing)
    pub const ALL_SHADERS: StageFlags = .{
        .vertex_shader = true,
        .tess_control_shader = true,
        .tess_evaluation_shader = true,
        .geometry_shader = true,
        .task_shader = true,
        .mesh_shader = true,
        .fragment_shader = true,
        .compute_shader = true,
        .raygen_shader = true,
        .miss_shader = true,
        .intersection_shader = true,
        .closest_hit_shader = true,
        .any_hit_shader = true,
        .callable_shader = true,
    };
    /// Index input + all graphics shaders and attachments
    pub const GRAPHICS: StageFlags = .{
        .index_input = true,
        .vertex_shader = true,
        .tess_control_shader = true,
        .tess_evaluation_shader = true,
        .geometry_shader = true,
        .task_shader = true,
        .mesh_shader = true,
        .fragment_shader = true,
        .depth_stencil_attachment = true,
        .color_attachment = true,
    };

    // Graphics // Invoked by "CmdDraw*"
    /// Index buffer consumption
    index_input: bool = false,
    /// Vertex shader
    vertex_shader: bool = false,
    /// Tessellation control (hull) shader
    tess_control_shader: bool = false,
    /// Tessellation evaluation (domain) shader
    tess_evaluation_shader: bool = false,
    /// Geometry shader
    geometry_shader: bool = false,
    /// Task (amplification) shader
    task_shader: bool = false,
    /// Mesh shader
    mesh_shader: bool = false,
    /// Fragment (pixel) shader
    fragment_shader: bool = false,
    /// Depth-stencil R/W operations
    depth_stencil_attachment: bool = false,
    /// Color R/W operations
    color_attachment: bool = false,

    // Compute // Invoked by "CmdDispatch*" (not Rays)
    /// Compute shader
    compute_shader: bool = false,

    // Ray tracing // Invoked by "CmdDispatchRays*"
    /// Ray generation shader
    raygen_shader: bool = false,
    /// Miss shader
    miss_shader: bool = false,
    /// Intersection shader
    intersection_shader: bool = false,
    /// Closest hit shader
    closest_hit_shader: bool = false,
    /// Any hit shader
    any_hit_shader: bool = false,
    /// Callable shader
    callable_shader: bool = false,
    /// Invoked by "Cmd*AccelerationStructure*" commands
    acceleration_structure: bool = false,
    /// Invoked by "Cmd*Micromap*" commands
    micromap: bool = false,

    // Other
    /// Invoked by "CmdCopy*", "CmdUpload*" and "CmdReadback*" commands
    copy: bool = false,
    /// Invoked by "CmdResolveTexture"
    resolve: bool = false,
    /// Invoked by "CmdClearStorage"
    clear_storage: bool = false,

    // Modifiers
    /// Invoked by "Indirect" commands (used in addition to other bits)
    indirect: bool = false,

    _: u9 = 0,

    pub inline fn bits(self: StageFlags) u32 {
        return @bitCast(self);
    }
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineStageFlagBits2.html
/// https://microsoft.github.io/DirectX-Specs/d3d/D3D12EnhancedBarriers.html#d3d12_barrier_sync
pub const StageBits = enum(u32) {
    // Special
    /// Lazy default for barriers  Shader stage
    ALL = 0,
    NONE = 0x7FFFFFFF,

    // Graphics // Invoked by "CmdDraw*"
    /// Index buffer consumption
    INDEX_INPUT = 1 << 0,
    /// Vertex shader
    VERTEX_SHADER = 1 << 1,
    /// Tessellation control (hull) shader
    TESS_CONTROL_SHADER = 1 << 2,
    /// Tessellation evaluation (domain) shader
    TESS_EVALUATION_SHADER = 1 << 3,
    /// Geometry shader
    GEOMETRY_SHADER = 1 << 4,
    /// Task (amplification) shader
    TASK_SHADER = 1 << 5,
    /// Mesh shader
    MESH_SHADER = 1 << 6,
    /// Fragment (pixel) shader
    FRAGMENT_SHADER = 1 << 7,
    /// Depth-stencil R/W operations
    DEPTH_STENCIL_ATTACHMENT = 1 << 8,
    /// Color R/W operations
    COLOR_ATTACHMENT = 1 << 9,

    // Compute // Invoked by "CmdDispatch*" (not Rays)
    /// Compute shader
    COMPUTE_SHADER = 1 << 10,

    // Ray tracing // Invoked by "CmdDispatchRays*"
    /// Ray generation shader
    RAYGEN_SHADER = 1 << 11,
    /// Miss shader
    MISS_SHADER = 1 << 12,
    /// Intersection shader
    INTERSECTION_SHADER = 1 << 13,
    /// Closest hit shader
    CLOSEST_HIT_SHADER = 1 << 14,
    /// Any hit shader
    ANY_HIT_SHADER = 1 << 15,
    /// Callable shader
    CALLABLE_SHADER = 1 << 16,
    /// Invoked by "Cmd*AccelerationStructure*" commands
    ACCELERATION_STRUCTURE = 1 << 17,
    /// Invoked by "Cmd*Micromap*" commands
    MICROMAP = 1 << 18,

    // Other
    /// Invoked by "CmdCopy*", "CmdUpload*" and "CmdReadback*" commands
    COPY = 1 << 19,
    /// Invoked by "CmdResolveTexture"
    RESOLVE = 1 << 20,
    /// Invoked by "CmdClearStorage"
    CLEAR_STORAGE = 1 << 21,

    // Modifiers
    /// Invoked by "Indirect" commands (used in addition to other bits)
    INDIRECT = 1 << 22,

    // Umbrella stages
    /// Tessellation control + evaluation shaders
    TESSELLATION_SHADERS = @bitCast(StageFlags.TESSELLATION_SHADERS),
    /// Task + mesh shaders
    MESH_SHADERS = @bitCast(StageFlags.MESH_SHADERS),
    /// All graphics stages (index input, all shaders and attachments)
    GRAPHICS_SHADERS = @bitCast(StageFlags.GRAPHICS_SHADERS),
    /// All ray tracing stages (all shaders)
    RAY_TRACING_SHADERS = @bitCast(StageFlags.RAY_TRACING_SHADERS),
    /// All shaders (graphics, compute and ray tracing)
    ALL_SHADERS = @bitCast(StageFlags.ALL_SHADERS),
    /// Index input + all graphics shaders and attachments
    GRAPHICS = @bitCast(StageFlags.GRAPHICS),
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkAccessFlagBits2.html
/// https://microsoft.github.io/DirectX-Specs/d3d/D3D12EnhancedBarriers.html#d3d12_barrier_access
pub const AccessFlags = packed struct(u32) {
    pub const NONE: AccessFlags = @bitCast(@as(u32, 0));
    // Umbrella access
    /// Color attachment read-write (D3D12: "render target" with no "read-only" or "write-only" flag)
    pub const COLOR_ATTACHMENT: AccessFlags = .{ .color_attachment_read = true, .color_attachment_write = true }; // COLOR_ATTACHMENT_READ | COLOR_ATTACHMENT_WRITE
    /// Depth-stencil attachment read-write (D3D12: "depth stencil" with no "read-only" or "write-only" flag)
    pub const DEPTH_STENCIL_ATTACHMENT: AccessFlags = .{ .depth_stencil_attachment_read = true, .depth_stencil_attachment_write = true }; // DEPTH_STENCIL_ATTACHMENT_READ | DEPTH_STENCIL_ATTACHMENT_WRITE
    /// Acceleration structure read-write (D3D12: "acceleration structure" with no "read-only" or "write-only" flag)
    pub const ACCELERATION_STRUCTURE: AccessFlags = .{ .acceleration_structure_read = true, .acceleration_structure_write = true };
    /// Micromap read-write (D3D12: "micromap" with no "read-only" or "write-only" flag)
    pub const MICROMAP: AccessFlags = .{ .micromap_read = true, .micromap_write = true }; // MICROMAP_READ | MICROMAP_WRITE
    // Buffer
    // Access   Compatible "StageBits" (including ALL)
    /// Index buffer read
    index_buffer: bool = false, // R        INDEX_INPUT
    /// Vertex buffer read
    vertex_buffer: bool = false, // R        VERTEX_SHADER
    /// Constant buffer read
    constant_buffer: bool = false, // R        ALL_SHADERS
    /// Argument buffer read (D3D12: "indirect argument" buffer)
    argument_buffer: bool = false, // R        INDIRECT
    /// Scratch buffer read-write (D3D12: "unordered access view" with no format)
    scratch_buffer: bool = false, // RW       ACCELERATION_STRUCTURE, MICROMAP

    // Attachment
    /// Color attachment read (D3D12: "render target" with "read-only" flag)
    color_attachment_read: bool = false, // R        COLOR_ATTACHMENT (implicitly by ROP)
    /// Color attachment write (D3D12: "render target" with "write-only" flag)
    color_attachment_write: bool = false, // W        COLOR_ATTACHMENT
    /// Depth-stencil attachment read (D3D12: "depth stencil" with "read-only" flag)
    depth_stencil_attachment_read: bool = false, // R        DEPTH_STENCIL_ATTACHMENT
    /// Depth-stencil attachment write (D3D12: "depth stencil" with "write-only" flag)
    depth_stencil_attachment_write: bool = false, // W        DEPTH_STENCIL_ATTACHMENT
    /// Shading rate attachment read (Vulkan only)
    shading_rate_attachment: bool = false, // R        FRAGMENT_SHADER
    /// Input attachment read (Vulkan only)
    input_attachment: bool = false, // R        FRAGMENT_SHADER

    // Acceleration structure
    /// Acceleration structure read (D3D12: "acceleration structure" with "read-only" flag)
    acceleration_structure_read: bool = false, // R        COMPUTE_SHADER, RAY_TRACING_SHADERS, ACCELERATION_STRUCTURE
    /// Acceleration structure write (D3D12: "acceleration structure" with "write-only" flag)
    acceleration_structure_write: bool = false, // W       ACCELERATION_STRUCTURE
    // Micromap
    /// Micromap read (D3D12: "micromap" with "read-only" flag)
    micromap_read: bool = false, // R        MICROMAP, ACCELERATION_STRUCTURE
    /// Micromap write (D3D12: "micromap" with "write-only" flag)
    micromap_write: bool = false, // W       MICROMAP

    // Shader
    /// Shader resource read (D3D12: "shader resource view" with no format)
    shader_resource: bool = false, // R        ALL_SHADERS
    /// Shader resource read-write (D3D12: "unordered access view" with no format)
    shader_resource_storage: bool = false, // RW       ALL_SHADERS, CLEAR
    /// Shader binding table read (D3D12: "ray tracing shader table" with "read-only" flag)
    shader_binding_table: bool = false, // R        RAY_TRACING_SHADERS

    // Copy
    /// Copy source (D3D12: "copy source" state)
    copy_source: bool = false, // R        COPY
    /// Copy destination (D3D12: "copy destination" state)
    copy_destination: bool = false, // W       COPY

    // Resolve
    /// Resolve source (D3D12: "resolve source" state)
    resolve_source: bool = false, // R        RESOLVE
    /// Resolve destination (D3D12: "resolve destination" state)
    resolve_destination: bool = false, // W       RESOLVE

    // Clear storage
    /// Clear storage write (D3D12: "unordered access view" with no format, used by "CmdClearStorage")
    clear_storage: bool = false, // W       CLEAR_STORAGE

    _: u9 = 0, // padding to 32 bits

    pub inline fn bits(self: AccessFlags) u32 {
        return @bitCast(self);
    }
};
pub const AccessBits = enum(u32) {
    // Special
    /// Lazy default for barriers  Access type
    NONE = 0,

    // Buffer                                       Access   Compatible "StageBits" (including ALL)
    /// Index buffer read
    INDEX_BUFFER = 1 << 0, // R        INDEX_INPUT
    /// Vertex buffer read
    VERTEX_BUFFER = 1 << 1, // R        VERTEX_SHADER
    /// Constant buffer read
    CONSTANT_BUFFER = 1 << 2, // R        ALL_SHADERS
    /// Argument buffer read (D3D12: "indirect argument" buffer)
    ARGUMENT_BUFFER = 1 << 3, // R        INDIRECT
    /// Scratch buffer read-write (D3D12: "unordered access view" with no format)
    SCRATCH_BUFFER = 1 << 4, // RW       ACCELERATION_STRUCTURE, MICROMAP

    // Attachment
    /// Color attachment read (D3D12: "render target" with "read-only" flag)
    COLOR_ATTACHMENT_READ = 1 << 5, // R        COLOR_ATTACHMENT (implicitly by ROP)
    /// Color attachment write (D3D12: "render target" with "write-only" flag)
    COLOR_ATTACHMENT_WRITE = 1 << 6, // W        COLOR_ATTACHMENT
    /// Depth-stencil attachment read (D3D12: "depth stencil" with "read-only" flag)
    DEPTH_STENCIL_ATTACHMENT_READ = 1 << 7, // R        DEPTH_STENCIL_ATTACHMENT
    /// Depth-stencil attachment write (D3D12: "depth stencil" with "write-only" flag)
    DEPTH_STENCIL_ATTACHMENT_WRITE = 1 << 8, // W        DEPTH_STENCIL_ATTACHMENT
    /// Shading rate attachment read (Vulkan only)
    SHADING_RATE_ATTACHMENT = 1 << 9, // R        FRAGMENT_SHADER
    /// Input attachment read (Vulkan only)
    INPUT_ATTACHMENT = 1 << 10, // R        FRAGMENT_SHADER

    // Acceleration structure
    /// Acceleration structure read (D3D12: "acceleration structure" with "read-only" flag)
    ACCELERATION_STRUCTURE_READ = 1 << 11, // R        COMPUTE_SHADER, RAY_TRACING_SHADERS, ACCELERATION_STRUCTURE
    /// Acceleration structure write (D3D12: "acceleration structure" with "write-only" flag)
    ACCELERATION_STRUCTURE_WRITE = 1 << 12, // W       ACCELERATION_STRUCTURE

    // Micromap
    /// Micromap read (D3D12: "micromap" with "read-only" flag)
    MICROMAP_READ = 1 << 13, // R        MICROMAP, ACCELERATION_STRUCTURE
    /// Micromap write (D3D12: "micromap" with "write-only" flag)
    MICROMAP_WRITE = 1 << 14, // W       MICROMAP

    // Shader
    /// Shader resource read (D3D12: "shader resource view" with no format)
    SHADER_RESOURCE = 1 << 15, // R        ALL_SHADERS
    /// Shader resource read-write (D3D12: "unordered access view" with no format)
    SHADER_RESOURCE_STORAGE = 1 << 16, // RW       ALL_SHADERS, CLEAR_STORAGE
    /// Shader binding table read (D3D12: "ray tracing shader table" with "read-only" flag)
    SHADER_BINDING_TABLE = 1 << 17, // R        RAY_TRACING_SHADERS

    // Copy
    /// Copy source (D3D12: "copy source" state)
    COPY_SOURCE = 1 << 18, // R        COPY
    /// Copy destination (D3D12: "copy destination" state)
    COPY_DESTINATION = 1 << 19, // W       COPY

    // Resolve
    /// Resolve source (D3D12: "resolve source" state)
    RESOLVE_SOURCE = 1 << 20, // R        RESOLVE
    /// Resolve destination (D3D12: "resolve destination" state)
    RESOLVE_DESTINATION = 1 << 21, // W       RESOLVE

    // Clear storage
    /// Clear storage write (D3D12: "unordered access view" with no format, used by "CmdClearStorage")
    CLEAR_STORAGE = 1 << 22, // W       CLEAR_STORAGE

    // Umbrella access
    /// Color attachment read-write (D3D12: "render target" with no "read-only" or "write-only" flag)
    COLOR_ATTACHMENT = 1 << 5 | // COLOR_ATTACHMENT_READ
        1 << 6, // COLOR_ATTACHMENT_WRITE
    /// Depth-stencil attachment read-write (D3D12: "depth stencil" with no "read-only" or "write-only" flag)
    DEPTH_STENCIL_ATTACHMENT = 1 << 7 | // DEPTH_STENCIL_ATTACHMENT_READ
        1 << 8, // DEPTH_STENCIL_ATTACHMENT_WRITE
    /// Acceleration structure read-write (D3D12: "acceleration structure" with no "read-only" or "write-only" flag)
    ACCELERATION_STRUCTURE = 1 << 11 | // ACCELERATION_STRUCTURE_READ
        1 << 12, // ACCELERATION_STRUCTURE_WRITE
    /// Micromap read-write (D3D12: "micromap" with no "read-only" or "write-only" flag)
    MICROMAP = 1 << 13 | // MICROMAP_READ
        1 << 14, // MICROMAP_WRITE
};
// NriBits(AccessBits, uint32_t,
//     NONE                            = 0,        // Mapped to "COMMON" (aka "GENERAL" access), if AgilitySDK is not available, leading to potential discrepancies with VK

//     // Buffer                                   // Access   Compatible "StageBits" (including ALL)
//     INDEX_BUFFER                    = NriBit(0),    // R        INDEX_INPUT
//     VERTEX_BUFFER                   = NriBit(1),    // R        VERTEX_SHADER
//     CONSTANT_BUFFER                 = NriBit(2),    // R        ALL_SHADERS
//     ARGUMENT_BUFFER                 = NriBit(3),    // R        INDIRECT
//     SCRATCH_BUFFER                  = NriBit(4),    // RW       ACCELERATION_STRUCTURE, MICROMAP

//     // Attachment
//     COLOR_ATTACHMENT_READ           = NriBit(5),    // R        COLOR_ATTACHMENT (implicitly by ROP)
//     COLOR_ATTACHMENT_WRITE          = NriBit(6),    //  W       COLOR_ATTACHMENT
//     DEPTH_STENCIL_ATTACHMENT_READ   = NriBit(7),    // R        DEPTH_STENCIL_ATTACHMENT
//     DEPTH_STENCIL_ATTACHMENT_WRITE  = NriBit(8),    //  W       DEPTH_STENCIL_ATTACHMENT
//     SHADING_RATE_ATTACHMENT         = NriBit(9),    // R        FRAGMENT_SHADER
//     INPUT_ATTACHMENT                = NriBit(10),   // R        FRAGMENT_SHADER

//     // Acceleration structure
//     ACCELERATION_STRUCTURE_READ     = NriBit(11),   // R        COMPUTE_SHADER, RAY_TRACING_SHADERS, ACCELERATION_STRUCTURE
//     ACCELERATION_STRUCTURE_WRITE    = NriBit(12),   //  W       ACCELERATION_STRUCTURE

//     // Micromap
//     MICROMAP_READ                   = NriBit(13),   // R        MICROMAP, ACCELERATION_STRUCTURE
//     MICROMAP_WRITE                  = NriBit(14),   //  W       MICROMAP

//     // Shader
//     SHADER_RESOURCE                 = NriBit(15),   // R        ALL_SHADERS
//     SHADER_RESOURCE_STORAGE         = NriBit(16),   // RW       ALL_SHADERS, CLEAR_STORAGE
//     SHADER_BINDING_TABLE            = NriBit(17),   // R        RAY_TRACING_SHADERS

//     // Copy
//     COPY_SOURCE                     = NriBit(18),   // R        COPY
//     COPY_DESTINATION                = NriBit(19),   //  W       COPY

//     // Resolve
//     RESOLVE_SOURCE                  = NriBit(20),   // R        RESOLVE
//     RESOLVE_DESTINATION             = NriBit(21),   //  W       RESOLVE

//     // Clear storage
//     CLEAR_STORAGE                   = NriBit(22),   //  W       CLEAR_STORAGE

//     // Umbrella access
//     COLOR_ATTACHMENT                = NriMember(AccessBits, COLOR_ATTACHMENT_READ)
//                                     | NriMember(AccessBits, COLOR_ATTACHMENT_WRITE),

//     DEPTH_STENCIL_ATTACHMENT        = NriMember(AccessBits, DEPTH_STENCIL_ATTACHMENT_READ)
//                                     | NriMember(AccessBits, DEPTH_STENCIL_ATTACHMENT_WRITE),

//     ACCELERATION_STRUCTURE          = NriMember(AccessBits, ACCELERATION_STRUCTURE_READ)
//                                     | NriMember(AccessBits, ACCELERATION_STRUCTURE_WRITE),

//     MICROMAP                        = NriMember(AccessBits, MICROMAP_READ)
//                                     | NriMember(AccessBits, MICROMAP_WRITE)
// );

/// "Layout" is ignored if "features.enhancedBarriers" is not supported
/// https://docs.vulkan.org/refpages/latest/refpages/source/VkImageLayout.html
/// https://microsoft.github.io/DirectX-Specs/d3d/D3D12EnhancedBarriers.html#d3d12_barrier_layout
pub const Layout = enum(u8) { // Compatible "AccessBits":
    // Special
    /// https://microsoft.github.io/DirectX-Specs/d3d/D3D12EnhancedBarriers.html#d3d12_barrier_layout_undefined
    UNDEFINED,
    /// ALL access, required for "SharingMode::SIMULTANEOUS" (but may be suboptimal if "features.unifiedTextureLayouts" is not supported)
    GENERAL,
    /// NONE (use "after.stages = StageBits::NONE")
    PRESENT,

    // Attachment
    /// COLOR_ATTACHMENT_READ/WRITE
    COLOR_ATTACHMENT,
    /// DEPTH_STENCIL_ATTACHMENT_READ/WRITE
    DEPTH_STENCIL_ATTACHMENT,
    /// DEPTH_STENCIL_ATTACHMENT_READ/WRITE, SHADER_RESOURCE (readonlyPlanes = "DEPTH")
    DEPTH_READONLY_STENCIL_ATTACHMENT,
    /// DEPTH_STENCIL_ATTACHMENT_READ/WRITE, SHADER_RESOURCE (readonlyPlanes = "STENCIL")
    DEPTH_ATTACHMENT_STENCIL_READONLY,
    /// DEPTH_STENCIL_ATTACHMENT_READ, SHADER_RESOURCE (readonlyPlanes = "DEPTH|STENCIL")
    DEPTH_STENCIL_READONLY,
    /// SHADING_RATE_ATTACHMENT
    SHADING_RATE_ATTACHMENT,
    /// COLOR_ATTACHMENT, INPUT_ATTACHMENT
    INPUT_ATTACHMENT,

    // Shader
    /// SHADER_RESOURCE
    SHADER_RESOURCE,
    /// SHADER_RESOURCE_STORAGE
    SHADER_RESOURCE_STORAGE,

    // Copy
    /// COPY_SOURCE
    COPY_SOURCE,
    /// COPY_DESTINATION
    COPY_DESTINATION,

    // Resolve
    /// RESOLVE_SOURCE
    RESOLVE_SOURCE,
    /// RESOLVE_DESTINATION
    RESOLVE_DESTINATION,
};

pub const AccessStage = extern struct {
    access: AccessFlags = .{},
    stages: StageFlags = .{},
};

pub const AccessLayoutStage = extern struct {
    access: AccessFlags = .{},
    layout: Layout = .UNDEFINED,
    stages: StageFlags = .{},
};

pub const GlobalBarrierDesc = extern struct {
    before: AccessStage = .{},
    after: AccessStage = .{},
};

pub const BufferBarrierDesc = extern struct {
    buffer: *Buffer, // use "GetAccelerationStructureBuffer" and "GetMicromapBuffer" for related barriers
    before: AccessStage = .{},
    after: AccessStage = .{},
};

pub const TextureBarrierDesc = extern struct {
    texture: *Texture,
    before: AccessLayoutStage = .{},
    after: AccessLayoutStage = .{},
    mip_offset: Dim_t = 0,
    mip_num: Dim_t = 0, // can be "REMAINING"
    layer_offset: Dim_t = 0,
    layer_num: Dim_t = 0, // can be "REMAINING"
    planes: PlaneFlags = .{},

    // Queue ownership transfer is potentially needed only for "SharingMode::EXCLUSIVE" textures
    // https://registry.khronos.org/vulkan/specs/latest/html/vkspec.html#synchronization-queue-transfers
    src_queue: ?*const Queue = null,
    dst_queue: ?*const Queue = null,
};

/// Using "CmdBarrier" inside a rendering pass is allowed, but only for "Layout::INPUT_ATTACHMENT" access transitions
pub const BarrierDesc = extern struct {
    global: ?[*]const GlobalBarrierDesc,
    global_num: u32 = 0,
    buffer: ?[*]const BufferBarrierDesc,
    buffer_num: u32 = 0,
    texture: ?[*]const TextureBarrierDesc,
    texture_num: u32 = 0,

    pub const Options = struct {
        global: []const GlobalBarrierDesc = &.{},
        buffer: []const BufferBarrierDesc = &.{},
        texture: []const TextureBarrierDesc = &.{},
    };
    pub inline fn from(opts: Options) @This() {
        return .{
            .global = opts.global.ptr,
            .global_num = @intCast(opts.global.len),
            .buffer = opts.buffer.ptr,
            .buffer_num = @intCast(opts.buffer.len),
            .texture = opts.texture.ptr,
            .texture_num = @intCast(opts.texture.len),
        };
    }

    pub fn globals(self: *const BarrierDesc) []GlobalBarrierDesc {
        return self.global[0..self.global_num];
    }

    pub fn buffers(self: *const BarrierDesc) []BufferBarrierDesc {
        return self.buffer[0..self.buffer_num];
    }

    pub fn textures(self: *const BarrierDesc) []TextureBarrierDesc {
        return self.texture[0..self.texture_num];
    }
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkImageType.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_resource_dimension
pub const TextureType = enum(u8) {
    TEXTURE_1D,
    TEXTURE_2D,
    TEXTURE_3D,
};

/// NRI tries to ease your life and avoid using "queue ownership transfers" (see "TextureBarrierDesc").
/// In most of cases "SharingMode" can be ignored. Where is it needed?
/// - VK: use "EXCLUSIVE" for attachments participating into multi-queue activities to preserve DCC (Delta Color Compression) on some HW
/// - D3D12: use "SIMULTANEOUS" to concurrently use a texture as a "SHADER_RESOURCE" (or "SHADER_RESOURCE_STORAGE") and as a "COPY_DESTINATION" for non overlapping texture regions
/// https://docs.vulkan.org/refpages/latest/refpages/source/VkSharingMode.html
pub const SharingMode = enum(u8) {
    /// VK: lazy default to avoid dealing with "queue ownership transfers", auto-optimized to "EXCLUSIVE" if all queues have the same type
    CONCURRENT,
    /// VK: may be used for attachments to preserve DCC on some HW in the cost of making a "queue ownership transfer"
    EXCLUSIVE,

    /// https://microsoft.github.io/DirectX-Specs/d3d/D3D12EnhancedBarriers.html#single-queue-simultaneous-access
    /// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_resource_flags
    /// D3D12: strengthened variant of "CONCURRENT", allowing simultaneous multiple readers and one writer for a texture (requires "Layout::GENERAL")
    SIMULTANEOUS,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkImageUsageFlagBits.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_resource_flags
pub const TextureUsageFlags = packed struct(u8) {
    pub const NONE: TextureUsageFlags = @bitCast(@as(u8, 0));

    /// SHADER_RESOURCE                          Read-only shader resource view (SRV)
    shader_resource: bool = false,
    /// SHADER_RESOURCE_STORAGE                  Read/write shader resource view (UAV)
    shader_resource_storage: bool = false,
    /// COLOR_ATTACHMENT                         Color attachment (render target)
    color_attachment: bool = false,
    /// DEPTH_STENCIL_ATTACHMENT_READ/WRITE      Depth-stencil attachment (depth-stencil target)
    depth_stencil_attachment: bool = false,
    /// SHADING_RATE_ATTACHMENT                  Shading rate attachment (source)
    shading_rate_attachment: bool = false,
    /// INPUT_ATTACHMENT                         Subpass input (read on-chip tile cache)
    input_attachment: bool = false,

    _: u2 = 0,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkImageUsageFlagBits.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_resource_flags
pub const TextureUsageBits = enum(u8) {
    NONE = 0,
    /// SHADER_RESOURCE                          Read-only shader resource view (SRV)
    SHADER_RESOURCE = 1 << 0,
    /// SHADER_RESOURCE_STORAGE                  Read/write shader resource view (UAV)
    SHADER_RESOURCE_STORAGE = 1 << 1,
    /// COLOR_ATTACHMENT                         Color attachment (render target)
    COLOR_ATTACHMENT = 1 << 2,
    /// DEPTH_STENCIL_ATTACHMENT_READ/WRITE      Depth-stencil attachment (depth-stencil target)
    DEPTH_STENCIL_ATTACHMENT = 1 << 3,
    /// SHADING_RATE_ATTACHMENT                  Shading rate attachment (source)
    SHADING_RATE_ATTACHMENT = 1 << 4,
    /// INPUT_ATTACHMENT                         Subpass input (read on-chip tile cache)
    INPUT_ATTACHMENT = 1 << 5,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkBufferUsageFlagBits.html
pub const BufferUsageFlags = packed struct(u16) {
    pub const NONE: BufferUsageFlags = @bitCast(@as(u16, 0));

    /// SHADER_RESOURCE                     Read-only shader resource view (SRV)
    shader_resource: bool = false,
    /// SHADER_RESOURCE_STORAGE             Read/write shader resource view (UAV)
    shader_resource_storage: bool = false,
    /// VERTEX_BUFFER                       Vertex buffer
    vertex_buffer: bool = false,
    /// INDEX_BUFFER                        Index buffer
    index_buffer: bool = false,
    /// CONSTANT_BUFFER                     Constant buffer (D3D11: can't be combined with other usages)
    constant_buffer: bool = false,
    /// ARGUMENT_BUFFER                     Argument buffer in "Indirect" commands
    argument_buffer: bool = false,
    /// SCRATCH_BUFFER                      Scratch buffer in "CmdBuild*" commands
    scratch_buffer: bool = false,
    /// SHADER_BINDING_TABLE                Shader binding table (SBT) in "CmdDispatchRays*" commands
    shader_binding_table: bool = false,
    /// ACCELERATION_STRUCTURE_BUILD_INPUT  Read-only input in "CmdBuildAccelerationStructures" command
    acceleration_structure_build_input: bool = false,
    /// ACCELERATION_STRUCTURE_STORAGE      (INTERNAL) acceleration structure storage
    acceleration_structure_storage: bool = false,
    /// MICROMAP_BUILD_INPUT                Read-only input in "CmdBuildMicromaps" command
    micromap_build_input: bool = false,
    /// MICROMAP_STORAGE                    (INTERNAL) micromap storage
    micromap_storage: bool = false,

    _: u4 = 0,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkBufferUsageFlagBits.html
pub const BufferUsageBits = enum(u16) {
    NONE = 0,
    /// SHADER_RESOURCE                     Read-only shader resource view (SRV)
    SHADER_RESOURCE = 1 << 0,
    /// SHADER_RESOURCE_STORAGE             Read/write shader resource view (UAV)
    SHADER_RESOURCE_STORAGE = 1 << 1,
    /// VERTEX_BUFFER                       Vertex buffer
    VERTEX_BUFFER = 1 << 2,
    /// INDEX_BUFFER                        Index buffer
    INDEX_BUFFER = 1 << 3,
    /// CONSTANT_BUFFER                     Constant buffer (D3D11: can't be combined with other usages)
    CONSTANT_BUFFER = 1 << 4,
    /// ARGUMENT_BUFFER                     Argument buffer in "Indirect" commands
    ARGUMENT_BUFFER = 1 << 5,
    /// SCRATCH_BUFFER                      Scratch buffer in "CmdBuild*" commands
    SCRATCH_BUFFER = 1 << 6,
    /// SHADER_BINDING_TABLE                Shader binding table (SBT) in "CmdDispatchRays*" commands
    SHADER_BINDING_TABLE = 1 << 7,
    /// ACCELERATION_STRUCTURE_BUILD_INPUT  Read-only input in "CmdBuildAccelerationStructures" command
    ACCELERATION_STRUCTURE_BUILD_INPUT = 1 << 8,
    /// ACCELERATION_STRUCTURE_STORAGE      (INTERNAL) acceleration structure storage
    ACCELERATION_STRUCTURE_STORAGE = 1 << 9,
    /// MICROMAP_BUILD_INPUT                Read-only input in "CmdBuildMicromaps" command
    MICROMAP_BUILD_INPUT = 1 << 10,
    /// MICROMAP_STORAGE                    (INTERNAL) micromap storage
    MICROMAP_STORAGE = 1 << 11,
};

pub const TextureDesc = extern struct {
    type: TextureType = .TEXTURE_2D,
    usage: TextureUsageFlags = .{},
    format: Format = .UNKNOWN,
    width: Dim_t = 0,
    height: Dim_t = 0, // Optional
    depth: Dim_t = 0, // Optional
    mip_num: Dim_t = 0, // Optional
    layer_num: Dim_t = 0, // Optional
    sample_num: Sample_t = 0, // Optional
    sharing_mode: SharingMode = .EXCLUSIVE, // Optional
    /// D3D12: not needed on desktop, since any HW can track many clear values
    optimized_clear_value: ClearValue = undefined, // Optional
};

/// - VK: buffers are always created with sharing mode "CONCURRENT" to match D3D12 spec
/// - "structureStride" values:
///   - 0  - allows only "typed" views
///   - 4  - allows "typed", "byte address" and "structured" views
///          D3D11: allows to create multiple "structured" views for a single resource, disobeying the spec
///   - >4 - allows only "structured" views
///          D3D11: locks this buffer to a single "structured" layout
pub const BufferDesc = extern struct {
    size: u64 = 0,
    structure_stride: u32 = 0,
    usage: BufferUsageFlags = .NONE,
};

pub const MemoryType = u32;

/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_heap_type
pub const MemoryLocation = enum(u8) {
    DEVICE,
    /// Soft fallback to "HOST_UPLOAD" if "deviceUploadHeapSize = 0"
    DEVICE_UPLOAD,
    HOST_UPLOAD,
    HOST_READBACK,
};

pub const MemoryDesc = extern struct {
    size: u64 = 0,
    alignment: u32 = 0,
    type: MemoryType = 0,
    /// must be put into a dedicated "Memory" object, containing only 1 object with offset = 0
    must_be_dedicated: bool = false,
};

/// A group of non-dedicated "MemoryDesc"s of the SAME "MemoryType" can be merged into a single memory allocation
pub const AllocateMemoryDesc = extern struct {
    pub const VMA = extern struct {
        enable: bool = false,
        alignment: u32 = 0, // by default worst-case alignment applied
    };

    size: u64 = 0,
    type: MemoryType = 0,

    /// https://learn.microsoft.com/en-us/windows/win32/direct3d12/residency
    /// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_residency_priority
    /// https://docs.vulkan.org/refpages/latest/refpages/source/VkMemoryPriorityAllocateInfoEXT.html
    priority: f32 = 0, // [-1; 1]: low < 0, normal = 0, high > 0

    /// Memory allocation goes through "AMD Virtual Memory Allocator"
    ///  - most likely a sub-allocation from a larger allocation
    ///  - alignment is the maximum of all "memoryDesc.alignment" values for all resources bound to this allocation
    ///  - https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator
    ///  - https://github.com/GPUOpen-LibrariesAndSDKs/D3D12MemoryAllocator
    vma: VMA,

    /// If "false", may reduce alignment requirements
    allow_multisample_textures: bool = false,
};

/// Binding resources to a memory (resources can overlap, i.e. alias)
pub const BindBufferMemoryDesc = extern struct {
    buffer: *Buffer,
    memory: *Memory,
    offset: u64, // in memory
};

pub const BindTextureMemoryDesc = extern struct {
    texture: *Texture,
    memory: *Memory,
    offset: u64, // in memory
};

/// https://microsoft.github.io/DirectX-Specs/d3d/ResourceBinding.html#creating-descriptors
pub const TextureView = enum(u8) {
    // Shader resources         // HLSL type                        Compatible "DescriptorType"     Compatible "TextureType"
    // Texture[1D/2D/3D](MS)            TEXTURE                         1D, 2D, 3D
    TEXTURE,
    // Texture[1D/2D](MS)Array          TEXTURE                         1D, 2D
    TEXTURE_ARRAY,
    // TextureCube                      TEXTURE                             2D
    TEXTURE_CUBE,
    // TextureCubeArray                 TEXTURE                             2D
    TEXTURE_CUBE_ARRAY,
    // RWTexture[1D/2D/3D](MS)          STORAGE_TEXTURE                 1D, 2D, 3D
    STORAGE_TEXTURE,
    // RWTexture[1D/2D](MS)Array        STORAGE_TEXTURE                 1D, 2D
    STORAGE_TEXTURE_ARRAY,
    // SubpassInput(MS) (non-array)     INPUT_ATTACHMENT                    2D
    SUBPASS_INPUT,

    // Host-only
    //                                                                  1D, 2D, 3D
    COLOR_ATTACHMENT,
    //                                                                  1D, 2D
    DEPTH_STENCIL_ATTACHMENT,
    //                                                                      2D
    SHADING_RATE_ATTACHMENT,
};

pub const BufferView = enum(u8) {
    // Shader resources         // HLSL type                        Compatible "DescriptorType"
    BUFFER, // Buffer                           BUFFER
    STRUCTURED_BUFFER, // StructuredBuffer                 STRUCTURED_BUFFER
    BYTE_ADDRESS_BUFFER, // ByteAddressBuffer                STRUCTURED_BUFFER
    STORAGE_BUFFER, // RWBuffer                         STORAGE_BUFFER
    STORAGE_STRUCTURED_BUFFER, // RWStructuredBuffer               STORAGE_STRUCTURED_BUFFER
    STORAGE_BYTE_ADDRESS_BUFFER, // RWByteAddressBuffer              STORAGE_STRUCTURED_BUFFER
    CONSTANT_BUFFER, // ConstantBuffer                   CONSTANT_BUFFER

    // Host-only
    ACCELERATION_STRUCTURE,
    MICROMAP,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkFilter.html
/// https://docs.vulkan.org/refpages/latest/refpages/source/VkSamplerMipmapMode.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_filter
pub const Filter = enum(u8) {
    NEAREST,
    LINEAR,
};

/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_filter_reduction_type
/// https://docs.vulkan.org/refpages/latest/refpages/source/VkSamplerReductionMode.html
pub const FilterOp = enum(u8) {
    /// a weighted average (sum) of values in the footprint (default)
    AVERAGE,
    /// a component-wise minimum of values in the footprint with non-zero weights, requires "features.filterOpMinMax"
    MIN,
    /// a component-wise maximum of values in the footprint with non-zero weights, requires "features.filterOpMinMax"
    MAX,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkSamplerAddressMode.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_texture_address_mode
pub const AddressMode = enum(u8) {
    REPEAT,
    MIRRORED_REPEAT,
    CLAMP_TO_EDGE,
    CLAMP_TO_BORDER,
    MIRROR_CLAMP_TO_EDGE,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkCompareOp.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_comparison_func
/// R - fragment depth, stencil reference or "SampleCmp" reference
/// D - depth or stencil buffer
pub const CompareOp = enum(u8) {
    /// test is disabled
    NONE,
    /// true
    ALWAYS,
    /// false
    NEVER,
    /// R == D
    EQUAL,
    /// R != D
    NOT_EQUAL,
    /// R < D
    LESS,
    /// R <= D
    LESS_EQUAL,
    /// R > D
    GREATER,
    /// R >= D
    GREATER_EQUAL,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkComponentSwizzle.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_shader_component_mapping
pub const ComponentSwizzle = enum(u8) {
    /// format-specific default
    IDENTITY,

    // Requires "features.componentSwizzle"
    /// 0
    ZERO,
    /// 1 or 1.0
    ONE,
    /// .x component (red)
    R,
    /// .y component (green)
    G,
    /// .z component (blue)
    B,
    /// .w component (alpha)
    A,
};

pub const ComponentMapping = extern struct {
    // Only for non-"STORAGE" views
    r: ComponentSwizzle = .IDENTITY,
    g: ComponentSwizzle = .IDENTITY,
    b: ComponentSwizzle = .IDENTITY,
    a: ComponentSwizzle = .IDENTITY,
};

pub const TextureViewDesc = extern struct {
    texture: *Texture,
    type: TextureView = .TEXTURE,
    format: Format = .UNKNOWN,
    mip_offset: Dim_t = 0,
    mip_num: Dim_t = 0, // can be "REMAINING"
    layer_offset: Dim_t = 0,
    layer_num: Dim_t = 0, // can be "REMAINING"
    slice_offset: Dim_t = 0,
    slice_num: Dim_t = 0, // can be "REMAINING"
    readonly_planes: PlaneFlags = .{}, // "DEPTH" and/or "STENCIL"
    components: ComponentMapping = .{},
};

pub const BufferViewDesc = extern struct {
    buffer: *Buffer,
    type: BufferView = .BUFFER,
    /// expects "memoryAlignment.bufferShaderResourceOffset" for shader resources
    offset: u64 = 0,
    /// can be "WHOLE_SIZE"
    size: u64 = 0,
    /// needed for typed views, i.e. "BUFFER" and "BUFFER_STORAGE"
    format: Format = .UNKNOWN,
    /// needed for structured views, i.e. "STRUCTURED_BUFFER" and "STRUCTURED_BUFFER_STORAGE" (= "BufferDesc::structureStride", if not provided)
    structure_stride: u32 = 0,
};

pub const AddressModes = extern struct {
    u: AddressMode = .REPEAT,
    v: AddressMode = .REPEAT,
    w: AddressMode = .REPEAT,
};

pub const Filters = extern struct {
    min: Filter = .NEAREST,
    mag: Filter = .NEAREST,
    mip: Filter = .NEAREST,
    op: FilterOp = .AVERAGE,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkSamplerCreateInfo.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_sampler_desc
pub const SamplerDesc = extern struct {
    filters: Filters = .{},
    anisotropy: u8 = 1,
    mip_bias: f32 = 0,
    mip_min: f32 = 0,
    mip_max: f32 = 0,
    address_modes: AddressModes = .{},
    compare_op: CompareOp = .NONE,
    border_color: Color = .{
        .f = .{ .x = 0, .y = 0, .z = 0, .w = 0 },
    },
    is_integer: bool = false,
    /// requires "features.unnormalizedCoordinates"
    unnormalized_coordinates: bool = false,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineBindPoint.html
pub const BindPoint = enum(u8) {
    INHERIT, // inherit from the last "CmdSetPipelineLayout" call
    GRAPHICS,
    COMPUTE,
    RAY_TRACING,
};

pub const PipelineLayoutFlags = packed struct(u8) {
    pub const NONE: PipelineLayoutFlags = @bitCast(@as(u8, 0));

    ignore_global_spirv_offsets: bool = false, // VK: ignore "DeviceCreationDesc::vkBindingOffsets"
    enable_draw_parameters_emulation: bool = false, // enable draw parameters emulation, requires "shaderFeatures.drawParametersEmulation"

    // https://github.com/Microsoft/DirectXShaderCompiler/blob/main/docs/SPIR-V.rst#resourcedescriptorheaps--samplerdescriptorheaps
    // Default VK bindings can be changed via "-fvk-bind-sampler-heap" and "-fvk-bind-resource-heap" DXC options
    sampler_heap_directly_indexed: bool = false, // requires "shaderModel >= 66"
    resource_heap_directly_indexed: bool = false, // requires "shaderModel >= 66"

    _: u4 = 0,

    pub inline fn bits(self: PipelineLayoutFlags) u8 {
        return @bitCast(self);
    }
};

pub const PipelineLayoutBits = enum(u8) {
    NONE = 0,
    IGNORE_GLOBAL_SPIRV_OFFSETS = 1 << 0,
    ENABLE_DRAW_PARAMETERS_EMULATION = 1 << 1,
    SAMPLER_HEAP_DIRECTLY_INDEXED = 1 << 2,
    RESOURCE_HEAP_DIRECTLY_INDEXED = 1 << 3,
};

pub const DescriptorPoolFlags = packed struct(u8) {
    pub const NONE: DescriptorPoolFlags = @bitCast(@as(u8, 0));

    allow_update_after_set: bool = false, // allows "DescriptorSetBits::ALLOW_UPDATE_AFTER_SET"

    _: u7 = 0,

    pub inline fn bits(self: DescriptorPoolFlags) u8 {
        return @bitCast(self);
    }
};

pub const DescriptorPoolBits = enum(u8) {
    NONE = 0,
    ALLOW_UPDATE_AFTER_SET = 1 << 0,
};

pub const DescriptorSetFlags = packed struct(u8) {
    pub const NONE: DescriptorSetFlags = @bitCast(@as(u8, 0));

    allow_update_after_set: bool = false, // allows "DescriptorRangeBits::ALLOW_UPDATE_AFTER_SET"

    _: u7 = 0,

    pub inline fn bits(self: DescriptorSetFlags) u8 {
        return @bitCast(self);
    }
};

pub const DescriptorSetBits = enum(u8) {
    NONE = 0,
    ALLOW_UPDATE_AFTER_SET = 1 << 0,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorBindingFlagBits.html
pub const DescriptorRangeFlags = packed struct(u8) {
    pub const NONE: DescriptorRangeFlags = @bitCast(@as(u8, 0));

    partially_bound: bool = false, // descriptors in range may not contain valid descriptors at the time the descriptors are consumed (but referenced descriptors must be valid)
    array: bool = false, // descriptors in range are organized into an array
    variable_sized_array: bool = false, // descriptors in range are organized into a variable-sized array, which size is specified via "variableDescriptorNum" argument of "AllocateDescriptorSets" function

    // https://docs.vulkan.org/samples/latest/samples/extensions/descriptor_indexing/README.html#_update_after_bind_streaming_descriptors_concurrently
    allow_update_after_set: bool = false, // descriptors in range can be updated after "CmdSetDescriptorSet" but before "QueueSubmit", also works as "DATA_VOLATILE"

    _: u4 = 0,

    pub inline fn bits(self: DescriptorRangeFlags) u8 {
        return @bitCast(self);
    }
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorBindingFlagBits.html
pub const DescriptorRangeBits = enum(u8) {
    NONE = 0,
    PARTIALLY_BOUND = 1 << 0,
    ARRAY = 1 << 1,
    VARIABLE_SIZED_ARRAY = 1 << 2,
    ALLOW_UPDATE_AFTER_SET = 1 << 3,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorType.html
pub const DescriptorType = enum(u8) {
    // Sampler heap
    SAMPLER, // -        s           sampler

    // Resource heap
    // - a mutable descriptor is a proxy "union" descriptor for all resource descriptor types, i.e. non-sampler
    // - a mutable descriptor can't be created, it can only be allocated from a pool (i.e. used in a "DescriptorRangeDesc")
    // - a mutable descriptor must "mutate" to any resource descriptor via "UpdateDescriptorRanges" or "CopyDescriptorRanges"
    // - a mutable descriptor range may include any non-sampler descriptors, which may be directly indexed in shaders
    MUTABLE, // -        -           any non-sampler

    // Optimized resources
    TEXTURE, // +        t           TextureView: TEXTURE, TEXTURE_ARRAY, TEXTURE_CUBE, TEXTURE_CUBE_ARRAY
    STORAGE_TEXTURE, // +        u           TextureView: STORAGE_TEXTURE, STORAGE_TEXTURE_ARRAY
    INPUT_ATTACHMENT, // +        -           TextureView: SUBPASS_INPUT

    BUFFER, // +        t           BufferView: BUFFER
    STORAGE_BUFFER, // +        u           BufferView: STORAGE_BUFFER
    CONSTANT_BUFFER, // -        b           BufferView: CONSTANT_BUFFER
    STRUCTURED_BUFFER, // -        t           BufferView: STRUCTURED_BUFFER, BYTE_ADDRESS_BUFFER
    STORAGE_STRUCTURED_BUFFER, // -        u           BufferView: STORAGE_STRUCTURED_BUFFER, STORAGE_BYTE_ADDRESS_BUFFER

    ACCELERATION_STRUCTURE, // -        t           acceleration structure, requires "features.rayTracing"
};

// "DescriptorRange" consists of "Descriptor" entities
pub const DescriptorRangeDesc = extern struct {
    base_register_index: u32, // "VKBindingOffsets" not applied to "MUTABLE" and "INPUT_ATTACHMENT" to avoid confusion
    descriptor_num: u32, // treated as max size if "VARIABLE_SIZED_ARRAY" flag is set
    descriptor_type: DescriptorType,
    shader_stages: StageFlags,
    flags: DescriptorRangeFlags,
};

// "DescriptorSet" consists of "DescriptorRange" entities
pub const DescriptorSetDesc = extern struct {
    register_space: u32, // must be unique, avoid big gaps
    ranges: [*]const DescriptorRangeDesc,
    range_num: u32,
    flags: DescriptorSetFlags,
};

// "PipelineLayout" consists of "DescriptorSet" descriptions and root parameters
pub const RootConstantDesc = extern struct { // aka push constants block
    register_index: u32,
    size: u32,
    shader_stages: StageFlags,
};

pub const RootDescriptorDesc = extern struct { // aka push descriptor
    register_index: u32,
    descriptor_type: DescriptorType, // a non-typed descriptor type
    shader_stages: StageFlags,
};

// https://learn.microsoft.com/en-us/windows/win32/direct3d12/root-signature-limits#static-samplers
pub const RootSamplerDesc = extern struct { // aka static (immutable) sampler
    register_index: u32,
    desc: SamplerDesc,
    shader_stages: StageFlags,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineLayoutCreateInfo.html
/// https://microsoft.github.io/DirectX-Specs/d3d/ResourceBinding.html#root-signature
/// https://microsoft.github.io/DirectX-Specs/d3d/ResourceBinding.html#root-signature-version-11
/// All indices are local in the currently bound pipeline layout. Pipeline layout example:
///     RootConstantDesc                #0          // "rootConstantIndex" - an index in "rootConstants" in the currently bound pipeline layout
///     ...
///     RootDescriptorDesc              #0          // "rootDescriptorIndex" - an index in "rootDescriptors" in the currently bound pipeline layout
///     ...
///     RootSamplerDesc                 #0
///     ...
///     Descriptor set                  #0          // "setIndex" - a descriptor set index in the pipeline layout, provided as an argument or bound to the pipeline
///         Descriptor range                #0      // "rangeIndex" - a descriptor range index in the descriptor set
///             Descriptor num                  N   // "descriptorIndex" and "baseDescriptor" - a descriptor (base) index in the descriptor range, i.e. sub-range start
///         ...
///     ...
pub const PipelineLayoutDesc = extern struct {
    root_register_space: u32, // must be unique, avoid big gaps
    root_constants: [*]allowzero const RootConstantDesc,
    root_constant_num: u32,
    root_descriptors: [*]allowzero const RootDescriptorDesc,
    root_descriptor_num: u32,
    root_samplers: [*]allowzero const RootSamplerDesc,
    root_sampler_num: u32,
    descriptor_sets: [*]allowzero const DescriptorSetDesc,
    descriptor_set_num: u32,
    shader_stages: StageFlags,
    flags: PipelineLayoutFlags,

    pub const Options = struct {
        root_register_space: u32 = 0,
        root_constants: []const RootConstantDesc = &.{},
        root_descriptors: []allowzero const RootDescriptorDesc = &.{},
        root_samplers: []allowzero const RootSamplerDesc = &.{},
        descriptor_sets: []allowzero const DescriptorSetDesc = &.{},
        shader_stages: StageFlags = .ALL,
        flags: PipelineLayoutFlags = .NONE,
    };
    pub inline fn from(opts: Options) @This() {
        return .{
            .root_register_space = opts.root_register_space,
            .root_constants = opts.root_constants.ptr,
            .root_constant_num = @intCast(opts.root_constants.len),
            .root_descriptors = opts.root_descriptors.ptr,
            .root_descriptor_num = @intCast(opts.root_descriptors.len),
            .root_samplers = opts.root_samplers.ptr,
            .root_sampler_num = @intCast(opts.root_samplers.len),
            .descriptor_sets = opts.descriptor_sets.ptr,
            .descriptor_set_num = @intCast(opts.descriptor_sets.len),
            .shader_stages = opts.shader_stages,
            .flags = opts.flags,
        };
    }
};

/// Descriptor pool
/// https://learn.microsoft.com/en-us/windows/win32/direct3d12/descriptor-heaps
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_descriptor_heap_desc
/// https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorPoolCreateInfo.html
pub const DescriptorPoolDesc = extern struct {
    // Maximum number of descriptor sets that can be allocated from this pool
    descriptor_set_max_num: u32,

    // Resource heap
    // - may be directly indexed in shaders via "RESOURCE_HEAP_DIRECTLY_INDEXED" pipeline layout flag
    // - https://docs.vulkan.org/features/latest/features/proposals/VK_EXT_mutable_descriptor_type.html
    mutable_max_num: u32, // number of "MUTABLE" descriptors, requires "features.mutableDescriptorType"

    // Sampler heap
    // - may be directly indexed in shaders via "SAMPLER_HEAP_DIRECTLY_INDEXED" pipeline layout flag
    // - root samplers do not count (not allocated from a descriptor pool)
    sampler_max_num: u32, // number of "SAMPLER" descriptors

    // Optimized resources (may have various sizes depending on Vulkan implementation)
    constant_buffer_max_num: u32, // number of "CONSTANT_BUFFER" descriptors
    texture_max_num: u32, // number of "TEXTURE" descriptors
    storage_texture_max_num: u32, // number of "STORAGE_TEXTURE" descriptors
    buffer_max_num: u32, // number of "BUFFER" descriptors
    storage_buffer_max_num: u32, // number of "STORAGE_BUFFER" descriptors
    structured_buffer_max_num: u32, // number of "STRUCTURED_BUFFER" descriptors
    storage_structured_buffer_max_num: u32, // number of "STORAGE_STRUCTURED_BUFFER" descriptors
    acceleration_structure_max_num: u32, // number of "ACCELERATION_STRUCTURE" descriptors, requires "features.rayTracing"
    input_attachment_max_num: u32, // number of "INPUT_ATTACHMENT" descriptors

    flags: DescriptorPoolFlags,
};

// Updating/initializing descriptors in a descriptor set
pub const UpdateDescriptorRangeDesc = extern struct {
    // Destination
    descriptor_set: *DescriptorSet,
    range_index: u32,
    base_descriptor: u32,
    // Source & count
    descriptors: [*]const *const Descriptor, // all descriptors must have the same type
    descriptor_num: u32,
};

// Copying descriptors between descriptor sets
pub const CopyDescriptorRangeDesc = extern struct {
    // Destination
    dst_descriptor_set: *DescriptorSet,
    dst_range_index: u32 = 0,
    dst_base_descriptor: u32 = 0,
    // Source & count
    src_descriptor_set: *const DescriptorSet,
    src_range_index: u32 = 0,
    src_base_descriptor: u32 = 0,
    descriptor_num: u32 = 0, // can be "ALL" (source)
};

// Binding
pub const SetDescriptorSetDesc = extern struct {
    set_index: u32,
    descriptor_set: *const DescriptorSet,
    bind_point: BindPoint = .COMPUTE,
};

pub const SetRootConstantsDesc = extern struct { // requires "pipelineLayoutRootConstantMaxSize > 0"
    root_constant_index: u32 = 0,
    data: *const anyopaque,
    size: u32 = 0,
    offset: u32 = 0, // requires "features.rootConstantsOffset"
    bind_point: BindPoint = .COMPUTE,
};

pub const SetRootDescriptorDesc = extern struct { // requires "pipelineLayoutRootDescriptorMaxNum > 0"
    root_descriptor_index: u32,
    descriptor: *Descriptor,
    offset: u32, // a non-"CONSTANT_BUFFER" descriptor requires "features.nonConstantBufferRootDescriptorOffset"
    bind_point: BindPoint = .COMPUTE,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkIndexType.html
pub const IndexType = enum(u8) {
    UINT16,
    UINT32,
};

pub const PrimitiveRestart = enum(u8) {
    DISABLED,
    INDICES_UINT16, // index "0xFFFF" enforces primitive restart
    INDICES_UINT32, // index "0xFFFFFFFF" enforces primitive restart
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkVertexInputRate.html
pub const VertexStreamStepRate = enum(u8) {
    PER_VERTEX,
    PER_INSTANCE,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkPrimitiveTopology.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3dcommon/ne-d3dcommon-d3d_primitive_topology
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_primitive_topology_type
pub const Topology = enum(u8) {
    POINT_LIST,
    LINE_LIST,
    LINE_STRIP,
    TRIANGLE_LIST,
    TRIANGLE_STRIP,
    LINE_LIST_WITH_ADJACENCY,
    LINE_STRIP_WITH_ADJACENCY,
    TRIANGLE_LIST_WITH_ADJACENCY,
    TRIANGLE_STRIP_WITH_ADJACENCY,
    PATCH_LIST,
};

pub const InputAssemblyDesc = extern struct {
    topology: Topology,
    tess_control_point_num: u8,
    primitive_restart: PrimitiveRestart,
};

pub const VertexAttributeD3D = extern struct {
    semantic_name: [*:0]const u8,
    semantic_index: u32,
};

pub const VertexAttributeVK = extern struct {
    location: u32,
};

pub const VertexAttributeDesc = extern struct {
    d3d: VertexAttributeD3D,
    vk: VertexAttributeVK,
    offset: u32,
    format: Format,
    stream_index: u16,
};

pub const VertexStreamDesc = extern struct {
    binding_slot: u16,
    step_rate: VertexStreamStepRate,
};

pub const VertexInputDesc = extern struct {
    attributes: [*]const VertexAttributeDesc,
    attribute_num: u8,
    streams: [*]const VertexStreamDesc,
    stream_num: u8,

    pub const Options = struct {
        attributes: []const VertexAttributeDesc = &.{},
        streams: []const VertexStreamDesc = &.{},
    };
    pub inline fn from(opts: Options) @This() {
        return .{
            .attributes = opts.attributes.ptr,
            .attribute_num = @intCast(opts.attributes.len),
            .streams = opts.streams.ptr,
            .stream_num = @intCast(opts.streams.len),
        };
    }
};

pub const VertexBufferDesc = extern struct {
    buffer: *const Buffer,
    offset: u64,
    stride: u32,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkPolygonMode.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_fill_mode
pub const FillMode = enum(u8) {
    SOLID,
    WIREFRAME,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkCullModeFlagBits.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_cull_mode
pub const CullMode = enum(u8) {
    NONE,
    FRONT,
    BACK,
};

/// https://docs.vulkan.org/samples/latest/samples/extensions/fragment_shading_rate_dynamic/README.html
/// https://microsoft.github.io/DirectX-Specs/d3d/VariableRateShading.html
pub const ShadingRate = enum(u8) {
    FRAGMENT_SIZE_1X1,
    FRAGMENT_SIZE_1X2,
    FRAGMENT_SIZE_2X1,
    FRAGMENT_SIZE_2X2,

    // Require "features.additionalShadingRates"
    FRAGMENT_SIZE_2X4,
    FRAGMENT_SIZE_4X2,
    FRAGMENT_SIZE_4X4,
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkFragmentShadingRateCombinerOpKHR.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_shading_rate_combiner
///    "primitiveCombiner"      "attachmentCombiner"
/// A   Pipeline shading rate    Result of Op1
/// B   Primitive shading rate   Attachment shading rate
pub const ShadingRateCombiner = enum(u8) {
    KEEP, // A
    REPLACE, // B
    MIN, // min(A, B)
    MAX, // max(A, B)
    SUM, // (A + B) or (A * B)
};

/// https://registry.khronos.org/vulkan/specs/latest/html/vkspec.html#primsrast-depthbias-computation
/// https://learn.microsoft.com/en-us/windows/win32/direct3d11/d3d10-graphics-programming-guide-output-merger-stage-depth-bias
/// R - minimum resolvable difference
/// S - maximum slope
///
/// bias = constant * R + slopeFactor * S
/// if (clamp > 0)
///     bias = min(bias, clamp)
/// else if (clamp < 0)
///     bias = max(bias, clamp)
///
/// enabled if constant != 0 or slope != 0
pub const DepthBiasDesc = extern struct {
    constant: f32 = 0,
    clamp: f32 = 0,
    slope: f32 = 0,
};

pub const RasterizationDesc = extern struct {
    depth_bias: DepthBiasDesc = .{},
    fill_mode: FillMode = .SOLID,
    cull_mode: CullMode = .NONE,
    front_counter_clockwise: bool = false,
    depth_clamp: bool = false,
    line_smoothing: bool = false, // requires "features.lineSmoothing"
    conservative_raster: bool = false, // requires "tiers.conservativeRaster != 0"
    shading_rate: bool = false, // requires "tiers.shadingRate != 0", expects "CmdSetShadingRate" and optionally "RenderingDesc::shadingRate"
};

pub const MultisampleDesc = extern struct {
    sample_mask: u32, // can be "ALL"
    sample_num: Sample_t,
    alpha_to_coverage: bool,
    sample_locations: bool, // requires "tiers.sampleLocations != 0", expects "CmdSetSampleLocations"
};

pub const ShadingRateDesc = extern struct {
    shading_rate: ShadingRate,
    primitive_combiner: ShadingRateCombiner, // requires "tiers.sampleLocations >= 2"
    attachment_combiner: ShadingRateCombiner, // requires "tiers.sampleLocations >= 2"
};

pub const Multiview = enum(u8) {
    // Destination "viewport" and/or "layer" must be set in shaders explicitly, "viewMask" for rendering can be < than the one used for pipeline creation (D3D12 style)
    FLEXIBLE, // requires "features.flexibleMultiview"

    // View instances go to statically assigned corresponding attachment layers, "viewMask" for rendering must match the one used for pipeline creation (VK style)
    LAYER_BASED, // requires "features.layerBasedMultiview"

    // View instances go to statically assigned corresponding viewports, "viewMask" for pipeline creation is unused (D3D11 style)
    VIEWPORT_BASED, // requires "features.viewportBasedMultiview"
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkLogicOp.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_logic_op
/// S - source color 0
/// D - destination color
pub const LogicOp = enum(u8) {
    NONE,
    CLEAR, // 0
    AND, // S & D
    AND_REVERSE, // S & ~D
    COPY, // S
    AND_INVERTED, // ~S & D
    XOR, // S ^ D
    OR, // S | D
    NOR, // ~(S | D)
    EQUIVALENT, // ~(S ^ D)
    INVERT, // ~D
    OR_REVERSE, // S | ~D
    COPY_INVERTED, // ~S
    OR_INVERTED, // ~S | D
    NAND, // ~(S & D)
    SET, // 1
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkStencilOp.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_stencil_op
/// R - reference, set by "CmdSetStencilReference"
/// D - stencil buffer
pub const StencilOp = enum(u8) {
    KEEP, // D = D
    ZERO, // D = 0
    REPLACE, // D = R
    INCREMENT_AND_CLAMP, // D = min(D++, 255)
    DECREMENT_AND_CLAMP, // D = max(D--, 0)
    INVERT, // D = ~D
    INCREMENT_AND_WRAP, // D++
    DECREMENT_AND_WRAP, // D--
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkBlendFactor.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_blend
/// S0 - source color 0
/// S1 - source color 1
/// D - destination color
/// C - blend constants, set by "CmdSetBlendConstants"
pub const BlendFactor = enum(u8) {
    ZERO, // 0                                 0
    ONE, // 1                                 1
    SRC_COLOR, // S0.r, S0.g, S0.b                  S0.a
    ONE_MINUS_SRC_COLOR, // 1 - S0.r, 1 - S0.g, 1 - S0.b      1 - S0.a
    DST_COLOR, // D.r, D.g, D.b                     D.a
    ONE_MINUS_DST_COLOR, // 1 - D.r, 1 - D.g, 1 - D.b         1 - D.a
    SRC_ALPHA, // S0.a                              S0.a
    ONE_MINUS_SRC_ALPHA, // 1 - S0.a                          1 - S0.a
    DST_ALPHA, // D.a                               D.a
    ONE_MINUS_DST_ALPHA, // 1 - D.a                           1 - D.a
    CONSTANT_COLOR, // C.r, C.g, C.b                     C.a
    ONE_MINUS_CONSTANT_COLOR, // 1 - C.r, 1 - C.g, 1 - C.b         1 - C.a
    CONSTANT_ALPHA, // C.a                               C.a
    ONE_MINUS_CONSTANT_ALPHA, // 1 - C.a                           1 - C.a
    SRC_ALPHA_SATURATE, // min(S0.a, 1 - D.a)                1
    SRC1_COLOR, // S1.r, S1.g, S1.b                  S1.a
    ONE_MINUS_SRC1_COLOR, // 1 - S1.r, 1 - S1.g, 1 - S1.b      1 - S1.a
    SRC1_ALPHA, // S1.a                              S1.a
    ONE_MINUS_SRC1_ALPHA, // 1 - S1.a                          1 - S1.a
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkBlendOp.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_blend_op
/// S - source color
/// D - destination color
/// Sf - source factor, produced by "BlendFactor"
/// Df - destination factor, produced by "BlendFactor"
pub const BlendOp = enum(u8) {
    ADD, // S * Sf + D * Df
    SUBTRACT, // S * Sf - D * Df
    REVERSE_SUBTRACT, // D * Df - S * Sf
    MIN, // min(S, D)
    MAX, // max(S, D)
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkColorComponentFlagBits.html
pub const ColorWriteFlags = packed struct(u8) {
    pub const NONE: ColorWriteFlags = @bitCast(@as(u8, 0));

    pub const RGB: ColorWriteFlags = .{ .r = true, .g = true, .b = true };
    pub const RGBA: ColorWriteFlags = .{ .r = true, .g = true, .b = true, .a = true };

    r: bool = false,
    g: bool = false,
    b: bool = false,
    a: bool = false,

    _: u4 = 0,

    pub inline fn bits(self: ColorWriteFlags) u8 {
        return @bitCast(self);
    }
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkColorComponentFlagBits.html
pub const ColorWriteBits = enum(u8) {
    NONE = 0,
    R = 1 << 0,
    G = 1 << 1,
    B = 1 << 2,
    A = 1 << 3,

    RGB = @bitCast(ColorWriteFlags.RGB),
    RGBA = @bitCast(ColorWriteFlags.RGBA),
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineDepthStencilStateCreateInfo.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_depth_stencil_desc
pub const StencilDesc = extern struct {
    compare_op: CompareOp = .NONE, // "compareOp != NONE", expects "CmdSetStencilReference"
    fail_op: StencilOp = .KEEP,
    pass_op: StencilOp = .KEEP,
    depth_fail_op: StencilOp = .KEEP,
    write_mask: u8 = 0,
    compare_mask: u8 = 0,
};

pub const DepthAttachmentDesc = extern struct {
    compare_op: CompareOp = .NONE,
    write: bool = false,
    bounds_test: bool = false, // requires "features.depthBoundsTest", expects "CmdSetDepthBounds"
};

pub const StencilAttachmentDesc = extern struct {
    front: StencilDesc = .{},
    back: StencilDesc = .{}, // requires "features.independentFrontAndBackStencilReferenceAndMasks" for "back.writeMask"
};

/// https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineColorBlendAttachmentState.html
/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_render_target_blend_desc
pub const BlendDesc = extern struct {
    src_factor: BlendFactor = .ZERO,
    dst_factor: BlendFactor = .ZERO,
    op: BlendOp = .ADD,
};

pub const ColorAttachmentDesc = extern struct {
    format: Format,
    color_blend: BlendDesc,
    alpha_blend: BlendDesc,
    color_write_mask: ColorWriteBits,
    blend_enabled: bool,
};

pub const OutputMergerDesc = extern struct {
    colors: [*]const ColorAttachmentDesc,
    color_num: u32,
    depth: DepthAttachmentDesc,
    stencil: StencilAttachmentDesc,
    depth_stencil_format: Format,
    logic_op: LogicOp, // requires "features.logicOp"
    view_mask: u32 = 0, // if non-0, requires "viewMaxNum > 1"
    multiview: Multiview = .FLEXIBLE, // if "viewMask != 0", requires "features.(xxx)Multiview"

    pub const Options = struct {
        colors: []const ColorAttachmentDesc,
        depth: DepthAttachmentDesc = .{},
        stencil: StencilAttachmentDesc = .{},
        depth_stencil_format: Format = .UNKNOWN,
        logic_op: LogicOp = .NONE,
        view_mask: u32 = 0,
        multiview: Multiview = .FLEXIBLE,
    };
    pub inline fn from(opts: Options) @This() {
        return .{
            .colors = opts.colors.ptr,
            .color_num = @intCast(opts.colors.len),
            .depth = opts.depth,
            .stencil = opts.stencil,
            .depth_stencil_format = opts.depth_stencil_format,
            .logic_op = opts.logic_op,
            .view_mask = opts.view_mask,
            .multiview = opts.multiview,
        };
    }
};

/// https://docs.vulkan.org/guide/latest/robustness.html
pub const Robustness = enum(u8) {
    DEFAULT, // don't care, follow device settings (VK level when used on a device)
    OFF, // no overhead, no robust access (out-of-bounds access is not allowed)
    VK, // minimal overhead, partial robust access
    D3D12, // moderate overhead, D3D12-level robust access (requires "VK_EXT_robustness2", soft fallback to VK mode)
};

// It's recommended to use "NRI.hlsl" in the shader code
pub const ShaderDesc = extern struct {
    stage: StageFlags,
    bytecode: [*]const u8,
    size: u64,
    entry_point_name: ?[*:0]const u8 = null,

    pub const Options = struct {
        stage: StageFlags,
        bytecode: []const u8,
        entry_point_name: ?[*:0]const u8 = null,
    };
    pub inline fn from(opts: Options) @This() {
        return .{
            .stage = opts.stage,
            .bytecode = opts.bytecode.ptr,
            .size = @intCast(opts.bytecode.len),
            .entry_point_name = opts.entry_point_name,
        };
    }
};

pub const GraphicsPipelineDesc = extern struct {
    pipeline_layout: *const PipelineLayout,
    vertex_input: ?*const VertexInputDesc = null,
    input_assembly: InputAssemblyDesc,
    rasterization: RasterizationDesc,
    multisample: ?*const MultisampleDesc = null,
    output_merger: OutputMergerDesc,
    shaders: [*]const ShaderDesc,
    shader_num: u32,
    robustness: Robustness = .DEFAULT,

    pub const Options = struct {
        pipeline_layout: *const PipelineLayout,
        vertex_input: ?VertexInputDesc.Options = null,
        input_assembly: InputAssemblyDesc,
        rasterization: RasterizationDesc,
        multisample: ?*const MultisampleDesc = null,
        output_merger: OutputMergerDesc.Options,
        shaders: []const ShaderDesc,
        robustness: Robustness = .DEFAULT,
    };
    pub inline fn from(opts: Options) @This() {
        return .{
            .pipeline_layout = opts.pipeline_layout,
            .vertex_input = if (opts.vertex_input) |v| &.from(v) else null,
            .input_assembly = opts.input_assembly,
            .rasterization = opts.rasterization,
            .multisample = opts.multisample,
            .output_merger = .from(opts.output_merger),
            .shaders = opts.shaders.ptr,
            .shader_num = @intCast(opts.shaders.len),
            .robustness = opts.robustness,
        };
    }
};

pub const ComputePipelineDesc = extern struct {
    pipeline_layout: *const PipelineLayout,
    shader: ShaderDesc,
    robustness: Robustness = .DEFAULT,
};

/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_render_pass_beginning_access_type
/// https://docs.vulkan.org/refpages/latest/refpages/source/VkAttachmentLoadOp.html
pub const LoadOp = enum(u8) {
    LOAD,
    CLEAR,
};

/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_render_pass_ending_access_type
/// https://docs.vulkan.org/refpages/latest/refpages/source/VkAttachmentStoreOp.html
pub const StoreOp = enum(u8) {
    STORE,
    DISCARD,
};

/// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_resolve_mode
/// https://docs.vulkan.org/refpages/latest/refpages/source/VkResolveModeFlagBits.html
pub const ResolveOp = enum(u8) {
    /// resolves the source samples to their average value
    AVERAGE,
    /// resolves the source samples to their minimum value, requires "features.resolveOpMinMax"
    MIN,
    /// resolves the source samples to their maximum value, requires "features.resolveOpMinMax"
    MAX,
};

pub const AttachmentDesc = extern struct {
    descriptor: *Descriptor,
    clear_value: ClearValue = .{ .depth_stencil = .{} },
    load_op: LoadOp = .LOAD,
    store_op: StoreOp = .STORE,
    resolve_op: ResolveOp = .AVERAGE,
    resolve_dst: ?*Descriptor = null, // must be valid during "CmdEndRendering"
};

pub const RenderingDesc = extern struct {
    colors: [*]const AttachmentDesc,
    color_num: u32 = 0,
    depth: AttachmentDesc, // may be treated as "depth-stencil"
    stencil: AttachmentDesc, // (optional) separation is needed for multisample resolve
    shading_rate: ?*const Descriptor = null, // requires "tiers.shadingRate >= 2"
    view_mask: u32 = 0, // if non-0, requires "viewMaxNum > 1"

    pub const Options = struct {
        colors: []const AttachmentDesc,
        depth: AttachmentDesc = std.mem.zeroes(AttachmentDesc),
        stencil: AttachmentDesc = std.mem.zeroes(AttachmentDesc),
        shading_rate: ?*const Descriptor = null,
        view_mask: u32 = 0,
    };
    pub inline fn from(opts: Options) @This() {
        return .{
            .colors = opts.colors.ptr,
            .color_num = @intCast(opts.colors.len),
            .depth = opts.depth,
            .stencil = opts.stencil,
            .shading_rate = opts.shading_rate,
            .view_mask = opts.view_mask,
        };
    }
};

/// https://microsoft.github.io/DirectX-Specs/d3d/CountersAndQueries.html
/// https://docs.vulkan.org/refpages/latest/refpages/source/VkQueryType.html
pub const QueryType = enum(u8) {
    TIMESTAMP, // uint64_t
    TIMESTAMP_COPY_QUEUE, // uint64_t (requires "features.copyQueueTimestamp"), same as "TIMESTAMP" but for a "COPY" queue
    OCCLUSION, // uint64_t
    PIPELINE_STATISTICS, // see "PipelineStatisticsDesc" (requires "features.pipelineStatistics")
    ACCELERATION_STRUCTURE_SIZE, // uint64_t, requires "features.rayTracing"
    ACCELERATION_STRUCTURE_COMPACTED_SIZE, // uint64_t, requires "features.rayTracing"
    MICROMAP_COMPACTED_SIZE, // uint64_t, requires "features.micromap"
};

pub const QueryPoolDesc = extern struct {
    query_type: QueryType = .TIMESTAMP,
    capacity: u32 = 0,
};

// Data layout for QueryType::PIPELINE_STATISTICS
// https://docs.vulkan.org/refpages/latest/refpages/source/VkQueryPipelineStatisticFlagBits.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_query_data_pipeline_statistics
pub const PipelineStatisticsDesc = extern struct {
    // Common part
    input_vertex_num: u64 = 0,
    input_primitive_num: u64 = 0,
    vertex_shader_invocation_num: u64 = 0,
    geometry_shader_invocation_num: u64 = 0,
    geometry_shader_primitive_num: u64 = 0,
    rasterizer_in_primitive_num: u64 = 0,
    rasterizer_out_primitive_num: u64 = 0,
    fragment_shader_invocation_num: u64 = 0,
    tess_control_shader_invocation_num: u64 = 0,
    tess_evaluation_shader_invocation_num: u64 = 0,
    compute_shader_invocation_num: u64 = 0,

    // If "features.meshShaderPipelineStats"
    task_shader_invocation_num: u64 = 0,
    mesh_shader_invocation_num: u64 = 0,

    // D3D12: if "features.meshShaderPipelineStats"
    mesh_shader_primitive_num: u64 = 0,
};

// To fill commands for indirect drawing in a shader use one of "NRI_FILL_X_DESC" macros

// Command signatures (default)

pub const DrawDesc = extern struct { // see NRI_FILL_DRAW_DESC
    vertex_num: u32 = 0,
    instance_num: u32 = 0,
    base_vertex: u32 = 0, // vertex buffer offset = CmdSetVertexBuffers.offset + baseVertex * VertexStreamDesc::stride
    base_instance: u32 = 0,
};

pub const DrawIndexedDesc = extern struct { // see NRI_FILL_DRAW_INDEXED_DESC
    index_num: u32 = 0,
    instance_num: u32 = 0,
    base_index: u32 = 0, // index buffer offset = CmdSetIndexBuffer.offset + baseIndex * sizeof(CmdSetIndexBuffer.indexType)
    base_vertex: i32 = 0, // index += baseVertex
    base_instance: u32 = 0,
};

pub const DispatchDesc = extern struct {
    x: u32 = 0,
    y: u32 = 0,
    z: u32 = 0,
};

// Modified draw command signatures, if the bound pipeline layout has "PipelineLayoutBits::ENABLE_DRAW_PARAMETERS_EMULATION"

pub const DrawBaseDesc = extern struct { // see NRI_FILL_DRAW_DESC
    shader_emulated_base_vertex: u32 = 0, // root constant
    shader_emulated_base_instance: u32 = 0, // root constant
    vertex_num: u32 = 0,
    instance_num: u32 = 0,
    base_vertex: u32 = 0, // vertex buffer offset = CmdSetVertexBuffers.offset + baseVertex * VertexStreamDesc::stride
    base_instance: u32 = 0,
};

pub const DrawIndexedBaseDesc = extern struct { // see NRI_FILL_DRAW_INDEXED_DESC
    shader_emulated_base_vertex: i32 = 0, // root constant
    shader_emulated_base_instance: u32 = 0, // root constant
    index_num: u32 = 0,
    instance_num: u32 = 0,
    base_index: u32 = 0, // index buffer offset = CmdSetIndexBuffer.offset + baseIndex * sizeof(CmdSetIndexBuffer.indexType)
    base_vertex: i32 = 0, // index += baseVertex
    base_instance: u32 = 0,
};

// Copy
pub const TextureRegionDesc = extern struct {
    x: Dim_t = 0,
    y: Dim_t = 0,
    z: Dim_t = 0,
    width: Dim_t = 0, // can be "WHOLE_SIZE" (mip)
    height: Dim_t = 0, // can be "WHOLE_SIZE" (mip)
    depth: Dim_t = 0, // can be "WHOLE_SIZE" (mip)
    mip_offset: Dim_t = 0,
    layer_offset: Dim_t = 0,
    planes: PlaneFlags = .{},
};

pub const TextureDataLayoutDesc = extern struct {
    offset: u64 = 0, // a buffer offset must be a multiple of "uploadBufferTextureSliceAlignment" (data placement alignment)
    row_pitch: u32 = 0, // must be a multiple of "uploadBufferTextureRowAlignment"
    slice_pitch: u32 = 0, // must be a multiple of "uploadBufferTextureSliceAlignment"
};

// Work submission
pub const FenceSubmitDesc = extern struct {
    fence: *Fence,
    value: u64 = 0,
    stages: StageFlags = .NONE,
};

pub const QueueSubmitDesc = extern struct {
    wait_fences: [*]const FenceSubmitDesc,
    wait_fence_num: u32 = 0,
    command_buffers: [*]const *const CommandBuffer,
    command_buffer_num: u32 = 0,
    signal_fences: [*]const FenceSubmitDesc,
    signal_fence_num: u32 = 0,
    swap_chain: ?*const SwapChain = null, // required if "NRILowLatency" is enabled in the swap chain

    pub const Options = struct {
        wait_fences: []const FenceSubmitDesc,
        command_buffers: []const *CommandBuffer,
        signal_fences: []const FenceSubmitDesc,
        swap_chain: ?*const SwapChain = null,
    };
    pub fn from(opts: Options) @This() {
        return .{
            .wait_fences = opts.wait_fences.ptr,
            .wait_fence_num = @intCast(opts.wait_fences.len),
            .command_buffers = opts.command_buffers.ptr,
            .command_buffer_num = @intCast(opts.command_buffers.len),
            .signal_fences = opts.signal_fences.ptr,
            .signal_fence_num = @intCast(opts.signal_fences.len),
            .swap_chain = opts.swap_chain,
        };
    }
};

// Clear
pub const ClearAttachmentDesc = extern struct {
    value: ClearValue,
    planes: PlaneBits,
    color_attachment_index: u8,
};

// Required synchronization
// - variant 1: "SHADER_RESOURCE_STORAGE" access ("SHADER_RESOURCE_STORAGE" layout) and "CLEAR_STORAGE" stage + any shader stage (or "ALL")
// - variant 2: "CLEAR_STORAGE" access ("SHADER_RESOURCE_STORAGE" layout) and "CLEAR_STORAGE" stage
pub const ClearStorageDesc = extern struct {
    // For any buffers and textures with integer formats:
    //  - Clears a storage descriptor with bit-precise values, copying the lower "N" bits from "value.[f/ui/i].channel"
    //    to the corresponding channel, where "N" is the number of bits in the "channel" of the resource format
    // For textures with non-integer formats:
    //  - Clears a storage descriptor with float values with format conversion from "FLOAT" to "UNORM/SNORM" where appropriate
    // For buffers:
    //  - To avoid discrepancies in behavior between GAPIs use "R32f/ui/i" formats for views
    //  - D3D: structured buffers are unsupported!
    descriptor: *Descriptor, // a "STORAGE" descriptor
    value: Color, // avoid overflow
    set_index: u32,
    range_index: u32,
    descriptor_index: u32,
};

pub const Vendor = enum(u8) {
    UNKNOWN,
    NVIDIA,
    AMD,
    INTEL,
};

// https://docs.vulkan.org/refpages/latest/refpages/source/VkPhysicalDeviceType.html
pub const Architecture = enum(u8) {
    UNKNOWN, // CPU device, virtual GPU or other
    INTEGRATED, // UMA
    DISCRETE, // yes, please!
};

// https://docs.vulkan.org/refpages/latest/refpages/source/VkQueueFlagBits.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_command_list_type
pub const QueueType = enum(u8) {
    GRAPHICS,
    COMPUTE,
    COPY,
};

pub const AdapterDesc = extern struct {
    name: [256]u8,
    uid: Uid_t, // "LUID" (preferred) if "uid.high = 0", or "UUID" otherwise
    video_memory_size: u64,
    shared_system_memory_size: u64,
    device_id: u32,
    queue_num: [3]u32, // [(uint32_t)NriScopedMember(QueueType, MAX_NUM)]
    vendor: Vendor,
    architecture: Architecture,
};

// Feature support coverage: https://vulkan.gpuinfo.org/ and https://d3d12infodb.boolka.dev/
pub const DeviceDesc = extern struct {
    pub const DeviceViewport = extern struct {
        max_num: u32,
        bounds_min: i16,
        bounds_max: i16,
    };

    pub const DeviceDimensions = extern struct {
        typed_buffer_max_dim: u32,
        attachment_max_dim: Dim_t,
        attachment_layer_max_num: Dim_t,
        texture1_d_max_dim: Dim_t,
        texture2_d_max_dim: Dim_t,
        texture3_d_max_dim: Dim_t,
        texture_layer_max_num: Dim_t,
    };

    pub const DevicePrecision = extern struct {
        viewport_bits: u32,
        sub_pixel_bits: u32,
        sub_texel_bits: u32,
        mipmap_bits: u32,
    };

    pub const DeviceMemory = extern struct {
        device_upload_heap_size: u64, // ReBAR
        buffer_max_size: u64,
        allocation_max_size: u64,
        allocation_max_num: u32,
        sampler_allocation_max_num: u32,
        constant_buffer_max_range: u32,
        storage_buffer_max_range: u32,
        buffer_texture_granularity: u32, // specifies a page-like granularity at which linear and non-linear resources must be placed in adjacent memory locations to avoid aliasing
        alignment_default: u32, // (INTERNAL) worst-case alignment for a memory allocation respecting all possible placed resources, excluding multisample textures
        alignment_multisample: u32, // (INTERNAL) worst-case alignment for a memory allocation respecting all possible placed resources, including multisample textures
    };

    pub const DeviceMemoryAlignment = extern struct {
        upload_buffer_texture_row: u32,
        upload_buffer_texture_slice: u32,
        buffer_shader_resource_offset: u32,
        constant_buffer_offset: u32,
        scratch_buffer_offset: u32,
        shader_binding_table: u32,
        acceleration_structure_offset: u32,
        micromap_offset: u32,
    };

    pub const DevicePipelineLayout = extern struct {
        descriptor_set_max_num: u32,
        root_constant_max_size: u32,
        root_descriptor_max_num: u32,
    };

    pub const DeviceDescriptorSet = extern struct {
        pub const UpdateAfterSet = extern struct {
            sampler_max_num: u32,
            constant_buffer_max_num: u32,
            storage_buffer_max_num: u32,
            texture_max_num: u32,
            storage_texture_max_num: u32,
        };

        sampler_max_num: u32,
        constant_buffer_max_num: u32,
        storage_buffer_max_num: u32,
        texture_max_num: u32,
        storage_texture_max_num: u32,

        update_after_set: UpdateAfterSet,
    };

    pub const ShaderStage = extern struct {
        pub const UpdateAfterSet = extern struct {
            descriptor_sampler_max_num: u32,
            descriptor_constant_buffer_max_num: u32,
            descriptor_storage_buffer_max_num: u32,
            descriptor_texture_max_num: u32,
            descriptor_storage_texture_max_num: u32,
            resource_max_num: u32,
        };

        pub const Vertex = extern struct {
            attribute_max_num: u32,
            stream_max_num: u32,
            output_component_max_num: u32,
        };

        pub const TessellationControl = extern struct {
            generation_max_level: f32,
            patch_point_max_num: u32,
            per_vertex_input_component_max_num: u32,
            per_vertex_output_component_max_num: u32,
            per_patch_output_component_max_num: u32,
            total_output_component_max_num: u32,
        };

        pub const TessellationEvaluation = extern struct {
            input_component_max_num: u32,
            output_component_max_num: u32,
        };

        pub const Geometry = extern struct {
            invocation_max_num: u32,
            input_component_max_num: u32,
            output_component_max_num: u32,
            output_vertex_max_num: u32,
            total_output_component_max_num: u32,
        };

        pub const Fragment = extern struct {
            input_component_max_num: u32,
            attachment_max_num: u32,
            dual_source_attachment_max_num: u32,
        };

        pub const Compute = extern struct {
            dispatch_max_dim: [3]u32,
            work_group_invocation_max_num: u32,
            work_group_max_dim: [3]u32,
            shared_memory_max_size: u32,
        };

        pub const Task = extern struct {
            dispatch_work_group_max_num: u32,
            dispatch_max_dim: [3]u32,
            work_group_invocation_max_num: u32,
            work_group_max_dim: [3]u32,
            shared_memory_max_size: u32,
            payload_max_size: u32,
        };

        pub const Mesh = extern struct {
            dispatch_work_group_max_num: u32,
            dispatch_max_dim: [3]u32,
            work_group_invocation_max_num: u32,
            work_group_max_dim: [3]u32,
            shared_memory_max_size: u32,
            output_vertices_max_num: u32,
            output_primitive_max_num: u32,
            output_component_max_num: u32,
        };

        pub const RayTracing = extern struct {
            shader_group_identifier_size: u32,
            shader_binding_table_max_stride: u32,
            recursion_max_depth: u32,
        };

        // Per stage resources
        descriptor_sampler_max_num: u32,
        descriptor_constant_buffer_max_num: u32,
        descriptor_storage_buffer_max_num: u32,
        descriptor_texture_max_num: u32,
        descriptor_storage_texture_max_num: u32,
        resource_max_num: u32,

        update_after_set: UpdateAfterSet,

        // Vertex
        vertex: Vertex,

        // Tessellation control
        tessellation_control: TessellationControl,

        // Tessellation evaluation
        tessellation_evaluation: TessellationEvaluation,

        // Geometry
        geometry: Geometry,

        // Fragment
        fragment: Fragment,

        // Compute
        compute: Compute,

        // Task
        task: Task,

        // Mesh
        mesh: Mesh,

        // Ray tracing
        ray_tracing: RayTracing,
    };

    pub const AccelerationStructure = extern struct {
        primitive_max_num: u64, // per BLAS
        geometry_max_num: u64, // per BLAS
        instance_max_num: u64, // per TLAS
        micromap_subdivision_max_level: u32,
    };

    pub const Wave = extern struct {
        lane_min_num: u32,
        lane_max_num: u32,
        wave_ops_stages: StageFlags, // SM 6.0+ (see "shaderFeatures.waveX")
        quad_ops_stages: StageFlags, // SM 6.0+ (see "shaderFeatures.waveQuad")
        derivative_ops_stages: StageFlags, // SM 6.6+ (https://microsoft.github.io/DirectX-Specs/d3d/HLSL_SM_6_6_Derivatives.html#derivative-functions)
    };

    pub const Other = extern struct {
        timestamp_frequency_hz: u64,
        draw_indirect_max_num: u32,
        sampler_lod_bias_max: f32,
        sampler_anisotropy_max: f32,
        texel_gather_offset_min: i8,
        texel_offset_min: i8,
        texel_offset_max: u8,
        texel_gather_offset_max: u8,
        clip_distance_max_num: u8,
        cull_distance_max_num: u8,
        combined_clip_and_cull_distance_max_num: u8,
        view_max_num: u8, // multiview is supported if > 1
        shading_rate_attachment_tile_size: u8, // square size
    };

    pub const Tiers = extern struct {
        /// https://microsoft.github.io/DirectX-Specs/d3d/ConservativeRasterization.html#tiered-support
        /// 1 - 1/2 pixel uncertainty region and does not support post-snap degenerates
        /// 2 - reduces the maximum uncertainty region to 1/256 and requires post-snap degenerates not be culled
        /// 3 - maintains a maximum 1/256 uncertainty region and adds support for inner input coverage, aka "SV_InnerCoverage"
        conservative_raster: u8,

        /// https://microsoft.github.io/DirectX-Specs/d3d/ProgrammableSamplePositions.html#hardware-tiers
        /// 1 - a single sample pattern can be specified to repeat for every pixel ("locationNum / sampleNum" ratio must be 1 in "CmdSetSampleLocations"),
        ///     1x and 16x sample counts do not support programmable locations
        /// 2 - four separate sample patterns can be specified for each pixel in a 2x2 grid ("locationNum / sampleNum" ratio can be 1 or 4 in "CmdSetSampleLocations"),
        ///     all sample counts support programmable positions
        sample_locations: u8,

        /// https://microsoft.github.io/DirectX-Specs/d3d/Raytracing.html#checkfeaturesupport-structures
        /// 1 - DXR 1.0: full raytracing functionality, except features below
        /// 2 - DXR 1.1: adds - ray query, "CmdDispatchRaysIndirect", "GeometryIndex()" intrinsic, additional ray flags & vertex formats
        /// 3 - DXR 1.2: adds - micromap, shader execution reordering
        ray_tracing: u8,

        /// https://microsoft.github.io/DirectX-Specs/d3d/VariableRateShading.html#feature-tiering
        /// 1 - shading rate can be specified only per draw
        /// 2 - adds: per primitive shading rate, per "shadingRateAttachmentTileSize" shading rate, combiners, "SV_ShadingRate" support
        shading_rate: u8,

        /// https://learn.microsoft.com/en-us/windows/win32/direct3d12/root-signature-limits#limitations-on-static-samplers
        /// 0 - ALL descriptors in range must be valid by the time the command list executes
        /// 1 - only "CONSTANT_BUFFER" and "STORAGE" descriptors in range must be valid
        /// 2 - only referenced descriptors must be valid
        resource_binding: u8,

        /// 1 - unbound arrays with dynamic indexing
        /// 2 - D3D12 dynamic resources: https://microsoft.github.io/DirectX-Specs/d3d/HLSL_SM_6_6_DynamicResources.html
        bindless: u8,

        /// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_resource_heap_tier
        /// 1 - a "Memory" can support resources from all 3 categories: buffers, attachments, all other textures
        memory: u8,
    };

    pub const Features = packed struct(u32) {
        // Bigger
        get_memory_desc2: bool, // "GetXxxMemoryDesc2" support (VK: requires "maintenance4", D3D: supported)
        enhanced_barriers: bool, // VK: supported, D3D12: requires "AgilitySDK", D3D11: unsupported
        swap_chain: bool, // NRISwapChain
        mesh_shader: bool, // NRIMeshShader
        low_latency: bool, // NRILowLatency

        // Smaller
        component_swizzle: bool, // see "ComponentSwizzle" (unsupported only in D3D11)
        independent_front_and_back_stencil_reference_and_masks: bool, // see "StencilAttachmentDesc::back"
        filter_op_min_max: bool, // see "FilterOp"
        logic_op: bool, // see "LogicOp"
        depth_bounds_test: bool, // see "DepthAttachmentDesc::boundsTest"
        draw_indirect_count: bool, // see "countBuffer" and "countBufferOffset"
        line_smoothing: bool, // see "RasterizationDesc::lineSmoothing"
        copy_queue_timestamp: bool, // see "QueryType::TIMESTAMP_COPY_QUEUE"
        mesh_shader_pipeline_stats: bool, // see "PipelineStatisticsDesc"
        dynamic_depth_bias: bool, // see "CmdSetDepthBias"
        additional_shading_rates: bool, // see "ShadingRate"
        viewport_origin_bottom_left: bool, // see "Viewport"
        region_resolve: bool, // see "CmdResolveTexture"
        resolve_op_min_max: bool, // see "ResolveOp"
        flexible_multiview: bool, // see "Multiview::FLEXIBLE"
        layer_based_multiview: bool, // see "Multiview::LAYERED_BASED"
        viewport_based_multiview: bool, // see "Multiview::VIEWPORT_BASED"
        present_from_compute: bool, // see "SwapChainDesc::queue"
        waitable_swap_chain: bool, // see "SwapChainDesc::waitable"
        resizable_swap_chain: bool, // swap chain can be resized without triggering an "OUT_OF_DATE" error
        pipeline_statistics: bool, // see "QueryType::PIPELINE_STATISTICS"
        root_constants_offset: bool, // see "SetRootConstantsDesc" (unsupported only in D3D11)
        non_constant_buffer_root_descriptor_offset: bool, // see "SetRootDescriptorDesc" (unsupported only in D3D11)
        mutable_descriptor_type: bool, // see "DescriptorType::MUTABLE"
        unified_texture_layouts: bool, // allows to use "GENERAL" everywhere: https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_unified_image_layouts.html

        _: u2 = 0,
    };

    pub const ShaderFeatures = packed struct(u32) {
        // Native types (I32 and F32 are always supported)
        // https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-scalar
        native_i8: bool, // "(u)int8_t"
        native_i16: bool, // "(u)int16_t"
        native_f16: bool, // "float16_t"
        native_i64: bool, // "(u)int64_t"
        native_f64: bool, // "double"

        // Atomics on native types (I32 atomics are always supported, for others it can be partial support of SMEM, texture or buffer atomics)
        // https://learn.microsoft.com/en-us/windows/win32/direct3d11/direct3d-11-advanced-stages-cs-atomic-functions
        // https://microsoft.github.io/DirectX-Specs/d3d/HLSL_SM_6_6_Int64_and_Float_Atomics.html
        atomics_i16: bool, // "(u)int16_t" atomics
        atomics_f16: bool, // "float16_t" atomics
        atomics_f32: bool, // "float" atomics
        atomics_i64: bool, // "(u)int64_t" atomics
        atomics_f64: bool, // "double" atomics

        // Storage without format
        // https://learn.microsoft.com/en-us/windows/win32/direct3d12/typed-unordered-access-view-loads#using-unorm-and-snorm-typed-uav-loads-from-hlsl
        storage_read_without_format: bool, // NRI_FORMAT("unknown") is allowed for storage reads
        storage_write_without_format: bool, // NRI_FORMAT("unknown") is allowed for storage writes

        // Wave intrinsics
        // https://github.com/microsoft/directxshadercompiler/wiki/wave-intrinsics
        wave_query: bool, // WaveIsFirstLane, WaveGetLaneCount, WaveGetLaneIndex
        wave_vote: bool, // WaveActiveAllTrue, WaveActiveAnyTrue, WaveActiveAllEqual
        wave_shuffle: bool, // WaveReadLaneFirst, WaveReadLaneAt
        wave_arithmetic: bool, // WaveActiveSum, WaveActiveProduct, WaveActiveMin, WaveActiveMax, WavePrefixProduct, WavePrefixSum
        wave_reduction: bool, // WaveActiveCountBits, WaveActiveBitAnd, WaveActiveBitOr, WaveActiveBitXor, WavePrefixCountBits
        wave_quad: bool, // QuadReadLaneAt, QuadReadAcrossX, QuadReadAcrossY, QuadReadAcrossDiagonal

        // Other
        viewport_index: bool, // SV_ViewportArrayIndex, always can be used in geometry shaders
        layer_index: bool, // SV_RenderTargetArrayIndex, always can be used in geometry shaders
        unnormalized_coordinates: bool, // https://microsoft.github.io/DirectX-Specs/d3d/VulkanOn12.html#non-normalized-texture-sampling-coordinates
        clock: bool, // https://github.com/Microsoft/DirectXShaderCompiler/blob/main/docs/SPIR-V.rst#readclock
        rasterized_ordered_view: bool, // https://microsoft.github.io/DirectX-Specs/d3d/RasterOrderViews.html (aka fragment shader interlock)
        barycentric: bool, // https://github.com/microsoft/DirectXShaderCompiler/wiki/SV_Barycentrics
        ray_tracing_position_fetch: bool, // https://docs.vulkan.org/features/latest/features/proposals/VK_KHR_ray_tracing_position_fetch.html
        integer_dot_product: bool, // https://github.com/microsoft/DirectXShaderCompiler/wiki/Shader-Model-6.4
        input_attachments: bool, // https://github.com/Microsoft/DirectXShaderCompiler/blob/main/docs/SPIR-V.rst#subpass-inputs
        draw_parameters: bool, // SV_StartVertexLocation, SV_StartInstanceLocation (native support)

        // For shaders using "draw parameters":
        //   - "ENABLE_DRAW_PARAMETERS_EMULATION" must be set for a corresponding "PipelineLayout"
        //   - "NRI_ENABLE_DRAW_PARAMETERS_EMULATION" must be defined prior inclusion of "NRI.hlsl" for such shaders
        draw_parameters_emulation: bool, // emulation of "drawParameters"

        _: u3 = 0,
    };

    // Common
    adapter_desc: AdapterDesc, // "queueNum" reflects available number of queues per "QueueType"
    graphics_api: GraphicsAPI,
    nri_version: u16,
    shader_model: u8, // major * 10 + minor

    // Viewport
    viewport: DeviceViewport,

    // Dimensions
    dimensions: DeviceDimensions,

    // Precision bits
    precision: DevicePrecision,

    // Memory
    memory: DeviceMemory,

    // Memory alignment requirements
    memory_alignment: DeviceMemoryAlignment,

    // Pipeline layout
    // D3D12 only: rootConstantSize + descriptorSetNum * 4 + rootDescriptorNum * 8 <= 256 (see "FitPipelineLayoutSettingsIntoDeviceLimits")
    pipeline_layout: DevicePipelineLayout,

    // Descriptor set
    descriptor_set: DeviceDescriptorSet,

    // Shader stages
    shader_stage: ShaderStage,

    // Acceleration structure
    // Acceleration structure
    acceleration_structure: AccelerationStructure,

    // Wave (subgroup)
    // https://github.com/microsoft/directxshadercompiler/wiki/wave-intrinsics
    // https://microsoft.github.io/DirectX-Specs/d3d/HLSL_SM_6_6_Derivatives.html
    wave: Wave,

    // Other
    other: Other,

    // Tiers (0 - unsupported)
    tiers: Tiers,

    // Features
    features: Features,

    // Shader features
    // https://github.com/Microsoft/DirectXShaderCompiler/blob/main/docs/SPIR-V.rst
    shader_features: ShaderFeatures,
};
