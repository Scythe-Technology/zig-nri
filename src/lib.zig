const std = @import("std");

pub const Descs = @import("Descs.zig");

// Extensions
pub const DeviceCreation = @import("extensions/DeviceCreation.zig");
pub const Helper = @import("extensions/Helper.zig");
pub const Imgui = @import("extensions/Imgui.zig");
pub const LowLatency = @import("extensions/LowLatency.zig");
pub const MeshShader = @import("extensions/MeshShader.zig");
pub const RayTracing = @import("extensions/RayTracing.zig");
pub const Streamer = @import("extensions/Streamer.zig");
pub const SwapChain = @import("extensions/SwapChain.zig");
pub const Upscaler = @import("extensions/Upscaler.zig");
pub const WrapperD3D11 = @import("extensions/WrapperD3D11.zig");
pub const WrapperD3D12 = @import("extensions/WrapperD3D12.zig");
pub const WrapperVK = @import("extensions/WrapperVK.zig");

const AllocateMemoryDesc = Descs.AllocateMemoryDesc;
const BarrierDesc = Descs.BarrierDesc;
const BindPoint = Descs.BindPoint;
const Buffer = Descs.Buffer;
const BufferDesc = Descs.BufferDesc;
const BufferViewDesc = Descs.BufferViewDesc;
const BindBufferMemoryDesc = Descs.BindBufferMemoryDesc;
const BindTextureMemoryDesc = Descs.BindTextureMemoryDesc;
const ClearAttachmentDesc = Descs.ClearAttachmentDesc;
const ClearStorageDesc = Descs.ClearStorageDesc;
const Color32f = Descs.Color32f;
const CopyDescriptorRangeDesc = Descs.CopyDescriptorRangeDesc;
const CommandAllocator = Descs.CommandAllocator;
const CommandBuffer = Descs.CommandBuffer;
const ComputePipelineDesc = Descs.ComputePipelineDesc;
const DepthBiasDesc = Descs.DepthBiasDesc;
const Descriptor = Descs.Descriptor;
const DescriptorPool = Descs.DescriptorPool;
const DescriptorPoolDesc = Descs.DescriptorPoolDesc;
const DescriptorSet = Descs.DescriptorSet;
const DescriptorSetDesc = Descs.DescriptorSetDesc;
const DeviceCreationDesc = Descs.DeviceDesc;
pub const Device = Descs.Device;
const DeviceDesc = Descs.DeviceDesc;
const DispatchDesc = Descs.DispatchDesc;
const DrawDesc = Descs.DrawDesc;
const DrawIndexedDesc = Descs.DrawIndexedDesc;
const Fence = Descs.Fence;
const Format = Descs.Format;
const FormatSupportFlags = Descs.FormatSupportFlags;
const GraphicsPipelineDesc = Descs.GraphicsPipelineDesc;
const IndexType = Descs.IndexType;
const Memory = Descs.Memory;
const MemoryDesc = Descs.MemoryDesc;
const MemoryLocation = Descs.MemoryLocation;
const Object = Descs.Object;
const Pipeline = Descs.Pipeline;
const PipelineLayout = Descs.PipelineLayout;
const PipelineLayoutDesc = Descs.PipelineLayoutDesc;
const QueryPool = Descs.QueryPool;
const QueryPoolDesc = Descs.QueryPoolDesc;
const Queue = Descs.Queue;
const QueueSubmitDesc = Descs.QueueSubmitDesc;
const QueueType = Descs.QueueType;
const Rect = Descs.Rect;
const RenderingDesc = Descs.RenderingDesc;
const ResolveOp = Descs.ResolveOp;
const Result = Descs.Result;
const SampleLocation = Descs.SampleLocation;
const Sample_t = Descs.Sample_t;
const SamplerDesc = Descs.SamplerDesc;
const SetDescriptorSetDesc = Descs.SetDescriptorSetDesc;
const SetRootConstantsDesc = Descs.SetRootConstantsDesc;
const SetRootDescriptorDesc = Descs.SetRootDescriptorDesc;
const ShadingRateDesc = Descs.ShadingRateDesc;
const Texture = Descs.Texture;
const TextureDataLayoutDesc = Descs.TextureDataLayoutDesc;
const TextureDesc = Descs.TextureDesc;
const TextureRegionDesc = Descs.TextureRegionDesc;
const TextureViewDesc = Descs.TextureViewDesc;
const UpdateDescriptorRangeDesc = Descs.UpdateDescriptorRangeDesc;
const Viewport = Descs.Viewport;
const VertexBufferDesc = Descs.VertexBufferDesc;

extern fn nriGetInterface(device: ?*const Descs.Device, interfaceName: [*c]const u8, interfaceSize: usize, interfacePtr: ?*anyopaque) Result;
extern fn nriBeginAnnotation(name: [*c]const u8, bgra: u32) void;
extern fn nriEndAnnotation() void;
extern fn nriAnnotation(name: [*c]const u8, bgra: u32) void;
extern fn nriSetThreadName(name: [*c]const u8) void;

pub fn getInterface(comptime T: type, device: ?*const Descs.Device) !T {
    const type_name: [:0]const u8 = @typeName(T);
    const name = type_name[comptime ((std.mem.lastIndexOfScalar(u8, type_name, '.') orelse 0) + 1)..];
    // @compileLog(name);
    // std.debug.print("{s}\n", .{name});
    var interface: T = undefined;
    try nriGetInterface(device, name.ptr, @sizeOf(T), @ptrCast(&interface)).success();
    return interface;
}
pub fn beginAnnotation(name: [:0]const u8, bgra: u32) void {
    nriBeginAnnotation(name.ptr, bgra);
}
pub fn endAnnotation() void {
    nriEndAnnotation();
}
pub fn annotation(name: [:0]const u8, bgra: u32) void {
    nriAnnotation(name.ptr, bgra);
}
pub fn setThreadName(name: [:0]const u8) void {
    nriSetThreadName(name.ptr);
}

// Threadsafe: yes
pub const CoreInterface = extern struct {
    // Get
    GetDeviceDesc: *const fn (device: *const Device) callconv(.c) *const DeviceDesc,
    GetBufferDesc: *const fn (buffer: *const Buffer) callconv(.c) *const BufferDesc,
    GetTextureDesc: *const fn (texture: *const Texture) callconv(.c) *const TextureDesc,
    GetFormatSupport: *const fn (device: *const Device, format: Format) callconv(.c) Descs.FormatSupportBits,

    // Returns one of the pre-created queues (see "DeviceCreationDesc" or wrapper extensions)
    // Return codes: "UNSUPPORTED" (no queues of "queueType") or "INVALID_ARGUMENT" (if "queueIndex" is out of bounds).
    // Getting "COMPUTE" and/or "COPY" queues switches VK sharing mode to "VK_SHARING_MODE_CONCURRENT" for resources created without "queueExclusive" flag.
    // This approach is used to minimize number of "queue ownership transfers", but also adds a requirement to "get" all async queues BEFORE creation of
    // resources participating into multi-queue activities. Explicit use of "queueExclusive" removes any restrictions.
    GetQueue: *const fn (device: *Device, queueType: QueueType, queueIndex: u32, queue: **Queue) callconv(.c) Result,

    // Create (doesn't assume allocation of big chunks of memory on the device, but it happens for some entities implicitly)
    CreateCommandAllocator: *const fn (queue: *Queue, commandAllocator: **CommandAllocator) callconv(.c) Result,
    CreateCommandBuffer: *const fn (commandAllocator: *CommandAllocator, commandBuffer: **CommandBuffer) callconv(.c) Result,
    CreateFence: *const fn (device: *Device, initialValue: u64, fence: **Fence) callconv(.c) Result,
    CreateDescriptorPool: *const fn (device: *Device, descriptorPoolDesc: *const DescriptorPoolDesc, descriptorPool: **DescriptorPool) callconv(.c) Result,
    CreatePipelineLayout: *const fn (device: *Device, pipelineLayoutDesc: *const PipelineLayoutDesc, pipelineLayout: **PipelineLayout) callconv(.c) Result,
    CreateGraphicsPipeline: *const fn (device: *Device, graphicsPipelineDesc: *const GraphicsPipelineDesc, pipeline: **Pipeline) callconv(.c) Result,
    CreateComputePipeline: *const fn (device: *Device, computePipelineDesc: *const ComputePipelineDesc, pipeline: **Pipeline) callconv(.c) Result,
    CreateQueryPool: *const fn (device: *Device, queryPoolDesc: *const QueryPoolDesc, queryPool: **QueryPool) callconv(.c) Result,
    CreateSampler: *const fn (device: *Device, samplerDesc: *const SamplerDesc, sampler: **Descriptor) callconv(.c) Result,
    CreateBufferView: *const fn (bufferViewDesc: *const BufferViewDesc, bufferView: **Descriptor) callconv(.c) Result,
    CreateTextureView: *const fn (textureViewDesc: *const TextureViewDesc, textureView: **Descriptor) callconv(.c) Result,

    // Destroy
    DestroyCommandAllocator: *const fn (commandAllocator: *CommandAllocator) callconv(.c) void,
    DestroyCommandBuffer: *const fn (commandBuffer: *CommandBuffer) callconv(.c) void,
    DestroyDescriptorPool: *const fn (descriptorPool: *DescriptorPool) callconv(.c) void,
    DestroyBuffer: *const fn (buffer: *Buffer) callconv(.c) void,
    DestroyTexture: *const fn (texture: *Texture) callconv(.c) void,
    DestroyDescriptor: *const fn (descriptor: *Descriptor) callconv(.c) void,
    DestroyPipelineLayout: *const fn (pipelineLayout: *PipelineLayout) callconv(.c) void,
    DestroyPipeline: *const fn (pipeline: *Pipeline) callconv(.c) void,
    DestroyQueryPool: *const fn (queryPool: *QueryPool) callconv(.c) void,
    DestroyFence: *const fn (fence: *Fence) callconv(.c) void,

    // Memory
    AllocateMemory: *const fn (device: *Device, allocateMemoryDesc: *const AllocateMemoryDesc, memory: *?*Memory) callconv(.c) Result,
    FreeMemory: *const fn (memory: ?*Memory) callconv(.c) void,

    // Resources and memory (VK style)
    //  - create a resource (buffer or texture)
    //  - use "Get[Resource]MemoryDesc" to get "MemoryDesc" ("usageBits" and "MemoryLocation" affect returned "MemoryType")
    //  - (optional) group returned "MemoryDesc"s by "MemoryType", but don't group if "mustBeDedicated = true"
    //  - (optional) sort returned "MemoryDesc"s by alignment
    //  - call "AllocateMemory" (even if "mustBeDedicated = true")
    //  - call "Bind[Resource]Memory" to bind resources to "Memory" objects
    //  - (optional) "CalculateAllocationNumber" and "AllocateAndBindMemory" from "NRIHelper" interface simplify this process for buffers and textures
    CreateBuffer: *const fn (device: *Device, bufferDesc: *const BufferDesc, buffer: *?*Buffer) callconv(.c) Result,
    CreateTexture: *const fn (device: *Device, textureDesc: *const TextureDesc, texture: *?*Texture) callconv(.c) Result,
    GetBufferMemoryDesc: *const fn (buffer: *const Buffer, memoryLocation: MemoryLocation, memoryDesc: *MemoryDesc) callconv(.c) void,
    GetTextureMemoryDesc: *const fn (texture: *const Texture, memoryLocation: MemoryLocation, memoryDesc: *MemoryDesc) callconv(.c) void,
    BindBufferMemory: *const fn (bindBufferMemoryDescs: ?[*]const BindBufferMemoryDesc, bindBufferMemoryDescNum: u32) callconv(.c) Result,
    BindTextureMemory: *const fn (bindTextureMemoryDescs: ?[*]const BindTextureMemoryDesc, bindTextureMemoryDescNum: u32) callconv(.c) Result,

    // Resources and memory (D3D12 style)
    // - "Get[Resource]MemoryDesc2" requires "maintenance4" support on Vulkan
    // - "memory, offset" pair can be replaced with a "Nri[Device/DeviceUpload/HostUpload/HostReadback]Heap" macro to create a placed resource in the corresponding memory using VMA (AMD Virtual Memory Allocator) implicitly
    GetBufferMemoryDesc2: *const fn (device: *const Device, bufferDesc: *const BufferDesc, memoryLocation: MemoryLocation, memoryDesc: *MemoryDesc) callconv(.c) void, // requires "features.getMemoryDesc2"
    GetTextureMemoryDesc2: *const fn (device: *const Device, textureDesc: *const TextureDesc, memoryLocation: MemoryLocation, memoryDesc: *MemoryDesc) callconv(.c) void, // requires "features.getMemoryDesc2"
    CreateCommittedBuffer: *const fn (device: *Device, memoryLocation: MemoryLocation, priority: f32, bufferDesc: *const BufferDesc, buffer: **Buffer) callconv(.c) Result,
    CreateCommittedTexture: *const fn (device: *Device, memoryLocation: MemoryLocation, priority: f32, textureDesc: *const TextureDesc, texture: **Texture) callconv(.c) Result,
    CreatePlacedBuffer: *const fn (device: *Device, memory: ?*Memory, offset: u64, bufferDesc: *const BufferDesc, buffer: **Buffer) callconv(.c) Result,
    CreatePlacedTexture: *const fn (device: *Device, memory: ?*Memory, offset: u64, textureDesc: *const TextureDesc, texture: **Texture) callconv(.c) Result,

    // Descriptor set management (entities don't require destroying)
    // - if "ALLOW_UPDATE_AFTER_SET" not used, descriptor sets (and data pointed to by descriptors) must be updated before "CmdSetDescriptorSet"
    // - "ResetDescriptorPool" resets the entire pool and wipes out all allocated descriptor sets. "DescriptorSet" is a tiny struct (<= 48 bytes),
    //   so lots of descriptor sets can be created in advance and reused without calling "ResetDescriptorPool"
    // - if there is a directly indexed descriptor heap:
    //    - D3D12: "GetDescriptorSetOffsets" returns offsets in resource and sampler descriptor heaps
    //       - these offsets are needed in shaders, if the corresponding descriptor set is not the first allocated from the descriptor pool
    //    - VK: "GetDescriptorSetOffsets" returns "0"
    //       - use "-fvk-bind-resource-heap" and "-fvk-bind-sampler-heap" DXC options to define bindings mimicking corresponding heaps
    AllocateDescriptorSets: *const fn (descriptorPool: *DescriptorPool, pipelineLayout: *const PipelineLayout, setIndex: u32, descriptorSets: *?*DescriptorSet, instanceNum: u32, variableDescriptorNum: u32) callconv(.c) Result,
    UpdateDescriptorRanges: *const fn (updateDescriptorRangeDescs: ?[*]const UpdateDescriptorRangeDesc, updateDescriptorRangeDescNum: u32) callconv(.c) void,
    CopyDescriptorRanges: *const fn (copyDescriptorRangeDescs: ?[*]const CopyDescriptorRangeDesc, copyDescriptorRangeDescNum: u32) callconv(.c) void,
    ResetDescriptorPool: *const fn (descriptorPool: *DescriptorPool) callconv(.c) void,
    GetDescriptorSetOffsets: *const fn (descriptorSet: *const DescriptorSet, resourceHeapOffset: *u32, samplerHeapOffset: *u32) callconv(.c) void,

    // Command buffer (one time submit)
    BeginCommandBuffer: *const fn (commandBuffer: *CommandBuffer, descriptorPool: ?*const DescriptorPool) callconv(.c) Result,
    // zig fmt: off
    // {                {
        // Set descriptor pool (initially can be set via "BeginCommandBuffer")
        CmdSetDescriptorPool: *const fn (commandBuffer: *CommandBuffer, descriptorPool: *const DescriptorPool) callconv(.c) void,

        // Resource binding (expect "CmdSetPipelineLayout" to be called first)
        CmdSetPipelineLayout: *const fn (commandBuffer: *CommandBuffer, bindPoint: BindPoint, pipelineLayout: *const PipelineLayout) callconv(.c) void,
        CmdSetDescriptorSet: *const fn (commandBuffer: *CommandBuffer, setDescriptorSetDesc: *const SetDescriptorSetDesc) callconv(.c) void,
        CmdSetRootConstants: *const fn (commandBuffer: *CommandBuffer, setRootConstantsDesc: *const SetRootConstantsDesc) callconv(.c) void,
        CmdSetRootDescriptor: *const fn (commandBuffer: *CommandBuffer, setRootDescriptorDesc: *const SetRootDescriptorDesc) callconv(.c) void,

        // Pipeline
        CmdSetPipeline: *const fn (commandBuffer: *CommandBuffer, pipeline: *const Pipeline) callconv(.c) void,

        // Barrier (outside of rendering)
        CmdBarrier: *const fn (commandBuffer: *CommandBuffer, barrierDesc: *const BarrierDesc) callconv(.c) void,

        // Input assembly
        CmdSetIndexBuffer: *const fn (commandBuffer: *CommandBuffer, buffer: *const Buffer, offset: u64, indexType: IndexType) callconv(.c) void,
        CmdSetVertexBuffers: *const fn (commandBuffer: *CommandBuffer, baseSlot: u32, vertexBufferDescs: ?[*]const VertexBufferDesc, vertexBufferNum: u32) callconv(.c) void,

        // Initial state (mandatory)
        CmdSetViewports: *const fn (commandBuffer: *CommandBuffer, viewports: ?[*]const Viewport, viewportNum: u32) callconv(.c) void,
        CmdSetScissors: *const fn (commandBuffer: *CommandBuffer, rects: ?[*]const Rect, rectNum: u32) callconv(.c) void,

        // Initial state (if enabled)
        CmdSetStencilReference: *const fn (commandBuffer: *CommandBuffer, frontRef: u8, backRef: u8) callconv(.c) void, // "backRef" requires "features.independentFrontAndBackStencilReferenceAndMasks"
        CmdSetDepthBounds: *const fn (commandBuffer: *CommandBuffer, boundsMin: f32, boundsMax: f32) callconv(.c) void, // requires "features.depthBoundsTest"
        CmdSetBlendConstants: *const fn (commandBuffer: *CommandBuffer, color: *const Color32f) callconv(.c) void,
        CmdSetSampleLocations: *const fn (commandBuffer: *CommandBuffer, locations: ?[*]const SampleLocation, locationNum: Sample_t, sampleNum: Sample_t) callconv(.c) void, // requires "tiers.sampleLocations != 0"
        CmdSetShadingRate: *const fn (commandBuffer: *CommandBuffer, shadingRateDesc: *const ShadingRateDesc) callconv(.c) void, // requires "tiers.shadingRate != 0"
        CmdSetDepthBias: *const fn (commandBuffer: *CommandBuffer, depthBiasDesc: *const DepthBiasDesc) callconv(.c) void, // requires "features.dynamicDepthBias", actually it's an override

        // Graphics
        CmdBeginRendering: *const fn (commandBuffer: *CommandBuffer, renderingDesc: *const RenderingDesc) callconv(.c) void,
        // {                {
            // Clear
            CmdClearAttachments: *const fn (commandBuffer: *CommandBuffer, clearAttachmentDescs: ?[*]const ClearAttachmentDesc, clearAttachmentDescNum: u32, rects: ?[*]const Rect, rectNum: u32) callconv(.c) void,

            // Draw
            CmdDraw: *const fn (commandBuffer: *CommandBuffer, drawDesc: *const DrawDesc) callconv(.c) void,
            CmdDrawIndexed: *const fn (commandBuffer: *CommandBuffer, drawIndexedDesc: *const DrawIndexedDesc) callconv(.c) void,

            // Draw indirect:
            //  - drawNum = min(drawNum, countBuffer ? countBuffer[countBufferOffset] : INF)
            //  - see "Modified draw command signatures"
            CmdDrawIndirect: *const fn (commandBuffer: *CommandBuffer, buffer: *const Buffer, offset: u64, drawNum: u32, stride: u32, countBuffer: ?*const Buffer, countBufferOffset: u64) callconv(.c) void, // "buffer" contains "Draw(Base)Desc" commands
            CmdDrawIndexedIndirect: *const fn (commandBuffer: *CommandBuffer, buffer: *const Buffer, offset: u64, drawNum: u32, stride: u32, countBuffer: ?*const Buffer, countBufferOffset: u64) callconv(.c) void, // "buffer" contains "DrawIndexed(Base)Desc" commands
        // }                }
        CmdEndRendering: *const fn (commandBuffer: *CommandBuffer) callconv(.c) void,

        // Compute (outside of rendering)
        CmdDispatch: *const fn (commandBuffer: *CommandBuffer, dispatchDesc: *const DispatchDesc) callconv(.c) void,
        CmdDispatchIndirect: *const fn (commandBuffer: *CommandBuffer, buffer: *const Buffer, offset: u64) callconv(.c) void, // buffer contains "DispatchDesc" commands

        // Copy (outside of rendering)
        CmdCopyBuffer: *const fn (commandBuffer: *CommandBuffer, dstBuffer: *Buffer, dstOffset: u64, srcBuffer: *const Buffer, srcOffset: u64, size: u64) callconv(.c) void,
        CmdCopyTexture: *const fn (commandBuffer: *CommandBuffer, dstTexture: *Texture, dstRegion: ?*const TextureRegionDesc, srcTexture: *const Texture, srcRegion: ?*const TextureRegionDesc) callconv(.c) void,
        CmdUploadBufferToTexture: *const fn (commandBuffer: *CommandBuffer, dstTexture: *Texture, dstRegion: *const TextureRegionDesc, srcBuffer: *const Buffer, srcDataLayout: *const TextureDataLayoutDesc) callconv(.c) void,
        CmdReadbackTextureToBuffer: *const fn (commandBuffer: *CommandBuffer, dstBuffer: *Buffer, dstDataLayout: *const TextureDataLayoutDesc, srcTexture: *const Texture, srcRegion: *const TextureRegionDesc) callconv(.c) void,
        CmdZeroBuffer: *const fn (commandBuffer: *CommandBuffer, buffer: *Buffer, offset: u64, size: u64) callconv(.c) void,

        // Resolve (outside of rendering)
        CmdResolveTexture: *const fn (commandBuffer: *CommandBuffer, dstTexture: *Texture, dstRegion: ?*const TextureRegionDesc, srcTexture: *const Texture, srcRegion: ?*const TextureRegionDesc, resolveOp: ResolveOp) callconv(.c) void, // "features.regionResolve" is needed for region specification

        // Clear (outside of rendering)
        CmdClearStorage: *const fn (commandBuffer: *CommandBuffer, clearStorageDesc: *const ClearStorageDesc) callconv(.c) void,

        // Query (outside of rendering, except Begin/End query)
        CmdResetQueries: *const fn (commandBuffer: *CommandBuffer, queryPool: *QueryPool, offset: u32, num: u32) callconv(.c) void,
        CmdBeginQuery: *const fn (commandBuffer: *CommandBuffer, queryPool: *QueryPool, offset: u32) callconv(.c) void,
        CmdEndQuery: *const fn (commandBuffer: *CommandBuffer, queryPool: *QueryPool, offset: u32) callconv(.c) void,
        CmdCopyQueries: *const fn (commandBuffer: *CommandBuffer, queryPool: *const QueryPool, offset: u32, num: u32, dstBuffer: *Buffer, dstOffset: u64) callconv(.c) void,

        // Annotations for profiling tools: command buffer
        CmdBeginAnnotation: *const fn (commandBuffer: *CommandBuffer, name: [*]const u8, bgra: u32) callconv(.c) void,
        CmdEndAnnotation: *const fn (commandBuffer: *CommandBuffer) callconv(.c) void,
        CmdAnnotation: *const fn (commandBuffer: *CommandBuffer, name: [*]const u8, bgra: u32) callconv(.c) void,
    // }                }
    // zig fmt: on
    EndCommandBuffer: *const fn (commandBuffer: *CommandBuffer) callconv(.c) Result, // D3D11 performs state tracking and resets it there

    // Annotations for profiling tools: command queue - D3D11: NOP
    QueueBeginAnnotation: *const fn (queue: *Queue, name: [*]const u8, bgra: u32) callconv(.c) void,
    QueueEndAnnotation: *const fn (queue: *Queue) callconv(.c) void,
    QueueAnnotation: *const fn (queue: *Queue, name: [*]const u8, bgra: u32) callconv(.c) void,

    // Query
    ResetQueries: *const fn (queryPool: *QueryPool, offset: u32, num: u32) callconv(.c) void, // on host
    GetQuerySize: *const fn (queryPool: *const QueryPool) callconv(.c) u32,

    // Work submission and synchronization
    QueueSubmit: *const fn (queue: *Queue, queueSubmitDesc: *const QueueSubmitDesc) callconv(.c) Result, // to device
    QueueWaitIdle: *const fn (queue: ?*Queue) callconv(.c) Result,
    DeviceWaitIdle: *const fn (device: ?*Device) callconv(.c) Result,
    Wait: *const fn (fence: *Fence, value: u64) callconv(.c) void, // on host
    GetFenceValue: *const fn (fence: *Fence) callconv(.c) u64,

    // Command allocator
    ResetCommandAllocator: *const fn (commandAllocator: *CommandAllocator) callconv(.c) void,

    // Host address
    // D3D11: no persistent mapping
    // D3D12: persistent mapping, "Map/Unmap" do nothing
    // VK: persistent mapping, but "Unmap" can do a flush if underlying memory is not "HOST_COHERENT" (unlikely)
    MapBuffer: *const fn (buffer: *Buffer, offset: u64, size: u64) callconv(.c) ?*anyopaque,
    UnmapBuffer: *const fn (buffer: *Buffer) callconv(.c) void,

    // Device address (aka GPU virtual address)
    // D3D11: returns "0"
    GetBufferDeviceAddress: *const fn (buffer: *const Buffer) callconv(.c) u64,

    // Debug name for any object declared as "NriForwardStruct" (skipped for buffers & textures in D3D if they are not bound to a memory)
    SetDebugName: *const fn (object: ?*Object, name: [*:0]const u8) callconv(.c) void,

    // Native objects                                                                                            ___D3D11 (latest interface)________|_D3D12 (latest interface)____|_VK_________________________________
    GetDeviceNativeObject: *const fn (device: ?*const Device) callconv(.c) ?*anyopaque, // ID3D11Device*                   | ID3D12Device*               | VkDevice
    GetQueueNativeObject: *const fn (queue: ?*const Queue) callconv(.c) ?*anyopaque, // -                               | ID3D12CommandQueue*         | VkQueue
    GetCommandBufferNativeObject: *const fn (commandBuffer: ?*const CommandBuffer) callconv(.c) ?*anyopaque, // ID3D11DeviceContext*            | ID3D12GraphicsCommandList*  | VkCommandBuffer
    GetBufferNativeObject: *const fn (buffer: ?*const Buffer) callconv(.c) u64, // ID3D11Buffer*                   | ID3D12Resource*             | VkBuffer
    GetTextureNativeObject: *const fn (texture: ?*const Texture) callconv(.c) u64, // ID3D11Resource*                 | ID3D12Resource*             | VkImage
    GetDescriptorNativeObject: *const fn (descriptor: ?*const Descriptor) callconv(.c) u64, // ID3D11View/ID3D11SamplerState*  | D3D12_CPU_DESCRIPTOR_HANDLE | VkImageView/VkBufferView/VkSampler

    pub fn getQueue(self: CoreInterface, device: *Device, queue_type: QueueType, queue_index: u32) !*Queue {
        var queue: *Queue = undefined;
        try self.GetQueue(device, queue_type, queue_index, &queue).success();
        return queue;
    }

    pub fn createCommandAllocator(self: CoreInterface, queue: *Queue) !*CommandAllocator {
        var command_allocator: *CommandAllocator = undefined;
        try self.CreateCommandAllocator(queue, &command_allocator).success();
        return command_allocator;
    }
    pub fn createCommandBuffer(self: CoreInterface, command_allocator: *CommandAllocator) !*CommandBuffer {
        var command_buffer: *CommandBuffer = undefined;
        try self.CreateCommandBuffer(command_allocator, &command_buffer).success();
        return command_buffer;
    }
    pub fn createFence(self: CoreInterface, device: *Device, initial_value: u64) !*Fence {
        var fence: *Fence = undefined;
        try self.CreateFence(device, initial_value, &fence).success();
        return fence;
    }

    pub fn createPipelineLayout(self: CoreInterface, device: *Device, opts: PipelineLayoutDesc.Options) !*PipelineLayout {
        var pipeline_layout: *PipelineLayout = undefined;
        try self.CreatePipelineLayout(device, &.from(opts), &pipeline_layout).success();
        return pipeline_layout;
    }
    pub fn createGraphicsPipeline(self: CoreInterface, device: *Device, opts: GraphicsPipelineDesc.Options) !*Pipeline {
        var pipeline: *Pipeline = undefined;
        try self.CreateGraphicsPipeline(device, &.from(opts), &pipeline).success();
        return pipeline;
    }
    pub fn createTextureView(self: CoreInterface, texture_view_desc: TextureViewDesc) !*Descriptor {
        var texture_view: *Descriptor = undefined;
        try self.CreateTextureView(&texture_view_desc, &texture_view).success();
        return texture_view;
    }

    pub fn createCommittedBuffer(self: CoreInterface, device: *Device, memory_location: MemoryLocation, priority: f32, buffer_desc: BufferDesc) !*Buffer {
        var buffer: *Buffer = undefined;
        try self.CreateCommittedBuffer(device, memory_location, priority, &buffer_desc, &buffer).success();
        return buffer;
    }

    pub inline fn beginCommandBuffer(self: CoreInterface, command_buffer: *CommandBuffer, descriptor_pool: ?*const DescriptorPool) !void {
        try self.BeginCommandBuffer(command_buffer, descriptor_pool).success();
    }
    pub inline fn cmdSetDescriptorPool(self: CoreInterface, command_buffer: *CommandBuffer, descriptor_pool: *const DescriptorPool) void {
        self.CmdSetDescriptorPool(command_buffer, descriptor_pool);
    }
    pub inline fn cmdSetPipelineLayout(self: CoreInterface, command_buffer: *CommandBuffer, bind_point: BindPoint, pipeline_layout: *const PipelineLayout) void {
        self.CmdSetPipelineLayout(command_buffer, bind_point, pipeline_layout);
    }
    pub inline fn cmdSetDescriptorSet(self: CoreInterface, command_buffer: *CommandBuffer, set_descriptor_set_desc: SetDescriptorSetDesc) void {
        self.CmdSetDescriptorSet(command_buffer, &set_descriptor_set_desc);
    }
    pub inline fn cmdSetRootConstants(self: CoreInterface, command_buffer: *CommandBuffer, set_root_constants_desc: SetRootConstantsDesc) void {
        self.CmdSetRootConstants(command_buffer, &set_root_constants_desc);
    }
    pub inline fn cmdSetRootDescriptor(self: CoreInterface, command_buffer: *CommandBuffer, set_root_descriptor_desc: SetRootDescriptorDesc) void {
        self.CmdSetRootDescriptor(command_buffer, &set_root_descriptor_desc);
    }
    pub inline fn cmdSetPipeline(self: CoreInterface, command_buffer: *CommandBuffer, pipeline: *const Pipeline) void {
        self.CmdSetPipeline(command_buffer, pipeline);
    }
    pub inline fn cmdBarrier(self: CoreInterface, command_buffer: *CommandBuffer, opts: BarrierDesc.Options) void {
        self.CmdBarrier(command_buffer, &.from(opts));
    }
    pub inline fn cmdSetIndexBuffer(self: CoreInterface, command_buffer: *CommandBuffer, buffer: *const Buffer, offset: u64, index_type: IndexType) void {
        self.CmdSetIndexBuffer(command_buffer, buffer, offset, index_type);
    }
    pub inline fn cmdSetVertexBuffers(self: CoreInterface, command_buffer: *CommandBuffer, base_slot: u32, vertex_buffer_descs: []const VertexBufferDesc) void {
        self.CmdSetVertexBuffers(command_buffer, base_slot, vertex_buffer_descs.ptr, @intCast(vertex_buffer_descs.len));
    }
    pub inline fn cmdSetViewports(self: CoreInterface, command_buffer: *CommandBuffer, viewports: []const Viewport) void {
        self.CmdSetViewports(command_buffer, viewports.ptr, viewports.len);
    }
    pub inline fn cmdSetScissors(self: CoreInterface, command_buffer: *CommandBuffer, rects: []const Rect) void {
        self.CmdSetScissors(command_buffer, rects.ptr, rects.len);
    }
    pub inline fn cmdSetStencilReference(self: CoreInterface, command_buffer: *CommandBuffer, front_ref: u8, back_ref: u8) void {
        self.CmdSetStencilReference(command_buffer, front_ref, back_ref);
    }
    pub inline fn cmdSetDepthBounds(self: CoreInterface, command_buffer: *CommandBuffer, bounds_min: f32, bounds_max: f32) void {
        self.CmdSetDepthBounds(command_buffer, bounds_min, bounds_max);
    }
    pub inline fn cmdSetBlendConstants(self: CoreInterface, command_buffer: *CommandBuffer, color: Color32f) void {
        self.CmdSetBlendConstants(command_buffer, &color);
    }
    pub inline fn cmdSetSampleLocations(self: CoreInterface, command_buffer: *CommandBuffer, locations: []const SampleLocation, location_num: Sample_t, sample_num: Sample_t) void {
        self.CmdSetSampleLocations(command_buffer, locations.ptr, location_num, sample_num);
    }
    pub inline fn cmdSetShadingRate(self: CoreInterface, command_buffer: *CommandBuffer, shading_rate_desc: ShadingRateDesc) void {
        self.CmdSetShadingRate(command_buffer, &shading_rate_desc);
    }
    pub inline fn cmdSetDepthBias(self: CoreInterface, command_buffer: *CommandBuffer, depth_bias_desc: DepthBiasDesc) void {
        self.CmdSetDepthBias(command_buffer, &depth_bias_desc);
    }
    pub inline fn cmdBeginRendering(self: CoreInterface, command_buffer: *CommandBuffer, opts: RenderingDesc.Options) void {
        self.CmdBeginRendering(command_buffer, &.from(opts));
    }
    pub inline fn cmdClearAttachments(self: CoreInterface, command_buffer: *CommandBuffer, clear_attachment_descs: []const ClearAttachmentDesc, rects: []const Rect) void {
        self.CmdClearAttachments(command_buffer, clear_attachment_descs.ptr, clear_attachment_descs.len, rects.ptr, rects.len);
    }
    pub inline fn cmdDraw(self: CoreInterface, command_buffer: *CommandBuffer, draw_desc: DrawDesc) void {
        self.CmdDraw(command_buffer, &draw_desc);
    }
    pub inline fn cmdDrawIndexed(self: CoreInterface, command_buffer: *CommandBuffer, draw_indexed_desc: DrawIndexedDesc) void {
        self.CmdDrawIndexed(command_buffer, &draw_indexed_desc);
    }
    pub inline fn cmdDrawIndirect(self: CoreInterface, command_buffer: *CommandBuffer, buffer: *const Buffer, offset: u64, draw_num: u32, stride: u32, count_buffer: ?*const Buffer, count_buffer_offset: u64) void {
        self.CmdDrawIndirect(command_buffer, buffer, offset, draw_num, stride, count_buffer, count_buffer_offset);
    }
    pub inline fn cmdDrawIndexedIndirect(self: CoreInterface, command_buffer: *CommandBuffer, buffer: *const Buffer, offset: u64, draw_num: u32, stride: u32, count_buffer: ?*const Buffer, count_buffer_offset: u64) void {
        self.CmdDrawIndexedIndirect(command_buffer, buffer, offset, draw_num, stride, count_buffer, count_buffer_offset);
    }
    pub inline fn cmdEndRendering(self: CoreInterface, command_buffer: *CommandBuffer) void {
        self.CmdEndRendering(command_buffer);
    }
    pub inline fn cmdDispatch(self: CoreInterface, command_buffer: *CommandBuffer, dispatch_desc: DispatchDesc) void {
        self.CmdDispatch(command_buffer, &dispatch_desc);
    }
    pub inline fn cmdDispatchIndirect(self: CoreInterface, command_buffer: *CommandBuffer, buffer: *const Buffer, offset: u64) void {
        self.CmdDispatchIndirect(command_buffer, buffer, offset);
    }
    pub inline fn cmdCopyBuffer(self: CoreInterface, command_buffer: *CommandBuffer, dst_buffer: *Buffer, dst_offset: u64, src_buffer: *const Buffer, src_offset: u64, size: u64) void {
        self.CmdCopyBuffer(command_buffer, dst_buffer, dst_offset, src_buffer, src_offset, size);
    }
    pub inline fn cmdCopyTexture(self: CoreInterface, command_buffer: *CommandBuffer, dst_texture: *Texture, dst_region: ?*const TextureRegionDesc, src_texture: *const Texture, src_region: ?*const TextureRegionDesc) void {
        self.CmdCopyTexture(command_buffer, dst_texture, dst_region, src_texture, src_region);
    }
    pub inline fn cmdUploadBufferToTexture(self: CoreInterface, command_buffer: *CommandBuffer, dst_texture: *Texture, dst_region: *const TextureRegionDesc, src_buffer: *const Buffer, src_data_layout: *const TextureDataLayoutDesc) void {
        self.CmdUploadBufferToTexture(command_buffer, dst_texture, dst_region, src_buffer, src_data_layout);
    }
    pub inline fn cmdReadbackTextureToBuffer(self: CoreInterface, command_buffer: *CommandBuffer, dst_buffer: *Buffer, dst_data_layout: *const TextureDataLayoutDesc, src_texture: *const Texture, src_region: *const TextureRegionDesc) void {
        self.CmdReadbackTextureToBuffer(command_buffer, dst_buffer, dst_data_layout, src_texture, src_region);
    }
    pub inline fn cmdZeroBuffer(self: CoreInterface, command_buffer: *CommandBuffer, buffer: *Buffer, offset: u64, size: u64) void {
        self.CmdZeroBuffer(command_buffer, buffer, offset, size);
    }
    pub inline fn cmdResolveTexture(self: CoreInterface, command_buffer: *CommandBuffer, dst_texture: *Texture, dst_region: ?*const TextureRegionDesc, src_texture: *const Texture, src_region: ?*const TextureRegionDesc, resolve_op: ResolveOp) void {
        self.CmdResolveTexture(command_buffer, dst_texture, dst_region, src_texture, src_region, resolve_op);
    }
    pub inline fn cmdClearStorage(self: CoreInterface, command_buffer: *CommandBuffer, clear_storage_desc: ClearStorageDesc) void {
        self.CmdClearStorage(command_buffer, &clear_storage_desc);
    }
    pub inline fn cmdResetQueries(self: CoreInterface, command_buffer: *CommandBuffer, query_pool: *QueryPool, offset: u32, num: u32) void {
        self.CmdResetQueries(command_buffer, query_pool, offset, num);
    }
    pub inline fn cmdBeginQuery(self: CoreInterface, command_buffer: *CommandBuffer, query_pool: *QueryPool, offset: u32) void {
        self.CmdBeginQuery(command_buffer, query_pool, offset);
    }
    pub inline fn cmdEndQuery(self: CoreInterface, command_buffer: *CommandBuffer, query_pool: *QueryPool, offset: u32) void {
        self.CmdEndQuery(command_buffer, query_pool, offset);
    }
    pub inline fn cmdCopyQueries(self: CoreInterface, command_buffer: *CommandBuffer, query_pool: *const QueryPool, offset: u32, num: u32, dst_buffer: *Buffer, dst_offset: u64) void {
        self.CmdCopyQueries(command_buffer, query_pool, offset, num, dst_buffer, dst_offset);
    }
    pub inline fn cmdBeginAnnotation(self: CoreInterface, command_buffer: *CommandBuffer, name: [:0]const u8, bgra: u32) void {
        self.CmdBeginAnnotation(command_buffer, name.ptr, bgra);
    }
    pub inline fn cmdEndAnnotation(self: CoreInterface, command_buffer: *CommandBuffer) void {
        self.CmdEndAnnotation(command_buffer);
    }
    pub inline fn endCommandBuffer(self: CoreInterface, command_buffer: *CommandBuffer) !void {
        try self.EndCommandBuffer(command_buffer).success();
    }

    pub inline fn queueSubmit(self: CoreInterface, queue: *Queue, opts: QueueSubmitDesc.Options) !void {
        try self.QueueSubmit(queue, &.from(opts)).success();
    }

    pub inline fn mapBuffer(self: CoreInterface, buffer: *Buffer, size: u64) []u8 {
        return @as([*]u8, @ptrCast(self.MapBuffer(buffer, 0, size)))[0..size];
    }
};
