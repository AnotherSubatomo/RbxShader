
# Changes Since Last Release
Last release was over eight months ago, `v1.8.5`.

> Quick Disclaimer (For previous users):
> This is not the same RbxShader you knew at v1.8.5.
> The entire API has changed; please read the logs and relevant documentation thoroughly.

### General Changes
* [x] Every file now has the directives `--!strict`, `--!optimize 2` and `--!native` by default.
* [x] The engine now uses the `vector` datatype (rather than their Roblox counterpart, `Vector3` and `Vector2`) by default for shader-related operations.
* [x] Every shader program examples now also use `vector` rather than their Roblox counterpart.
* [x] Removed support for the custom datatype `Vector4`. [^1]
* [ ] Implemented input channels via the `Input` library. [^2] 
* [x] Optimized various shader program examples (especially the old ones).
* [x] Updated README.md to reflect the feature changes.
* [ ] Completion of `DOCUMENTATION.md`. Necessary updates to the [*DevForum tutorial*](https://devforum.roblox.com/t/rbxshader-tutorial/2965555) will soon be made.

### Repository / Structural Changes
* Re-organized [`src`](/src/) such that it now bears two child folders (namely `lib` and `sys`), `common.` and the `Worker.client` file.
* `utils` has been destructured, as the removal of the `Argue` module has made the folder obsolete. It's remaining child, `common`, is now a child of `src`.
* `client` has been renamed to `demo`, as its previous name seemed to imply that its contents were a necessity rather than an example.
* `Canvas` and `Culler` are relocated to the `sys` folder.
* `GraphicsMathLib` has been renamed to `Graphics` and relocated to the `lib` folder, along with&mdash;

#### At [`src/init.luau`](/src/init.luau)
This file has been completely rewritten as an attempt to improve readability, as well as to resolve unwanted behavior and side-effects brought by some methods that are inherent to their implementation.

* Removed restrictions on the usage of shaders for the server-side; but consequently made the culling of shaders parented to `BillboardGui` or `SurfaceGui`'s as manual work.
* Renamed `.run()` to `.start()` in order to semantically match `.stop()`. 
* Removed a stupid line that probably prevented you from running multiple shader program. :facepalm:
* Raised minimum shader resolution from "4 by 4" to a more practical "32 by 32".
* Removed `:GetMathLib()` as a method of RbxShader. To access the graphics math library, it is recommended that you directly require it instead.
* Added `ReconcileConfiguration()` which constructs a new and stable `EngineConfiguration` based on the given, the built-in, and the default. This function not only eliminates bugs that may arise from working with unresolved configuration conflicts, but also a side-effect that rewrites the contents of the given configs at `.new()` and `.set()`.

#### At [`Common.luau`](/src/util/Common.luau)
* Renamed type `ShaderBuffer` to `FragmentOperator` as it is a more beffiting name.
* Updated type definition `Shader` to include the new `CHANNELS` field.
* Generalized the `fragCoords` parameter type of the `FragmentOperator` type to accomodate to the environment `Sampler3D` has.

#### At [`Worker.client.luau`](/src/Worker.client.luau)
* `iMouse` is now converted into a `vec2` instead of a SharedTable&mdash;I don't know why I didn't think of this earlier.
* Made `iMouse` account for the `OriginOffset` and `CountDirection`&mdash;something I embarassingly forgot to implement last release.
* Added sanity checks to thread actions relevant to rendering like `Start`, `Stop`, `Pause`, etc.
* Renamed `RunProgram()` to `ConnectRenderer()`, to aptly reflect its functionality.
* Renamed thread action `SetContext` to `Init`, to aptly reflect its functionality.
* Relocated shader buffer fetching and `iMouse` object fetching from `ConnectRenderer()` to the `Init` action, as these objects will always return the same output and fit the idea of the "program context initialization".
* Removed single-axis interlacing as an option&mdash;making dual-axis interlacing the default (interlacing can still be disabled by setting `InterlaceFactor` to 1).
* Switched the interlacer's logical orientation to be column-major, as it seems shows greater visual videlity.
* Optimized `iDate` update behavior.

### At [`GraphicsMath.luau`](/src/lib/GraphicsMath.luau)
* Optimized and rewrote all functions in a way such that inling its functions into your module is as easy as copying and pasting it. 
* Removed fields from the library that pointed to functions from the global `math` library, as not only are they unsupported by auto-complete and the typechecker, but also seemed to only slow down the shader.
* Added `vec2_mat2`, a function that multiplies a `vec2` to a `mat2`, given its two columns (formatted as `vec2`s; be very careful in contructing this).

### At [`Canvas.luau`](/src/sys/Canvas.luau)
* Rewritten to be more data-oriented.

---

Cummulatively, these changes make up `v3.0.0-rc.1`.

#### Wait, we just skipped a major version level; why is that?
Well, that's because `1.8.5` should've been called `2.0.0` due to the backwards-incompatible changes it brought. How did I make this mistake? Well, at that time I didn't know any better and how semantic versioning really worked up until a few weeks later its release. This skipping is done to formally correct this mistake, and to radically symbolize how much the project grown since its conception.

[^1]: It was just too computationally unfeasable for any productive shader. I recommend working with `vector`s purely for better performance, and try to avoid having to return an alpha value as much as possible. In fact, most of the time, shaders don't even care about the alpha channel.

[^2]: I have realized that my implementation of Shadertoy's `buffers` were wrong, and that they are actually similar to a Sampler2D but differ in the aspect of being dynamic (i.e. it's values are recalculated every single frame, the same way how the `mainImage` function works) rather than being static. This has been corrected with the implementation of this new library called `Input`. It will be responsible for handling *input channels*, which are used for sampling: static textures *(Sampler2D)*, static volumes *(Sampler3D)*, and keyboard *(also a Sampler2D)* inputs.