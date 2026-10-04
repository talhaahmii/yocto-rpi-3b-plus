# Yocto Raspberry Pi 3B+

Yocto Project development environment for building a Linux image for the Raspberry Pi 3B+.

The project uses Docker so that the Yocto build environment is isolated from the host system and can be reproduced on another development machine.

## Project Status

Current target:

* Board: Raspberry Pi 3B+
* Yocto release: Wrynose / Yocto 6.0
* BitBake: 2.18
* Machine: `raspberrypi3-64`
* Image: `core-image-minimal`
* Container: Ubuntu 24.04
* Host development environment: Docker

> This project is currently being developed. Some setup steps are still being converted into a fully reproducible automated setup.

---

## 1. Directory Structure

```text
yocto-rpi3bplus/
├── docker/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── start.sh
│
├── sources/
│   ├── bitbake/
│   ├── meta-raspberrypi/
│   ├── meta-yocto/
│   └── openembedded-core/
│
├── build/                 # Generated Yocto build directory (not committed)
├── downloads/             # Downloaded source archives (not committed)
├── sstate-cache/          # Shared Yocto build cache (not committed)
├── bitbake-builds/        # bitbake-setup generated files (not committed)
├── bitbake-setup-venv/    # Python virtual environment (not committed)
├── .gitignore
└── README.md
```

Large generated files and build caches are intentionally excluded from Git.

---

# 2. Requirements

A Linux development machine is recommended.

The current development machine uses:

* Ubuntu 24.04
* x86_64 CPU
* Docker
* Git

A significant amount of disk space is required for Yocto builds.

The build can consume tens of gigabytes of disk space.

---

# 3. Clone the Project

On a new development machine:

```bash
git clone <GITHUB_REPOSITORY_URL>
cd yocto-rpi3bplus
```

The Git repository contains the Docker environment and project configuration.

The large Yocto source trees and build output are not stored directly in this repository.

---

# 4. Docker Environment

The Docker environment is defined in:

```text
docker/Dockerfile
docker/docker-compose.yml
docker/start.sh
```

The Dockerfile creates an Ubuntu 24.04 environment with the packages required for Yocto development.

The container also creates a `yocto` user using the host user's UID/GID.

This prevents permission problems when the project directory is mounted into the container.

---

## 4.1 Build the Docker Image

From the project root:

```bash
./docker/start.sh build
```

This builds the Docker image defined by `docker/Dockerfile`.

---

## 4.2 Enter the Yocto Container

From the project root:

```bash
./docker/start.sh run --rm yocto bash
```

After entering the container:

```bash
cd /workspace
```

The project directory on the host is mounted at:

```text
/workspace
```

---

# 5. Python Virtual Environment

The project currently uses a Python virtual environment for `bitbake-setup`.

Create it inside the container:

```bash
python3 -m venv --clear ./bitbake-setup-venv
```

Activate it:

```bash
source /workspace/bitbake-setup-venv/bin/activate
```

Install `bitbake-setup`:

```bash
pip install bitbake-setup
```

Check the installation:

```bash
bitbake-setup --version
```

The Python virtual environment is only for the `bitbake-setup` utility.

Yocto/BitBake itself does not require this Python virtual environment.

---

# 6. Yocto Source Repositories

The current project uses the following repositories:

```text
openembedded-core
bitbake
meta-yocto
meta-raspberrypi
```

Current branches:

```text
openembedded-core   wrynose
meta-yocto          wrynose
meta-raspberrypi    wrynose
bitbake             2.18
```

The repositories are stored under:

```text
/workspace/sources/
```

Example clone commands:

```bash
git clone -b wrynose https://git.openembedded.org/openembedded-core sources/openembedded-core

git clone -b wrynose https://git.yoctoproject.org/meta-yocto sources/meta-yocto

git clone -b wrynose https://git.yoctoproject.org/meta-raspberrypi sources/meta-raspberrypi

git clone -b 2.18 https://git.openembedded.org/bitbake sources/bitbake
```

> These commands are currently manual. The project will later use pinned revisions and an automated setup script for stronger reproducibility.

---

# 7. Initialize the Yocto Build Environment

Enter the container first.

Then:

```bash
cd /workspace/sources/openembedded-core
```

Initialize the build environment:

```bash
source oe-init-build-env /workspace/build
```

This creates:

```text
/workspace/build/
├── conf/
├── downloads/
├── sstate-cache/
└── tmp/
```

The shell is now configured for Yocto development.

---

# 8. Configure the Raspberry Pi Machine

The Raspberry Pi 3B+ 64-bit machine is:

```text
raspberrypi3-64
```

Edit:

```bash
nano /workspace/build/conf/local.conf
```

Set:

```text
MACHINE ??= "raspberrypi3-64"
```

Verify:

```bash
bitbake -e | grep '^MACHINE='
```

Expected:

```text
MACHINE="raspberrypi3-64"
```

---

# 9. Add Required Layers

Check the current layers:

```bash
bitbake-layers show-layers
```

Add the Raspberry Pi layer:

```bash
bitbake-layers add-layer /workspace/sources/meta-raspberrypi
```

Add the Poky layer:

```bash
bitbake-layers add-layer /workspace/sources/meta-yocto/meta-poky
```

Verify:

```bash
bitbake-layers show-layers
```

The current configuration should contain:

```text
core
yocto
raspberrypi
```

---

# 10. Build the Image

The current test image is:

```text
core-image-minimal
```

Build it with:

```bash
bitbake core-image-minimal
```

The build can take a long time, especially the first time.

Keep the terminal running while BitBake is working.

---

# 11. Check Whether the Build Finished

A successful build should produce output under:

```text
/workspace/build/tmp/deploy/images/raspberrypi3-64/
```

Check:

```bash
ls -lah /workspace/build/tmp/deploy/images/raspberrypi3-64/
```

You should eventually see Raspberry Pi image and boot files.

You can also check the end of the BitBake output for a summary indicating that the build completed successfully.

---

# 12. If the Machine Reboots During a Build

Do not immediately delete the build directory.

Yocto stores downloaded sources and build state that can be reused.

After reboot:

1. Start Docker.
2. Enter the project directory.
3. Enter the container.
4. Reinitialize the Yocto environment.
5. Run the same BitBake command again.

For example:

```bash
cd ~/yocto-rpi3bplus
./docker/start.sh run --rm yocto bash
```

Then:

```bash
cd /workspace/sources/openembedded-core
source oe-init-build-env /workspace/build
```

Then:

```bash
bitbake core-image-minimal
```

BitBake should reuse available downloads and sstate data and continue the build rather than starting completely from zero.

---

# 13. Important Build Directories

The current build directory is:

```text
build/
```

Important subdirectories:

```text
build/downloads/
```

Downloaded source archives.

```text
build/sstate-cache/
```

Reusable shared-state build cache.

```text
build/tmp/
```

Main generated build output and work directory.

```text
build/tmp/deploy/images/raspberrypi3-64/
```

Final Raspberry Pi image output.

Do not commit these directories to Git.

---

# 14. Git Workflow

Check the project status:

```bash
git status
```

Check changed files:

```bash
git status --short
```

Add files:

```bash
git add <file>
```

Create a commit:

```bash
git commit -m "Description of change"
```

View commits:

```bash
git log --oneline
```

Push to GitHub:

```bash
git push
```

Large Yocto build output should never be committed to the repository.

---

# 15. Docker Commands

Build/rebuild the container:

```bash
./docker/start.sh build
```

Enter the container:

```bash
./docker/start.sh run --rm yocto bash
```

Run a command inside the container:

```bash
./docker/start.sh run --rm yocto <command>
```

For example:

```bash
./docker/start.sh run --rm yocto git --version
```

---

# 16. Useful Yocto Commands

Show BitBake version:

```bash
bitbake --version
```

Show active layers:

```bash
bitbake-layers show-layers
```

Show the current machine:

```bash
bitbake -e | grep '^MACHINE='
```

Show available recipes:

```bash
bitbake-layers show-recipes
```

Build an image:

```bash
bitbake core-image-minimal
```

---

# 17. Current Project Goal

The long-term goal of this project is to create a custom Yocto Linux distribution for the Raspberry Pi 3B+.

Planned areas include:

* Minimal Raspberry Pi Linux image
* Custom Yocto layers
* Custom device tree / DTS configuration
* Hardware configuration
* OTA updates
* USB-based upgrade
* Recovery / fallback system
* Reproducible development environment
* Reproducible source revisions
* Automated project setup

These features will be added incrementally as the project develops.

---

# 18. Reproducibility

The project intentionally separates:

**Source/configuration that belongs in Git**

from:

**Generated build data that does not belong in Git.**

The repository should eventually contain everything necessary to recreate the development environment and configure the Yocto build without committing gigabytes of generated data.

The current next step is to create an automated source/setup configuration with pinned repository revisions.

---

## License

Project-specific licensing information will be added later.
