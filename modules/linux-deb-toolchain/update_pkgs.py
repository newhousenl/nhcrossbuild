import urllib.request
import gzip
import json
import hashlib
import os
import sys
import subprocess
import argparse

# Default packages to fetch (all listed in deb10 version)
DEFAULT_PACKAGES = [
    "adwaita-icon-theme", "dconf-gsettings-backend", "gcc-8", "gcc-8-base", "gcc-10", "gcc-10-base", "gettext",
    "libasound2", "libasound2-dev", "libatk1.0-0", "libatk1.0-dev", "libatk-adaptor",
    "libatk-bridge2.0-0", "libatk-bridge2.0-dev", "libatspi2.0-0", "libatspi2.0-dev",
    "libblkid1", "libblkid-dev", "libbz2-1.0", "libbz2-dev", "libc6", "libc6-dev",
    "libcairo2", "libcairo2-dev", "libcairo-gobject2", "libcairo-script-interpreter2",
    "libcolord2", "libcups2", "libcups2-dev", "libdbus-1-3", "libdbus-1-dev", "libdconf1",
    "libdrm2", "libdrm-amdgpu1", "libdrm-dev", "libdrm-intel1", "libdrm-nouveau2",
    "libdrm-radeon1", "libdw1", "libdw-dev", "libegl1", "libegl1-mesa", "libegl1-mesa-dev",
    "libegl-mesa0", "libelf1", "libelf-dev", "libepoxy0", "libepoxy-dev", "libexpat1",
    "libexpat1-dev", "libffi6", "libffi7", "libffi-dev", "libfontconfig1", "libfontconfig1-dev",
    "libfreetype6", "libfreetype6-dev", "libgcc-8-dev", "libgcc-10-dev", "libgcc1", "libgcc-s1", "libgdk-pixbuf2.0-0",
    "libgdk-pixbuf2.0-common", "libgdk-pixbuf2.0-dev", "libgl1", "libgl1-mesa-dev",
    "libgl1-mesa-glx", "libglapi-mesa", "libgles1", "libgles2", "libgles2-mesa",
    "libgles2-mesa-dev", "libglib2.0-0", "libglib2.0-bin", "libglib2.0-dev", "libglu1-mesa",
    "libglu1-mesa-dev", "libglvnd0", "libglvnd-core-dev", "libglvnd-dev", "libglx0",
    "libglx-mesa0", "libgraphite2-3", "libgraphite2-dev", "libgtk-3-0", "libgtk-3-common",
    "libgtk-3-dev", "libharfbuzz0b", "libharfbuzz-dev", "libharfbuzz-gobject0",
    "libharfbuzz-icu0", "libice6", "libice-dev", "libicu63", "libicu67", "libicu-dev", "libjpeg62-turbo",
    "libjpeg62-turbo-dev", "libjson-glib-1.0-0", "libkmod2", "liblzma5", "liblzma-dev",
    "libmount1", "libmount-dev", "libopengl0", "libpango-1.0-0", "libpango1.0-dev",
    "libpangocairo-1.0-0", "libpangoft2-1.0-0", "libpangoxft-1.0-0", "libpciaccess0",
    "libpciaccess-dev", "libpcre2-8-0", "libpcre2-dev", "libpcre3", "libpcre3-dev",
    "libpixman-1-0", "libpixman-1-dev", "libpng16-16", "libpng-dev", "librest-0.7-0",
    "libseccomp2", "libselinux1", "libselinux1-dev", "libsepol1", "libsm6", "libsm-dev",
    "libssl1.1", "libstartup-notification0", "libstartup-notification0-dev",
    "libsystemd0", "libtiff5", "libtiff-dev", "libudev1", "libudev-dev", "libuuid1",
    "libwayland-bin", "libwayland-client0", "libwayland-cursor0", "libwayland-dev",
    "libwayland-egl1", "libwayland-egl-backend-dev", "libwayland-server0", "libx11-6",
    "libx11-dev", "libx11-xcb1", "libx11-xcb-dev", "libxau6", "libxau-dev", "libxcb1",
    "libxcb1-dev", "libxcomposite1", "libxcomposite-dev", "libxcursor1", "libxcursor-dev",
    "libxdamage1", "libxdamage-dev", "libxdmcp6", "libxdmcp-dev", "libxext6", "libxext-dev",
    "libxfixes3", "libxfixes-dev", "libxft2", "libxft-dev", "libxi6", "libxi-dev",
    "libxinerama1", "libxinerama-dev", "libxkbcommon0", "libxkbcommon-dev", "libxkbcommon-x11-0",
    "libxrandr2", "libxrandr-dev", "libxrender1", "libxrender-dev", "libxtst6", "libxtst-dev",
    "libxxf86vm1", "libxxf86vm-dev", "linux-libc-dev", "mesa-common-dev", "ocl-icd-libopencl1",
    "ocl-icd-opencl-dev", "opencl-c-headers", "shared-mime-info", "uuid-dev", "wayland-protocols",
    "x11proto-dev", "xkb-data", "xorg-sgml-doctools", "zlib1g", "zlib1g-dev"
]

# Per-version extra packages to add on top of DEFAULT_PACKAGES.
# In Debian 11, libfontconfig1-dev became a dummy which depends on the real package libfontconfig-dev.
VERSION_EXTRA_PACKAGES = {
    "11": ["libfontconfig-dev"],
}

DEBIAN_MIRRORS = {
    "10": "https://archive.debian.org/debian",
    "11": "https://deb.debian.org/debian"
}

DEBIAN_SUITES = {
    "10": "buster",
    "11": "bullseye"
}

def get_nix_hash(url):
    print(f"Downloading and hashing {url}")
    # Use nix-prefetch-url to get the hash directly
    try:
        safe_name = os.path.basename(url).replace("~", "_")
        result = subprocess.run(["nix-prefetch-url", "--type", "sha256", "--name", safe_name, url], capture_output=True, text=True, check=True)
        sha256_hex = result.stdout.strip()
        # Convert hex to base64 to get the standard sha256-... format
        res = subprocess.run(["nix-hash", "--type", "sha256", "--to-base64", sha256_hex], capture_output=True, text=True, check=True)
        return f"sha256-{res.stdout.strip()}" 
    except subprocess.CalledProcessError as e:
        print(f"Error hashing {url}: {e.stderr}")
        return None

def fetch_package_list(version, arch):
    mirror = DEBIAN_MIRRORS[version]
    suite = DEBIAN_SUITES[version]
    url = f"{mirror}/dists/{suite}/main/binary-{arch}/Packages.gz"
    print(f"Fetching package list from {url}")
    
    with urllib.request.urlopen(url) as response:
        with gzip.GzipFile(fileobj=response) as unzipped:
            content = unzipped.read().decode('utf-8')
            
    packages = {}
    current_pkg = {}
    for line in content.splitlines():
        if not line.strip():
            if 'Package' in current_pkg:
                packages[current_pkg['Package']] = current_pkg
            current_pkg = {}
            continue
        if ':' in line:
            key, value = line.split(':', 1)
            current_pkg[key.strip()] = value.strip()
            
    return packages

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", choices=["10", "11"], required=True)
    parser.add_argument("--arch", default="amd64")
    args = parser.parse_args()
    
    version = args.version
    arch = args.arch
    json_path = os.path.join(os.path.dirname(__file__), "debsysroot", f"pkgs-deb{version}-{arch}.json")
    
    existing_pkgs = {}
    if os.path.exists(json_path):
        with open(json_path, 'r') as f:
            data = json.load(f)
            for pkg in data:
                existing_pkgs[pkg['name']] = pkg

    available_pkgs = fetch_package_list(version, arch)
    mirror = DEBIAN_MIRRORS[version]

    effective_packages = DEFAULT_PACKAGES + VERSION_EXTRA_PACKAGES.get(version, [])

    updated_list = []
    
    for pkg_name in effective_packages:
        # Some packages might have version-specific names or might be missing in newer release
        # For now we assume they exist or handle errors
        if pkg_name not in available_pkgs:
            # Try to handle common renames between deb 10 and 11 if necessary
            # For now just warn
            if pkg_name in existing_pkgs:
                 print(f"Warning: {pkg_name} not found in {version} package list, keeping existing if available.")
                 updated_list.append(existing_pkgs[pkg_name])
            else:
                 print(f"Warning: {pkg_name} not found in {version} package list.")
            continue
            
        pkg_info = available_pkgs[pkg_name]
        pkg_url = f"{mirror}/{pkg_info['Filename']}"
        pkg_ver = pkg_info['Version']
        
        if pkg_name in existing_pkgs and existing_pkgs[pkg_name]['url'] == pkg_url:
            print(f"Skipping {pkg_name}, already up to date.")
            updated_list.append(existing_pkgs[pkg_name])
        else:
            sha256 = get_nix_hash(pkg_url)
            if sha256:
                updated_list.append({
                    "name": pkg_name,
                    "url": pkg_url,
                    "sha256": sha256
                })
                
    with open(json_path, 'w') as f:
        json.dump(updated_list, f, indent=2)
    print(f"Updated {json_path}")

if __name__ == "__main__":
    main()
