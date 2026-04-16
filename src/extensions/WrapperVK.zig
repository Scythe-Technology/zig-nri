const Descs = @import("../Descs.zig");
const DeviceCreation = @import("DeviceCreation.zig");
const RayTracing = @import("RayTracing.zig");

const Device = Descs.Device;
const CommandAllocator = Descs.CommandAllocator;
const CommandBuffer = Descs.CommandBuffer;
const DescriptorPool = Descs.DescriptorPool;
const Buffer = Descs.Buffer;
const Texture = Descs.Texture;
const Memory = Descs.Memory;
const Pipeline = Descs.Pipeline;
const QueryPool = Descs.QueryPool;
const Fence = Descs.Fence;
const QueueType = Descs.QueueType;
const Dim_t = Descs.Dim_t;
const Sample_t = Descs.Sample_t;
const Result = Descs.Result;

const CallbackInterface = DeviceCreation.CallbackInterface;
const AllocationCallbacks = DeviceCreation.AllocationCallbacks;
const VKBindingOffsets = DeviceCreation.VKBindingOffsets;
const VKExtensions = DeviceCreation.VKExtensions;

const AccelerationStructure = RayTracing.AccelerationStructure;
const AccelerationStructureFlags = RayTracing.AccelerationStructureFlags;

pub const Queue = Descs.Queue;

pub const VKHandle = ?*anyopaque;
pub const VKEnum = i32;
pub const VKFlags = u32;
pub const VKNonDispatchableHandle = u64;

/// A collection of queues of the same type
pub const QueueFamilyVKDesc = extern struct {
    queue_num: u32 = 0,
    queue_type: QueueType = .GRAPHICS,
    family_index: u32 = 0,
};

pub const DeviceCreationVKDesc = extern struct {
    callback_interface: CallbackInterface = .{},
    allocation_callbacks: AllocationCallbacks = .{},
    library_path: ?[*:0]const u8 = null,
    vk_binding_offsets: VKBindingOffsets = .{},
    /// enabled
    vk_extensions: VKExtensions = .{},
    vk_instance: VKHandle,
    vk_device: VKHandle,
    vk_physical_device: VKHandle,
    queue_families: [*]const QueueFamilyVKDesc,
    queue_family_num: u32 = 0,
    /// >= 2
    minor_version: u8,
    // Switches (disabled by default)
    enable_nri_validation: bool = false,
    /// page-clears are fast, but memory is not cleared by default in VK
    enable_memory_zero_initialization: bool = false,
};

pub const CommandAllocatorVKDesc = extern struct {
    vk_command_pool: VKNonDispatchableHandle = 0,
    queue_type: QueueType = .GRAPHICS,
};

pub const CommandBufferVKDesc = extern struct {
    vk_command_buffer: VKHandle,
    queue_type: QueueType = .GRAPHICS,
};

pub const DescriptorPoolVKDesc = extern struct {
    vk_descriptor_pool: VKNonDispatchableHandle = 0,
    descriptor_set_max_num: u32 = 0,
};

pub const BufferVKDesc = extern struct {
    vk_buffer: VKNonDispatchableHandle = 0,
    size: u64 = 0,
    /// must be provided if used as a structured or raw buffer
    structure_stride: u32 = 0,
    // must be provided if the underlying memory is mapped
    mapped_memory: ?[*]u8 = null,
    /// must be provided *only* if the mapped memory exists and *not* HOST_COHERENT
    vk_device_memory: VKNonDispatchableHandle = 0,
    /// must be provided for ray tracing
    device_address: u64 = 0,
};

pub const TextureVKDesc = extern struct {
    vk_image: VKNonDispatchableHandle = 0,
    vk_format: VKEnum = 0,
    vk_image_type: VKEnum = 0,
    vk_image_usage_flags: VKFlags = 0,
    width: Dim_t = 0,
    height: Dim_t = 0,
    depth: Dim_t = 0,
    mip_num: Dim_t = 0,
    layer_num: Dim_t = 0,
    sample_num: Sample_t = 0,
};

pub const MemoryVKDesc = extern struct {
    vk_device_memory: VKNonDispatchableHandle = 0,
    offset: u64 = 0,
    /// at "offset"
    mapped_memory: ?*anyopaque = null,
    size: u64 = 0,
    memory_type_index: u32 = 0,
};

pub const PipelineVKDesc = extern struct {
    vk_pipeline: VKNonDispatchableHandle = 0,
    vk_pipeline_bind_point: VKEnum = 0,
};

pub const QueryPoolVKDesc = extern struct {
    vk_query_pool: VKNonDispatchableHandle = 0,
    vk_query_type: VKEnum = 0,
};

pub const FenceVKDesc = extern struct {
    vk_timeline_semaphore: VKNonDispatchableHandle = 0,
};

pub const AccelerationStructureVKDesc = extern struct {
    vk_acceleration_structure: VKNonDispatchableHandle = 0,
    vk_buffer: VKNonDispatchableHandle = 0,
    buffer_size: u64 = 0,
    build_scratch_size: u64 = 0,
    update_scratch_size: u64 = 0,
    flags: AccelerationStructureFlags = .NONE,
};

/// Threadsafe: yes
pub const WrapperVKInterface = extern struct {
    CreateCommandAllocatorVK: *const fn (device: *Device, commandAllocatorVKDesc: *const CommandAllocatorVKDesc, commandAllocator: *?*CommandAllocator) callconv(.c) Result,
    CreateCommandBufferVK: *const fn (device: *Device, commandBufferVKDesc: *const CommandBufferVKDesc, commandBuffer: *?*CommandBuffer) callconv(.c) Result,
    CreateDescriptorPoolVK: *const fn (device: *Device, descriptorPoolVKDesc: *const DescriptorPoolVKDesc, descriptorPool: *?*DescriptorPool) callconv(.c) Result,
    CreateBufferVK: *const fn (device: *Device, bufferVKDesc: *const BufferVKDesc, buffer: *?*Buffer) callconv(.c) Result,
    CreateTextureVK: *const fn (device: *Device, textureVKDesc: *const TextureVKDesc, texture: *?*Texture) callconv(.c) Result,
    CreateMemoryVK: *const fn (device: *Device, memoryVKDesc: *const MemoryVKDesc, memory: *?*Memory) callconv(.c) Result,
    CreatePipelineVK: *const fn (device: *Device, pipelineVKDesc: *const PipelineVKDesc, pipeline: *?*Pipeline) callconv(.c) Result,
    CreateQueryPoolVK: *const fn (device: *Device, queryPoolVKDesc: *const QueryPoolVKDesc, queryPool: *?*QueryPool) callconv(.c) Result,
    CreateFenceVK: *const fn (device: *Device, fenceVKDesc: *const FenceVKDesc, fence: *?*Fence) callconv(.c) Result,
    CreateAccelerationStructureVK: *const fn (device: *Device, accelerationStructureVKDesc: *const AccelerationStructureVKDesc, accelerationStructure: *?*AccelerationStructure) callconv(.c) Result,

    GetQueueFamilyIndexVK: *const fn (queue: *const Queue) callconv(.c) u32,
    GetPhysicalDeviceVK: *const fn (device: *const Device) callconv(.c) VKHandle,
    GetInstanceVK: *const fn (device: *const Device) callconv(.c) VKHandle,
    GetInstanceProcAddrVK: *const fn (device: *const Device) callconv(.c) ?*anyopaque,
    GetDeviceProcAddrVK: *const fn (device: *const Device) callconv(.c) ?*anyopaque,
};

pub extern fn nriCreateDeviceFromVKDevice(deviceDesc: *const DeviceCreationVKDesc, device: *?*Device) Result;
