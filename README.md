# RbxShader
A robust shader engine, for everyone

*As of May 10, 2024, the shader only contains a fragment shader (which doesn't support buffers).

The shader can run virtually any shader program that can run on [Shadertoy](https://www.shadertoy.com/), and porting is relatively easy due to their code structuring being !
similar. If you wish to test the abilities of this shader, you can use the [sample shader program provided](https://github.com/AnotherSubatomo/RbxShader/blob/main/Shaders/VoxelShader.lua), which are also ports of pre-existing shader programs in Shadertoy 😊.

If you have an eye for possible optimizations, or how the shader could be better in any way, please feel free to contribute as **this project is open-source and is open for contribution.**

#### The shader features/provides:
- The ability to interlace your renders
- Partial reimplementation of GLSL functions (no [_swizzling_](https://en.wikipedia.org/wiki/Swizzling_(computer_graphics)) tho)
- Multithreading

#### Features that are planned to be implemented:
- Support for multiple buffers
- User input handling
- Make rendering go brr
<br><br>
---

<br>Learn how to use the module here: https://devforum.roblox.com/t/...
