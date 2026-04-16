// Goal: ray tracing
// https://microsoft.github.io/DirectX-Specs/d3d/Raytracing.html
// https://microsoft.github.io/DirectX-Specs/d3d/Raytracing2.html

const Descs = @import("../Descs.zig");

const Device = Descs.Device;
const Result = Descs.Result;
const Pipeline = Descs.Pipeline;
const Descriptor = Descs.Descriptor;
const Buffer = Descs.Buffer;
const Memory = Descs.Memory;
const MemoryLocation = Descs.MemoryLocation;
const MemoryDesc = Descs.MemoryDesc;
const QueryPool = Descs.QueryPool;
const CommandBuffer = Descs.CommandBuffer;
const PipelineLayout = Descs.PipelineLayout;
const Robustness = Descs.Robustness;
const IndexType = Descs.IndexType;
const Format = Descs.Format;
const ShaderDesc = Descs.ShaderDesc;

/// bottom- or top- level acceleration structure (aka BLAS or TLAS respectively)
pub const AccelerationStructure = opaque {};
/// a micromap that encodes sub-triangle opacity (aka OMM, can be attached to a triangle BLAS)
pub const Micromap = opaque {};

/// only to indicate buffer presence in "AccelerationStructureDesc"
pub const HAS_BUFFER: *Buffer = @ptrFromInt(1);

pub const RayTracingPipelineFlags = packed struct(u8) {
    pub const NONE: RayTracingPipelineFlags = @bitCast(@as(u8, 0));

    /// provides knowledge that "triangles" doesn't need to be considered
    skip_triangles: bool,
    /// provides knowledge that "aabbs" doesn't need to be considered
    skip_aabbs: bool,
    /// specifies that the ray tracing pipeline can be used with acceleration structures which reference micromaps
    allow_micromaps: bool,

    _: u5 = 0,
};

pub const RayTracingPipelineBits = enum(u8) {
    NONE = 0,
    /// provides knowledge that "triangles" doesn't need to be considered
    SKIP_TRIANGLES = 1 << 0,
    /// provides knowledge that "aabbs" doesn't need to be considered
    SKIP_AABBS = 1 << 1,
    /// specifies that the ray tracing pipeline can be used with acceleration structures which reference micromaps
    ALLOW_MICROMAPS = 1 << 2,
};

pub const ShaderLibraryDesc = extern struct {
    shaders: [*]const ShaderDesc,
    shader_num: u32 = 0,
};

pub const ShaderGroupDesc = extern struct {
    /// in ShaderLibrary, starting from 1 (0 - unused)
    /// Use cases:
    ///  - general: RAYGEN_SHADER, MISS_SHADER or CALLABLE_SHADER
    ///  - HitGroup: CLOSEST_HIT_SHADER and/or ANY_HIT_SHADER in any order
    ///  - HitGroup with an intersection shader: INTERSECTION_SHADER + CLOSEST_HIT_SHADER and/or ANY_HIT_SHADER in any order
    shader_indices: [3]u32,
};

pub const RayTracingPipelineDesc = extern struct {
    pipeline_layout: *PipelineLayout,
    shader_library: *const ShaderLibraryDesc,
    shader_groups: [*]const ShaderGroupDesc,
    shader_group_num: u32 = 0,
    recursion_max_depth: u32 = 0,
    ray_payload_max_size: u32 = 0,
    ray_hit_attribute_max_size: u32 = 0,
    flags: RayTracingPipelineFlags = .NONE,
    robustness: Robustness = .DEFAULT,
};

pub const MicromapFormat = enum(u16) {
    OPACITY_2_STATE = 1,
    OPACITY_4_STATE = 2,
};

pub const MicromapSpecialIndex = enum(i8) {
    /// specifies that the entire triangle is fully transparent
    FULLY_TRANSPARENT = -1,
    /// specifies that the entire triangle is fully opaque
    FULLY_OPAQUE = -2,
    /// specifies that the entire triangle is unknown-transparent
    FULLY_UNKNOWN_TRANSPARENT = -3,
    /// specifies that the entire triangle is unknown-opaque
    FULLY_UNKNOWN_OPAQUE = -4,
};

pub const MicromapFlags = packed struct(u8) {
    pub const NONE: MicromapFlags = @bitCast(@as(u8, 0));

    /// allows to compact the micromap by copying using "COMPACT" mode
    allow_compaction: bool,
    /// prioritize traversal performance over build time
    prefer_fast_trace: bool,
    /// prioritize build time over traversal performance
    prefer_fast_build: bool,

    _: u5 = 0,
};

pub const MicromapBits = enum(u8) {
    NONE = 0,
    /// allows to compact the micromap by copying using "COMPACT" mode
    ALLOW_COMPACTION = 1 << 0,
    /// prioritize traversal performance over build time
    PREFER_FAST_TRACE = 1 << 1,
    /// prioritize build time over traversal performance
    PREFER_FAST_BUILD = 1 << 2,
};

pub const MicromapUsageDesc = extern struct {
    /// represents "MicromapTriangle" number for "{format, subdivisionLevel}" pair contained in the micromap
    triangle_num: u32 = 0,
    /// micro triangles count = 4 ^ subdivisionLevel
    subdivision_level: u16 = 0,
    format: MicromapFormat = .OPACITY_2_STATE,
};

pub const MicromapDesc = extern struct {
    /// can be retrieved by "CmdWriteMicromapsSizes" and used for compaction via "CmdCopyMicromap"
    optimized_size: u64 = 0,
    usages: [*]const MicromapUsageDesc,
    usage_num: u32 = 0,
    flags: MicromapFlags = .NONE,
};

pub const BindMicromapMemoryDesc = extern struct {
    micromap: *Micromap,
    memory: *Memory,
    offset: u64 = 0,
};

pub const BuildMicromapDesc = extern struct {
    dst: *Micromap,
    data_buffer: *const Buffer,
    data_offset: u64 = 0,
    /// contains "MicromapTriangle" entries
    triangle_buffer: *const Buffer,
    triangle_offset: u64 = 0,
    scratch_buffer: *Buffer,
    scratch_offset: u64 = 0,
};

pub const BottomLevelMicromapDesc = extern struct {
    // For each triangle in the geometry, the acceleration structure build fetches an index from "indexBuffer".
    // If an index is the unsigned cast of one of the values from "MicromapSpecialIndex" then that triangle behaves as described for that special value.
    // Otherwise that triangle uses the micromap information from "micromap" at that index plus "baseTriangle".
    // If an index buffer is not provided, "1:1" mapping between geometry triangles and micromap triangles is assumed.

    micromap: ?*Micromap,
    index_buffer: ?*const Buffer,
    index_offset: u64 = 0,
    base_triangle: u32 = 0,
    index_type: IndexType = .UINT16,
};

pub const MicromapTriangle = extern struct {
    data_offset: u32 = 0,
    subdivision_level: u16 = 0,
    format: MicromapFormat = .OPACITY_2_STATE,
};

pub const BottomLevelGeometryType = enum(u8) {
    TRIANGLES,
    AABBS,
};

pub const BottomLevelGeometryFlags = packed struct(u8) {
    pub const NONE: BottomLevelGeometryFlags = @bitCast(@as(u8, 0));

    /// the geometry acts as if no any hit shader is present (can be overriden by "TopLevelInstanceBits" or ray flags)
    opaque_geometry: bool,
    /// the any-hit shader must be called once for each primitive in this geometry
    no_duplicate_any_hit_invocation: bool,

    _: u6 = 0,
};

pub const BottomLevelGeometryBits = enum(u8) {
    NONE = 0,
    /// the geometry acts as if no any hit shader is present (can be overriden by "TopLevelInstanceBits" or ray flags)
    OPAQUE_GEOMETRY = 1 << 0,
    /// the any-hit shader must be called once for each primitive in this geometry
    NO_DUPLICATE_ANY_HIT_INVOCATION = 1 << 1,
};

pub const BottomLevelTrianglesDesc = extern struct {
    // Vertices
    vertex_buffer: *const Buffer,
    vertex_offset: u64 = 0,
    vertex_num: u32 = 0,
    vertex_stride: u16 = 0,
    vertex_format: Format = .UNKNOWN,

    // Indices
    index_buffer: ?*const Buffer,
    index_offset: u64 = 0,
    index_num: u32 = 0,
    index_type: IndexType = .UINT16,

    // Transform
    /// contains "TransformMatrix" entries
    transform_buffer: ?*const Buffer,
    transform_offset: u64 = 0,

    // Micromap
    micromap: ?*BottomLevelMicromapDesc,
};

pub const BottomLevelAabbsDesc = extern struct {
    /// contains "BottomLevelAabb" entries
    buffer: *const Buffer,
    offset: u64 = 0,
    num: u32 = 0,
    stride: u32 = 0,
};

pub const BottomLevelGeometryDesc = extern struct {
    flags: BottomLevelGeometryFlags = .NONE,
    type: BottomLevelGeometryType = .TRIANGLES,
    geometry: union {
        triangles: BottomLevelTrianglesDesc,
        aabbs: BottomLevelAabbsDesc,
    },
};

/// Data layout
pub const TransformMatrix = extern struct {
    /// 3x4 row-major affine transformation matrix, the first three columns of matrix must define an invertible 3x3 matrix
    transform: [3][4]f32,
};

pub const BottomLevelAabb = extern struct {
    min_x: f32 = 0,
    min_y: f32 = 0,
    min_z: f32 = 0,
    max_x: f32 = 0,
    max_y: f32 = 0,
    max_z: f32 = 0,
};

pub const TopLevelInstanceFlags = packed struct(u32) {
    pub const NONE: TopLevelInstanceFlags = @bitCast(@as(u32, 0));

    /// disables face culling for this instance
    triangle_cull_disable: bool,
    /// inverts the facing determination for geometry in this instance (since the facing is determined in object space, an instance transform does not change the winding, but a geometry transform does)
    triangle_flip_facing: bool,
    /// force enable "OPAQUE_GEOMETRY" bit on all geometries referenced by this instance
    force_opaque: bool,
    /// force disable "OPAQUE_GEOMETRY" bit on all geometries referenced by this instance
    force_non_opaque: bool,
    /// ignore the "unknown" state and only consider the "transparent" or "opaque" bit for all 4-state micromaps encountered during traversal
    force_opacity_2_state: bool,
    /// disable micromap test for all triangles and revert to using geometry opaque/non-opaque state instead
    disable_micromaps: bool,

    _: u26 = 0,
};

pub const TopLevelInstanceBits = enum(u32) {
    NONE = 0,
    /// disables face culling for this instance
    TRIANGLE_CULL_DISABLE = 1 << 0,
    /// inverts the facing determination for geometry in this instance (since the facing is determined in object space, an instance transform does not change the winding, but a geometry transform does)
    TRIANGLE_FLIP_FACING = 1 << 1,
    /// force enable "OPAQUE_GEOMETRY" bit on all geometries referenced by this instance
    FORCE_OPAQUE = 1 << 2,
    /// force disable "OPAQUE_GEOMETRY" bit on all geometries referenced by this instance
    FORCE_NON_OPAQUE = 1 << 3,
    /// ignore the "unknown" state and only consider the "transparent" or "opaque" bit for all 4-state micromaps encountered during traversal
    FORCE_OPACITY_2_STATE = 1 << 4,
    /// disable micromap test for all triangles and revert to using geometry opaque/non-opaque state instead
    DISABLE_MICROMAPS = 1 << 5,
};

pub const TopLevelInstance = extern struct {
    pub const Info = packed struct {
        instance_id: u24 = 0,
        mask: u8 = 0,
        shader_binding_table_local_offset: u24 = 0,
        flags: u8 = @intCast(@as(u32, @bitCast(TopLevelInstanceFlags.NONE))),
    };
    transform: [3][4]f32,
    info: Info = .{},
    acceleration_structure_handle: u64 = 0,
};

pub const AccelerationStructureType = enum(u8) {
    TOP_LEVEL,
    BOTTOM_LEVEL,
};

pub const AccelerationStructureFlags = packed struct(u8) {
    pub const NONE: AccelerationStructureFlags = @bitCast(@as(u8, 0));

    /// allows to do "updates", which are faster than "builds" (may increase memory usage, build time and decrease traversal performance)
    allow_update: bool = false,
    /// allows to compact the acceleration structure by copying using "COMPACT" mode
    allow_compaction: bool = false,
    /// allows to access vertex data from shaders (requires "features.rayTracingPositionFetch")
    allow_data_access: bool = false,
    /// allows to update micromaps via acceleration structure update (may increase size and decrease traversal performance)
    allow_micromap_update: bool = false,
    /// allows to have "DISABLE_MICROMAPS" flag for instances referencing this BLAS
    allow_disable_micromaps: bool = false,
    /// prioritize traversal performance over build time
    prefer_fast_trace: bool = false,
    /// prioritize build time over traversal performance
    prefer_fast_build: bool = false,
    /// minimize the amount of memory used during the build (may increase build time and decrease traversal performance)
    minimize_memory: bool = false,
};

pub const AccelerationStructureBits = enum(u8) {
    NONE = 0,
    /// allows to do "updates", which are faster than "builds" (may increase memory usage, build time and decrease traversal performance)
    ALLOW_UPDATE = 1 << 0,
    /// allows to compact the acceleration structure by copying using "COMPACT" mode
    ALLOW_COMPACTION = 1 << 1,
    /// allows to access vertex data from shaders (requires "features.rayTracingPositionFetch")
    ALLOW_DATA_ACCESS = 1 << 2,
    /// allows to update micromaps via acceleration structure update (may increase size and decrease traversal performance)
    ALLOW_MICROMAP_UPDATE = 1 << 3,
    /// allows to have "DISABLE_MICROMAPS" flag for instances referencing this BLAS
    ALLOW_DISABLE_MICROMAPS = 1 << 4,
    /// prioritize traversal performance over build time
    PREFER_FAST_TRACE = 1 << 5,
    /// prioritize build time over traversal performance
    PREFER_FAST_BUILD = 1 << 6,
    /// minimize the amount of memory used during the build (may increase build time and decrease traversal performance)
    MINIMIZE_MEMORY = 1 << 7,
};

pub const AccelerationStructureDesc = extern struct {
    /// can be retrieved by "CmdWriteAccelerationStructuresSizes" and used for compaction via "CmdCopyAccelerationStructure"
    optimized_size: u64 = 0,
    /// needed only for "BOTTOM_LEVEL", "HAS_BUFFER" can be used to indicate a buffer presence (no real entities needed at initialization time)
    geometries: ?[*]const BottomLevelGeometryDesc,
    geometry_or_instance_num: u32 = 0,
    flags: AccelerationStructureFlags = .NONE,
    type: AccelerationStructureType = .TOP_LEVEL,
};

pub const BindAccelerationStructureMemoryDesc = extern struct {
    acceleration_structure: ?*AccelerationStructure,
    memory: ?*Memory,
    offset: u64 = 0,
};

pub const BuildTopLevelAccelerationStructureDesc = extern struct {
    dst: *AccelerationStructure,
    /// implies "update" instead of "build" if provided (requires "ALLOW_UPDATE")
    src: ?*const AccelerationStructure,
    instance_num: u32 = 0,
    /// contains "TopLevelInstance" entries
    instance_buffer: *const Buffer,
    instance_offset: u64 = 0,
    /// use "GetAccelerationStructureBuildScratchBufferSize" or "GetAccelerationStructureUpdateScratchBufferSize" to determine the required size
    scratch_buffer: *Buffer,
    scratch_offset: u64 = 0,
};

pub const BuildBottomLevelAccelerationStructureDesc = extern struct {
    dst: *AccelerationStructure,
    /// implies "update" instead of "build" if provided (requires "ALLOW_UPDATE")
    src: ?*const AccelerationStructure,
    geometries: [*]const BottomLevelGeometryDesc,
    geometry_num: u32 = 0,
    scratch_buffer: *Buffer,
    scratch_offset: u64 = 0,
};

pub const CopyMode = enum(u8) {
    CLONE,
    COMPACT,
};

pub const StridedBufferRegion = extern struct {
    buffer: *const Buffer,
    offset: u64 = 0,
    size: u64 = 0,
    stride: u64 = 0,
};

pub const DispatchRaysDesc = extern struct {
    raygen_shader: StridedBufferRegion,
    miss_shaders: StridedBufferRegion,
    hit_shader_groups: StridedBufferRegion,
    callable_shaders: StridedBufferRegion,
    x: u32 = 0,
    y: u32 = 0,
    z: u32 = 0,
};

pub const DispatchRaysIndirectDesc = extern struct {
    raygen_shader_record_address: u64 = 0,
    raygen_shader_record_size: u64 = 0,
    miss_shader_binding_table_address: u64 = 0,
    miss_shader_binding_table_size: u64 = 0,
    miss_shader_binding_table_stride: u64 = 0,
    hit_shader_binding_table_address: u64 = 0,
    hit_shader_binding_table_size: u64 = 0,
    hit_shader_binding_table_stride: u64 = 0,
    callable_shader_binding_table_address: u64 = 0,
    callable_shader_binding_table_size: u64 = 0,
    callable_shader_binding_table_stride: u64 = 0,
    x: u32 = 0,
    y: u32 = 0,
    z: u32 = 0,
};

/// Threadsafe: yes
pub const RayTracingInterface = extern struct {
    // Create
    CreateRayTracingPipeline: *const fn (device: *Device, rayTracingPipelineDesc: *const RayTracingPipelineDesc, pipeline: *?*Pipeline) callconv(.c) Result,
    CreateAccelerationStructureDescriptor: *const fn (accelerationStructure: *const AccelerationStructure, descriptor: *?*Descriptor) callconv(.c) Result,

    // Get
    GetAccelerationStructureHandle: *const fn (accelerationStructure: *const AccelerationStructure) callconv(.c) u64,
    GetAccelerationStructureUpdateScratchBufferSize: *const fn (accelerationStructure: *const AccelerationStructure) callconv(.c) u64,
    GetAccelerationStructureBuildScratchBufferSize: *const fn (accelerationStructure: *const AccelerationStructure) callconv(.c) u64,
    GetMicromapBuildScratchBufferSize: *const fn (micromap: *const Micromap) callconv(.c) u64,

    // For barriers
    GetAccelerationStructureBuffer: *const fn (accelerationStructure: *const AccelerationStructure) callconv(.c) ?*Buffer,
    GetMicromapBuffer: *const fn (micromap: *const Micromap) callconv(.c) ?*Buffer,

    // Destroy
    DestroyAccelerationStructure: *const fn (accelerationStructure: ?*AccelerationStructure) callconv(.c) void,
    DestroyMicromap: *const fn (micromap: ?*Micromap) callconv(.c) void,

    // Resources and memory (VK style)
    CreateAccelerationStructure: *const fn (device: *Device, accelerationStructureDesc: *const AccelerationStructureDesc, accelerationStructure: *?*AccelerationStructure) callconv(.c) Result,
    CreateMicromap: *const fn (device: *Device, micromapDesc: *const MicromapDesc, micromap: *?*Micromap) callconv(.c) Result,
    GetAccelerationStructureMemoryDesc: *const fn (accelerationStructure: *const AccelerationStructure, memoryLocation: MemoryLocation, memoryDesc: *MemoryDesc) callconv(.c) void,
    GetMicromapMemoryDesc: *const fn (micromap: *const Micromap, memoryLocation: MemoryLocation, memoryDesc: *MemoryDesc) callconv(.c) void,
    BindAccelerationStructureMemory: *const fn (bindAccelerationStructureMemoryDescs: ?[*]const BindAccelerationStructureMemoryDesc, bindAccelerationStructureMemoryDescNum: u32) callconv(.c) Result,
    BindMicromapMemory: *const fn (bindMicromapMemoryDescs: ?[*]const BindMicromapMemoryDesc, bindMicromapMemoryDescNum: u32) callconv(.c) Result,

    // Resources and memory (D3D12 style)
    GetAccelerationStructureMemoryDesc2: *const fn (device: *const Device, accelerationStructureDesc: *const AccelerationStructureDesc, memoryLocation: MemoryLocation, memoryDesc: *MemoryDesc) callconv(.c) void, // requires "features.getMemoryDesc2"
    GetMicromapMemoryDesc2: *const fn (device: *const Device, micromapDesc: *const MicromapDesc, memoryLocation: MemoryLocation, memoryDesc: *MemoryDesc) callconv(.c) void, // requires "features.getMemoryDesc2"
    CreateCommittedAccelerationStructure: *const fn (device: *Device, memoryLocation: MemoryLocation, priority: f32, accelerationStructureDesc: *const AccelerationStructureDesc, accelerationStructure: *?*AccelerationStructure) callconv(.c) Result,
    CreateCommittedMicromap: *const fn (device: *Device, memoryLocation: MemoryLocation, priority: f32, micromapDesc: *const MicromapDesc, micromap: *?*Micromap) callconv(.c) Result,
    CreatePlacedAccelerationStructure: *const fn (device: *Device, memory: ?*Memory, offset: u64, accelerationStructureDesc: *const AccelerationStructureDesc, accelerationStructure: *?*AccelerationStructure) callconv(.c) Result,
    CreatePlacedMicromap: *const fn (device: *Device, memory: ?*Memory, offset: u64, micromapDesc: *const MicromapDesc, micromap: *?*Micromap) callconv(.c) Result,

    // Shader table
    // "dst" size must be >= "shaderGroupNum * rayTracingShaderGroupIdentifierSize" bytes
    // VK doesn't have a "local root signature" analog, thus stride = "rayTracingShaderGroupIdentifierSize", i.e. tight packing
    WriteShaderGroupIdentifiers: *const fn (pipeline: *const Pipeline, baseShaderGroupIndex: u32, shaderGroupNum: u32, dst: ?*anyopaque) callconv(.c) Result,
    // Command buffer
    // zig fmt: off
    // {
        // Micromap
        CmdBuildMicromaps: *const fn (commandBuffer: *CommandBuffer, buildMicromapDescs: ?[*]const BuildMicromapDesc, buildMicromapDescNum: u32) callconv(.c) void,
        CmdWriteMicromapsSizes: *const fn (commandBuffer: *CommandBuffer, micromaps: ?[*]const ?*Micromap, micromapNum: u32, queryPool: *QueryPool, queryPoolOffset: u32) callconv(.c) void,
        CmdCopyMicromap: *const fn (commandBuffer: *CommandBuffer, dst: *Micromap, src: *const Micromap, copyMode: CopyMode) callconv(.c) void,
        // Acceleration structure
        CmdBuildTopLevelAccelerationStructures: *const fn (commandBuffer: *CommandBuffer, buildTopLevelAccelerationStructureDescs: ?[*]const BuildTopLevelAccelerationStructureDesc, buildTopLevelAccelerationStructureDescNum: u32) callconv(.c) void,
        CmdBuildBottomLevelAccelerationStructures: *const fn (commandBuffer: *CommandBuffer, buildBotomLevelAccelerationStructureDescs: ?[*]const BuildBottomLevelAccelerationStructureDesc, buildBotomLevelAccelerationStructureDescNum: u32) callconv(.c) void,
        CmdWriteAccelerationStructuresSizes: *const fn (commandBuffer: *CommandBuffer, accelerationStructures: ?[*]const ?*AccelerationStructure, accelerationStructureNum: u32, queryPool: *QueryPool, queryPoolOffset: u32) callconv(.c) void,
        CmdCopyAccelerationStructure: *const fn (commandBuffer: *CommandBuffer, dst: *AccelerationStructure, src: *const AccelerationStructure, copyMode: CopyMode) callconv(.c) void,
        // Ray tracing
        CmdDispatchRays: *const fn (commandBuffer: *CommandBuffer, dispatchRaysDesc: *const DispatchRaysDesc) callconv(.c) void,
        CmdDispatchRaysIndirect: *const fn (commandBuffer: *CommandBuffer, buffer: *const Buffer, offset: u64) callconv(.c) void, // buffer contains "DispatchRaysIndirectDesc" commands
    // }
    // zig fmt: on

    // Native object
    GetAccelerationStructureNativeObject: *const fn (accelerationStructure: ?*AccelerationStructure) callconv(.c) u64, // ID3D12Resource* or VkAccelerationStructureKHR
    GetMicromapNativeObject: *const fn (micromap: ?*Micromap) callconv(.c) u64, // ID3D12Resource* or VkMicromapEXT
};
