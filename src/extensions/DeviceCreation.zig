const Descs = @import("../Descs.zig");

const Result = Descs.Result;
const Device = Descs.Device;
const GraphicsAPI = Descs.GraphicsAPI;
const AdapterDesc = Descs.AdapterDesc;
const QueueType = Descs.QueueType;
const Robustness = Descs.Robustness;

pub const Message = enum(u8) {
    INFO,
    WARNING,
    ERROR, // "wingdi.h" must not be included after
};

/// Callbacks must be thread safe
pub const AllocationCallbacks = extern struct {
    Allocate: ?*const fn (userArg: ?*anyopaque, size: usize, alignment: usize) callconv(.c) ?*anyopaque = null,
    Reallocate: ?*const fn (userArg: ?*anyopaque, memory: ?*anyopaque, size: usize, alignment: usize) callconv(.c) ?*anyopaque = null,
    Free: ?*const fn (userArg: ?*anyopaque, memory: ?*anyopaque) callconv(.c) void = null,
    user_arg: ?*anyopaque = null,
    disable_3rd_party_allocation_callbacks: bool = false,
};

pub const CallbackInterface = extern struct {
    MessageCallback: ?*const fn (messageType: Message, file: [*:0]const u8, line: u32, message: [*:0]const u8, userArg: ?*anyopaque) callconv(.c) void = null,
    AbortExecution: ?*const fn (userArg: ?*anyopaque) callconv(.c) void = null,
    user_arg: ?*anyopaque = null,
};

/// Use largest offset for the resource type planned to be used as an unbounded array
pub const VKBindingOffsets = extern struct {
    s_register: u32 = 0, // samplers
    t_register: u32 = 0, // shader resources, including acceleration structures (SRVs)
    b_register: u32 = 0, // constant buffers
    u_register: u32 = 0, // storage shader resources (UAVs)
};

pub const VKExtensions = extern struct {
    instance_extensions: ?[*][*:0]const u8 = null,
    instance_extension_num: u32 = 0,
    device_extensions: ?[*][*:0]const u8 = null,
    device_extension_num: u32 = 0,
};

/// A collection of queues of the same type
pub const QueueFamilyDesc = extern struct {
    queue_priorities: ?[*]const f32 = null, // [-1; 1]: low < 0, normal = 0, high > 0 ("queueNum" entries expected)
    queue_num: u32 = 0,
    queue_type: QueueType = .COMPUTE,
};

pub const DeviceCreationDesc = extern struct {
    graphics_api: GraphicsAPI = .NONE,
    robustness: Robustness = .DEFAULT,
    adapter_desc: ?*const AdapterDesc = null,
    callback_interface: CallbackInterface = .{},
    allocation_callbacks: AllocationCallbacks = .{},

    // One "GRAPHICS" queue is created by default
    queue_families: ?[*]const QueueFamilyDesc = null,
    queue_family_num: u32 = 0, // put "GRAPHICS" queue at the beginning of the list

    // D3D specific
    d3d_shader_ext_register: u32 = 0, // vendor specific shader extensions (default is "NRI_SHADER_EXT_REGISTER", space is always "0")
    d3d_zero_buffer_size: u32 = 0, // no "memset" functionality in D3D, "CmdZeroBuffer" implemented via a bunch of copies (4 Mb by default)

    // Vulkan specific
    vk_binding_offsets: VKBindingOffsets = .{},
    vk_extensions: VKExtensions = .{}, // to enable

    // Switches (disabled by default)
    enable_nri_validation: bool = false, // embedded validation layer, checks for NRI specifics
    enable_graphics_api_validation: bool = false, // GAPI-provided validation layer
    enable_d3d11_command_buffer_emulation: bool = false, // enable? but why? (auto-enabled if deferred contexts are not supported)
    enable_d3d12_ray_tracing_validation: bool = false, // slow but useful, can only be enabled if envvar "NV_ALLOW_RAYTRACING_VALIDATION" is set to "1"
    enable_memory_zero_initialization: bool = false, // page-clears are fast, but memory is not cleared by default in VK

    // Switches (enabled by default)
    disable_vk_ray_tracing: bool = true, // to save CPU memory in some implementations
    disable_d3d12_enhanced_barriers: bool = true, // even if AgilitySDK is in use, some apps still use legacy barriers. It can be important for integrations
};

// if "adapterDescs == NULL", then "adapterDescNum" is set to the number of adapters
// else "adapterDescNum" must be set to number of elements in "adapterDescs"
extern fn nriEnumerateAdapters(adapterDescs: ?[*]AdapterDesc, adapterDescNum: *u32) Result;
pub fn enumerateAdapters(adapterDescs: ?[*]AdapterDesc, adapterDescNum: *u32) Result {
    return nriEnumerateAdapters(adapterDescs, adapterDescNum);
}

extern fn nriCreateDevice(deviceCreationDesc: *const DeviceCreationDesc, device: *?*Device) Result;
pub fn createDevice(deviceCreationDesc: DeviceCreationDesc) !*Device {
    var device: ?*Device = undefined;
    try nriCreateDevice(&deviceCreationDesc, &device).success();
    return device.?;
}
extern fn nriDestroyDevice(device: ?*Device) void;
pub fn destroyDevice(device: *Device) void {
    nriDestroyDevice(device);
}

// It's global state for D3D, not needed for VK because validation is tied to the logical device
extern fn nriReportLiveObjects() void;
pub fn reportLiveObjects() void {
    nriReportLiveObjects();
}
