<div align="center">

# RbxShader
A robust, simple, and performant fragment shader engine, for everyone.

[![Last Commit](https://img.shields.io/github/last-commit/AnotherSubatomo/RbxShader/main)](https://github.com/AnotherSubatomo/RbxShader/commits/main/) [![Release version](https://img.shields.io/github/v/release/AnotherSubatomo/RbxShader?color=green)](https://github.com/AnotherSubatomo/RbxShader/releases/latest) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

</div>

The shader engine can run virtually any shader program that operates on a per-pixel basis, just like those on [Shadertoy](https://www.shadertoy.com/). Porting these programs are relatively easy due to their code structuring being similar. If you wish to test the abilities of this engine or understand how to write shader programs with this engine, you can use [any of the give example shader programs provided](https://github.com/AnotherSubatomo/RbxShader/blob/main/Shaders/), which are also ports of pre-existing shader programs in Shadertoy 😊.

If you have an eye for possible optimizations, or how the shader could be better in any way, please feel free to contribute as **this project is open-source and is open for contribution.**

#### Features
1. Multithreading - shader program rendering is divided among an amount of worker threads, which is specified by the user. *For practicality, this amount can only be a multiple of four.*

2. Interlacing - this is a rendering technique that intentionally skips over the rendering of some amount of rows & columns per frame. It is employed to double the percieved frame rate but also boost performance as skipping reduces the amount of computations done per frame, increasing the likelyhood of the frame budget being satisfied, therefore reducing FPS decrease.

3. Partial re-implementation of *common* GLSL functions - a library containing some of the common graphics-related math operations is provided along the engine. [_Swizzling_](https://en.wikipedia.org/wiki/Swizzling_(computer_graphics)) is not planned to be a feature of this library that is widely supported anytime in the future. As while it improves readability, the overhead from the additional function frame hurts overall performance.

4. Multiple shader buffer support (multipass) - a multipass system is provided by the engine; where the shader can go through function `bufferA`, `bufferB`, etc. before finally going through `mainImage`.

5. User input handling (mouse movement) - the mouses position within the shader's viewport is tracked every left-click on the viewport, and stops tracking when the button is let go or the mouse goes outside the viewport.

#### Features that are planned to be implemented:
- Texture channel sampling
- Frame interpolation (possible performance gains are yet to be evauated)
<br><br>
---

Read more about the engine through the [DevForum post](https://devforum.roblox.com/t/rbxshader-a-robust-shader-engine-for-everyone/2965460).

Learn more about the engine via the a [DevForum tutorial post](https://devforum.roblox.com/t/rbxshader-tutorial/2965555) or [documentations](docs/DOCUMENTATION.md).

---

## Getting Started
To build the place from scratch, use:

```bash
rojo build -o "RbxShader.rbxlx"
```

Next, open `RbxShader.rbxlx` in Roblox Studio and start the Rojo server:

```bash
rojo serve
```

For more help, check out [the Rojo documentation](https://rojo.space/docs).