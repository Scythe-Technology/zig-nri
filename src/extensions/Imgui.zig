// Goal: ImGui rendering

const Descs = @import("../Descs.zig");

const Device = Descs.Device;
const Result = Descs.Result;
const CommandBuffer = Descs.CommandBuffer;
const Format = Descs.Format;
const Dim2_t = Descs.Dim2_t;

//
// Requirements:
// - ImGui 1.92+ with "ImGuiBackendFlags_RendererHasTextures" flag ("IMGUI_DISABLE_OBSOLETE_FUNCTIONS" is recommended)
// - unmodified "ImDrawVert" (20 bytes) and "ImDrawIdx" (2 bytes)
// - "ImTextureID_Invalid" = 0

// Expected usage:
// - the goal of this extension is to support latest ImGui only
// - designed only for rendering
// - "drawList->AddCallback" functionality is not supported! But there is a special callback, allowing to override "hdrScale":
//      drawList->AddCallback(NRI_IMGUI_OVERRIDE_HDR_SCALE(1000.0f)); // to override "DrawImguiDesc::hdrScale"
//      drawList->AddCallback(NRI_IMGUI_OVERRIDE_HDR_SCALE(0.0f));    // to revert back to "DrawImguiDesc::hdrScale"
// - "ImGui::Image*" functions are supported. "ImTextureID" must be a "SHADER_RESOURCE" descriptor:
//      ImGui::Image((ImTextureID)descriptor, ...)
//

pub const ImDrawList = opaque {};
pub const ImTextureData = opaque {};

pub const Imgui = opaque {};
pub const Streamer = opaque {};

pub const ImguiDesc = extern struct {
    /// upper bound of textures used by Imgui for drawing: {number of queued frames} * {number of "CmdDrawImgui" calls} * (1 + {"drawList->AddImage*" calls})
    descriptor_pool_size: u32 = 0,
};

pub const CopyImguiDataDesc = extern struct {
    /// ImDrawData::CmdLists.Data
    draw_lists: ?[*]*ImDrawList,
    /// ImDrawData::CmdLists.Size
    draw_list_num: u32 = 0,
    /// ImDrawData::Textures->Data (same as "ImGui::GetPlatformIO().Textures.Data")
    textures: ?[*]*ImTextureData,
    /// ImDrawData::Textures->Size (same as "ImGui::GetPlatformIO().Textures.Size")
    texture_num: u32 = 0,
};

pub const DrawImguiDesc = extern struct {
    /// ImDrawData::CmdLists.Data (same as for "CopyImguiDataDesc")
    draw_lists: ?[*]*ImDrawList,
    /// ImDrawData::CmdLists.Size (same as for "CopyImguiDataDesc")
    draw_list_num: u32 = 0,
    /// ImDrawData::DisplaySize
    display_size: Dim2_t = 0,
    /// SDR intensity in HDR mode (1 by default)
    hdr_scale: f32 = 1,
    /// destination attachment (render target) format
    attachment_format: Format = .UNKNOWN,
    /// apply de-gamma to vertex colors (needed for sRGB attachments and HDR)
    linear_color: bool = false,
};

/// Threadsafe: yes
pub const ImguiInterface = extern struct {
    CreateImgui: *const fn (device: *Device, imguiDesc: *const ImguiDesc, imgui: *?*Imgui) callconv(.c) Result,
    DestroyImgui: *const fn (imgui: *Imgui) callconv(.c) void,

    // Command buffer
    // zig fmt: off
    // {
        /// Copy
        CmdCopyImguiData: *const fn (commandBuffer: *CommandBuffer, streamer: *Streamer, imgui: *Imgui, streamImguiDesc: *const CopyImguiDataDesc) callconv(.c) void,
        /// Draw (changes descriptor pool, pipeline layout and pipeline, barriers are externally controlled)
        CmdDrawImgui: *const fn (commandBuffer: *CommandBuffer, imgui: *Imgui, drawImguiDesc: *const DrawImguiDesc) callconv(.c) void,
    // }
    // zig fmt: on
};
