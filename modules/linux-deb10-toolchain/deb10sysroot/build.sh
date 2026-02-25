#! /usr/bin/env nix-shell
#! nix-shell -i bash -p fakeroot fakechroot debootstrap findutils curl
set -e

if [[ $EUID -eq 0 ]]; then
  echo "This script must not be run as root"
  exit 1
fi

SCRIPTDIR=$(dirname $(realpath $0))

KEYRINGTEMPDIR=/tmp/xxkeyringx
rm -rf $KEYRINGTEMPDIR
mkdir -p $KEYRINGTEMPDIR
pushd $KEYRINGTEMPDIR
curl -o keyring.deb https://ftp.debian.org/debian/pool/main/d/debian-archive-keyring/debian-archive-keyring_2023.4_all.deb
ar x keyring.deb data.tar.xz
tar -xf data.tar.xz .
popd
KEYRINGFILE=$KEYRINGTEMPDIR/usr/share/keyrings/debian-archive-bullseye-automatic.gpg

TARGETDIR=/tmp/xxlinuxsysroot
rm -rf $TARGETDIR
mkdir -p $TARGETDIR
set +e  # somehow this returns failure, but it works
fakechroot fakeroot debootstrap --foreign --keyring=$KEYRINGFILE --variant=fakechroot --include=fakeroot,fakechroot,gcc,liblzma-dev,libgtk-3-dev,libx11-dev,libgl1-mesa-dev,libglu1-mesa-dev,libzstd-dev,ocl-icd-opencl-dev,libxext-dev,libgmp-dev,nettle-dev,libpcre2-dev,libpcre++-dev,libpcre3-dev,libssl-dev,libgtk-3-dev,autoconf,xutils-dev,make,libnotify-dev,libmspack-dev,libsecret-1-dev,libsdl2-dev buster $TARGETDIR
set -e

# Problem: the sysroot has many symlinks pointing to absolute paths, which makes the targets unfindable when the sysroot is moved to a different location
rm -f $TARGETDIR/proc
rm -f $TARGETDIR/dev

find "$TARGETDIR" -type l | while read -r symlink; do
    target=$(readlink "$symlink")

    # Check if it's an absolute symlink
    if [[ "$target" == /* ]]; then
        # Compute relative path
        echo "Symlink $symlink points to an absolute path: $target"
        rel_target=$(realpath --relative-to="$(dirname "$symlink")" "$TARGETDIR$target")
        # Replace the symlink
        ln -sf "$rel_target" "$symlink"
        echo "Updated: $symlink -> $rel_target"
    fi
done

outfile=/tmp/linuxsysroot.tar.xz

tar -cJf $outfile -C $TARGETDIR .
echo "Created $outfile"
echo "Add it to the nix store:"
echo "nix-store --add-fixed sha256 $outfile"
echo "nix-prefetch-url --type sha256 file://$outfile"