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
* Future support for custom Device Trees, kernels and drivers

---

## Docker

### Build Image

```bash
docker build \
  --platform linux/amd64 \
  -t tetraforge:latest .
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
  tetraforge:latest
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
* Source package URLs
* Default release

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
        └── Linux_for_Tegra/
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

./scripts/package.sh jp6
```

Generated package:

```text
output/jp6/r36.4.4/flash-package.tar.gz
```

This package can be copied to a native Linux machine for flashing.
