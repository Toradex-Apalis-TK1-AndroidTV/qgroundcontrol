#!/bin/bash -x

set +e

if [[ $# -eq 0 ]]; then
	echo 'create_linux_appimage.sh QGC_SRC_DIR QGC_RELEASE_DIR'
	exit 1
fi

QGC_SRC=$1
if [ ! -f ${QGC_SRC}/qgroundcontrol.pro ]; then
	echo 'please specify path to qgroundcontrol source as the 1st argument'
	exit 1
fi

QGC_RELEASE_DIR=$2
if [ ! -f ${QGC_RELEASE_DIR}/QGroundControl ]; then
	echo 'please specify path to QGroundControl release as the 2nd argument'
	exit 1
fi

OUTPUT_DIR=${3-`pwd`}
echo "Output directory:" ${OUTPUT_DIR}

# Generate AppImage using the binaries currently provided by the project.
# These require at least GLIBC 2.14, which older distributions might not have. 
# On the other hand, 2.14 is not that recent so maybe we can just live with it.

APP=QGroundControl

TMPDIR=`mktemp -d`
APPDIR=${TMPDIR}/$APP".AppDir"
mkdir -p ${APPDIR}

cd ${TMPDIR}
wget -c --quiet http://ftp.us.debian.org/debian/pool/main/u/udev/udev_175-7.2_armhf.deb
wget -c --quiet http://ftp.us.debian.org/debian/pool/main/s/speech-dispatcher/speech-dispatcher_0.8.8-6_armhf.deb
wget -c --quiet http://ftp.us.debian.org/debian/pool/main/libs/libsdl2/libsdl2-2.0-0_2.0.2%2bdfsg1-6_armhf.deb

cd ${APPDIR}
find ../ -name *.deb -exec dpkg -x {} . \;

# copy libdirectfb-1.2.so.9
cd ${TMPDIR}
wget -c --quiet http://ftp.us.debian.org/debian/pool/main/d/directfb/libdirectfb-1.2-9_1.2.10.0-5.1_armhf.deb
mkdir libdirectfb
dpkg -x libdirectfb-1.2-9_1.2.10.0-5.1_armhf.deb libdirectfb
cp -L libdirectfb/usr/lib/arm-linux-gnueabihf/libdirectfb-1.2.so.9 ${APPDIR}/usr/lib/arm-linux-gnueabihf/
cp -L libdirectfb/usr/lib/arm-linux-gnueabihf/libfusion-1.2.so.9 ${APPDIR}/usr/lib/arm-linux-gnueabihf/
cp -L libdirectfb/usr/lib/arm-linux-gnueabihf/libdirect-1.2.so.9 ${APPDIR}/usr/lib/arm-linux-gnueabihf/

# copy libts-0.0-0
wget -c --quiet http://ftp.us.debian.org/debian/pool/main/t/tslib/libts0_1.16-1_armhf.deb
mkdir libts
dpkg -x libts0_1.16-1_armhf.deb libts
cp -L libts/usr/lib/arm-linux-gnueabihf/libts.so.0.9.1 ${APPDIR}/usr/lib/arm-linux-gnueabihf/

# copy QGroundControl release into appimage
cp -r ${QGC_RELEASE_DIR}/* ${APPDIR}/
rm -rf ${APPDIR}/package
mv ${APPDIR}/qgroundcontrol-start.sh ${APPDIR}/AppRun

# copy icon
cp ${QGC_SRC}/resources/icons/qgroundcontrol.png ${APPDIR}/

cat > ./qgroundcontrol.desktop <<\EOF
[Desktop Entry]
Type=Application
Name=QGroundControl
GenericName=Ground Control Station
Comment=UAS ground control station
Icon=qgroundcontrol
Exec=AppRun
Terminal=false
Categories=Utility;
Keywords=computer;
EOF

VERSION=$(strings ${APPDIR}/qgroundcontrol | grep '^v[0-9*]\.[0-9*].[0-9*]' | head -n 1)
echo QGC Version: ${VERSION}

# Go out of AppImage
cd ${TMPDIR}
#wget -c --quiet "https://github.com/probonopd/AppImageKit/releases/download/5/AppImageAssistant" # (64-bit)
#wget -c --quiet "https://github.com/probonopd/AppImageKit/releases/download/5/AppImageAssistant" # (ARM 64-bit) Add arm64 when build
chmod a+x ./AppImageAssistant

appimagetool ./$APP.AppDir/ ${TMPDIR}/$APP".AppImage"

cp ${TMPDIR}/$APP".AppImage" ${OUTPUT_DIR}/$APP".AppImage"
