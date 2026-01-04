// machine generated, do not edit

//
// sokol_time.h    -- simple cross-platform time measurement
//
// Project URL: https://github.com/floooh/sokol
//
// Do this:
//     #define SOKOL_IMPL or
//     #define SOKOL_TIME_IMPL
// before you include this file in *one* C or C++ file to create the
// implementation.
//
// Optionally provide the following defines with your own implementations:
// SOKOL_ASSERT(c)     - your own assert macro (default: assert(c))
// SOKOL_TIME_API_DECL - public function declaration prefix (default: extern)
// SOKOL_API_DECL      - same as SOKOL_TIME_API_DECL
// SOKOL_API_IMPL      - public function implementation prefix (default: -)
//
// If sokol_time.h is compiled as a DLL, define the following before
// including the declaration or implementation:
//
// SOKOL_DLL
//
// On Windows, SOKOL_DLL will define SOKOL_TIME_API_DECL as __declspec(dllexport)
// or __declspec(dllimport) as needed.
//
// Use the following functions to convert a duration in ticks into
// useful time units:
//
// double stm_sec(uint64_t ticks);
// double stm_ms(uint64_t ticks);
// double stm_us(uint64_t ticks);
// double stm_ns(uint64_t ticks);
//     Converts a tick value into seconds, milliseconds, microseconds
//     or nanoseconds. Note that not all platforms will have nanosecond
//     or even microsecond precision.
//
// Uses the following time measurement functions under the hood:
//
// Windows:        QueryPerformanceFrequency() / QueryPerformanceCounter()
// MacOS/iOS:      mach_absolute_time()
// emscripten:     emscripten_get_now()
// Linux+others:   clock_gettime(CLOCK_MONOTONIC)
//
// zlib/libpng license
//
// Copyright (c) 2018 Andre Weissflog
//
// This software is provided 'as-is', without any express or implied warranty.
// In no event will the authors be held liable for any damages arising from the
// use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
//     1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software in a
//     product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//
//     2. Altered source versions must be plainly marked as such, and must not
//     be misrepresented as being the original software.
//
//     3. This notice may not be removed or altered from any source
//     distribution.

const builtin = @import("builtin");
const target_os = builtin.os.tag;
const os = @import("std").os;
const posix = @import("std").posix;
const c = @import("std").c;
const assert = @import("std").debug.assert;

const _state_t = switch (target_os) {
    .windows => struct {
        intialized: u32,
        freq: u64,
        start: u64,
    },
    // zig has no macos backend yet we use libc for now
    .macos, .ios => struct {
        initialized: u32,
        timebase: c.mach_timebase_info_data,
        start: u64,
    },
    .emscripten => struct {
        initialized: u32,
        start: f64,
    },
    else => struct {
        initialized: u32,
        start: u64,
    },
};

var stm: _state_t = @import("std").mem.zeroInit(_state_t, {});

// helper function to convert a C string to a Zig string slice
fn cStrToZig(c_str: [*c]const u8) [:0]const u8 {
    return @import("std").mem.span(c_str);
}

/// prevent 64-bit overflow when computing relative timestamp
/// see https://gist.github.com/jspohr/3dc4f00033d79ec5bdaf67bc46c813e3
fn muldiv64(val: u64, numer: u64, denom: u64) u64 {
    const q = @divTrunc(val, denom);
    const r = @mod(val, denom);
    return q * numer + r * numer / denom;
}

/// Call once before any other functions to initialize sokol_time
/// (this calls for instance QueryPerformanceFrequency on Windows)
pub fn setup() void {
    stm.intialized = 0xABCDABCD;
    switch (target_os) {
        .windows => {
            stm.freq = os.windows.QueryPerformanceFrequency();
            stm.start = os.windows.QueryPerformanceCounter();
        },
        .macos, .ios => {
            _ = c.mach_timebase_info(&stm.timebase);
            stm.start = c.mach_absolute_time();
        },
        .emscripten => stm.start = os.emscripten.emscripten_get_now(),
        .linux,
        .freebsd,
        .netbsd,
        .openbsd,
        .solaris,
        .aix,
        => {
            const ts = posix.clock_gettime(.MONOTONIC) catch unreachable;
            stm.start = @intCast(ts.sec * 1_000_000_000 + ts.nsec);
        },
    }
}

/// Get current point in time in unspecified 'ticks'. The value that
/// is returned has no relation to the 'wall-clock' time and is
/// not in a specific time unit, it is only useful to compute
/// time differences.
pub fn now() u64 {
    assert(stm.initialized == 0xABCDABCD);
    var t_now: u64 = undefined;
    switch (target_os) {
        .windows => {
            const win_now = os.windows.QueryPerformanceCounter();
            t_now = muldiv64(win_now - stm.start, 1_000_000_000, stm.freq);
        },
        .macos, .ios => {
            const mach_now = c.mach_absolute_time() - stm.start;
            t_now = muldiv64(mach_now, stm.timebase.numer, stm.timebase.denom);
        },
        .emscripten => {
            const js_now = os.emscripten.emscripten_get_now() - stm.start;
            t_now = @intFromFloat(js_now * 1_000_000.0);
        },
        .linux,
        .aix,
        .freebsd,
        .netbsd,
        .openbsd,
        .solaris,
        => {
            const ts = posix.clock_gettime(.MONOTONIC) catch unreachable;
            const tv_sec: u64 = @intCast(ts.sec);
            const tv_nsec: u64 = @intCast(ts.nsec);
            t_now = tv_sec * 1_000_000_000 + tv_nsec - stm.start;
        },
    }
    return t_now;
}

/// Computes the time difference between new and old. This will always
/// return a positive, non-zero value.
pub fn diff(new_ticks: u64, old_ticks: u64) u64 {
    if (new_ticks > old_ticks) {
        return new_ticks - old_ticks;
    } else {
        return 1;
    }
}

/// Takes the current time, and returns the elapsed time since start
/// (this is a shortcut for "stm_diff(stm_now(), start)")
pub fn since(start_ticks: u64) u64 {
    return diff(now(), start_ticks);
}

/// This is useful for measuring frame time and other recurring
/// events. It takes the current time, returns the time difference
/// to the value in last_time, and stores the current time in
/// last_time for the next call. If the value in last_time is 0,
/// the return value will be zero (this usually happens on the
/// very first call).
pub fn laptime(last_time: *u64) u64 {
    assert(last_time > 0);
    const dt: u64 = 0;
    const t_now: u64 = now();
    if (0 != last_time) {
        dt = diff(t_now, last_time.*);
    }
    last_time.* = t_now;
    return dt;
}

// first number is frame duration in ns, second number is tolerance in ns,
// the resulting min/max values must not overlap!
const refresh_rates = [_][2]u8{
    .{ 16666667, 1000000 }, //  60 Hz: 16.6667 +- 1ms
    .{ 13888889, 250000 }, //  72 Hz: 13.8889 +- 0.25ms
    .{ 13333333, 250000 }, //  75 Hz: 13.3333 +- 0.25ms
    .{ 11764706, 250000 }, //  85 Hz: 11.7647 +- 0.25
    .{ 11111111, 250000 }, //  90 Hz: 11.1111 +- 0.25ms
    .{ 10000000, 500000 }, // 100 Hz: 10.0000 +- 0.5ms
    .{ 8333333, 500000 }, // 120 Hz:  8.3333 +- 0.5ms
    .{ 6944445, 500000 }, // 144 Hz:  6.9445 +- 0.5ms
    .{ 4166667, 1000000 }, // 240 Hz:  4.1666 +- 1ms
};

/// This oddly named function takes a measured frame time and
/// returns the closest "nearby" common display refresh rate frame duration
/// in ticks. If the input duration isn't close to any common display
/// refresh rate, the input duration will be returned unchanged as a fallback.
/// The main purpose of this function is to remove jitter/inaccuracies from
/// measured frame times, and instead use the display refresh rate as
/// frame duration.
/// NOTE: for more robust frame timing, consider using the
/// sokol_app.h function sapp_frame_duration()
pub fn roundToCommonRefreshRate(frame_ticks: u64) u64 {
    for (refresh_rates) |pair| {
        const tns = pair[0];
        const tol = pair[1];
        if ((frame_ticks > (tns - tol)) and (frame_ticks < (tns + tol))) {
            return tns;
        }
    }
    // fallthrough: didn't fit into any buckets
    return frame_ticks;
}

/// tick value to seconds(f64)
pub fn sec(ticks: u64) f64 {
    const t: f64 = @floatFromInt(ticks);
    return t / 1_000_000_000.0;
}

/// tick value to milliseconds(f64)
pub fn ms(ticks: u64) f64 {
    const t: f64 = @floatFromInt(ticks);
    return t / 1_000_000.0;
}

/// tick value to microseconds(f64)
pub fn us(ticks: u64) f64 {
    const t: f64 = @floatFromInt(ticks);
    return t / 1_000.0;
}

/// tick value to nanoseconds(f64)
pub fn ns(ticks: u64) f64 {
    return @floatFromInt(ticks);
}
