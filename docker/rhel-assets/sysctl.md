Includes a patched version of sysctl that exits 0 when encountering a
read-only filesystem on /proc or when running as non-root user

These patches are included by default Debian/Ubuntu.

This was compiled on rhel 7 by doing:

1. Clone the source from: https://gitlab.com/procps-ng/procps
2. Checkout the right tag for rhel 7 (currently ships with v3.3.10)
3. Grab debians patch files from: https://launchpad.net/ubuntu/+archive/primary/+files/procps_3.3.10-4ubuntu2.debian.tar.xz
4. Apply patch files: `debian/patches/ignore_eaccess.patch` and `debian/patches/erofs_eaccess.patch`
5. Run `autogen.sh`
6. Run configure with the flags used by centos7 `./configure --prefix=/ --bindir=/usr/bin --sbindir=/usr/sbin --libdir=/usr/lib64 --mandir=/usr/share/man --includedir=/usr/include --sysconfdir=/etc --localedir=/usr/share/locale --docdir=/unwanted --disable-static --enable-w-from --disable-kill --disable-rpath --enable-watch8bit --enable-skill --enable-sigwinch --enable-libselinux --disable-pidof --disable-modern-top`
7. Run `make`
8. `.libs/sysctl` is your patched sysctl
