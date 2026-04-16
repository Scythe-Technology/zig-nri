// Goal: utilities

const nri = @import("../lib.zig");
const Descs = @import("../Descs.zig");

const Device = Descs.Device;
const Result = Descs.Result;
const Queue = Descs.Queue;
const Texture = Descs.Texture;
const Buffer = Descs.Buffer;
const Memory = Descs.Memory;
const Format = Descs.Format;
const MemoryLocation = Descs.MemoryLocation;
const AccessLayoutStage = Descs.AccessLayoutStage;
const AccessStage = Descs.AccessStage;
const DeviceDesc = Descs.DeviceDesc;
const GraphicsAPI = Descs.GraphicsAPI;

pub const VideoMemoryInfo = extern struct {
    /// the OS-provided video memory budget. If "usageSize" > "budgetSize", the application may incur stuttering or performance penalties
    budget_size: u64,
    /// specifies the application’s current video memory usage
    usage_size: u64,
};

pub const TextureSubresourceUploadDesc = extern struct {
    slices: ?*const anyopaque,
    slice_num: u32,
    row_pitch: u32,
    slice_pitch: u32,
};

pub const TextureUploadDesc = extern struct {
    /// if provided, must include ALL subresources = layerNum * mipNum
    subresources: ?[*]const TextureSubresourceUploadDesc,
    texture: ?*Texture,
    after: AccessLayoutStage = .{},
    planes: Descs.PlaneFlags = .{},
};

pub const BufferUploadDesc = extern struct {
    /// if provided, must be data for the whole buffer
    data: ?*const anyopaque,
    buffer: ?*Buffer,
    after: AccessStage = .{},
};

pub const ResourceGroupDesc = extern struct {
    memory_location: MemoryLocation,
    textures: ?[*]?*Texture,
    texture_num: u32,
    buffers: ?[*]?*Buffer,
    buffer_num: u32,
    /// desired chunk size (but can be greater if a resource doesn't fit), 256 Mb if 0
    preferred_memory_size: u64,
};

pub const FormatProps = extern struct {
    pub const Flags = packed struct(u32) {
        /// block size in bytes
        stride: u6 = 0,
        /// 1 for plain formats, >1 for compressed
        block_width: u4 = 0,
        /// 1 for plain formats, >1 for compressed
        block_height: u4 = 0,
        /// reversed channels (RGBA => BGRA)
        is_bgr: bool = false,
        /// block-compressed format
        is_compressed: bool = false,
        /// has depth component
        is_depth: bool = false,
        /// shared exponent in alpha channel
        is_exp_shared: bool = false,
        /// floating point
        is_float: bool = false,
        /// 16- or 32- bit packed
        is_packed: bool = false,
        /// integer
        is_integer: bool = false,
        /// [0; 1] normalized
        is_norm: bool = false,
        /// signed
        is_signed: bool = false,
        /// sRGB
        is_srgb: bool = false,
        /// has stencil component
        is_stencil: bool = false,
        unused: u7 = 0,
    };

    /// format name
    name: [*:0]const u8,
    /// self
    format: Format = .UNKNOWN,
    /// R (or depth) bits
    red_bits: u8 = 0,
    /// G (or stencil) bits (0 if channels < 2)
    green_bits: u8 = 0,
    /// B bits (0 if channels < 3)
    blue_bits: u8 = 0,
    /// A (or shared exponent) bits (0 if channels < 4)
    alpha_bits: u8 = 0,
    flags: Flags,
};

/// Threadsafe: yes
pub const HelperInterface = extern struct {
    /// Optimized memory allocation for a group of resources
    CalculateAllocationNumber: *const fn (device: *const Device, resourceGroupDesc: *const ResourceGroupDesc) callconv(.c) u32,
    AllocateAndBindMemory: *const fn (device: *Device, resourceGroupDesc: *const ResourceGroupDesc, allocations: *?*Memory) callconv(.c) Result,

    /// Populate resources with data (not for streaming!)
    UploadData: *const fn (queue: *Queue, textureUploadDescs: ?[*]const TextureUploadDesc, textureUploadDescNum: u32, bufferUploadDescs: ?[*]const BufferUploadDesc, bufferUploadDescNum: u32) callconv(.c) Result,

    /// Information about video memory
    QueryVideoMemoryInfo: *const fn (device: *const Device, memoryLocation: MemoryLocation, videoMemoryInfo: *VideoMemoryInfo) callconv(.c) Result,
};

pub extern fn nriConvertDXGIFormatToNRI(dxgiFormat: u32) Format;
pub extern fn nriConvertVKFormatToNRI(vkFormat: u32) Format;
pub extern fn nriConvertNRIFormatToDXGI(format: Format) u32;
pub extern fn nriConvertNRIFormatToVK(format: Format) u32;
pub extern fn nriGetFormatProps(format: Format) ?*const FormatProps;
pub extern fn nriGetGraphicsAPIString(graphicsAPI: Descs.GraphicsAPI) [*:0]const u8;

// A friendly way to get a supported depth format
pub fn getSupportedDepthFormat(coreInterface: *const nri.CoreInterface, device: *const Device, minBits: u32, stencil: bool) Format {
    if (minBits <= 16 and !stencil) {
        const support = coreInterface.GetFormatSupport(device, .D16_UNORM);
        if (support.depth_stencil_attachment)
            return .D16_UNORM;
    }

    if (minBits <= 24) {
        const support = coreInterface.GetFormatSupport(device, .D24_UNORM_S8_UINT);
        if (support.depth_stencil_attachment)
            return .D24_UNORM_S8_UINT;
    }

    if (minBits <= 32 and !stencil) {
        const support = coreInterface.GetFormatSupport(device, .D32_SFLOAT);
        if (support.depth_stencil_attachment)
            return .D32_SFLOAT;
    }

    {
        const support = coreInterface.GetFormatSupport(device, .D32_SFLOAT_S8_UINT_X24);
        if (support.depth_stencil_attachment)
            return .D32_SFLOAT_S8_UINT_X24;
    }

    // Should be unreachable
    return .UNKNOWN;
}

// A convinient way to fit pipeline layout settings into the device limits, respecting various restrictions
pub const PipelineLayoutSettingsDesc = extern struct {
    descriptor_set_num: u32 = 0,
    descriptor_range_num: u32 = 0,
    root_constant_size: u32 = 0,
    root_descriptor_num: u32 = 0,
    prefer_root_descriptors_over_constants: bool = false,
    /// not needed for VK, unsupported in D3D11
    enable_d3d12_draw_parameters_emulation: bool = false,
};

pub fn fitPipelineLayoutSettingsIntoDeviceLimits(deviceDesc: *const DeviceDesc, pipelineLayoutSettingsDesc: *const PipelineLayoutSettingsDesc) PipelineLayoutSettingsDesc {
    var descriptor_set_num = pipelineLayoutSettingsDesc.descriptor_set_num;
    var descriptor_range_num = pipelineLayoutSettingsDesc.descriptor_range_num;
    var root_constant_size = pipelineLayoutSettingsDesc.root_constant_size;
    var root_descriptor_num = pipelineLayoutSettingsDesc.root_descriptor_num;

    // Apply global limits
    if (root_constant_size > deviceDesc.pipelineLayout.rootConstantMaxSize)
        root_constant_size = deviceDesc.pipelineLayout.rootConstantMaxSize;

    if (root_descriptor_num > deviceDesc.pipelineLayout.rootDescriptorMaxNum)
        root_descriptor_num = deviceDesc.pipelineLayout.rootDescriptorMaxNum;

    var pipelineLayoutDescriptorSetMaxNum = deviceDesc.pipelineLayout.descriptorSetMaxNum;

    // D3D12 has limited-size root signature
    if (deviceDesc.graphicsAPI == GraphicsAPI.D3D12) {
        const descriptorTableCost = 4;
        const rootDescriptorCost = 8;

        var freeBytesInRootSignature: u32 = 256;

        // Reserved 1 root descriptor for "draw parameters" emulation
        if (pipelineLayoutSettingsDesc.enable_d3d12_draw_parameters_emulation)
            freeBytesInRootSignature -= 8;

        // Must fit
        const availableDescriptorRangeNum = @divTrunc(freeBytesInRootSignature, descriptorTableCost);
        if (descriptor_range_num > availableDescriptorRangeNum)
            descriptor_range_num = availableDescriptorRangeNum;

        freeBytesInRootSignature -= descriptor_range_num * descriptorTableCost;

        // Desired fit
        if (pipelineLayoutSettingsDesc.prefer_root_descriptors_over_constants) {
            const availableRootDescriptorNum = @divTrunc(freeBytesInRootSignature, rootDescriptorCost);
            if (root_descriptor_num > availableRootDescriptorNum)
                root_descriptor_num = availableRootDescriptorNum;

            freeBytesInRootSignature -= root_descriptor_num * rootDescriptorCost;

            if (root_constant_size > freeBytesInRootSignature)
                root_constant_size = freeBytesInRootSignature;
        } else {
            if (root_constant_size > freeBytesInRootSignature)
                root_constant_size = freeBytesInRootSignature;

            freeBytesInRootSignature -= root_constant_size;

            const availableRootDescriptorNum = @divTrunc(freeBytesInRootSignature, rootDescriptorCost);
            if (root_descriptor_num > availableRootDescriptorNum)
                root_descriptor_num = availableRootDescriptorNum;
        }
    } else if (root_descriptor_num != 0)
        pipelineLayoutDescriptorSetMaxNum -= 1;

    if (descriptor_set_num > pipelineLayoutDescriptorSetMaxNum)
        descriptor_set_num = pipelineLayoutDescriptorSetMaxNum;

    var modifiedPipelineLayoutLimitsDesc = pipelineLayoutSettingsDesc.*;
    modifiedPipelineLayoutLimitsDesc.descriptor_set_num = descriptor_set_num;
    modifiedPipelineLayoutLimitsDesc.descriptor_range_num = descriptor_range_num;
    modifiedPipelineLayoutLimitsDesc.root_constant_size = root_constant_size;
    modifiedPipelineLayoutLimitsDesc.root_descriptor_num = root_descriptor_num;

    return modifiedPipelineLayoutLimitsDesc;
}
