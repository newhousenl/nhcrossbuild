import urllib.request
import gzip
import json
import os
import sys
import subprocess
import argparse

# Packages present in ALL supported versions (Debian 10 & 11) and ALL architectures (amd64, arm64).
COMMON_PACKAGES = [
    "adwaita-icon-theme", "dconf-gsettings-backend", "gettext",
    "libasound2", "libasound2-dev",
    "libatk1.0-0", "libatk1.0-dev", "libatk-adaptor",
    "libatk-bridge2.0-0", "libatk-bridge2.0-dev", "libatspi2.0-0", "libatspi2.0-dev",
    "libblkid1", "libblkid-dev",
    "libbrotli1", "libbrotli-dev",
    "libbz2-1.0", "libbz2-dev",
    "libc6", "libc6-dev",
    "libcairo2", "libcairo2-dev", "libcairo-gobject2", "libcairo-script-interpreter2",
    "libcolord2",
    "libcups2", "libcups2-dev",
    "libdbus-1-3", "libdbus-1-dev", "libdconf1",
    "libdrm2", "libdrm-amdgpu1", "libdrm-dev", "libdrm-nouveau2", "libdrm-radeon1",
    "libdw1", "libdw-dev",
    "libegl1", "libegl1-mesa", "libegl1-mesa-dev", "libegl-mesa0",
    "libelf1", "libelf-dev",
    "libepoxy0", "libepoxy-dev",
    "libexpat1", "libexpat1-dev",
    "libffi-dev",
    "libfontconfig1",  # runtime library (both versions)
    "libfreetype6",
    "libfribidi0", "libfribidi-dev",
    "libgdk-pixbuf2.0-0", "libgdk-pixbuf2.0-common",
    "libgl1", "libgl1-mesa-dev", "libgl1-mesa-glx", "libglapi-mesa",
    "libgles1", "libgles2", "libgles2-mesa", "libgles2-mesa-dev",
    "libglib2.0-0", "libglib2.0-bin", "libglib2.0-dev",
    "libglu1-mesa", "libglu1-mesa-dev",
    "libglvnd0", "libglvnd-core-dev", "libglvnd-dev",
    "libglx0", "libglx-mesa0",
    "libgraphite2-3", "libgraphite2-dev",
    "libgtk-3-0", "libgtk-3-common", "libgtk-3-dev",
    "libharfbuzz0b", "libharfbuzz-dev", "libharfbuzz-gobject0", "libharfbuzz-icu0",
    "libice6", "libice-dev",
    "libicu-dev",  # unversioned meta-dev (exists in both deb10 and deb11)
    "libjpeg62-turbo", "libjpeg62-turbo-dev",
    "libjson-glib-1.0-0",
    "libkmod2",
    "liblzma5", "liblzma-dev",
    "libmount1", "libmount-dev",
    "libopengl0",
    "libpango-1.0-0", "libpango1.0-dev",
    "libpangocairo-1.0-0", "libpangoft2-1.0-0", "libpangoxft-1.0-0",
    "libpciaccess0", "libpciaccess-dev",
    "libpcre2-8-0", "libpcre2-dev", "libpcre3", "libpcre3-dev",
    "libpixman-1-0", "libpixman-1-dev",
    "libpng16-16", "libpng-dev",
    "librest-0.7-0",
    "libseccomp2",
    "libselinux1", "libselinux1-dev",
    "libsepol1",
    "libsm6", "libsm-dev",
    "libssl1.1",
    "libstartup-notification0", "libstartup-notification0-dev",
    "libsystemd0",
    "libtiff5", "libtiff-dev",
    "libudev1", "libudev-dev",
    "libuuid1",
    "libwayland-bin", "libwayland-client0", "libwayland-cursor0", "libwayland-dev",
    "libwayland-egl1", "libwayland-egl-backend-dev", "libwayland-server0",
    "libx11-6", "libx11-dev", "libx11-xcb1", "libx11-xcb-dev",
    "libxau6", "libxau-dev",
    "libxcb1", "libxcb1-dev",
    "libxcomposite1", "libxcomposite-dev",
    "libxcursor1", "libxcursor-dev",
    "libxdamage1", "libxdamage-dev",
    "libxdmcp6", "libxdmcp-dev",
    "libxext6", "libxext-dev",
    "libxfixes3", "libxfixes-dev",
    "libxft2", "libxft-dev",
    "libxi6", "libxi-dev",
    "libxinerama1", "libxinerama-dev",
    "libxkbcommon0", "libxkbcommon-dev", "libxkbcommon-x11-0",
    "libxrandr2", "libxrandr-dev",
    "libxrender1", "libxrender-dev",
    "libxtst6", "libxtst-dev",
    "libxxf86vm1", "libxxf86vm-dev",
    "linux-libc-dev",
    "mesa-common-dev",
    "ocl-icd-libopencl1", "ocl-icd-opencl-dev", "opencl-c-headers",
    "shared-mime-info",
    "uuid-dev",
    "wayland-protocols",
    "x11proto-dev", "xkb-data", "xorg-sgml-doctools",
    "zlib1g", "zlib1g-dev",
]

# Packages specific to a Debian version (present in both amd64 and arm64 for that version).
VERSION_PACKAGES = {
    "10": [
        # GCC 8 is the default compiler in Debian 10 (Buster)
        "gcc-8", "gcc-8-base", "libgcc-8-dev",
        "libgcc1",      # renamed to libgcc-s1 in Debian 11
        "libffi6",      # replaced by libffi7 in Debian 11
        "libicu63",     # replaced by libicu67 in Debian 11
        # In Debian 10, libfontconfig1-dev is the real dev package
        "libfontconfig1-dev",
        "libfreetype6-dev",
        "libgdk-pixbuf2.0-dev",
    ],
    "11": [
        # GCC 10 is the default compiler in Debian 11 (Bullseye)
        "gcc-10", "gcc-10-base", "libgcc-10-dev",
        "libgcc-s1",    # replaces libgcc1 from Debian 10
        "libffi7",      # replaces libffi6 from Debian 10
        "libicu67",     # replaces libicu67 in Debian 11
        # In Debian 11, libfontconfig1-dev is a dummy; libfontconfig-dev has the real files
        "libfontconfig-dev",
        "libfreetype-dev",
        "libgdk-pixbuf-2.0-dev",
        # Proper vendor-neutral GL/GLES/EGL dev packages (Debian 11 libglvnd transition)
        "libgl-dev",
        "libgles-dev",
        "libegl-dev",
    ],
}

# Packages specific to a CPU architecture (present in both Debian 10 and 11 for that arch).
ARCH_PACKAGES = {
    "amd64": [
        "libdrm-intel1",  # Intel DRM support only available on x86
    ],
    "arm64": [],
}

DEBIAN_MIRRORS = {
    "10": "https://archive.debian.org/debian",
    "11": "https://deb.debian.org/debian",
}

DEBIAN_SUITES = {
    "10": "buster",
    "11": "bullseye",
}


def get_nix_hash(url):
    print(f"  Downloading and hashing {url}")
    try:
        safe_name = os.path.basename(url).replace("~", "_")
        result = subprocess.run(
            ["nix-prefetch-url", "--type", "sha256", "--name", safe_name, url],
            capture_output=True, text=True, check=True,
        )
        sha256_hex = result.stdout.strip()
        res = subprocess.run(
            ["nix-hash", "--type", "sha256", "--to-base64", sha256_hex],
            capture_output=True, text=True, check=True,
        )
        return f"sha256-{res.stdout.strip()}"
    except subprocess.CalledProcessError as e:
        print(f"Error hashing {url}: {e.stderr}", file=sys.stderr)
        return None


def fetch_package_list(version, arch):
    mirror = DEBIAN_MIRRORS[version]
    suite = DEBIAN_SUITES[version]
    url = f"{mirror}/dists/{suite}/main/binary-{arch}/Packages.gz"
    print(f"Fetching package list from {url}")
    with urllib.request.urlopen(url) as response:
        with gzip.GzipFile(fileobj=response) as unzipped:
            content = unzipped.read().decode("utf-8")

    packages = {}
    current_pkg = {}
    for line in content.splitlines():
        if not line.strip():
            if "Package" in current_pkg:
                packages[current_pkg["Package"]] = current_pkg
            current_pkg = {}
            continue
        if ":" in line:
            key, value = line.split(":", 1)
            current_pkg[key.strip()] = value.strip()
    return packages


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", choices=["10", "11"], required=True)
    parser.add_argument("--arch", default="amd64")
    parser.add_argument("--full", action="store_true", help="Include all system libraries and dev packages")
    args = parser.parse_args()

    version = args.version
    arch = args.arch
    json_path = os.path.join(
        os.path.dirname(__file__), "debsysroot", f"pkgs-deb{version}-{arch}.json"
    )

    existing_pkgs = {}
    if os.path.exists(json_path):
        with open(json_path, "r") as f:
            data = json.load(f)
            for pkg in data:
                existing_pkgs[pkg["name"]] = pkg

    available_pkgs = fetch_package_list(version, arch)
    mirror = DEBIAN_MIRRORS[version]

    if args.full:
        print("Running in FULL mode: filtering all system libraries...")
        def is_system_library(pkg_name, info):
            section = info.get("Section", "").lower()
            if section not in ["devel", "libdevel", "libs"]:
                return False
            
            # Exclude common non-C++ language bindings and large metadata/apps
            exclude_keywords = [
                "perl", "python", "java", "php", "ruby", "ocaml", "node-",
                "ghc-", "android-", "mingw-", "-doc", "-bin", "-samples", "-gcj"
            ]
            if any(k in pkg_name.lower() for k in exclude_keywords):
                return False
            return True

        library_packages = [n for n, info in available_pkgs.items() if is_system_library(n, info)]
        effective_packages = sorted(list(set(
            COMMON_PACKAGES 
            + VERSION_PACKAGES.get(version, []) 
            + ARCH_PACKAGES.get(arch, [])
            + library_packages
        )))
    else:
        effective_packages = (
            COMMON_PACKAGES
            + VERSION_PACKAGES.get(version, [])
            + ARCH_PACKAGES.get(arch, [])
        )

    # Validate all packages exist before doing any download work
    missing = [p for p in effective_packages if p not in available_pkgs]
    if missing:
        print(
            f"FATAL: The following packages were not found in the Debian {version} {arch} package list:",
            file=sys.stderr,
        )
        for p in missing:
            print(f"  - {p}", file=sys.stderr)
        sys.exit(1)

    updated_list = []
    for pkg_name in effective_packages:
        pkg_info = available_pkgs[pkg_name]
        pkg_url = f"{mirror}/{pkg_info['Filename']}"

        if pkg_name in existing_pkgs and existing_pkgs[pkg_name]["url"] == pkg_url:
            print(f"  Skipping {pkg_name} (up to date)")
            updated_list.append(existing_pkgs[pkg_name])
        else:
            sha256 = get_nix_hash(pkg_url)
            if sha256:
                updated_list.append({"name": pkg_name, "url": pkg_url, "sha256": sha256})
            else:
                print(f"FATAL: Failed to hash {pkg_name}", file=sys.stderr)
                sys.exit(1)

    with open(json_path, "w") as f:
        json.dump(updated_list, f, indent=2)
    print(f"Updated {json_path} ({len(updated_list)} packages)")


if __name__ == "__main__":
    main()
