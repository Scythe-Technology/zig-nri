const Descs = @import("../Descs.zig");
const DeviceCreation = @import("DeviceCreation.zig");

const Device = Descs.Device;
const CommandBuffer = Descs.CommandBuffer;
const Buffer = Descs.Buffer;
const Texture = Descs.Texture;
const BufferDesc = Descs.BufferDesc;
const Result = Descs.Result;
const CallbackInterface = DeviceCreation.CallbackInterface;
const AllocationCallbacks = DeviceCreation.AllocationCallbacks;

pub const DXGIFormat = i32;

pub const AGSContext = opaque {};
pub const ID3D11Device = opaque {};
pub const ID3D11DeviceContext = opaque {};
pub const ID3D11Resource = opaque {};

pub const DeviceCreationD3D11Desc = extern struct {
    d3d11_device: *ID3D11Device,
    ags_context: ?*AGSContext,
    callback_interface: CallbackInterface = .{},
    allocation_callbacks: AllocationCallbacks = .{},
    /// vendor specific shader extensions (default is "NRI_SHADER_EXT_REGISTER", space is always "0")
    d3d_shader_ext_register: u32 = 0,
    /// no "memset" functionality in D3D, "CmdZeroBuffer" implemented via a bunch of copies (4 Mb by default)
    d3d_zero_buffer_size: u32 = 4 * 1024 * 1024,
    // Switches (disabled by default)
    /// embedded validation layer, checks for NRI specifics
    enable_nri_validation: bool = false,
    /// enable? but why? (auto-enabled if deferred contexts are not supported)
    enable_d3d11_command_buffer_emulation: bool = false,

    // Switches (enabled by default)
    /// at least NVAPI requires calling "NvAPI_Initialize" in DLL/EXE where the device is created
    disable_nvapi_initialization: bool = true,
};

pub const CommandBufferD3D11Desc = extern struct {
    d3d11_device_context: *ID3D11DeviceContext,
};

pub const BufferD3D11Desc = extern struct {
    d3d11_resource: *ID3D11Resource,
    /// not all information can be retrieved from the resource if not provided
    desc: ?*const BufferDesc,
};

pub const TextureD3D11Desc = extern struct {
    d3d11_resource: *ID3D11Resource,
    /// must be provided "as a compatible typed format" if the resource is typeless
    format: DXGIFormat = 0,
};

/// Threadsafe: yes
pub const WrapperD3D11Interface = extern struct {
    CreateCommandBufferD3D11: *const fn (device: *Device, commandBufferD3D11Desc: *const CommandBufferD3D11Desc, commandBuffer: *?*CommandBuffer) callconv(.c) Result,
    CreateBufferD3D11: *const fn (device: *Device, bufferD3D11Desc: *const BufferD3D11Desc, buffer: *?*Buffer) callconv(.c) Result,
    CreateTextureD3D11: *const fn (device: *Device, textureD3D11Desc: *const TextureD3D11Desc, texture: *?*Texture) callconv(.c) Result,
};

pub extern fn nriCreateDeviceFromD3D11Device(deviceDesc: *const DeviceCreationD3D11Desc, device: *?*Device) Result;
