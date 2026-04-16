// Goal: data streaming

const Descs = @import("../Descs.zig");

const Device = Descs.Device;
const CommandBuffer = Descs.CommandBuffer;
const Buffer = Descs.Buffer;
const Texture = Descs.Texture;
const MemoryLocation = Descs.MemoryLocation;
const BufferDesc = Descs.BufferDesc;
const TextureRegionDesc = Descs.TextureRegionDesc;
const Result = Descs.Result;

pub const Streamer = opaque {};

pub const DataSize = extern struct {
    data: ?*const anyopaque,
    size: u64 = 0,
};

pub const BufferOffset = extern struct {
    buffer: *Buffer,
    offset: u64 = 0,
};

pub const StreamerDesc = extern struct {
    // Statically allocated ring-buffer for dynamic constants
    /// UPLOAD or DEVICE_UPLOAD
    constant_buffer_memory_location: MemoryLocation = .DEVICE_UPLOAD,
    /// should be large enough to avoid overwriting data for enqueued frames
    constant_buffer_size: u64 = 0,

    // Dynamically (re)allocated ring-buffer for copying and rendering
    /// UPLOAD or DEVICE_UPLOAD
    dynamic_buffer_memory_location: MemoryLocation = .DEVICE_UPLOAD,
    /// "size" is ignored
    dynamic_buffer_desc: BufferDesc = .{},
    /// number of frames "in-flight" (usually 1-3), adds 1 under the hood for the current "not-yet-committed" frame
    queued_frame_num: u32 = 0,
};

pub const StreamBufferDataDesc = extern struct {
    // Data to upload
    /// will be concatenated in dynamic buffer memory
    data_chunks: [*]const DataSize,
    data_chunk_num: u32 = 0,
    /// desired alignment for "BufferOffset::offset"
    placement_alignment: u32 = 0,

    // Destination
    dst_buffer: ?*Buffer = null,
    dst_offset: u64 = 0,
};

pub const StreamTextureDataDesc = extern struct {
    // Data to upload
    data: ?*const anyopaque,
    data_row_pitch: u32,
    data_slice_pitch: u32,

    // Destination
    dst_texture: ?*Texture = null,
    dst_region: TextureRegionDesc = .{},
};

// Threadsafe: yes by default (see NRI_STREAMER_THREAD_SAFE CMake option)
pub const StreamerInterface = extern struct {
    CreateStreamer: *const fn (device: *Device, streamerDesc: *const StreamerDesc, streamer: *?*Streamer) callconv(.c) Result,
    DestroyStreamer: *const fn (streamer: ?*Streamer) callconv(.c) void,

    // Statically allocated (never changes)
    GetStreamerConstantBuffer: *const fn (streamer: *Streamer) callconv(.c) ?*Buffer,

    // (HOST) Stream data to a dynamic buffer. Return "buffer & offset" for direct usage in the current frame
    StreamBufferData: *const fn (streamer: *Streamer, streamBufferDataDesc: *const StreamBufferDataDesc) callconv(.c) BufferOffset,
    StreamTextureData: *const fn (streamer: *Streamer, streamTextureDataDesc: *const StreamTextureDataDesc) callconv(.c) BufferOffset,

    // (HOST) Stream data to a constant buffer. Return "offset" in "GetStreamerConstantBuffer" for direct usage in the current frame
    StreamConstantData: *const fn (streamer: *Streamer, data: ?*const anyopaque, dataSize: u32) callconv(.c) u32,

    // Command buffer
    // zig fmt: off
    // {
        // (DEVICE) Copy data to destinations (if any), which must be in "COPY_DESTINATION" state
        CmdCopyStreamedData: *const fn (commandBuffer: *CommandBuffer, streamer: *Streamer) callconv(.c) void,
    // }
    // zig fmt: on

    // (HOST) Must be called once at the very end of the frame
    EndStreamerFrame: *const fn (streamer: *Streamer) callconv(.c) void,
};
