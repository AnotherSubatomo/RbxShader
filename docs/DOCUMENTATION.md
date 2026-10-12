# RbxShader Documentation


0. [Installation](#installation)
1. [Main Library](#main-interface)
3. [Graphics Library](#graphics-library)
4. [Input Library](#input-library)

*Up-to-date with `3.0.0-rc.1`*

---

## Installation
Here's a breif guide how to install `RbxShader` in various contexts.

#### a. In-experience integration
1. Download the attached `.rbxm` file from the [latest release](https://github.com/AnotherSubatomo/RbxShader/releases/latest).
2. Insert the file into the experience of your choice at `ReplicatedStorage` *strictly*.

#### b. Manual repository integration
1. Download the attached `.zip` file from the [latest release](https://github.com/AnotherSubatomo/RbxShader/releases/latest).
2. Open the ZIP file, select the `src` folder, then extract it to your repository.

#### c. Repository integration via Wally
1. Make sure your repository has a `wally.toml` file; if not, create one either manually or via `wally init` on your terminal.
2. Within this file, write `rbxshader = "anothersubatomo/rbxshader@[VERSION]"` under your `[dependencies]` table. (make no mistake in replacing `[VERSION]` with the version of your choice&mdash;*preferably the latest version*)
2. Pop the terminal, type `wally install`, and hit enter.

---

## Main API
The interface to this system is as simple as it can be to get your shader programs up and running while maintaining a level of control. Here are 9 methods, from the most relevant to the least.

### new()
Creats a new **shader context**. This function can error if:
1. `Resolution` is missing or of incorrect datatype.
2. `Resolution` is less than the minimum (32 by 32).
3. 

```luau
new(ShaderModule: ModuleScript, Host: Script, Resolution: Vector2, GivenConfiguration: LooseEngineConfiguration?): (ShaderContext)
```

* `ShaderModule: ModuleScript` - The module that contains the source code of the shader program.
* `Host: Script` - 
* `Resolution: Vector2` - 
* `GivenConfiguration: LooseEngineConfiguration?` - 

> [!NOTE]
> A **shader context**  is a table that represents the runtime context and environment which a given shader program runs on. It holds data crucial for the control of shader processes, such as the engine configurations the shader process follows, the `Actor`, `LocalScript`, and `EditableImage` instances that run and represent this process, the resolution the shader runs on, and its unique runtime ID.

---

## Graphics Library API

* introduce usage
* elaborate API

---

## Input Library API

* introduce usage
* elaborate API
