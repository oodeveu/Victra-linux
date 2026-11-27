# VIctory-linux

An experimental launcher script and guide that builds and runs **VIctory** (including its forks and builds) on Linux through **GE-Proton** (Wine + vkd3d-proton, D3D12 → Vulkan).

This repository contains **only a shell script and documentation**. It does not include the game, any game files, or the VIctory source code. You need your own copy of the game.

> **Status: experimental.** Compatibility and performance vary depending on the VIctory build/fork, GPU, and system setup. See [Current status](https://www.google.com/search?q=%23current-status).

## What it does

`run.sh`:

* builds `victory.exe` for `x86_64-pc-windows-gnu` (mingw cross-compilation),
* creates the Wine prefix, cache and data directories,
* sets the `VICTORY_*` and `VKD3D_*` environment variables,
* launches the game through GE-Proton.

## Current status

| Stage | Status | Notes |
| --- | --- | --- |
| Cross-build with mingw | ✅ | Builds with the toolchain pinned by your VIctory repository/fork. |
| Game launch | ✅ | Starts and renders through vkd3d-proton. |
| Texture quality | ⚠️ | Models stayed at the lowest detail until `VICTORY_CARD_REHASH_RUNS=0` was set. |
| Frame rate | ❌ | About 1 FPS, GPU nearly idle on the reference test machine. Cause not yet identified. |
| Gameplay | ❌ | Not yet playable on the reference test machine. |
| Controller support | ❓ | Not tested. |

On the reference test machine, the GPU stays cold (about 47 °C on an RTX 3060) while the game is running, which points to a CPU-side or synchronization bottleneck rather than a GPU one. It is not yet known whether the cause is Proton, the settings, or the game's translation layer. Testing the same build on native Windows is the planned way to tell them apart.

## Test environment

| Component | Specification |
| --- | --- |
| Build | VIctory (`diag` profile, `--features diagnostics`) |
| OS | Linux (distribution: Arch Linux x86_64) |
| Kernel | linux_zen |
| CPU | AMD Ryzen 5 5600 |
| GPU | NVIDIA GeForce RTX 3060 |
| RAM | 32 GB |
| Compatibility layer | GE-Proton11-14 |
| Other | `ntsync` enabled |

## Requirements

* A recent NVIDIA driver with Vulkan support.
* [GE-Proton](https://github.com/GloriousEggroll/proton-ge-custom) (tested with GE-Proton11-14), extracted into a Steam compatibility tools directory, e.g. `~/.local/share/Steam/compatibilitytools.d/`.
* [rustup](https://rustup.rs/) and a mingw-w64 cross-compiler.
* Arch Linux: `sudo pacman -S rustup mingw-w64-gcc`


* A checkout of your **VIctory** repository or fork.
* Your own game files, prepared as VIctory expects (a directory containing `game_scarlett_master.exe`).
* Optional: a native `d3dcompiler_47.dll`. Without it Wine may reject helper shaders.
* At least 32 GB of RAM is recommended. The game can use 24–30 GB.

## Setup

1. Clone your VIctory repository/fork and this repository:
```bash
git clone <victory-repo-url>
git clone <this-repo-url>

```


2. Set the required variables (there are no defaults):
```bash
export VICTORY_REPO=/path/to/victory
export VICTORY_GAME_ROOT=/path/to/game
export PROTON_DIR=$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton11-14-x86_64
export VICTORY_COMPILER_DLL=/path/to/d3dcompiler_47.dll   # optional

```


3. Check the configuration:
```bash
./run.sh --check

```


4. Build, then start:
```bash
./run.sh build
./run.sh

```



On the first run `run.sh` copies `victory.example.toml` to `victory.toml` in the VIctory directory if it is missing (when provided by your build/fork). Edit it to point at your game files, using Windows-style paths (Wine maps `/` to `Z:`).

## Usage

```text
./run.sh                     build (if needed) and start the game
./run.sh --no-build          start without building
./run.sh build               build only
./run.sh victory <args...>   run victory.exe with arbitrary arguments
./run.sh --check             verify the configured paths
./run.sh --series-x          use the Series X profile instead of Series S

```

### Configuration

| Variable | Required | Description |
| --- | --- | --- |
| `VICTORY_REPO` | yes | Path to the VIctory repository or fork checkout. |
| `VICTORY_GAME_ROOT` | yes | Working directory for the prefix, caches and data. |
| `PROTON_DIR` | yes | GE-Proton directory (contains the `proton` script). |
| `VICTORY_STAGE` | no | Directory with `game_scarlett_master.exe` (default: `$VICTORY_GAME_ROOT/victory-win`). |
| `VICTORY_PREFIX` | no | Wine prefix (default: `$VICTORY_GAME_ROOT/victory-prefix`). |
| `VICTORY_COMPILER_DLL` | no | Native `d3dcompiler_47.dll`. |
| `VICTORY_BUILD` | no | Cargo profile: `diag` (default) or `release`. |
| `VICTORY_CONSOLE` | no | `series-s` (default) or `series-x`. |
| `VICTORY_EXTRA` | no | Extra settings, e.g. `"VICTORY_MAP_THREADS=4 VICTORY_THIN=0"`. |
| `VICTORY_LAUNCH` | no | Set to `wine` to run via `runinprefix` so stdout reaches the terminal. |

### Shader preparation

VIctory builds may translate shaders on the fly, which is very slow on a fresh build. If your build/fork supports pre-warming or shader commands, run them through the script:

```bash
./run.sh victory warm --used

```

Check your specific VIctory build or fork documentation for the exact arguments supported by `shaders` and `warm`.

## Debugging

Logging is quiet by default, because thousands of Wine log lines per second slow the game down. For diagnostics:

```bash
WINEDEBUG=err+all VICTORY_LOG=info VICTORY_LAUNCH=wine ./run.sh --no-build

```

The game log is written to `~/.local/share/victory.log` (override with `VICTORY_LOG_FILE`).

Useful checks while the game is running slowly:

```bash
nvidia-smi dmon -s um                    # GPU utilization and memory
ps -eLo pid,tid,pcpu,comm --sort=-pcpu | head -25   # busiest threads
free -h                                  # RAM and swap

```

## Known issues

* Very low frame rate in the world on the reference test machine; cause unknown and may vary across VIctory builds/forks.
* `VICTORY_CARD_REHASH_RUNS` must be `0` or models stay at the lowest detail (already set in the script).
* Wine does not implement `NtQueryVirtualMemory` information class 7 and logs a `fixme` for it. Harmless on its own, but it floods the log when `WINEDEBUG` is not silenced.
* Some default settings used here were chosen for Windows and high-end GPUs and may not be optimal under Proton across all VIctory builds.

## Contributing

Reports are welcome, especially:

* results from different VIctory builds/forks, GPUs, and Linux distributions,
* a comparison of the same build on native Windows and on Linux,
* the per-second timing line the game prints (GPU / preparing / copying back).

## Credits and legal

* **VIctory** and its forks/builds (including Marvisak/VIctory and community forks such as Vice-Tay). The `VICTORY_*` defaults in `run.sh` are based on upstream script conventions.
* [GE-Proton](https://github.com/GloriousEggroll/proton-ge-custom) by GloriousEggroll.
* [vkd3d-proton](https://github.com/HansKristian-Work/vkd3d-proton) and [Wine](https://www.winehq.org/).

This project is not affiliated with any of the above. It does not distribute game files or Microsoft binaries. You must supply your own legally obtained copy of the game.

## License

The script and documentation in this repository are released under the MIT License (add a `LICENSE` file). VIctory, its forks, and the other projects above keep their own licenses.
