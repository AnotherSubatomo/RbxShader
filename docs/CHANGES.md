
# Changes Since Last Release
Last release was over 6 months ago, `v1.5.3`.

#### Notice
Yes, the usage of Ethanthegrand14's CanvasDraw has been dropped in favor of a more minimal canvas API, which is specially built for the use case of this engine. The reason for this is simply because a lot of CanvasDraw's features simply aren't used, indirectly becoming bloatware.

#### General Changes
* Updated [`README.md`](/README.md) to be more informative of changes.
* Changed `default.project.json` to be the project file that contains the demo, and the project file for the package has now been renamed to `package.project.json`.
* The engine has now matured enough to be published as a package, therefore `wally*` files have been made.
* [`CHANGES.md`](/CHANGES.md) has been made to keep track of all the changes since last release.

* Optimized local function `IsAVector4()` at the [Vector4](src/Vector4.luau) library.
* Cleaned up and updated some types at [`Common.luau`](src/utils/Common.luau).
* Added `OriginOffset` as an engine configuration. It is a unit Vector2 that describes where on the screen is the origin point. Its default value is `(0, 1)`, bottom-left in other words (this is an OpenGL convention).
* Added `CountDirection` as an engine configuration. It is a unit Vector2 that describes where the pixel coordinate counts upwards to. If `X` is positive, then the `X` counts upwards towards the right-side, and vice-versa. If 'Y' is positive, then the 'Y' counts upwards towards the bottom of the screen, and vice-versa.
* The aforementioned configurations are meant to resolve OpenGL shader port compatability issues when it came to pixel mapping, which I discovered and faced while adding the *four new shader examples*.

* Added four new shader examples, namely:
	`Plasma` by *[@Xor](https://shadertoy.com/user/Xor)*,
	`ZippyZaps` by *[@SnoopethDuckDuck](https://shadertoy.com/user/SnoopethDuckDuck)*,
	`ShootingStars` by *[@Xor](https://shadertoy.com/user/Xor)*,
	and `Currents` by *[@s23b](https://shadertoy.com/user/s23b)*.

* Re-ordered the parameters of the Shader constructor to represent its priorities better.

#### At [`Canvas.luau`](src/Canvas.luau)
* Refined type definitions.
* Redefined Canvas constructor to be a pure constructor. To set the initial color and alpha content of the canvas, the new `:Fill()` method should be used.
* Fragment coordinate can now be cached onto the canvases. Since fragment coordinates assigned to the pixels of a canvas don't change over time, we can calculate them all at once, and fetch them whenever they're needed during operations. As a consequence, two new methods have been introduced, `:RecalculateVirtualPixelMapping()` and `:GetVirtualPosition()`.

#### At [`Worker.client.luau`](src/Worker.client.luau)
* Changed comment stylization, section-marking comments are not denoted with `#` at the beginning.
* Proper type references to `Common.luau` are finally possible and have been made. This is all thanks to the aformentioned project file JSON restructuring.
* Fixed an embarassing oversight with the implementation of shader buffers, meaning it never worked in the first place. How TF did I do that?
* `PerFrame` variable has been renamed to `Renderer`, as it fit the use more.
* Renamed action `Initialize` to `SetContext`, as the action is meant to set the environment context that the worker threads act for.
* Reorganized the parameters of actions `SetContext` and `MakeCanvas` to purely represent their action names. These changes obviously cascade to whose responsible for what variable/function.
* Reorganized `RunProgram()`'s internal logic.

#### At [`init.luau`](src/init.luau)
* `iMouse` SharedTable and culler references are now properly garbage collected when shaders are cleared via `:Clear()`
* Optimized the disconnection of the Mouse.Move connection by reusing the responsible function.
* Calling for the action `SetContext` to all workers is now done first before the `MakeCanvas` action.

---

Cummulatively, these changes make up `v1.8.5`.

*A fact I discovered during development is that the amount of RAM currently available for system influences the performance of the shader system. What I think the reason behind this is that some of the resources allocated by the engine through Roblox, due to tight RAM budget, actually lives in the virtual RAM rather than real RAM. Obviously, memory access here are slower than actual RAM, the slowdown obviously cascades to Roblox and to our engine.*

*This discovery took place when I was watching the FPS while a shader was running. I the FPS was fewer than before, despite the shader being the same unchanged shader I ran a moment ago. I recalled that before this, a lot of Chrome tabs were inactive. So I closed the entire window, re-ran the shader, and **voila**, back to normal FPS.*