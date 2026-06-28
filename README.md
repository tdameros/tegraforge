# TegraForge

Universal Linux_for_Tegra (L4T) BSP Builder for NVIDIA Jetson platforms.

Supports:

* JetPack 4
* JetPack 5
* JetPack 6
* JetPack 7 (future)

Features:

* Manifest-driven version management
* Automated BSP downloads
* Automated extraction
* Automated BSP preparation
* Docker-based reproducible builds
* Native Linux support
* Custom BSP packaging
* Board-specific file injection into `Linux_for_Tegra`
* Board-specific patches and hooks
* Future support for custom Device Trees, kernels and drivers

---

## Docker

### Build Image

```bash
docker build \
  --platform linux/amd64 \
  -t tegraforge:latest .
```

### Create Persistent Volumes

```bash
docker volume create tegraforge-build
```

### Run Container

```bash
docker run \
  --platform linux/amd64 \
  --privileged \
  -it \
  --rm \
  -v $(pwd):/workspace \
  -v tegraforge-build:/workspace/build \
  tegraforge:latest
```

The project source code remains on the host machine while build artifacts are stored in persistent Docker volumes.


## Project Layout

```text
workspace/
├── boards/
├── manifests/
├── scripts/
├── downloads/
├── build/
├── output/
└── README.md
```

## Manifest System

TegraForge uses manifests to manage JetPack versions without modifying scripts.

Manifest files are located in:

```text
manifests/
├── jp4.yaml
├── jp5.yaml
├── jp6.yaml
└── jp7.yaml
```

Each manifest contains:

* Available releases
* BSP URLs
* RootFS URLs
* Toolchain URLs (optional, per release)
* Source package URLs
* Default release

Example release entry with toolchain:

```yaml
releases:

  35.6.4:

    bsp:
      url: https://developer.nvidia.com/...
      filename: jetson_linux_r35.6.4_aarch64.tbz2

    rootfs:
      url: https://developer.nvidia.com/...
      filename: tegra_linux_sample-root-filesystem_r35.6.4_aarch64.tbz2

    toolchain:
      url: https://developer.nvidia.com/embedded/jetson-linux/bootlin-toolchain-gcc-93
      filename: aarch64--glibc--stable-final.tar.gz

    sources:
      url: https://developer.nvidia.com/...
      filename: public_sources.tbz2
```

The `toolchain` key is optional. If absent for a release, the download and extract steps skip it automatically.

## Download BSP Packages

### Download Default Release

```bash
./scripts/download.sh jp6
```

### Download Specific Release

```bash
./scripts/download.sh jp6 r36.4.4
```

### Download JetPack 5

```bash
./scripts/download.sh jp5
```

### Download JetPack 4

```bash
./scripts/download.sh jp4
```

### Download Result

```text
downloads/

└── jp6/
    └── r36.4.4/
        ├── bsp/
        ├── rootfs/
        ├── toolchain/     # only if defined in manifest
        └── sources/
```

## Extract BSP

### Extract Default Release

```bash
./scripts/extract.sh jp6
```

### Extract Specific Release

```bash
./scripts/extract.sh jp6 r36.4.4
```

### Extraction Result

```text
build/

└── jp6/
    └── r36.4.4/
        ├── Linux_for_Tegra/
        ├── toolchain/     # only if defined in manifest
        └── sources/
```

## Prepare BSP

Applies NVIDIA binaries to the root filesystem and prepares the BSP for customization or flashing.

### Prepare Default Release

```bash
./scripts/prepare.sh jp6
```

### Prepare Specific Release

```bash
./scripts/prepare.sh jp6 r36.4.4
```

### Preparation Result

```text
build/

└── jp6/
    └── r36.4.4/
        └── Linux_for_Tegra/
```

Prepared BSP location:

```text
build/jp6/r36.4.4/Linux_for_Tegra
```

## Package BSP

Generate a portable flash package.

### Package Default Release

```bash
./scripts/package.sh jp6
```

### Package Specific Release

```bash
./scripts/package.sh jp6 r36.4.4
```

### Package Result

```text
output/

└── jp6/
    └── r36.4.4/
        ├── flash-package.tar.gz
        ├── release.json
        └── README.md
```

The archive contains:

```text
Linux_for_Tegra/
release.json
README.md
```

## Manifest Management

### Change Default Release

Edit:

```bash
vim manifests/jp6.yaml
```

Example:

```yaml
default_release: r36.5.0
```

Then:

```bash
./scripts/download.sh jp6
```

will automatically use:

```text
r36.5.0
```

## Multi-Version Support

Multiple JetPack releases can coexist on the same workstation.

Example:

```bash
./scripts/download.sh jp5 r35.6.2

./scripts/download.sh jp6 r36.4.4

./scripts/download.sh jp6 r36.5.0
```

Result:

```text
downloads/

├── jp5/
│   └── r35.6.2/

└── jp6/
    ├── r36.4.4/
    └── r36.5.0/
```

## Typical Workflow

```bash
./scripts/download.sh jp6

./scripts/extract.sh jp6

./scripts/prepare.sh jp6

./scripts/patch.sh jp6 my-custom-board

./scripts/files.sh jp6 my-custom-board

./scripts/hooks.sh jp6 my-custom-board

./scripts/package.sh jp6
```

Generated package:

```text
output/jp6/r36.4.4/flash-package.tar.gz
```

This package can be copied to a native Linux machine for flashing.

## Board Customization

TegraForge supports board-specific customization through patches and hooks.

Board customizations are stored under:

```text
boards/

└── my-custom-board/
    ├── patches/
    ├── files/
    └── hooks/
```

Customizations are applied after BSP preparation and before packaging, in this order: `patch` → `files` → `hooks`.

### BSP Patches

Patch files allow modifying any file inside `Linux_for_Tegra`.

Patch files must use standard Git patch format:

```text
boards/

└── my-custom-board/
    └── patches/
        ├── 0001-pinmux.patch
        ├── 0002-gpio.patch
        └── 0003-can.patch
```

#### Apply Patches

Default Release:

```bash
./scripts/patch.sh jp6 my-custom-board
```

Specific Release:

```bash
./scripts/patch.sh jp6 r36.4.4 my-custom-board
```

#### Patch Workflow

Patches are:

1. Validated using `git apply --check`
2. Applied in lexical order
3. Applied from the root of `Linux_for_Tegra`

Supported targets include:

* Device Trees
* Flash configurations
* Bootloader files
* Kernel sources
* BSP configuration files
* Any file inside `Linux_for_Tegra`

### BSP Files

Files allow injecting static files directly into `Linux_for_Tegra` without writing a hook. The directory structure under `files/` is mirrored verbatim.

Directory layout:

```text
boards/

└── my-custom-board/
    └── files/
        └── rootfs/
            └── etc/
                └── motd
```

The file above is copied to `Linux_for_Tegra/rootfs/etc/motd`.

#### Copy Files

Default Release:

```bash
./scripts/files.sh jp6 my-custom-board
```

Specific Release:

```bash
./scripts/files.sh jp6 r36.4.4 my-custom-board
```

Force re-copy (even if already applied):

```bash
./scripts/files.sh -f jp6 r36.4.4 my-custom-board
```

#### Behavior

* Files are copied in lexical order.
* A `[WARN]` is printed when an existing file is overwritten.
* The step is skipped on subsequent runs unless `-f` is passed (idempotent by default).

### BSP Hooks

Hooks allow executing arbitrary shell scripts during BSP customization.

Directory layout:

```text
boards/

└── my-custom-board/
    └── hooks/
        ├── 10-create-user.sh
        ├── 20-install-service.sh
        └── 30-custom.sh
```

#### Run Hooks

Default Release:

```bash
./scripts/hooks.sh jp6 my-custom-board
```

Specific Release:

```bash
./scripts/hooks.sh jp6 r36.4.4 my-custom-board
```

#### Hook Environment

The following variables are automatically exported:

```text
ROOT
JETPACK
RELEASE
BOARD
BUILD_DIR
L4T_DIR
```

Hooks execute in lexical order:

```text
10-*.sh
20-*.sh
30-*.sh
...
```

#### Example Hook

Create a default user:

```bash
#!/usr/bin/env bash

set -euo pipefail

sudo "${L4T_DIR}/tools/l4t_create_default_user.sh" \
    --accept-license \
    -u tegra \
    -p tegra123 \
    -n jetson
```

Example custom rootfs modification:

```bash
#!/usr/bin/env bash

set -euo pipefail

echo "Welcome to TegraForge" \
    > "${L4T_DIR}/rootfs/etc/motd"
```

Hooks can be used to:

* Create default users
* Install services
* Modify rootfs contents
* Configure system settings
* Install board-specific files
* Execute custom BSP preparation logic
