#!/usr/bin/env bash

RAMDISK=$(diskutil list | awk '/tmp-ffmpeg/ {print $5}')

if [ -z "${RAMDISK}" ]; then
  diskutil erasevolume HFS+ 'tmp-ffmpeg' $(hdiutil attach -nobrowse -nomount ram://8388608)
else
  hdiutil detach ${RAMDISK}
  diskutil erasevolume HFS+ 'tmp-ffmpeg' $(hdiutil attach -nobrowse -nomount ram://8388608)
fi

export SOURCE="/Volumes/tmp-ffmpeg/sw"
export COMPILED="/Volumes/tmp-ffmpeg/compile"

mkdir -p ${SOURCE}
mkdir -p ${COMPILED}

cp -r patches ${COMPILED}/

export PATH=${SOURCE}/bin:$PATH
export CC=clang
export PKG_CONFIG_PATH="${SOURCE}/lib/pkgconfig"

#
# versions
#

YASM_VERSION=1.3.0
NASM_VERSION=2.15.05
PKG_CONFIG_VERSION=0.29.1
ZLIB_VERSION=1.2.12
CMAKE_VERSION=3.23.2
FDK_AAC_VERSION=2.0.2
VPX_VERSION=1.11.0
EXPAT_VERSION=2.4.8
ICONV_VERSION=1.17
GETTEXT_VERSION=0.21
ENCA_VERSION=1.19
FREETYPE_VERSION=2.12.1
FRIBIDI_VERSION=1.0.12
FONTCONFIG_VERSION=2.14.0
HARFBUZZ_VERSION=4.3.0
LIBASS_VERSION=0.16.0
OPUS_VERSION=1.3.1
LIBOGG_VERSION=1.3.5
LIBVORBIS_VERSION=1.3.7
LIBTHEORA_VERSION=1.1.1
SNAPPY_VERSION=1.1.9
OPENJPEG_VERSION=2.5.0
LIBWEBP_VERSION=1.2.2
FFMPEG_VERSION=5.0.1
SDL_VERSION=2.0.22


echo '♻️ ' Start compiling YASM

#
# compile YASM
#

cd ${COMPILED}

wget http://www.tortall.net/projects/yasm/releases/yasm-${YASM_VERSION}.tar.gz
tar xf yasm-${YASM_VERSION}.tar.gz
cd yasm-${YASM_VERSION}

./configure --prefix=${SOURCE}

make -j

if [ $? -ne 0 ]; then
  echo "YASM compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "YASM compile failed"
  exit 1
fi

sleep 1

echo '♻️ ' Start compiling NASM

#
# compile NASM
#

cd ${COMPILED}
wget https://www.nasm.us/pub/nasm/releasebuilds/${NASM_VERSION}/nasm-${NASM_VERSION}.tar.gz
tar xf nasm-${NASM_VERSION}.tar.gz
cd nasm-${NASM_VERSION}

./configure --prefix=${SOURCE}

make -j

if [ $? -ne 0 ]; then
  echo "NASM compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "NASM compile failed"
  exit 1
fi

sleep 1

echo '♻️ ' Start compiling PKG

#
# compile PKG
#


cd ${COMPILED}
wget https://pkg-config.freedesktop.org/releases/pkg-config-${PKG_CONFIG_VERSION}.tar.gz
tar xf pkg-config-${PKG_CONFIG_VERSION}.tar.gz
cd pkg-config-${PKG_CONFIG_VERSION}


export LDFLAGS="-framework Foundation -framework Cocoa"

./configure --prefix=${SOURCE} --with-pc-path=${SOURCE}/lib/pkgconfig --with-internal-glib --disable-shared --enable-static

make -j

if [ $? -ne 0 ]; then
  echo "PKG compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "PKG compile failed"
  exit 1
fi

unset LDFLAGS

sleep 1

echo '♻️ ' Start compiling ZLIB

#
# ZLIB
#

cd ${COMPILED}
wget https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz
tar xf zlib-${ZLIB_VERSION}.tar.gz
cd zlib-${ZLIB_VERSION}

./configure --prefix=${SOURCE}

make -j

if [ $? -ne 0 ]; then
  echo "ZLIB compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "ZLIB compile failed"
  exit 1
fi

rm ${SOURCE}/lib/libz.so*

rm ${SOURCE}/lib/libz.*

echo '♻️ ' Start compiling CMAKE

#
# compile CMAKE
#

cd ${COMPILED}
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz

tar xf cmake-${CMAKE_VERSION}.tar.gz

cd cmake-${CMAKE_VERSION}


./configure --prefix=${SOURCE}


make -j

if [ $? -ne 0 ]; then
  echo "CMAKE compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "CMAKE compile failed"
  exit 1
fi

sleep 1

echo '♻️ ' Start compiling Lame

#
# compile LAME
#

cd ${COMPILED}
git clone https://git.skj.dev/sean/lame
cd lame

./configure --prefix=${SOURCE} --disable-shared --enable-static --disable-frontend --disable-debug --disable-dependency-tracking --disable-decoder

make -j

if [ $? -ne 0 ]; then
  echo "LAME compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "LAME compile failed"
  exit 1
fi

echo '♻️ ' Start compiling X264

#
# compile FDK-AAC
#

cd ${COMPILED}
wget https://github.com/mstorsjo/fdk-aac/archive/refs/tags/v${FDK_AAC_VERSION}.tar.gz
tar xf v${FDK_AAC_VERSION}.tar.gz
cd fdk-aac-${FDK_AAC_VERSION}

autoreconf -fiv
./configure --prefix=${SOURCE} --enable-static --disable-shared

make -j

if [ $? -ne 0 ]; then
  echo "FDK-AAC compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "FDK-AAC compile failed"
  exit 1
fi

#
# x264
#

cd ${COMPILED}
git clone https://code.videolan.org/videolan/x264.git
cd x264

./configure --prefix=${SOURCE} --disable-shared --enable-static --enable-pic --disable-cli

make -j

if [ $? -ne 0 ]; then
  echo "x264 compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "x264 compile failed"
  exit 1
fi

make install-lib-static

if [ $? -ne 0 ]; then
  echo "x264 compile failed"
  exit 1
fi

# echo
# echo continue
# read -s

sleep 1

echo '♻️ ' Start compiling X265

#
# x265
#

rm -f ${SOURCE}/include/x265*.h 2>/dev/null
rm -f ${SOURCE}/lib/libx265.a 2>/dev/null

cd ${COMPILED}
git clone https://bitbucket.org/multicoreware/x265_git
cd x265_git/build/linux

patch -p1 multilib.sh < ../../../patches/multilib.patch

./multilib.sh

if [ $? -ne 0 ]; then
  echo "x265 compile failed"
  exit 1
fi

sleep 1

echo '♻️ ' Start compiling VPX

#
# VPX
#

cd ${COMPILED}
wget https://github.com/webmproject/libvpx/archive/refs/tags/v${VPX_VERSION}.tar.gz
tar xf v${VPX_VERSION}.tar.gz
cd libvpx-${VPX_VERSION}

./configure --prefix=${SOURCE} --enable-vp8 --enable-postproc --enable-vp9-postproc --enable-vp9-highbitdepth --disable-examples --disable-docs --enable-multi-res-encoding --disable-unit-tests --enable-pic --disable-shared

make -j

if [ $? -ne 0 ]; then
  echo "VPX compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "VPX compile failed"
  exit 1
fi

echo '♻️ ' Start compiling EXPAT

#
# EXPAT
#

cd ${COMPILED}
wget https://github.com/libexpat/libexpat/archive/refs/tags/R_${EXPAT_VERSION//./_}.tar.gz
tar xf R_${EXPAT_VERSION//./_}.tar.gz
cd libexpat-R_${EXPAT_VERSION//./_}/expat

./buildconf.sh
./configure --prefix=${SOURCE} --disable-shared --enable-static

make -j

if [ $? -ne 0 ]; then
  echo "EXPAT compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "EXPAT compile failed"
  exit 1
fi

echo '♻️ ' Start compiling LIBICONV

#
# LIBICONV
#

cd ${COMPILED}
wget https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${ICONV_VERSION}.tar.gz
tar xf libiconv-${ICONV_VERSION}.tar.gz
cd libiconv-${ICONV_VERSION}

./configure --prefix=${SOURCE} --disable-shared --enable-static

make -j

if [ $? -ne 0 ]; then
  echo "LIBICONV compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "LIBICONV compile failed"
  exit 1
fi

echo '♻️ ' Start compiling Gettext

#
# GETTEXT
#

cd ${COMPILED}
wget https://ftp.gnu.org/pub/gnu/gettext/gettext-${GETTEXT_VERSION}.tar.gz
tar xf gettext-${GETTEXT_VERSION}.tar.gz
cd gettext-${GETTEXT_VERSION}

./configure --prefix=${SOURCE} --disable-dependency-tracking --disable-silent-rules --disable-debug --with-included-gettext --with-included-glib \
--with-included-libcroco --with-included-libunistring --with-emacs --disable-java --disable-native-java --disable-csharp \
--disable-shared --enable-static --without-git --without-cvs --disable-docs --disable-examples

make -j

if [ $? -ne 0 ]; then
  echo "GETTEXT compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "GETTEXT compile failed"
  exit 1
fi

echo '♻️ ' Start compiling LIBPNG

#
# LIBPNG
#

cd ${COMPILED}
git clone https://git.code.sf.net/p/libpng/code libpng
cd libpng

./configure --prefix=${SOURCE} --disable-dependency-tracking --disable-silent-rules --enable-static --disable-shared

make -j

if [ $? -ne 0 ]; then
  echo "LIBPNG compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "LIBPNG compile failed"
  exit 1
fi

echo '♻️ ' Start compiling ENCA


#
# ENCA
#

cd ${COMPILED}
wget https://dl.cihar.com/enca/enca-${ENCA_VERSION}.tar.xz
tar xf enca-${ENCA_VERSION}.tar.xz
cd enca-${ENCA_VERSION}

./configure --prefix=${SOURCE} --disable-shared --enable-static

make -j

if [ $? -ne 0 ]; then
  echo "ENCA compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "ENCA compile failed"
  exit 1
fi

echo '♻️ ' Start compiling FREETYPE

#
# FREETYPE
#

cd ${COMPILED}
wget https://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VERSION}.tar.gz
tar xf freetype-${FREETYPE_VERSION}.tar.gz
cd freetype-${FREETYPE_VERSION}

./configure --prefix=${SOURCE} --disable-shared --enable-static

make -j

if [ $? -ne 0 ]; then
  echo "FREETYPE compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "FREETYPE compile failed"
  exit 1
fi

echo '♻️ ' Start compiling FRIBIDI

#
# FRIBIDI
#

cd ${COMPILED}
wget https://github.com/fribidi/fribidi/releases/download/v${FRIBIDI_VERSION}/fribidi-${FRIBIDI_VERSION}.tar.xz
tar xf fribidi-${FRIBIDI_VERSION}.tar.xz
cd fribidi-${FRIBIDI_VERSION}

./configure --prefix=${SOURCE} --disable-shared --enable-static

make -j

if [ $? -ne 0 ]; then
  echo "FRIBIDI compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "FRIBIDI compile failed"
  exit 1
fi


echo '♻️ ' Start compiling FONTCONFIG

#
# FONTCONFIG
#

cd ${COMPILED}
wget https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.gz
tar xf fontconfig-${FONTCONFIG_VERSION}.tar.gz
cd fontconfig-${FONTCONFIG_VERSION}

./configure --prefix=${SOURCE} --enable-iconv --disable-libxml2 --disable-shared --enable-static

make -j

if [ $? -ne 0 ]; then
  echo "FONTCONFIG compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "FONTCONFIG compile failed"
  exit 1
fi

sleep 1

echo '♻️ ' Start compiling harfbuzz

#
# HARFBUZZ
#

cd ${COMPILED}
wget https://github.com/harfbuzz/harfbuzz/releases/download/${HARFBUZZ_VERSION}/harfbuzz-${HARFBUZZ_VERSION}.tar.xz
tar xf harfbuzz-${HARFBUZZ_VERSION}.tar.xz
cd harfbuzz-${HARFBUZZ_VERSION}

./configure --prefix=${SOURCE} --disable-shared --enable-static

make -j

if [ $? -ne 0 ]; then
  echo "HARFBUZZ compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "HARFBUZZ compile failed"
  exit 1
fi


echo '♻️ ' Start compiling LIBASS

sleep 1

#
# LIBASS
#

cd ${COMPILED}
wget https://github.com/libass/libass/releases/download/${LIBASS_VERSION}/libass-${LIBASS_VERSION}.tar.gz
tar xf libass-${LIBASS_VERSION}.tar.gz
cd libass-${LIBASS_VERSION}

./configure --prefix=${SOURCE} --disable-fontconfig --disable-shared --enable-static

make -j

if [ $? -ne 0 ]; then
  echo "LIBASS compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "LIBASS compile failed"
  exit 1
fi

sleep 1

echo '♻️ ' Start compiling OPUS

#
# OPUS
#

cd ${COMPILED}
wget https://archive.mozilla.org/pub/opus/opus-${OPUS_VERSION}.tar.gz
tar xf opus-${OPUS_VERSION}.tar.gz
cd opus-${OPUS_VERSION}

./configure --prefix=${SOURCE} --disable-shared --enable-static

make -j

if [ $? -ne 0 ]; then
  echo "OPUS compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "OPUS compile failed"
  exit 1
fi

sleep 1



#
# LIBOGG
#

cd ${COMPILED}
wget https://downloads.xiph.org/releases/ogg/libogg-${LIBOGG_VERSION}.tar.gz
tar xf libogg-${LIBOGG_VERSION}.tar.gz
cd libogg-${LIBOGG_VERSION}

./configure --prefix=${SOURCE} --disable-shared --enable-static

make -j

if [ $? -ne 0 ]; then
  echo "LIBOGG compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "LIBOGG compile failed"
  exit 1
fi

sleep 1

#
# LIBVORBIS
#

cd ${COMPILED}
wget https://downloads.xiph.org/releases/vorbis/libvorbis-${LIBVORBIS_VERSION}.tar.gz
tar xf libvorbis-${LIBVORBIS_VERSION}.tar.gz
cd libvorbis-${LIBVORBIS_VERSION}

./configure --prefix=${SOURCE} --with-ogg-libraries=${SOURCE}/lib --with-ogg-includes=${SOURCE}/include/ --enable-static --disable-shared

make -j

if [ $? -ne 0 ]; then
  echo "LIBVORBIS compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "LIBVORBIS compile failed"
  exit 1
fi

sleep 1

#
# THEORA
#

cd ${COMPILED}
wget https://downloads.xiph.org/releases/theora/libtheora-${LIBTHEORA_VERSION}.tar.bz2
tar xf libtheora-${LIBTHEORA_VERSION}.tar.bz2
cd libtheora-${LIBTHEORA_VERSION}

./configure --prefix=${SOURCE} --disable-asm --with-ogg-libraries=${SOURCE}/lib --with-ogg-includes=${SOURCE}/include/ --with-vorbis-libraries=${SOURCE}/lib --with-vorbis-includes=${SOURCE}/include/ --enable-static --disable-shared --disable-examples --disable-doc

make -j

if [ $? -ne 0 ]; then
  echo "LIBTHEORA compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "LIBTHEORA compile failed"
  exit 1
fi

sleep 1

echo '♻️ ' Start compiling Vid-stab

#
# Vidstab
#

cd ${COMPILED}
git clone https://github.com/georgmartius/vid.stab.git
cd vid.stab

cmake -DCMAKE_INSTALL_PREFIX:PATH=${SOURCE} -DLIBTYPE=STATIC -DBUILD_SHARED_LIBS=OFF -DUSE_OMP=OFF -DENABLE_SHARED=off .

make -j

if [ $? -ne 0 ]; then
  echo "VIDSTAB compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "VIDSTAB compile failed"
  exit 1
fi

sleep 1

#
# OpenJPEG
#

cd ${COMPILED}
wget https://github.com/uclouvain/openjpeg/archive/refs/tags/v${OPENJPEG_VERSION}.tar.gz
tar xf v${OPENJPEG_VERSION}.tar.gz
cd openjpeg-${OPENJPEG_VERSION}

cmake -DCMAKE_INSTALL_PREFIX:PATH=${SOURCE} -DENABLE_C_DEPS=ON -DLIBTYPE=STATIC -DENABLE_SHARED=OFF -DENABLE_STATIC=ON .

make -j

if [ $? -ne 0 ]; then
  echo "OPENJPEG compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "OPENJPEG compile failed"
  exit 1
fi

rm ${SOURCE}/lib/libopenjp2.2.4.0.dy*
rm ${SOURCE}/lib/libopenjp2.dy*
rm ${SOURCE}/lib/libopenjp2.7.dy*

sleep 1

echo '♻️ ' Start compiling WEBP

#
# WEBP
#

cd ${COMPILED}
wget https://github.com/webmproject/libwebp/archive/refs/tags/v${LIBWEBP_VERSION}.tar.gz
tar xf v${LIBWEBP_VERSION}.tar.gz
cd libwebp-${LIBWEBP_VERSION}

cmake -DCMAKE_INSTALL_PREFIX:PATH=${SOURCE} -DENABLE_C_DEPS=ON -DLIBTYPE=STATIC -DENABLE_SHARED=OFF -DENABLE_STATIC=ON .

make -j

if [ $? -ne 0 ]; then
  echo "LIBPNG compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "LIBPNG compile failed"
  exit 1
fi

sleep 1

#
# SDL
#

cd ${COMPILED}
wget https://libsdl.org/release/SDL2-${SDL_VERSION}.tar.gz
tar xf SDL2-${SDL_VERSION}.tar.gz
cd SDL2-${SDL_VERSION}

./configure --prefix=${SOURCE} --enable-shared=no --enable-static=yes

make -j

if [ $? -ne 0 ]; then
  echo "SDL2 compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "SDL2 compile failed"
  exit 1
fi

#
# SVT-AV1
#

cd ${COMPILED}
git clone --depth=1 https://gitlab.com/AOMediaCodec/SVT-AV1.git
cd SVT-AV1
cd Build
cmake .. -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=${SOURCE} -DBUILD_SHARED_LIBS=off

make -j
make install

#
# ffmpeg
#

echo '♻️ ' Start compiling FFMPEG

cd ${COMPILED}
wget https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2
tar xf ffmpeg-${FFMPEG_VERSION}.tar.bz2
cd ffmpeg-${FFMPEG_VERSION}

export LDFLAGS="-L${SOURCE}/lib"

export CFLAGS="-I${SOURCE}/include"

export LDFLAGS="$LDFLAGS -framework VideoToolbox"

./configure --prefix=${SOURCE} \
  --extra-cflags="-fno-stack-check" \
  --arch=arm64 \
  --cc=/usr/bin/clang \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --enable-gpl \
  --enable-libopenjpeg \
  --enable-libopus \
  --enable-libmp3lame \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libvpx \
  --enable-libwebp \
  --enable-libass \
  --enable-libfreetype \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libvidstab \
  --enable-version3 \
  --enable-libfdk_aac \
  --pkg-config-flags="--static" \
  --enable-postproc \
  --enable-nonfree \
  --enable-neon \
  --enable-runtime-cpudetect \
  --enable-libsvtav1

make -j

if [ $? -ne 0 ]; then
  echo "FFMPEG compile failed"
  exit 1
fi

make install

if [ $? -ne 0 ]; then
  echo "FFMPEG compile failed"
  exit 1
fi

#
# Create Package
#

cd ${SOURCE}/bin
zip ffmpeg_bin.zip ffmpeg ffprobe
cp ffmpeg_bin.zip "${HOME}/"

