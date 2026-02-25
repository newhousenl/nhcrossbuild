{ stdenv, fetchurl, lib, dpkg }:

let
  # Fetch a single .deb package from Debian 10 (buster) archive
  fetchDebPackage = { name, url, sha256 }:
    fetchurl {
      inherit url;
      name = name + ".deb";
      hash = sha256;
    };

  # All packages fetched from https://archive.debian.org/debian (Debian 10 buster, amd64)
  debPackages = [
    (fetchDebPackage {
      name = "libc6";
      url = "https://archive.debian.org/debian/pool/main/g/glibc/libc6_2.28-10+deb10u1_amd64.deb";
      sha256 = "sha256-DuDwv817Wf/aHbx271j6eVEpEyBPKjNiBkZ7+/Rbxp8=";
    })
    (fetchDebPackage {
      name = "libc6-dev";
      url = "https://archive.debian.org/debian/pool/main/g/glibc/libc6-dev_2.28-10+deb10u1_amd64.deb";
      sha256 = "sha256-drhBOSDZGppCifmYOZM9DTAJXg7BKwW7Txp/J+XvSlU=";
    })
    (fetchDebPackage {
      name = "linux-libc-dev";
      url = "https://archive.debian.org/debian/pool/main/l/linux/linux-libc-dev_4.19.249-2_amd64.deb";
      sha256 = "sha256-xRLzD1q+QTRkt57SO1SVjfjMEERGw66T2D0o4jcopXE=";
    })
    (fetchDebPackage {
      name = "ocl-icd-libopencl1";
      url = "https://archive.debian.org/debian/pool/main/o/ocl-icd/ocl-icd-libopencl1_2.2.12-2_amd64.deb";
      sha256 = "sha256-9oQfCet7MNXHe4/wfC0AUfHCyiAf24auenr9vNdqRjo=";
    })
    (fetchDebPackage {
      name = "ocl-icd-opencl-dev";
      url = "https://archive.debian.org/debian/pool/main/o/ocl-icd/ocl-icd-opencl-dev_2.2.12-2_amd64.deb";
      sha256 = "sha256-z+x8SaByiXW2aZyXWMwsNqXaoE2U4H5wP8e89rOIa0Q=";
    })
    (fetchDebPackage {
      name = "libgtk-3-0";
      url = "https://archive.debian.org/debian/pool/main/g/gtk+3.0/libgtk-3-0_3.24.5-1_amd64.deb";
      sha256 = "sha256-5lLgSwTMimfCTFdzGAp/3WWmz8VaJ3dyLoCCWlajNyk=";
    })
    (fetchDebPackage {
      name = "libgtk-3-dev";
      url = "https://archive.debian.org/debian/pool/main/g/gtk+3.0/libgtk-3-dev_3.24.5-1_amd64.deb";
      sha256 = "sha256-YHHaeIk50LKrlZ6ejWrhKn8CH1wH12QR8BodK/VaOUg=";
    })
    (fetchDebPackage {
      name = "libgtk-3-common";
      url = "https://archive.debian.org/debian/pool/main/g/gtk+3.0/libgtk-3-common_3.24.5-1_all.deb";
      sha256 = "sha256-HhyXnsiCVCzgm0DA9yRqfzSLQtm+xvMesmFKjdzNSHQ=";
    })
    (fetchDebPackage {
      name = "libdbus-1-3";
      url = "https://archive.debian.org/debian/pool/main/d/dbus/libdbus-1-3_1.12.20-0+deb10u1_amd64.deb";
      sha256 = "sha256-45S9NWJuPM9Dfh53duZXNjbmQTsOviSDvVSsJD7tEAc=";
    })
    (fetchDebPackage {
      name = "libdbus-1-dev";
      url = "https://archive.debian.org/debian/pool/main/d/dbus/libdbus-1-dev_1.12.20-0+deb10u1_amd64.deb";
      sha256 = "sha256-kMf4esJFN30vwwGGGZqnD7pJqldnfBME8xLHFNlCLs8=";
    })
    (fetchDebPackage {
      name = "libglib2.0-0";
      url = "https://archive.debian.org/debian/pool/main/g/glib2.0/libglib2.0-0_2.58.3-2+deb10u3_amd64.deb";
      sha256 = "sha256-Vm5mTMaeI/reNL6ScR81nsAqmFQiIkTzYD/fZAzGaIo=";
    })
    (fetchDebPackage {
      name = "libglib2.0-dev";
      url = "https://archive.debian.org/debian/pool/main/g/glib2.0/libglib2.0-dev_2.58.3-2+deb10u3_amd64.deb";
      sha256 = "sha256-YSo1M5eeTRQr6kiq/f2yrUCzW8XVZFldZdA3Eq8f5f4=";
    })
    (fetchDebPackage {
      name = "libglib2.0-bin";
      url = "https://archive.debian.org/debian/pool/main/g/glib2.0/libglib2.0-bin_2.58.3-2+deb10u3_amd64.deb";
      sha256 = "sha256-TsXazbAMh55yQei+otkM3wvXGPC/Fr+Muq2tSQ6GUYY=";
    })
    (fetchDebPackage {
      name = "libmount1";
      url = "https://archive.debian.org/debian/pool/main/u/util-linux/libmount1_2.33.1-0.1_amd64.deb";
      sha256 = "sha256-uLKGadxJlaekjUfZGZ0YBtT86cQFEncnnU3MUUwIa6M=";
    })
    (fetchDebPackage {
      name = "libmount-dev";
      url = "https://archive.debian.org/debian/pool/main/u/util-linux/libmount-dev_2.33.1-0.1_amd64.deb";
      sha256 = "sha256-2YmFop1wUUbN3/7RRCmAVJ2L8NUUj78D+8QTvdOuyMo=";
    })
    (fetchDebPackage {
      name = "libblkid1";
      url = "https://archive.debian.org/debian/pool/main/u/util-linux/libblkid1_2.33.1-0.1_amd64.deb";
      sha256 = "sha256-CxXz6zzy++VA+Zrhyf1ewXMPIkW5njHJF1XecblnNDo=";
    })
    (fetchDebPackage {
      name = "libblkid-dev";
      url = "https://archive.debian.org/debian/pool/main/u/util-linux/libblkid-dev_2.33.1-0.1_amd64.deb";
      sha256 = "sha256-mWkU1s7BusFRx2bVtlGXiItGTDUF9j96u8Ep105fKKw=";
    })
    (fetchDebPackage {
      name = "libuuid1";
      url = "https://archive.debian.org/debian/pool/main/u/util-linux/libuuid1_2.33.1-0.1_amd64.deb";
      sha256 = "sha256-kLkL70WT1PNH+x50pjxWCdqobUxQA7FOhfWGKNbBGLI=";
    })
    (fetchDebPackage {
      name = "uuid-dev";
      url = "https://archive.debian.org/debian/pool/main/u/util-linux/uuid-dev_2.33.1-0.1_amd64.deb";
      sha256 = "sha256-aN38yeh9RItkbasnXu+dvz6smsgYfDj6Dmb69hgv7Nw=";
    })
    (fetchDebPackage {
      name = "libgl1-mesa-glx";
      url = "https://archive.debian.org/debian/pool/main/m/mesa/libgl1-mesa-glx_18.3.6-2+deb10u1_amd64.deb";
      sha256 = "sha256-vmlbR7mQZM/1EBbLsCMYjGqiwB+gvtowgwSEzVUTTDM=";
    })
    (fetchDebPackage {
      name = "libgl1-mesa-dev";
      url = "https://archive.debian.org/debian/pool/main/m/mesa/libgl1-mesa-dev_18.3.6-2+deb10u1_amd64.deb";
      sha256 = "sha256-/XsX6C8cz5XVotpyaj4YOl8B98OwqsNscLLrxdGQP80=";
    })
    (fetchDebPackage {
      name = "libglu1-mesa";
      url = "https://archive.debian.org/debian/pool/main/libg/libglu/libglu1-mesa_9.0.0-2.1+b3_amd64.deb";
      sha256 = "sha256-Xq7WewpCURdgHTan8tHSmaRbtoSNGnHZOK40Ui3u2Y0=";
    })
    (fetchDebPackage {
      name = "libglu1-mesa-dev";
      url = "https://archive.debian.org/debian/pool/main/libg/libglu/libglu1-mesa-dev_9.0.0-2.1+b3_amd64.deb";
      sha256 = "sha256-b5zl7XJEfttP1khLs0oqyTuoIpJ7LsT0+WiGs/yT/9c=";
    })
    (fetchDebPackage {
      name = "libegl1-mesa";
      url = "https://archive.debian.org/debian/pool/main/m/mesa/libegl1-mesa_18.3.6-2+deb10u1_amd64.deb";
      sha256 = "sha256-PLF/Xu4+ldT+C07ExNoJJ+D0kEJfpm7J5PbUxwn8B2U=";
    })
    (fetchDebPackage {
      name = "libegl1-mesa-dev";
      url = "https://archive.debian.org/debian/pool/main/m/mesa/libegl1-mesa-dev_18.3.6-2+deb10u1_amd64.deb";
      sha256 = "sha256-YmqGzaiDPPRawgKZI3yo59gx4ErLNxa4Rlge1WezZ/Y=";
    })
    (fetchDebPackage {
      name = "libgles2-mesa";
      url = "https://archive.debian.org/debian/pool/main/m/mesa/libgles2-mesa_18.3.6-2+deb10u1_amd64.deb";
      sha256 = "sha256-hDpkRvcskua+2Hbwahj4qQeFipNz4Ru6yc5ihUXIJrc=";
    })
    (fetchDebPackage {
      name = "libgles2-mesa-dev";
      url = "https://archive.debian.org/debian/pool/main/m/mesa/libgles2-mesa-dev_18.3.6-2+deb10u1_amd64.deb";
      sha256 = "sha256-6ym6HYBQaImESQzVPhxnJ8fZzbeZRrDEXfu+ea7UdMA=";
    })
    (fetchDebPackage {
      name = "mesa-common-dev";
      url = "https://archive.debian.org/debian/pool/main/m/mesa/mesa-common-dev_18.3.6-2+deb10u1_amd64.deb";
      sha256 = "sha256-exld0qeM3VrZl5IS83V5FqYbQcEBbQWzwaQ4I0RjVmQ=";
    })
    (fetchDebPackage {
      name = "libglapi-mesa";
      url = "https://archive.debian.org/debian/pool/main/m/mesa/libglapi-mesa_18.3.6-2+deb10u1_amd64.deb";
      sha256 = "sha256-QA+hWo2jaTWTKK1BrIk8TLUWhlFO5qlFbbv9EuiDbsM=";
    })
    (fetchDebPackage {
      name = "libxkbcommon0";
      url = "https://archive.debian.org/debian/pool/main/libx/libxkbcommon/libxkbcommon0_0.8.2-1_amd64.deb";
      sha256 = "sha256-qTcp8dMlWYrZxqf/4AxGT74nYYGjoSSFUEHB4wMXXww=";
    })
    (fetchDebPackage {
      name = "libxkbcommon-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libxkbcommon/libxkbcommon-dev_0.8.2-1_amd64.deb";
      sha256 = "sha256-Xng6GeYOv5S/snc2EidrBPbqDpFiKE9iDS763msRaT8=";
    })
    (fetchDebPackage {
      name = "libx11-6";
      url = "https://archive.debian.org/debian/pool/main/libx/libx11/libx11-6_1.6.7-1+deb10u2_amd64.deb";
      sha256 = "sha256-Qj0s/qCgwZYTpcBTzIixv3XmpLJ4LuYVpOZRbgtQpbY=";
    })
    (fetchDebPackage {
      name = "libx11-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libx11/libx11-dev_1.6.7-1+deb10u2_amd64.deb";
      sha256 = "sha256-tzsDteoy0EVmQEhrlgJZNjbiWpNmeCtOLgwYPY2wyfk=";
    })
    (fetchDebPackage {
      name = "libxcursor1";
      url = "https://archive.debian.org/debian/pool/main/libx/libxcursor/libxcursor1_1.1.15-2_amd64.deb";
      sha256 = "sha256-XFw8UCCz6WOvz0WvIa2MDBQ3WuNfbGSaBaInkFA78kw=";
    })
    (fetchDebPackage {
      name = "libxcursor-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libxcursor/libxcursor-dev_1.1.15-2_amd64.deb";
      sha256 = "sha256-87959qMqYtNoVnknkqqufK1HnXEK2Qy64drNAvOOk/Y=";
    })
    (fetchDebPackage {
      name = "libxrandr2";
      url = "https://archive.debian.org/debian/pool/main/libx/libxrandr/libxrandr2_1.5.1-1_amd64.deb";
      sha256 = "sha256-j92LpKitgZcx1rvZA7UoUaLsL570E52IDpvkIephM4w=";
    })
    (fetchDebPackage {
      name = "libxrandr-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libxrandr/libxrandr-dev_1.5.1-1_amd64.deb";
      sha256 = "sha256-Z9QBdAFei04+L+O2+ymQlDMhoWjg+7LRIIL2N5FKCi4=";
    })
    (fetchDebPackage {
      name = "libice6";
      url = "https://archive.debian.org/debian/pool/main/libi/libice/libice6_1.0.9-2_amd64.deb";
      sha256 = "sha256-WrZYx+/AUJS2n20JUEhqcN9hcwX6sQmDt9iFqwp1DyE=";
    })
    (fetchDebPackage {
      name = "libice-dev";
      url = "https://archive.debian.org/debian/pool/main/libi/libice/libice-dev_1.0.9-2_amd64.deb";
      sha256 = "sha256-9fCaIpr4gMlHahYmtRjPHWJeuIzwaTePvxF/tFAY3lY=";
    })
    (fetchDebPackage {
      name = "libsm6";
      url = "https://archive.debian.org/debian/pool/main/libs/libsm/libsm6_1.2.3-1_amd64.deb";
      sha256 = "sha256-IqQgiQSJAjNG8w/s7xTqkAoHiOe/lZ74Jqq7g5RPzPs=";
    })
    (fetchDebPackage {
      name = "libsm-dev";
      url = "https://archive.debian.org/debian/pool/main/libs/libsm/libsm-dev_1.2.3-1_amd64.deb";
      sha256 = "sha256-L/hkHTIX3BoPJlFPXY3iAJZpQjpKoNtGs99WSos2cCY=";
    })
    (fetchDebPackage {
      name = "libxext6";
      url = "https://archive.debian.org/debian/pool/main/libx/libxext/libxext6_1.3.3-1+b2_amd64.deb";
      sha256 = "sha256-ckkBEFeS6YO9DnwrRpYM2SXdaiszte6Zm06AqvYksII=";
    })
    (fetchDebPackage {
      name = "libxext-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libxext/libxext-dev_1.3.3-1+b2_amd64.deb";
      sha256 = "sha256-hv/VgZAghqsL9DgbKNj75m/DeN4tsCqWolcF7qvuDHs=";
    })
    (fetchDebPackage {
      name = "libxtst6";
      url = "https://archive.debian.org/debian/pool/main/libx/libxtst/libxtst6_1.2.3-1_amd64.deb";
      sha256 = "sha256-cHL5vher25xa99BSsZyE0abBwTwwwSCpjShLpz0tpz8=";
    })
    (fetchDebPackage {
      name = "libxtst-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libxtst/libxtst-dev_1.2.3-1_amd64.deb";
      sha256 = "sha256-ntVuD9WAev4gz+6PrRbGV8bXQQ15NNhyZYR5S9d+qYk=";
    })
    (fetchDebPackage {
      name = "libxrender1";
      url = "https://archive.debian.org/debian/pool/main/libx/libxrender/libxrender1_0.9.10-1_amd64.deb";
      sha256 = "sha256-PqF9B7WqiQEhMOKs2S8PwOpnMU4vXqtuM5MO9oj0gpQ=";
    })
    (fetchDebPackage {
      name = "libxrender-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libxrender/libxrender-dev_0.9.10-1_amd64.deb";
      sha256 = "sha256-E17XyKWJ4X0hcYqRtafaSBWfM8heCzN6rpufSE06SVQ=";
    })
    (fetchDebPackage {
      name = "libxfixes3";
      url = "https://archive.debian.org/debian/pool/main/libx/libxfixes/libxfixes3_5.0.3-1_amd64.deb";
      sha256 = "sha256-OzB0kMZprM1S3GJ61NwmmgNjLKUS+8exhbVy92YI/04=";
    })
    (fetchDebPackage {
      name = "libxfixes-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libxfixes/libxfixes-dev_5.0.3-1_amd64.deb";
      sha256 = "sha256-6hGlE8ci4Fh/S/DRQzy5glrL33qHOm/oLHuNndI/9zg=";
    })
    (fetchDebPackage {
      name = "libxi6";
      url = "https://archive.debian.org/debian/pool/main/libx/libxi/libxi6_1.7.9-1_amd64.deb";
      sha256 = "sha256-/iZzOt8gJfGEv5BMrwiKXT9qopqIY7YWr5yvqthbEjc=";
    })
    (fetchDebPackage {
      name = "libxi-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libxi/libxi-dev_1.7.9-1_amd64.deb";
      sha256 = "sha256-4RHzkA7LN10CvcsBqTOVvPak8ECdVv+xQO3wLZ3Bu10=";
    })
    (fetchDebPackage {
      name = "libxinerama1";
      url = "https://archive.debian.org/debian/pool/main/libx/libxinerama/libxinerama1_1.1.4-2_amd64.deb";
      sha256 = "sha256-9pLIVJNVce5E/jE1Qdip9nik8R3FE7xDudClAcbf8L0=";
    })
    (fetchDebPackage {
      name = "libxinerama-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libxinerama/libxinerama-dev_1.1.4-2_amd64.deb";
      sha256 = "sha256-GAR/UsOhKU1hvCZC0i0FvYecFTk8TotKwu5qUGFYW5s=";
    })
    (fetchDebPackage {
      name = "libxcomposite1";
      url = "https://archive.debian.org/debian/pool/main/libx/libxcomposite/libxcomposite1_0.4.4-2_amd64.deb";
      sha256 = "sha256-BDyHg1aVT0UhxAGxYNVUgJEVxHLKOE2feTwcdUIxbrk=";
    })
    (fetchDebPackage {
      name = "libxcomposite-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libxcomposite/libxcomposite-dev_0.4.4-2_amd64.deb";
      sha256 = "sha256-1KxtrItC87Gc86VVh+NzppKJRdThpOvyPaXSZfuxSbw=";
    })
    (fetchDebPackage {
      name = "libxdamage1";
      url = "https://archive.debian.org/debian/pool/main/libx/libxdamage/libxdamage1_1.1.4-3+b3_amd64.deb";
      sha256 = "sha256-6VOYONR8sQtCc8Mg+OiF74Xfe9OpXw6pvLwUTbgsA64=";
    })
    (fetchDebPackage {
      name = "libxdamage-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libxdamage/libxdamage-dev_1.1.4-3+b3_amd64.deb";
      sha256 = "sha256-T7/fZHoqCCESrZoLhKB4D6wtD7+r8bfLLMYyX8CWrEo=";
    })
    (fetchDebPackage {
      name = "libxau6";
      url = "https://archive.debian.org/debian/pool/main/libx/libxau/libxau6_1.0.8-1+b2_amd64.deb";
      sha256 = "sha256-p4V7cmw+DRbNovu5Ag1C4CSjFg1U74WPWFeGEidmg+g=";
    })
    (fetchDebPackage {
      name = "libxau-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libxau/libxau-dev_1.0.8-1+b2_amd64.deb";
      sha256 = "sha256-WplNcPNuDK/pmzj2geWElx22zJMt8DgOvKD+wMMqQpU=";
    })
    (fetchDebPackage {
      name = "libxdmcp6";
      url = "https://archive.debian.org/debian/pool/main/libx/libxdmcp/libxdmcp6_1.1.2-3_amd64.deb";
      sha256 = "sha256-7LhTb1+zRUO1W7ncX1sUydu0FQp73bPyKHt8q26dJe8=";
    })
    (fetchDebPackage {
      name = "libxdmcp-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libxdmcp/libxdmcp-dev_1.1.2-3_amd64.deb";
      sha256 = "sha256-xnM+X2Rjr9JhmY5Ai+brN/JM4KZLY77VCofdsY68Fpk=";
    })
    (fetchDebPackage {
      name = "libxxf86vm1";
      url = "https://archive.debian.org/debian/pool/main/libx/libxxf86vm/libxxf86vm1_1.1.4-1+b2_amd64.deb";
      sha256 = "sha256-b0ypFqrsJtcAD6f1jeP3ERkwmrdZDOH1F6v+GCWmdsc=";
    })
    (fetchDebPackage {
      name = "libxxf86vm-dev";
      url = "https://archive.debian.org/debian/pool/main/libx/libxxf86vm/libxxf86vm-dev_1.1.4-1+b2_amd64.deb";
      sha256 = "sha256-L7dTp8LC/Wt0uEKdGAslmvnCtCAfjHd2IayIxj1Dzqc=";
    })
    (fetchDebPackage {
      name = "x11proto-dev";
      url = "https://archive.debian.org/debian/pool/main/x/xorgproto/x11proto-dev_2018.4-4_all.deb";
      sha256 = "sha256-qgI3Rn/LXMq/apP8Gfrk122Mbfv55Ent2l9jk+UNhnQ=";
    })
    (fetchDebPackage {
      name = "xorg-sgml-doctools";
      url = "https://archive.debian.org/debian/pool/main/x/xorg-sgml-doctools/xorg-sgml-doctools_1.11-1_all.deb";
      sha256 = "sha256-NZ3Ha/exn7vbC548owd+QVtbnKj/hRYszIifmXRJNgA=";
    })
    (fetchDebPackage {
      name = "libudev1";
      url = "https://archive.debian.org/debian/pool/main/s/systemd/libudev1_241-7~deb10u8_amd64.deb";
      sha256 = "sha256-GKgc7ydqOvn1/2H+9HcVGLePNzigURldr9MBv7eBWyk=";
    })
    (fetchDebPackage {
      name = "libudev-dev";
      url = "https://archive.debian.org/debian/pool/main/s/systemd/libudev-dev_241-7~deb10u8_amd64.deb";
      sha256 = "sha256-Yep1lKf1mlgVgNqcvECZkWpAHejTXqG2my5MKNyZtNI=";
    })
    (fetchDebPackage {
      name = "libsystemd0";
      url = "https://archive.debian.org/debian/pool/main/s/systemd/libsystemd0_241-7~deb10u8_amd64.deb";
      sha256 = "sha256-+tzo28NpVayT7OarJRb5J8hUgN+UGaV4yVw4iDS0mA4=";
    })
    (fetchDebPackage {
      name = "libasound2";
      url = "https://archive.debian.org/debian/pool/main/a/alsa-lib/libasound2_1.1.8-1_amd64.deb";
      sha256 = "sha256-bMKBtKbR+v/k/G2D7HE2XBrw7m14BvoSL+8A+FoN3mI=";
    })
    (fetchDebPackage {
      name = "libasound2-dev";
      url = "https://archive.debian.org/debian/pool/main/a/alsa-lib/libasound2-dev_1.1.8-1_amd64.deb";
      sha256 = "sha256-78rgUigArA8ypy16wkA3Xv/eBkc7ta6rviDS1AV8GF4=";
    })
    (fetchDebPackage {
      name = "libgdk-pixbuf2.0-0";
      url = "https://archive.debian.org/debian/pool/main/g/gdk-pixbuf/libgdk-pixbuf2.0-0_2.38.1+dfsg-1_amd64.deb";
      sha256 = "sha256-kOGEJ3GWj/rktMKPGtaov3f/Oldha3mavtkzVLhg7cg=";
    })
    (fetchDebPackage {
      name = "libgdk-pixbuf2.0-dev";
      url = "https://archive.debian.org/debian/pool/main/g/gdk-pixbuf/libgdk-pixbuf2.0-dev_2.38.1+dfsg-1_amd64.deb";
      sha256 = "sha256-ZKpVm6pANdqj0wWahzBeTL8cBhYWQcGGyyAAdHSEIdI=";
    })
    (fetchDebPackage {
      name = "libgdk-pixbuf2.0-common";
      url = "https://archive.debian.org/debian/pool/main/g/gdk-pixbuf/libgdk-pixbuf2.0-common_2.38.1+dfsg-1_all.deb";
      sha256 = "sha256-ExDj8CWIZutNDpXxQNXZAlz2vh4+LDdfSkJszC54z2g=";
    })
    (fetchDebPackage {
      name = "libcairo2";
      url = "https://archive.debian.org/debian/pool/main/c/cairo/libcairo2_1.16.0-4+deb10u1_amd64.deb";
      sha256 = "sha256-Io6K8fLqOINnwmpkpEke4/dY2eYac/Qhu2CgPAezDSs=";
    })
    (fetchDebPackage {
      name = "libcairo2-dev";
      url = "https://archive.debian.org/debian/pool/main/c/cairo/libcairo2-dev_1.16.0-4+deb10u1_amd64.deb";
      sha256 = "sha256-DO5Ubh8mvCghp1QccGllpiATrERGsONDgXUeRiKU2Cg=";
    })
    (fetchDebPackage {
      name = "libcairo-gobject2";
      url = "https://archive.debian.org/debian/pool/main/c/cairo/libcairo-gobject2_1.16.0-4+deb10u1_amd64.deb";
      sha256 = "sha256-wedKaFKtCymbkZfKALoJHvaBU4Ml0fgWgLTesprfCUw=";
    })
    (fetchDebPackage {
      name = "libcairo-script-interpreter2";
      url = "https://archive.debian.org/debian/pool/main/c/cairo/libcairo-script-interpreter2_1.16.0-4+deb10u1_amd64.deb";
      sha256 = "sha256-bCJpNf4Yb5cRkCFUVjwbmCiiq7aRm1zZk3F8cEv6HdM=";
    })
    (fetchDebPackage {
      name = "libharfbuzz0b";
      url = "https://archive.debian.org/debian/pool/main/h/harfbuzz/libharfbuzz0b_2.3.1-1_amd64.deb";
      sha256 = "sha256-ruHdb5iEwazdG21vSb1BkjXezQD0nNkn5L5MN68uzas=";
    })
    (fetchDebPackage {
      name = "libharfbuzz-dev";
      url = "https://archive.debian.org/debian/pool/main/h/harfbuzz/libharfbuzz-dev_2.3.1-1_amd64.deb";
      sha256 = "sha256-QZeYi+9atSXq9eEBiND3AHNImOVg7VaK9VO/BeAKVF4=";
    })
    (fetchDebPackage {
      name = "libharfbuzz-icu0";
      url = "https://archive.debian.org/debian/pool/main/h/harfbuzz/libharfbuzz-icu0_2.3.1-1_amd64.deb";
      sha256 = "sha256-+1S3VjZtrjn787dAQB2k9gvOB6xwqeiQM+TTLBBj5Q0=";
    })
    (fetchDebPackage {
      name = "libharfbuzz-gobject0";
      url = "https://archive.debian.org/debian/pool/main/h/harfbuzz/libharfbuzz-gobject0_2.3.1-1_amd64.deb";
      sha256 = "sha256-KdjBXGiCzMldR5ONEABMkSDoe6+b48kwNGnWyHW337k=";
    })
    (fetchDebPackage {
      name = "libpango-1.0-0";
      url = "https://archive.debian.org/debian/pool/main/p/pango1.0/libpango-1.0-0_1.42.4-8~deb10u1_amd64.deb";
      sha256 = "sha256-79Z3x3y16J3ZSm+YHH3U5wXjk7YbpP02EACdLKFA+hE=";
    })
    (fetchDebPackage {
      name = "libpango1.0-dev";
      url = "https://archive.debian.org/debian/pool/main/p/pango1.0/libpango1.0-dev_1.42.4-8~deb10u1_amd64.deb";
      sha256 = "sha256-vnxFLvQTsvCBNscSS6WJa1dPmrS4yfKlAiiQK7Snn2w=";
    })
    (fetchDebPackage {
      name = "libpangocairo-1.0-0";
      url = "https://archive.debian.org/debian/pool/main/p/pango1.0/libpangocairo-1.0-0_1.42.4-8~deb10u1_amd64.deb";
      sha256 = "sha256-PKLoqqbAYfka4FFjzjGzvGOmEcY8GkPM+FUzDlBYJfA=";
    })
    (fetchDebPackage {
      name = "libpangoft2-1.0-0";
      url = "https://archive.debian.org/debian/pool/main/p/pango1.0/libpangoft2-1.0-0_1.42.4-8~deb10u1_amd64.deb";
      sha256 = "sha256-RyS7LfolvrnBqXjeDFeA9tPOWqAyMuR8EbKXtImaYHM=";
    })
    (fetchDebPackage {
      name = "libpangoxft-1.0-0";
      url = "https://archive.debian.org/debian/pool/main/p/pango1.0/libpangoxft-1.0-0_1.42.4-8~deb10u1_amd64.deb";
      sha256 = "sha256-pQ/bM9OeqWYogwijKhLNQ08wvwt8Rb0zp2QmglBncGY=";
    })
    (fetchDebPackage {
      name = "libatk1.0-0";
      url = "https://archive.debian.org/debian/pool/main/a/atk1.0/libatk1.0-0_2.30.0-2_amd64.deb";
      sha256 = "sha256-UWA8wFS6qCzuTNUKxBV4Jm4TIe8cdLzLt4o9zxcp0Wg=";
    })
    (fetchDebPackage {
      name = "libatk1.0-dev";
      url = "https://archive.debian.org/debian/pool/main/a/atk1.0/libatk1.0-dev_2.30.0-2_amd64.deb";
      sha256 = "sha256-6kFLxyYWoniLwtYYXV+/RomQqnJPH8iEVM2vI5sWuDY=";
    })
    (fetchDebPackage {
      name = "libatk-bridge2.0-0";
      url = "https://archive.debian.org/debian/pool/main/a/at-spi2-atk/libatk-bridge2.0-0_2.30.0-5_amd64.deb";
      sha256 = "sha256-Uu0zM/0OFDC1czQ/xl1ZSgde5fSTuMv/D2TV9B9vP48=";
    })
    (fetchDebPackage {
      name = "libatk-bridge2.0-dev";
      url = "https://archive.debian.org/debian/pool/main/a/at-spi2-atk/libatk-bridge2.0-dev_2.30.0-5_amd64.deb";
      sha256 = "sha256-9BnSFrxJENAx/OKF9/2/gS0lYfZ9dCudYf0Rm2CNn8c=";
    })
    (fetchDebPackage {
      name = "libwayland-client0";
      url = "https://archive.debian.org/debian/pool/main/w/wayland/libwayland-client0_1.16.0-1_amd64.deb";
      sha256 = "sha256-gm/dGmpf+gFBXxOOI42oWKriKsT0g1zt/sq3bdDcsBs=";
    })
    (fetchDebPackage {
      name = "libwayland-server0";
      url = "https://archive.debian.org/debian/pool/main/w/wayland/libwayland-server0_1.16.0-1_amd64.deb";
      sha256 = "sha256-k8e7nf0Qfx59Kz4KmvbvxlPXXMXlj2U8/RSvwS0SVlU=";
    })
    (fetchDebPackage {
      name = "libwayland-egl1";
      url = "https://archive.debian.org/debian/pool/main/w/wayland/libwayland-egl1_1.16.0-1_amd64.deb";
      sha256 = "sha256-oCHpqpqSJw+iWSEaDKabXoQo8yxugApKk/B2awpIpcY=";
    })
    (fetchDebPackage {
      name = "libwayland-cursor0";
      url = "https://archive.debian.org/debian/pool/main/w/wayland/libwayland-cursor0_1.16.0-1_amd64.deb";
      sha256 = "sha256-7umQ6grWisQJmG6/khBrjeraVMws/RkpMXf1+TjDVpA=";
    })
    (fetchDebPackage {
      name = "libwayland-dev";
      url = "https://archive.debian.org/debian/pool/main/w/wayland/libwayland-dev_1.16.0-1_amd64.deb";
      sha256 = "sha256-fZeP4h6gcLnxqAMnKS2QqGRPUNonKEwkXlTAt/VgKZk=";
    })
    (fetchDebPackage {
      name = "adwaita-icon-theme";
      url = "https://archive.debian.org/debian/pool/main/a/adwaita-icon-theme/adwaita-icon-theme_3.30.1-1_all.deb";
      sha256 = "sha256-aYs/D6M3uzbqT+Byo3oyocgYddsTBCNoZ3SQuwh8y5M=";
    })
    (fetchDebPackage {
      name = "libpixman-1-0";
      url = "https://archive.debian.org/debian/pool/main/p/pixman/libpixman-1-0_0.36.0-1_amd64.deb";
      sha256 = "sha256-Q4Lr/FxSYj2RfcD2PCL796eR0A9bMDzVakS/lhb6X74=";
    })
    (fetchDebPackage {
      name = "libpixman-1-dev";
      url = "https://archive.debian.org/debian/pool/main/p/pixman/libpixman-1-dev_0.36.0-1_amd64.deb";
      sha256 = "sha256-Aonp5yfU2/bFtoXVcd7X/o9qPDW4UktEKUEqA/p+U7s=";
    })
    (fetchDebPackage {
      name = "libfreetype6";
      url = "https://archive.debian.org/debian/pool/main/f/freetype/libfreetype6_2.9.1-3+deb10u3_amd64.deb";
      sha256 = "sha256-Yv+YYd22wl1ORzI461VhMWrcVwzEg2yT8wzx9EH1gjk=";
    })
    (fetchDebPackage {
      name = "libfreetype6-dev";
      url = "https://archive.debian.org/debian/pool/main/f/freetype/libfreetype6-dev_2.9.1-3+deb10u3_amd64.deb";
      sha256 = "sha256-nWj5Rzw6yvHbIXmKJyHoGXe7xbSfhlXCKRPa1zUKu/Y=";
    })
    (fetchDebPackage {
      name = "libfontconfig1";
      url = "https://archive.debian.org/debian/pool/main/f/fontconfig/libfontconfig1_2.13.1-2_amd64.deb";
      sha256 = "sha256-Z2bQvPxhX7FVQu+1I104I3zK7Ewhm+uE29ItFmLM6o8=";
    })
    (fetchDebPackage {
      name = "libfontconfig1-dev";
      url = "https://archive.debian.org/debian/pool/main/f/fontconfig/libfontconfig1-dev_2.13.1-2_amd64.deb";
      sha256 = "sha256-KAYKjvWNDbYqGWwJwuMm4RT9JZfwNZruYSHuGIx93Gc=";
    })
    (fetchDebPackage {
      name = "libexpat1";
      url = "https://archive.debian.org/debian/pool/main/e/expat/libexpat1_2.2.6-2+deb10u4_amd64.deb";
      sha256 = "sha256-V0h/N2/SLD8QQ1X5/ruP8vUvPBsCqqymOiJI/saMmnQ=";
    })
    (fetchDebPackage {
      name = "libexpat1-dev";
      url = "https://archive.debian.org/debian/pool/main/e/expat/libexpat1-dev_2.2.6-2+deb10u4_amd64.deb";
      sha256 = "sha256-QK00U4FW2k/883grfEkOF5g/SvBlv6sqqoxyx0x7/p8=";
    })
    (fetchDebPackage {
      name = "libffi6";
      url = "https://archive.debian.org/debian/pool/main/libf/libffi/libffi6_3.2.1-9_amd64.deb";
      sha256 = "sha256-1NdI2Jfo5TqiOerSOhhyShowCFzGykGowxs7Hhs0UvQ=";
    })
    (fetchDebPackage {
      name = "libffi-dev";
      url = "https://archive.debian.org/debian/pool/main/libf/libffi/libffi-dev_3.2.1-9_amd64.deb";
      sha256 = "sha256-ZDvxnoWcm/j2EDPkjXunPBFAOe++hR9Ac1btqzlq8xc=";
    })
    (fetchDebPackage {
      name = "libpcre2-8-0";
      url = "https://archive.debian.org/debian/pool/main/p/pcre2/libpcre2-8-0_10.32-5_amd64.deb";
      sha256 = "sha256-GPqQEgXtIcgz/2adquJvZ1gDFH9Mxk3clfyc3df2VMg=";
    })
    (fetchDebPackage {
      name = "libpcre2-dev";
      url = "https://archive.debian.org/debian/pool/main/p/pcre2/libpcre2-dev_10.32-5_amd64.deb";
      sha256 = "sha256-7U5FlFsb5Kq3OmQGDtn2ejNSLPueO5P9gpj5GkfEoPM=";
    })
    (fetchDebPackage {
      name = "zlib1g";
      url = "https://archive.debian.org/debian/pool/main/z/zlib/zlib1g_1.2.11.dfsg-1+deb10u1_amd64.deb";
      sha256 = "sha256-oUvP/DlSj0ImJXFcuMBakhsoO8TTfifG2413EGzX2Kk=";
    })
    (fetchDebPackage {
      name = "zlib1g-dev";
      url = "https://archive.debian.org/debian/pool/main/z/zlib/zlib1g-dev_1.2.11.dfsg-1+deb10u1_amd64.deb";
      sha256 = "sha256-U4jt3/2Hm90AAvsJlta5QA0KwKs6h+zrbYDKQ+2C3+s=";
    })
    (fetchDebPackage {
      name = "libpng16-16";
      url = "https://archive.debian.org/debian/pool/main/libp/libpng1.6/libpng16-16_1.6.36-6_amd64.deb";
      sha256 = "sha256-gqJSR4RlUhzenVr0c98B7XnxbpEu/8WXGJKldOkRNQA=";
    })
    (fetchDebPackage {
      name = "libpng-dev";
      url = "https://archive.debian.org/debian/pool/main/libp/libpng1.6/libpng-dev_1.6.36-6_amd64.deb";
      sha256 = "sha256-Q8kLNol5rxqvK6ojmJIlAgOyTx2ggUJm4Am64KhQdj0=";
    })
    (fetchDebPackage {
      name = "libjpeg62-turbo";
      url = "https://archive.debian.org/debian/pool/main/libj/libjpeg-turbo/libjpeg62-turbo_1.5.2-2+deb10u1_amd64.deb";
      sha256 = "sha256-tsvH1yLL9pfO282biyCfjPoF8Uf7pAYa3y/O5sxkxVY=";
    })
    (fetchDebPackage {
      name = "libjpeg62-turbo-dev";
      url = "https://archive.debian.org/debian/pool/main/libj/libjpeg-turbo/libjpeg62-turbo-dev_1.5.2-2+deb10u1_amd64.deb";
      sha256 = "sha256-4ZbVO4G2T2ZcAjYIyKAOs+5vGPyOncPul/cdJRtDJxE=";
    })
    (fetchDebPackage {
      name = "libtiff5";
      url = "https://archive.debian.org/debian/pool/main/t/tiff/libtiff5_4.1.0+git191117-2~deb10u4_amd64.deb";
      sha256 = "sha256-hYMC8W+qaA3oI2rFyMtBUDvWxBxG4z/HTJPKZ+rP+Eo=";
    })
    (fetchDebPackage {
      name = "libtiff-dev";
      url = "https://archive.debian.org/debian/pool/main/t/tiff/libtiff-dev_4.1.0+git191117-2~deb10u4_amd64.deb";
      sha256 = "sha256-FQL9pDIOYA9v/PVDgMrm7QKQ5QwS1yR7ZtYjNW4eVZY=";
    })
    (fetchDebPackage {
      name = "libatspi2.0-0";
      url = "https://archive.debian.org/debian/pool/main/a/at-spi2-core/libatspi2.0-0_2.30.0-7_amd64.deb";
      sha256 = "sha256-j/GrFQh5lnnjIJGIxfR2XD2hanh24iDEnYBe8DzO05c=";
    })
    (fetchDebPackage {
      name = "libatspi2.0-dev";
      url = "https://archive.debian.org/debian/pool/main/a/at-spi2-core/libatspi2.0-dev_2.30.0-7_amd64.deb";
      sha256 = "sha256-bMng9nw1/fCA2yFTRR1eJX9QJdtTgbp1VSiM1xOjHVM=";
    })
    (fetchDebPackage {
      name = "libdconf1";
      url = "https://archive.debian.org/debian/pool/main/d/dconf/libdconf1_0.30.1-2_amd64.deb";
      sha256 = "sha256-IndVY/2APbPa/k/Mk5UPcqzwTj2HtRs91cEHshEFpf8=";
    })
    (fetchDebPackage {
      name = "dconf-gsettings-backend";
      url = "https://archive.debian.org/debian/pool/main/d/dconf/dconf-gsettings-backend_0.30.1-2_amd64.deb";
      sha256 = "sha256-jdn2du1R21V8/bsQdUK/VAZifcHIPe1WUUnwKrtg4mg=";
    })
    (fetchDebPackage {
      name = "libcolord2";
      url = "https://archive.debian.org/debian/pool/main/c/colord/libcolord2_1.4.3-4_amd64.deb";
      sha256 = "sha256-L9ePx2HMhGVwLOTsA7xpIrFy5H9STHxkMS3PKtDbFIk=";
    })
    (fetchDebPackage {
      name = "libcups2";
      url = "https://archive.debian.org/debian/pool/main/c/cups/libcups2_2.2.10-6+deb10u6_amd64.deb";
      sha256 = "sha256-6B2JwhXP1XsX/Mumd8UBed9krtSVd5eFcpPcJq/NPII=";
    })
    (fetchDebPackage {
      name = "libcups2-dev";
      url = "https://archive.debian.org/debian/pool/main/c/cups/libcups2-dev_2.2.10-6+deb10u6_amd64.deb";
      sha256 = "sha256-E+NVVd+7xzT4BXqKbGbs4pVRh3YGQJWGJgvZfqYt1/k=";
    })
    (fetchDebPackage {
      name = "librest-0.7-0";
      url = "https://archive.debian.org/debian/pool/main/libr/librest/librest-0.7-0_0.8.1-1_amd64.deb";
      sha256 = "sha256-F9JUed2PsL/H/ZLKktfAY+nQoi9Dy5Di3iQ7iREc3pM=";
    })
    (fetchDebPackage {
      name = "libjson-glib-1.0-0";
      url = "https://archive.debian.org/debian/pool/main/j/json-glib/libjson-glib-1.0-0_1.4.4-2_amd64.deb";
      sha256 = "sha256-WPhy32vFIafvSZDCpLMmSxofqxVEApen6S74gGfjCO0=";
    })
    (fetchDebPackage {
      name = "libdrm2";
      url = "https://archive.debian.org/debian/pool/main/libd/libdrm/libdrm2_2.4.97-1_amd64.deb";
      sha256 = "sha256-dZyu8fv4hcUVrnJzzflp0YXPcna0MqgTxGZR5GjFdIk=";
    })
    (fetchDebPackage {
      name = "libdrm-dev";
      url = "https://archive.debian.org/debian/pool/main/libd/libdrm/libdrm-dev_2.4.97-1_amd64.deb";
      sha256 = "sha256-i1GXxAxf6woJa++uJziA/5BNRM1IU8E2yKX/nqfSRVg=";
    })
    (fetchDebPackage {
      name = "libdrm-amdgpu1";
      url = "https://archive.debian.org/debian/pool/main/libd/libdrm/libdrm-amdgpu1_2.4.97-1_amd64.deb";
      sha256 = "sha256-KDv/SQn1DaBR8FfPa46ExZBnXt6R5XznQU0vHUCXtpE=";
    })
    (fetchDebPackage {
      name = "libdrm-intel1";
      url = "https://archive.debian.org/debian/pool/main/libd/libdrm/libdrm-intel1_2.4.97-1_amd64.deb";
      sha256 = "sha256-1ctm+CaBGSrhQVc3DJj8ErrAMxKDqK/WssnBpwyRClc=";
    })
    (fetchDebPackage {
      name = "libdrm-nouveau2";
      url = "https://archive.debian.org/debian/pool/main/libd/libdrm/libdrm-nouveau2_2.4.97-1_amd64.deb";
      sha256 = "sha256-h1tgQoOtW1b7CuDsKLTlK6MFXOkRbnHUvOx4VLZ7p7Y=";
    })
    (fetchDebPackage {
      name = "libdrm-radeon1";
      url = "https://archive.debian.org/debian/pool/main/libd/libdrm/libdrm-radeon1_2.4.97-1_amd64.deb";
      sha256 = "sha256-5+mPe+7fsyaj3E0s7z7/FEx8/iK++ZwgBHCMGqXM64w=";
    })
    (fetchDebPackage {
      name = "libpciaccess0";
      url = "https://archive.debian.org/debian/pool/main/libp/libpciaccess/libpciaccess0_0.14-1_amd64.deb";
      sha256 = "sha256-X2zEjudIIAhYq1b0OkdTRzH1ASwsfJNqNktcUsDL6Ak=";
    })
    (fetchDebPackage {
      name = "libpciaccess-dev";
      url = "https://archive.debian.org/debian/pool/main/libp/libpciaccess/libpciaccess-dev_0.14-1_amd64.deb";
      sha256 = "sha256-BiVL2ua8nLobozHE1Ak6kVweTLZKWwuaGPr4ejxTJLU=";
    })
    (fetchDebPackage {
      name = "libwayland-bin";
      url = "https://archive.debian.org/debian/pool/main/w/wayland/libwayland-bin_1.16.0-1_amd64.deb";
      sha256 = "sha256-o5TP89a3tP1OfEAf8rVr6xEOSqPy4VZqM52i2YfeXhE=";
    })
    (fetchDebPackage {
      name = "wayland-protocols";
      url = "https://archive.debian.org/debian/pool/main/w/wayland-protocols/wayland-protocols_1.17-1_all.deb";
      sha256 = "sha256-EoO+YXCD9/OMiG99i94o73LQ12zpNjylNemtdpabBYM=";
    })
    (fetchDebPackage {
      name = "libxkbcommon-x11-0";
      url = "https://archive.debian.org/debian/pool/main/libx/libxkbcommon/libxkbcommon-x11-0_0.8.2-1_amd64.deb";
      sha256 = "sha256-uocM0NWWDKYq+nLkG0PvJK7A9I8z8/SOZN2mEJ4VD2E=";
    })
    (fetchDebPackage {
      name = "xkb-data";
      url = "https://archive.debian.org/debian/pool/main/x/xkeyboard-config/xkb-data_2.26-2_all.deb";
      sha256 = "sha256-F9IVZMlA3Y2J4KG2nW/qAUTQV+RpiQI3j1yDUAYSt3k=";
    })
    (fetchDebPackage {
      name = "libepoxy0";
      url = "https://archive.debian.org/debian/pool/main/libe/libepoxy/libepoxy0_1.5.3-0.1_amd64.deb";
      sha256 = "sha256-loKVrnOCvg/AblNfKhQI9UsLKQluAUJhjRhdocekLtA=";
    })
    (fetchDebPackage {
      name = "libepoxy-dev";
      url = "https://archive.debian.org/debian/pool/main/libe/libepoxy/libepoxy-dev_1.5.3-0.1_amd64.deb";
      sha256 = "sha256-Fcy8Orcq/8VSTfN4cZSjdVvbyBA1VDOPLvJlviCZpGo=";
    })
    (fetchDebPackage {
      name = "libatk-adaptor";
      url = "https://archive.debian.org/debian/pool/main/a/at-spi2-atk/libatk-adaptor_2.30.0-5_amd64.deb";
      sha256 = "sha256-MlDEAWX/61kKmDUohYlg7Er5d1boMI1z33rHJxH8gG8=";
    })
    (fetchDebPackage {
      name = "shared-mime-info";
      url = "https://archive.debian.org/debian/pool/main/s/shared-mime-info/shared-mime-info_1.10-1_amd64.deb";
      sha256 = "sha256-ahn2LFl4i6OlLIsIdQomPt3omsmOY8fkzPsUtA6vr1E=";
    })
    (fetchDebPackage {
      name = "libselinux1";
      url = "https://archive.debian.org/debian/pool/main/libs/libselinux/libselinux1_2.8-1+b1_amd64.deb";
      sha256 = "sha256-BSOKjBPDJBhRGpZee3VqsDHBQO8VTKCzsqG7ehTi+qs=";
    })
    (fetchDebPackage {
      name = "libselinux1-dev";
      url = "https://archive.debian.org/debian/pool/main/libs/libselinux/libselinux1-dev_2.8-1+b1_amd64.deb";
      sha256 = "sha256-2YiA+6oPoQNdaE7IkS6PD5wtHXOL8D6wygUr5Ui8gpc=";
    })
    (fetchDebPackage {
      name = "libsepol1";
      url = "https://archive.debian.org/debian/pool/main/libs/libsepol/libsepol1_2.8-1_amd64.deb";
      sha256 = "sha256-Xk6/iQurJCLTyv9XkAbALMOxU+mKYbjFSKlR4kwGk/I=";
    })
    (fetchDebPackage {
      name = "libpcre3";
      url = "https://archive.debian.org/debian/pool/main/p/pcre3/libpcre3_8.39-12_amd64.deb";
      sha256 = "sha256-VJbqRrgSsaABBPyXsw4T/F+Pbp7BKKj/T9LWaoDMa+4=";
    })
    (fetchDebPackage {
      name = "libpcre3-dev";
      url = "https://archive.debian.org/debian/pool/main/p/pcre3/libpcre3-dev_8.39-12_amd64.deb";
      sha256 = "sha256-4rPD3T4jpw+UiMMdU8iKrpD4TVdLb9sBXdbeSpzIU/4=";
    })
    (fetchDebPackage {
      name = "libssl1.1";
      url = "https://archive.debian.org/debian/pool/main/o/openssl/libssl1.1_1.1.1n-0+deb10u3_amd64.deb";
      sha256 = "sha256-kiR8LAEexMAfWDKjjeDsGpws+sXGxdwinloayBFIhUw=";
    })
    (fetchDebPackage {
      name = "liblzma5";
      url = "https://archive.debian.org/debian/pool/main/x/xz-utils/liblzma5_5.2.4-1+deb10u1_amd64.deb";
      sha256 = "sha256-wFR1Cr1bLFsrAjMp0E5Ki0Mt8RzUpkv4QkeKS2Co4UA=";
    })
    (fetchDebPackage {
      name = "liblzma-dev";
      url = "https://archive.debian.org/debian/pool/main/x/xz-utils/liblzma-dev_5.2.4-1+deb10u1_amd64.deb";
      sha256 = "sha256-8z2DU0ke23JUlDIohkCtjHYjNgVewProSZffQidY1c8=";
    })
    (fetchDebPackage {
      name = "libbz2-1.0";
      url = "https://archive.debian.org/debian/pool/main/b/bzip2/libbz2-1.0_1.0.6-9.2~deb10u1_amd64.deb";
      sha256 = "sha256-I4GTy6pxzFNl7yqlrUXehSGsON1U9KtTuvp94VBG+ok=";
    })
    (fetchDebPackage {
      name = "libbz2-dev";
      url = "https://archive.debian.org/debian/pool/main/b/bzip2/libbz2-dev_1.0.6-9.2~deb10u1_amd64.deb";
      sha256 = "sha256-T93PKkvYTAxHdh6koVfOB0X6K+/nGC6qu+AariYb7BI=";
    })
    (fetchDebPackage {
      name = "gettext";
      url = "https://archive.debian.org/debian/pool/main/g/gettext/gettext_0.19.8.1-9_amd64.deb";
      sha256 = "sha256-Iuu+B/CjbsgjZZ2ZIi5UmCKfAlT9+9fmghys5uMOGNA=";
    })
    (fetchDebPackage {
      name = "libseccomp2";
      url = "https://archive.debian.org/debian/pool/main/libs/libseccomp/libseccomp2_2.3.3-4_amd64.deb";
      sha256 = "sha256-DQ/PxhCnpwI9VYNeVd3PYlt2DRle8ln7E3r/+bpPLp0=";
    })
    (fetchDebPackage {
      name = "libkmod2";
      url = "https://archive.debian.org/debian/pool/main/k/kmod/libkmod2_26-1_amd64.deb";
      sha256 = "sha256-dsYUrXW1iG3g233cHpn2aS+qqCJRdqZaVPHIeAUzcYQ=";
    })
    (fetchDebPackage {
      name = "libelf1";
      url = "https://archive.debian.org/debian/pool/main/e/elfutils/libelf1_0.176-1.1_amd64.deb";
      sha256 = "sha256-zHSWyphqp30B4Ta43tWj43HsjySLMxtBJNH9LL6uw+8=";
    })
    (fetchDebPackage {
      name = "libelf-dev";
      url = "https://archive.debian.org/debian/pool/main/e/elfutils/libelf-dev_0.176-1.1_amd64.deb";
      sha256 = "sha256-65fV3/Lbme9E8TzDFRs/CmZuLJYJPV4yNAkUYI2HSlk=";
    })
    (fetchDebPackage {
      name = "libdw1";
      url = "https://archive.debian.org/debian/pool/main/e/elfutils/libdw1_0.176-1.1_amd64.deb";
      sha256 = "sha256-+qylrOkPEp08beiMZDpTPRtgNb4bmknQDF8nMuJXZcs=";
    })
    (fetchDebPackage {
      name = "libdw-dev";
      url = "https://archive.debian.org/debian/pool/main/e/elfutils/libdw-dev_0.176-1.1_amd64.deb";
      sha256 = "sha256-84/U8YL+R3PrsOxmA0M2ebxsNn9HJ//p0PpUyElhKB8=";
    })
    (fetchDebPackage {
      name = "gcc-8-base";
      url = "https://archive.debian.org/debian/pool/main/g/gcc-8/gcc-8-base_8.3.0-6_amd64.deb";
      sha256 = "sha256-GwD3zvVnZFp+aVyvbBrTlVd+fS6QOCAJfr00lt3PzIQ=";
    })
    (fetchDebPackage {
      name = "libgcc1";
      url = "https://archive.debian.org/debian/pool/main/g/gcc-8/libgcc1_8.3.0-6_amd64.deb";
      sha256 = "sha256-sbt2EfM3JzKInVAssdCf5XK1+7UoikqLHtA2P+zDVVo=";
    })
    (fetchDebPackage {
      name = "gcc-8";
      url = "https://archive.debian.org/debian/pool/main/g/gcc-8/gcc-8_8.3.0-6_amd64.deb";
      sha256 = "sha256-BekPlDYwVc8nzYi3loggZFGA03pkmpPPXX6m88f+lz4=";
    })
    (fetchDebPackage {
      name = "libgcc-8-dev";
      url = "https://archive.debian.org/debian/pool/main/g/gcc-8/libgcc-8-dev_8.3.0-6_amd64.deb";
      sha256 = "sha256-pS1SFoWMcYW8JF5SrZWmrVFdCHvCXoVW3wbFYmtBqDc=";
    })
    (fetchDebPackage {
      name = "libstartup-notification0";
      url = "https://archive.debian.org/debian/pool/main/s/startup-notification/libstartup-notification0_0.12-6_amd64.deb";
      sha256 = "sha256-C6a6thEQ8hGgILKNMmEGApvhhAZPvmsOfpN57k1yYTg=";
    })
    (fetchDebPackage {
      name = "libstartup-notification0-dev";
      url = "https://archive.debian.org/debian/pool/main/s/startup-notification/libstartup-notification0-dev_0.12-6_amd64.deb";
      sha256 = "sha256-lApNTLYzyXIK+XsAER2NWdC2CwozysRJ7OEIp4tg4i0=";
    })
    (fetchDebPackage {
      name = "libicu63";
      url = "https://archive.debian.org/debian/pool/main/i/icu/libicu63_63.1-6+deb10u3_amd64.deb";
      sha256 = "sha256-OPZarsTuCI9lMwz2NsHNbt7zgQnIBVmDbs844jkKV2E=";
    })
    (fetchDebPackage {
      name = "libicu-dev";
      url = "https://archive.debian.org/debian/pool/main/i/icu/libicu-dev_63.1-6+deb10u3_amd64.deb";
      sha256 = "sha256-bmh6ID44ByUChMZufuhEipUte+egAXvm1kOClrfs05Q=";
    })
    (fetchDebPackage {
      name = "libgraphite2-3";
      url = "https://archive.debian.org/debian/pool/main/g/graphite2/libgraphite2-3_1.3.13-7_amd64.deb";
      sha256 = "sha256-95v9z+CShczO5owHAXGIi5itvz570+j2r8tsrvViMXk=";
    })
    (fetchDebPackage {
      name = "libgraphite2-dev";
      url = "https://archive.debian.org/debian/pool/main/g/graphite2/libgraphite2-dev_1.3.13-7_amd64.deb";
      sha256 = "sha256-6bhlU0pGWy8tonudjQNdatfN2IV39rmgPt5DT4DwcmI=";
    })
    (fetchDebPackage {
      name = "libxft2";
      url = "https://archive.debian.org/debian/pool/main/x/xft/libxft2_2.3.2-2_amd64.deb";
      sha256 = "sha256-zXE4S01RHLppvO4przJpQ8fKEkUHZfRMQNJGYIx3mq0=";
    })
    (fetchDebPackage {
      name = "libxft-dev";
      url = "https://archive.debian.org/debian/pool/main/x/xft/libxft-dev_2.3.2-2_amd64.deb";
      sha256 = "sha256-xpGbE0I9TjtBt2ULLZu29t6sKQaz1R0Ee1iYoWnrwTw=";
    })
    (fetchDebPackage {
      name = "libwayland-egl-backend-dev";
      url = "https://archive.debian.org/debian/pool/main/w/wayland/libwayland-egl-backend-dev_1.16.0-1_amd64.deb";
      sha256 = "sha256-6DfrXthu+XrgmFjl1VegRHg9cDGiR2XIKWcbaMg8KoQ=";
    })
  ];

in
stdenv.mkDerivation {
  name = "deb10sysroot";

  # No source archive - we assemble from individual .deb files
  dontUnpack = true;

  nativeBuildInputs = [ dpkg ];

  buildPhase = ''
    mkdir -p $out

    # Unpack each .deb into the sysroot
    for deb in ${lib.concatStringsSep " " debPackages}; do
      echo "Unpacking $deb ..."
      dpkg-deb -x "$deb" "$out"
    done

    # Remove files that conflict with our custom toolchain builds
    # (expat comes from our own build; libstdc++ is not used - we use libc++)
    # rm -f $out/lib/x86_64-linux-gnu/pkgconfig/expat.pc || true
    # rm -f $out/usr/lib/x86_64-linux-gnu/libexpat.so* || true
    # rm -f $out/usr/lib/x86_64-linux-gnu/libexpat.a || true

    # Fix absolute symlinks: Debian packages contain symlinks to absolute paths
    # (e.g. /lib/x86_64-linux-gnu/libfoo.so.1) which break outside a real rootfs.
    echo "Fixing absolute symlinks..."
    find "$out" -type l | while read -r symlink; do
      target=$(readlink "$symlink")
      if [[ "$target" == /* ]]; then
        sysroot_target="$out$target"
        if [ -e "$sysroot_target" ]; then
          rel_target=$(realpath --relative-to="$(dirname "$symlink")" "$sysroot_target")
          ln -sf "$rel_target" "$symlink"
        else
          echo "Removing dangling absolute symlink: $symlink -> $target"
          rm -f "$symlink"
        fi
      fi
    done

    # Remove any remaining dangling symlinks. Some -dev packages reference versioned
    # .so files from runtime variants (e.g. libpcre16, libpcre32, libtiffxx) that
    # we have not included. These are not needed for cross-compilation.
    echo "Removing remaining dangling symlinks..."
    find "$out" -type l | while read -r symlink; do
      if ! [ -e "$symlink" ]; then
        echo "Removing dangling symlink: $symlink -> $(readlink "$symlink")"
        rm -f "$symlink"
      fi
    done
  '';

  installPhase = "true";
}