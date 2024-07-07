#!/bin/sh

set -ex

DIR="${1:-.}"

MAKEOPTS=-j5

GCC_VERSION=14.1.0
BINUTILS_VERSION=2.42
NEWLIB_VERSION=4.4.0.20231231

GCC_MIRROR=https://mirrorservice.org/sites/sourceware.org/pub/gcc/releases
BINUTILS_MIRROR=https://mirrorservice.org/sites/sourceware.org/pub/binutils/releases
NEWLIB_MIRROR=https://mirrorservice.org/sites/sourceware.org/pub/newlib

mkdir -p "${DIR}"
cd "${DIR}"

mkdir -p archive
wget -nc --directory-prefix=archive "${GCC_MIRROR}/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz"
wget -nc --directory-prefix=archive "${BINUTILS_MIRROR}/binutils-${BINUTILS_VERSION}.tar.xz"
wget -nc --directory-prefix=archive "${NEWLIB_MIRROR}/newlib-${NEWLIB_VERSION}.tar.gz"

PREFIX=`pwd`
PATH="${PREFIX}/bin${PATH:+:}${PATH}"
export PATH

mkdir -p elf
cd elf
test -d gcc-"${GCC_VERSION}" || tar xJf ../archive/gcc-"${GCC_VERSION}".tar.xz
test -d binutils-"${BINUTILS_VERSION}" || tar xJf ../archive/binutils-"${BINUTILS_VERSION}".tar.xz
test -d newlib-"${NEWLIB_VERSION}" || tar xzf ../archive/newlib-"${NEWLIB_VERSION}".tar.gz

mkdir build-binutils; cd build-binutils
  ../binutils-"${BINUTILS_VERSION}"/configure \
	      --target=or1k-elf \
	      --prefix="${PREFIX}" \
	      --disable-itcl \
	      --disable-tk \
	      --disable-tcl \
	      --disable-winsup \
	      --disable-gdbtk \
	      --disable-rda \
	      --disable-sid \
	      --disable-sim \
	      --disable-gdb \
	      --with-sysroot \
	      --disable-newlib \
	      --disable-libgloss \
	      --with-system-zlib
  make $MAKEOPTS
  make install
cd ..

mkdir build-gcc-stage1; cd build-gcc-stage1
  ../gcc-"${GCC_VERSION}"/configure \
	 --target=or1k-elf \
	 --prefix="${PREFIX}" \
	 --enable-languages=c \
	 --with-multilib-list=mcmov,msext,msfimm \
	 --disable-shared \
	 --disable-libssp
  make $MAKEOPTS
  make install
cd ..

mkdir build-newlib; cd build-newlib
  ../newlib-"${NEWLIB_VERSION}"/configure \
	    --target=or1k-elf \
	    --prefix="${PREFIX}" \
	    --disable-newlib-wide-orient \
	    --enable-newlib-nano-malloc \
	    --disable-newlib-unbuf-stream-opt \
	    --disable-newlib-iconv \
	    --disable-newlib-io-float \
	    --enable-newlib-nano-formatted-io \
	    CC_FOR_TARGET=or1k-elf-gcc \
	    CFLAGS_FOR_TARGET="-g -O2 -Wno-implicit-function-declaration -Wno-incompatible-pointer-types -Wno-int-conversion"
  make $MAKEOPTS
  make install
cd ..

mkdir build-gcc-stage2; cd build-gcc-stage2
  ../gcc-"${GCC_VERSION}"/configure \
	 --target=or1k-elf \
	 --prefix="${PREFIX}" \
	 --enable-languages=c,c++ \
	 --with-multilib-list=mcmov,msext,msfimm \
	 --disable-shared \
	 --disable-libssp \
	 --with-newlib
  make $MAKEOPTS
  make install
cd ..

cd ..
rm -rf elf
