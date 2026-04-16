// Goal: minimizing latency between input sampling and frame presentation

const Descs = @import("../Descs.zig");

const Result = Descs.Result;

pub const SwapChain = opaque {};
pub const Queue = Descs.Queue;

// us = microseconds

pub const LatencyMarker = enum(u8) {
    // Should be called:
    /// at the start of the simulation execution each frame, but after the call to "LatencySleep"
    SIMULATION_START = 0,
    /// at the end of the simulation execution each frame
    SIMULATION_END = 1,
    /// at the beginning of the render submission execution each frame (must not span into asynchronous rendering)
    RENDER_SUBMIT_START = 2,
    /// at the end of the render submission execution each frame
    RENDER_SUBMIT_END = 3,
    /// just before the application gathers input data, but between "SIMULATION_START" and "SIMULATION_END" (yes, 6!)
    INPUT_SAMPLE = 6,
};

pub const LatencySleepMode = extern struct {
    /// minimum allowed frame interval (0 - no frame rate limit)
    min_interval_us: u32 = 0,
    low_latency_mode: bool = false,
    low_latency_boost: bool = false,
};

pub const LatencyReport = extern struct {
    /// when "INPUT_SAMPLE" marker is set
    input_sample_time_us: u64 = 0,
    // when "SIMULATION_START" marker is set
    simulation_start_time_us: u64 = 0,
    /// when "SIMULATION_END" marker is set
    simulation_end_time_us: u64 = 0,
    /// when "RENDER_SUBMIT_START" marker is set
    render_submit_start_time_us: u64 = 0,
    /// when "RENDER_SUBMIT_END" marker is set
    render_submit_end_time_us: u64 = 0,
    /// right before "Present"
    present_start_time_us: u64 = 0,
    /// right after "Present"
    present_end_time_us: u64 = 0,
    // when the first "QueueSubmitTrackable" is called
    driver_start_time_us: u64 = 0,
    /// when the final "QueueSubmitTrackable" hands off from the driver
    driver_end_time_us: u64 = 0,
    os_render_queue_start_time_us: u64 = 0,
    os_render_queue_end_time_us: u64 = 0,
    /// when the first submission reaches the GPU
    gpu_render_start_time_us: u64 = 0,
    /// when the final submission finishes on the GPU
    gpu_render_end_time_us: u64 = 0,
};

/// Multi-swapchain is supported only by VK
/// "QueueSubmitDesc::swapChain" must be used to associate work submission with a low latency swap chain
/// Threadsafe: no
pub const LowLatencyInterface = extern struct {
    SetLatencySleepMode: *const fn (swapChain: *SwapChain, latencySleepMode: *const LatencySleepMode) callconv(.c) Result,
    SetLatencyMarker: *const fn (swapChain: *SwapChain, latencyMarker: LatencyMarker) callconv(.c) Result,
    LatencySleep: *const fn (swapChain: *SwapChain) callconv(.c) Result, // call once before "INPUT_SAMPLE"
    GetLatencyReport: *const fn (swapChain: *const SwapChain, latencyReport: *LatencyReport) callconv(.c) Result,
};
