# zig-nri

Zig wrapper/bindings for [NVIDIA-RTX/NRI](https://github.com/NVIDIA-RTX/NRI).

This zig library can be used to compile NRI alone and use emitted static/dyanmic library from `zig-out`.

The Zig wrapper is not complete yet, but a few wrapper are implemented, such as the ones in [Usage Section](#usage)

**Status**: Incomplete, but usable with NRI's interfaces and data structures.

**NRI Version**: `179`

## Issues
For any issues while using this library, please open an issue in this repository. When problems are related to NRI, the issue can still be made on this repository and upstreamed to NRI if needed.

## Usage

```zig
const std = @import("std");
const nri = @import("nri");

pub fn main() !void {
    const device = try nri.DeviceCreation.createDevice(.{
        .graphics_api = .VK,
    });
    defer device.destroy();
    const core = try nri.getInterface(nri.CoreInterface, device);
    const swap = try nri.getInterface(nri.SwapChain.SwapChainInterface, device);
    
    // Use the interfaces...
}
```

## Compile Options

Build options:
```sh
zig build -D<option name>=<value>
```
Package options (`build.zig`):
```zig
const nri = b.dependency("zig_nri", .{
    .<option name> = <value>,
});
```

can be used to set the following options:

- `static_library` - Build NRI as a static library (default: `false`)
- `enable_nvtx_support` - Enable NVTX support (default: `false`)
- `enable_debug_names_and_annotations` - Enable debug names, host and device annotations (default: `false`)
- `enable_none_support` - Enable NONE backend (default: `true`)
- `enable_vk_support` - Enable Vulkan support (default: `true`)
- `enable_validation_support` - Enable Validation backend (otherwise 'enableNRIValidation' is ignored) (default: `true`)
- `enable_nis_sdk` - Enable NVIDIA Image Sharpening SDK (default: `false`)
- `enable_imgui_extensions` - Enable 'NRIImgui' extension (default: `false`)
- `enable_streamer_thread_safe` - 'NRIStreamer' thread safety (OFF is faster) (default: `true`)
- `enable_d3d11_support` - Enable D3D11 support (default: `os == windows`)
- `enable_d3d12_support` - Enable D3D12 support (default: `os == windows`)
- `enable_amdags_support` - Enable AMD AGS library for D3D (default: `d3d12 or d3d11`)
- `enable_nvapi_support` - Enable NVAPI library for D3D (default: `d3d12 or d3d11`)
- `enable_agility_sdk_support` - Enable Agility SDK support to unlock access to latest D3D12 features (default: `d3d12`)
- `enable_xlib_support` - Enable X11 support (default: `true`, for Linux)
- `enable_wayland_support` - Enable Wayland support (default: `true`, for Linux)
- `enable_ngx_sdk` - Enable NVIDIA NGX (DLSS) SDK (default: `false`)
- `enable_ffx_sdk` - Enable AMD FidelityFX SDK (default: `false`)
- `enable_xess_sdk` - Enable INTEL XeSS SDK (default: `false`)

## Licenses
- zig-nri: [MIT License](LICENSE).
- NRI: [MIT License](NRI-LICENSE).