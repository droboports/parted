CFLAGS="${CFLAGS:-} -ffunction-sections -fdata-sections"
LDFLAGS="-L${DEST}/lib -L${DEPS}/lib -Wl,--gc-sections -Wl,-rpath-link,${DEPS}/lib"

### PCRE ###
_build_pcre() {
local VERSION="8.37"
local FOLDER="pcre-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --disable-shared --enable-static --disable-cpp --enable-utf --enable-unicode-properties
make
make install
popd
}

### LIBSEPOL ###
_build_libsepol() {
local VERSION="2.4"
local FOLDER="libsepol-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://raw.githubusercontent.com/wiki/SELinuxProject/selinux/files/releases/20150202/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
make install ARCH="arm" DESTDIR="${DEPS}" PREFIX="${DEPS}"
rm -vf "${DEPS}/lib/libsepol.so"*
popd
}

### LIBSELINUX ###
# requires pcre, libsepol
_build_libselinux() {
local VERSION="2.4"
local FOLDER="libselinux-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://raw.githubusercontent.com/wiki/SELinuxProject/selinux/files/releases/20150202/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
make install ARCH="arm" DESTDIR="${DEPS}" PREFIX="${DEPS}"
rm -vf "${DEPS}/lib/libselinux.so"*
popd
}

### E2FSPROGS ###
_build_e2fsprogs() {
local VERSION="1.42.13"
local FOLDER="e2fsprogs-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sourceforge.net/projects/e2fsprogs/files/e2fsprogs/v${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp "src/${FOLDER}-dumpe2fs.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 -i "${FOLDER}-dumpe2fs.patch"
./configure --host="${HOST}" --prefix="${DEPS}" --disable-elf-shlibs \
  --enable-symlink-install --enable-relative-symlinks --enable-symlink-build --enable-threads=posix --disable-rpath
make
pushd "lib/uuid"
make install
popd
popd
}

### PARTED ###
_build_parted() {
# parted versions > 1.9.0 are not compatible with the 5N
local VERSION="1.9.0"
local FOLDER="parted-${VERSION}"
local FILE="${FOLDER}.tar.xz"
local URL="http://ftp.gnu.org/gnu/parted/${FILE}"

_download_xz "${FILE}" "${URL}" "${FOLDER}"
# see https://lists.gnu.org/archive/html/bug-parted/2014-07/msg00036.html
#cp "src/${FOLDER}-no-dm.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
#patch -p1 -i "${FOLDER}-no-dm.patch"
./configure --host="${HOST}" --prefix="${DEST}" --mandir="${DEST}/man" --disable-shared \
  --enable-selinux --disable-device-mapper --without-readline --disable-rpath
make
make install
find "${DEST}" -type f -executable -print | while read binfile; do
  if file "${binfile}" | grep -q "executable, ARM"; then
    echo "${binfile}"
    "${STRIP}" -s -R .comment -R .note -R .note.ABI-tag "${binfile}"
  fi
done
popd
}

_build_rootfs() {
# /sbin/parted
  return 0
}

_build() {
  _build_pcre
  _build_libsepol
  _build_libselinux
  _build_e2fsprogs
  _build_parted
  _package
}
