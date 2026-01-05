// machine generated, do not edit

//
// sokol_glue.h -- glue helper functions for sokol headers
//
// Project URL: https://github.com/floooh/sokol
//
// Do this:
//     #define SOKOL_IMPL or
//     #define SOKOL_GLUE_IMPL
// before you include this file in *one* C or C++ file to create the
// implementation.
//
// ...optionally provide the following macros to override defaults:
//
// SOKOL_ASSERT(c)     - your own assert macro (default: assert(c))
// SOKOL_GLUE_API_DECL - public function declaration prefix (default: extern)
// SOKOL_API_DECL      - same as SOKOL_GLUE_API_DECL
// SOKOL_API_IMPL      - public function implementation prefix (default: -)
//
// If sokol_glue.h is compiled as a DLL, define the following before
// including the declaration or implementation:
//
// SOKOL_DLL
//
// On Windows, SOKOL_DLL will define SOKOL_GLUE_API_DECL as __declspec(dllexport)
// or __declspec(dllimport) as needed.
//
// OVERVIEW
// ========
// sokol_glue.h provides glue helper functions between sokol_gfx.h and sokol_app.h,
// so that sokol_gfx.h doesn't need to depend on sokol_app.h but can be
// used with different window system glue libraries.
//
// PROVIDED FUNCTIONS
// ==================
//
// sg_environment sglue_environment(void)
//
//     Returns an sg_environment struct initialized by calling sokol_app.h
//     functions. Use this in the sg_setup() call like this:
//
//     sg_setup(&(sg_desc){
//         .environment = sglue_environment(),
//         ...
//     });
//
// sg_swapchain sglue_swapchain(void)
//
//     Returns an sg_swapchain struct initialized by calling sokol_app.h
//     functions. Use this in sg_begin_pass() for a 'swapchain pass' like
//     this:
//
//     sg_begin_pass(&(sg_pass){ .swapchain = sglue_swapchain(), ... });
//
// LICENSE
// =======
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
const sg = @import("gfx.zig");
const sapp = @import("app.zig");
// helper function to convert a C string to a Zig string slice
fn cStrToZig(c_str: [*c]const u8) [:0]const u8 {
    return @import("std").mem.span(c_str);
}

fn sglue_to_sgpixelformat(fmt: sapp.PixelFormat) sg.PixelFormat {
    switch (fmt) {
        .NONE => return .NONE,
        .RGBA8 => return .RGBA8,
        .SRGB8A8 => return .SRGB8A8,
        .BGRA8 => return .BGRA8,
        .DEPTH_STENCIL => return .DEPTH_STENCIL,
        .DEPTH => return .DEPTH,
        else => unreachable,
    }
}

/// Returns an sg_environment struct initialized by calling sokol_app.h
/// functions. Use this in the sg_setup() call like this:
/// ```zig
/// sg.setup(&(sg.Desc){
///     .environment = sglue.environment(),
///     ...
/// });
/// ```
pub fn environment() sg.Environment {
    var res: sg.Environment = @import("std").mem.zeroes(sg.Environment);
    const env: sapp.Environment = sapp.getEnvironment();
    res.defaults.color_format = sglue_to_sgpixelformat(env.defaults.color_format);
    res.defaults.depth_format = sglue_to_sgpixelformat(env.defaults.depth_format);
    res.defaults.sample_count = env.defaults.sample_count;
    res.metal.device = env.metal.device;
    res.d3d11.device = env.d3d11.device;
    res.d3d11.device_context = env.d3d11.device_context;
    res.wgpu.device = env.wgpu.device;
    res.vulkan.physical_device = env.vulkan.physical_device;
    res.vulkan.device = env.vulkan.device;
    res.vulkan.queue = env.vulkan.queue;
    res.vulkan.queue_family_index = env.vulkan.queue_family_index;
    return res;
}

/// Returns an sg.Swapchain struct initialized by calling app.zig
/// functions. Use this in sg.beginPass() for a 'swapchain pass' like
/// this:
/// ```zig
/// sg.beginPass(&(sg.Pass){ .swapchain = sglue.swapchain(), ... });
/// ```
pub fn swapchain() sg.Swapchain {
    var res: sg.Swapchain = @import("std").mem.zeroes(sg.Swapchain);
    const sc: sapp.Swapchain = sapp.getSwapchain();
    res.width = sc.width;
    res.height = sc.height;
    res.sample_count = sc.sample_count;
    res.color_format = sglue_to_sgpixelformat(sc.color_format);
    res.depth_format = sglue_to_sgpixelformat(sc.depth_format);
    res.metal.current_drawable = sc.metal.current_drawable;
    res.metal.depth_stencil_texture = sc.metal.depth_stencil_texture;
    res.metal.msaa_color_texture = sc.metal.msaa_color_texture;
    res.d3d11.render_view = sc.d3d11.render_view;
    res.d3d11.resolve_view = sc.d3d11.resolve_view;
    res.d3d11.depth_stencil_view = sc.d3d11.depth_stencil_view;
    res.wgpu.render_view = sc.wgpu.render_view;
    res.wgpu.resolve_view = sc.wgpu.resolve_view;
    res.wgpu.depth_stencil_view = sc.wgpu.depth_stencil_view;
    res.vulkan.render_image = sc.vulkan.render_image;
    res.vulkan.render_view = sc.vulkan.render_view;
    res.vulkan.resolve_image = sc.vulkan.resolve_image;
    res.vulkan.resolve_view = sc.vulkan.resolve_view;
    res.vulkan.depth_stencil_image = sc.vulkan.depth_stencil_image;
    res.vulkan.depth_stencil_view = sc.vulkan.depth_stencil_view;
    res.vulkan.render_finished_semaphore = sc.vulkan.render_finished_semaphore;
    res.vulkan.present_complete_semaphore = sc.vulkan.present_complete_semaphore;
    res.gl.framebuffer = sc.gl.framebuffer;
    return res;
}
