const Descs = @import("../Descs.zig");
const DeviceCreation = @import("DeviceCreation.zig");
const RayTracing = @import("RayTracing.zig");

const Device = Descs.Device;
const CommandBuffer = Descs.CommandBuffer;
const DescriptorPool = Descs.DescriptorPool;
const Buffer = Descs.Buffer;
const Texture = Descs.Texture;
const Memory = Descs.Memory;
const Fence = Descs.Fence;
const BufferDesc = Descs.BufferDesc;
const QueueType = Descs.QueueType;
const Result = Descs.Result;
const CallbackInterface = DeviceCreation.CallbackInterface;
const AllocationCallbacks = DeviceCreation.AllocationCallbacks;
const AccelerationStructure = RayTracing.AccelerationStructure;
const AccelerationStructureFlags = RayTracing.AccelerationStructureFlags;

pub const DXGIFormat = i32;

pub const AGSContext = opaque {};
pub const ID3D12Heap = opaque {};
pub const ID3D12Fence = opaque {};
pub const ID3D12Device = opaque {};
pub const ID3D12Resource = opaque {};
pub const ID3D12CommandQueue = opaque {};
pub const ID3D12DescriptorHeap = opaque {};
pub const ID3D12CommandAllocator = opaque {};
pub const ID3D12GraphicsCommandList = opaque {};

/// A collection of queues of the same type
pub const QueueFamilyD3D12Desc = extern struct {
    /// if not provided, will be created
    d3d12_queues: ?[*]?*ID3D12CommandQueue,
    queue_num: u32 = 0,
    queue_type: QueueType = .GRAPHICS,
};

pub const DeviceCreationD3D12Desc = extern struct {
    d3d12_device: *ID3D12Device,
    queue_families: [*]const QueueFamilyD3D12Desc,
    queue_family_num: u32 = 0,
    ags_context: ?*AGSContext = null,
    callback_interface: CallbackInterface = .{},
    allocation_callbacks: AllocationCallbacks = .{},
    /// vendor specific shader extensions (default is "NRI_SHADER_EXT_REGISTER", space is always "0")
    d3d_shader_ext_register: u32 = 0,
    /// no "memset" functionality in D3D, "CmdZeroBuffer" implemented via a bunch of copies (4 Mb by default)
    d3d_zero_buffer_size: u32 = 4 * 1024 * 1024,

    // Switches (disabled by default)
    enable_nri_validation: bool = false,
    /// page-clears are fast, not enabled by default to match VK (the extension needed)
    enable_memory_zero_initialization: bool = false,

    // Switches (enabled by default)
    /// even if AgilitySDK is in use, some apps still use legacy barriers. It can be important for integrations
    disable_d3d12_enhanced_barriers: bool = true,
    /// at least NVAPI requires calling "NvAPI_Initialize" in DLL/EXE where the device is created
    disable_nvapi_initialization: bool = true,
};

pub const CommandBufferD3D12Desc = extern struct {
    d3d12_command_list: *ID3D12GraphicsCommandList,
    /// needed only for "BeginCommandBuffer"
    d3d12_command_allocator: ?*ID3D12CommandAllocator,
};

pub const DescriptorPoolD3D12Desc = extern struct {
    d3d12_resource_descriptor_heap: *ID3D12DescriptorHeap,
    d3d12_sampler_descriptor_heap: *ID3D12DescriptorHeap,

    /// Allocation limits (D3D12 unrelated, but must match expected usage)
    descriptor_set_max_num: u32 = 0,
};

pub const BufferD3D12Desc = extern struct {
    d3d12_resource: *ID3D12Resource,
    /// not all information can be retrieved from the resource if not provided
    desc: ?*const BufferDesc,
    /// must be provided if used as a structured or raw buffer
    structure_stride: u32 = 0,
};

pub const TextureD3D12Desc = extern struct {
    d3d12_resource: *ID3D12Resource,
    /// must be provided "as a compatible typed format" if the resource is typeless
    format: DXGIFormat = 0,
};

pub const MemoryD3D12Desc = extern struct {
    d3d12_heap: *ID3D12Heap,
    offset: u64 = 0,
};

pub const FenceD3D12Desc = extern struct {
    d3d12_fence: *ID3D12Fence,
};

pub const AccelerationStructureD3D12Desc = extern struct {
    d3d12_resource: *ID3D12Resource,
    flags: AccelerationStructureFlags = .NONE,

    // D3D12_RAYTRACING_ACCELERATION_STRUCTURE_PREBUILD_INFO
    size: u64 = 0,
    build_scratch_size: u64 = 0,
    update_scratch_size: u64 = 0,
};

/// Threadsafe: yes
pub const WrapperD3D12Interface = extern struct {
    CreateCommandBufferD3D12: *const fn (device: *Device, commandBufferD3D12Desc: *const CommandBufferD3D12Desc, commandBuffer: *?*CommandBuffer) callconv(.c) Result,
    CreateDescriptorPoolD3D12: *const fn (device: *Device, descriptorPoolD3D12Desc: *const DescriptorPoolD3D12Desc, descriptorPool: *?*DescriptorPool) callconv(.c) Result,
    CreateBufferD3D12: *const fn (device: *Device, bufferD3D12Desc: *const BufferD3D12Desc, buffer: *?*Buffer) callconv(.c) Result,
    CreateTextureD3D12: *const fn (device: *Device, textureD3D12Desc: *const TextureD3D12Desc, texture: *?*Texture) callconv(.c) Result,
    CreateMemoryD3D12: *const fn (device: *Device, memoryD3D12Desc: *const MemoryD3D12Desc, memory: *?*Memory) callconv(.c) Result,
    CreateFenceD3D12: *const fn (device: *Device, fenceD3D12Desc: *const FenceD3D12Desc, fence: *?*Fence) callconv(.c) Result,
    CreateAccelerationStructureD3D12: *const fn (device: *Device, accelerationStructureD3D12Desc: *const AccelerationStructureD3D12Desc, accelerationStructure: *?*AccelerationStructure) callconv(.c) Result,
};

pub extern fn nriCreateDeviceFromD3D12Device(deviceDesc: *const DeviceCreationD3D12Desc, device: *?*Device) Result;
