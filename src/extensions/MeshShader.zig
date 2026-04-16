// Goal: mesh shaders
// https://www.khronos.org/blog/mesh-shading-for-vulkan
// https://microsoft.github.io/DirectX-Specs/d3d/MeshShader.html

const Descs = @import("../Descs.zig");

const CommandBuffer = Descs.CommandBuffer;
const Buffer = Descs.Buffer;

pub const DrawMeshTasksDesc = extern struct {
    x: u32 = 1,
    y: u32 = 1,
    z: u32 = 1,
};

/// Threadsafe: no
pub const MeshShaderInterface = extern struct {
    // Command buffer
    // zig fmt: off
    // {
        // Draw
        CmdDrawMeshTasks: ?*const fn (commandBuffer: *CommandBuffer, drawMeshTasksDesc: *const DrawMeshTasksDesc) callconv(.c) void,
        CmdDrawMeshTasksIndirect: ?*const fn (commandBuffer: *CommandBuffer, buffer: *const Buffer, offset: u64, drawNum: u32, stride: u32, countBuffer: ?*const Buffer, countBufferOffset: u64) callconv(.c) void, // buffer contains "DrawMeshTasksDesc" commands
    // }
    // zig fmt: on
};
