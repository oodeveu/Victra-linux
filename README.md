# Victra-linux

# Overview

**Victra-linux** is a compatibility layer and wrapper designed to bring **VIctory** from Microsoft Windows to Linux, powered by **Proton**.

## Goals

The primary goal of this project is to allow Linux users to run **VIctory** seamlessly without relying on dual-boot setups or virtual machines. The project is built on three core pillars:

* **Compatibility:** Designed to run across any Linux distribution and support most builds/ports of **VIctory**.
* **Performance:** Aims to achieve at least 90% of native Windows framerate (FPS) performance.
* **Stability:** Engineered to introduce zero additional errors or crashes beyond any issues inherent to the underlying **VIctory** build itself.

## Current Progress

| Stage | Status | Notes |
| :--- | :---: | :--- |
| **Game Launch** | ✅ | Boots consistently within 10–20 seconds. |
| **Controller Support** | ✅ | Works with all gamepads via Steam Input (verified on DualShock 4). |
| **Main Menu** | ✅ | Locked 30 FPS with zero stuttering during intro and splash screens. |
| **Loading Screens** | ⚠️ | Occasional minor stutters with dips no lower than 15 FPS (matches Windows behavior). |
| **Opening Cutscenes** | ⚠️ | Severe bottleneck (~1–2 FPS, slideshow-level playback). |
| **Gameplay** | ❌ | Not yet reached. |

## Test Environment

All benchmarks and status checks listed above were recorded on the following hardware and software stack:

| Component | Specification |
| :--- | :--- |
| **OS / Distribution** | Arch Linux |
| **Kernel** | `linux-zen` |
| **CPU** | AMD Ryzen 5 5600 |
| **GPU** | NVIDIA GeForce RTX 3060 |
| **RAM** | 32 GB DDR4 |
| **Compatibility Layer** | GE-Proton11-14 |
