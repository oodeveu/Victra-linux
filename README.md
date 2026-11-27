# Victra-linux

**Victra-linux** is a compatibility layer and wrapper designed to bring **VIctory** from Microsoft Windows to Linux, powered by **Proton**.

## Goals

The primary goal of this project is to allow Linux users to run **VIctory** seamlessly without relying on dual-boot setups or virtual machines. The project is built on three core pillars:

- **Compatibility:** Designed to run across any Linux distribution and support most builds/ports of **VIctory**.
- **Performance:** Aims to achieve at least 90% of native Windows framerate (FPS) performance.
- **Stability:** Engineered to introduce zero additional errors or crashes beyond any issues inherent to the underlying **VIctory** build itself.

## Current Progress

| Stage | Status | Notes |
| :--- | :---: | :--- |
| **Game Launch** | ✅ | Boots consistently within 10–20 seconds. |
| **Controller Support** | ✅ | Works with all gamepads via Steam Input (verified on DualShock 4). |
| **Main Menu** | ✅ | Locked 30 FPS with zero stuttering during intro and splash screens. |
| **Loading Screens** | ⚠️ | Occasional minor stutters with dips no lower than 15 FPS (matches Windows behavior). |
| **Opening Cutscenes** | ⚠️ | Severe bottleneck (~1–2 FPS, slideshow-level playback). Note: performance on this exact Windows build is already poor (3–5 FPS). |
| **Gameplay** | ❌ | Not yet reached. |

## Test Environment

All benchmarks and status checks listed above were recorded on the following hardware and software stack:

| Component | Specification |
| :--- | :--- |
| **Tested Build / Port** | `VIctory-NVIDIA` |
| **OS / Distribution** | Arch Linux |
| **Kernel** | `linux-zen` |
| **CPU** | AMD Ryzen 5 5600 |
| **GPU** | NVIDIA GeForce RTX 3060 |
| **RAM** | 32 GB DDR4 |
| **Compatibility Layer** | GE-Proton11-14 |

---

## Setup & Usage Guide

### 1. Prerequisites
* A Linux distribution with up-to-date GPU drivers (an up-to-date Vulkan-capable driver is recommended for NVIDIA GPUs).
* **Steam** (for managing Proton versions and controller mappings via **Steam Input**).
* **GE-Proton11-14** installed (e.g., via a tool such as `protonup-qt` or extracted manually to `~/.steam/root/compatibilitytools.d/` or `~/.local/share/Steam/compatibilitytools.d/`).
* Your **VIctory** build files (such as `VIctory-NVIDIA`).

### 2. Installing GE-Proton11-14
1. Download the **GE-Proton11-14** archive and extract it into Steam's compatibility tools directory:
   ```bash
   mkdir -p ~/.local/share/Steam/compatibilitytools.d
   tar -xzf GE-Proton11-14*.tar.gz -C ~/.local/share/Steam/compatibilitytools.d/
   ```
2. Restart **Steam** so it detects the new Proton build.

### 3. Adding the Game to Steam & Configuring Compatibility
1. In Steam, click **Add a Game** → **Add a Non-Steam Game...** and select the **VIctory** executable (`.exe`).
2. Right-click the added entry in your library → **Properties** → **Compatibility**.
3. Check **Force the use of a specific Steam Play compatibility tool** and select **GE-Proton11-14**.
4. Under **Controller**, verify **Steam Input** is enabled (especially when using controllers such as a DualShock 4).

### 4. Launching & Debugging
* Launch the game from Steam and allow **10–20 seconds** for startup (initial launch or shader compilation may take slightly longer).
* To collect Proton diagnostic logs if something goes wrong, add the following to **Launch Options** in Steam:
  ```bash
  PROTON_LOG=1 %command%
  ```
  The log file will be written to your home directory (`~/steam-<AppID>.log`).

### 5. Known Behavior & Notes
* **Loading Screens:** Brief stutters with dips down to around 15 FPS match behavior observed on Windows.
* **Opening Cutscenes:** Performance drops sharply (~1–2 FPS), reflecting poor performance on this specific build on Windows as well (3–5 FPS).
* **Gameplay:** This stage is still under active testing and development as wrapper support progresses further into the game.
