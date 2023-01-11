#!/bin/bash

version="0.1.0"
revision="1"
architecture="amd64"
name="chattelite"

DIR="$name_$version-$revision_$architecture"

echo "copying .deb package template"
mkdir -p build/deb/$DIR/DEBIAN
cp -r deb/* build/deb/$DIR/

echo "copying binary"
mkdir -p build/deb/$DIR/usr/bin
cp backend/api/target/release/chattelite-server build/deb/$DIR/usr/bin

echo "extracting dpkg-shlibdeps"
mkdir debian
touch debian/control
dpkg-shlibdeps -O build/deb/$DIR/usr/bin/chattelite-server
sed -i "s/\[\[DEPENDS\]\]/$depends/g" build/deb/$DIR/DEBIAN/control
sed -i "s/\[\[NAME\]\]/$name/g" build/deb/$DIR/DEBIAN/control
sed -i "s/\[\[VERSION\]\]/$version/g" build/deb/$DIR/DEBIAN/control
sed -i "s/\[\[ARCHITECTURE\]\]/$architecture/g" build/deb/$DIR/DEBIAN/control
rm  debian/control
rm -r debian

cd build/deb && dpkg-deb --build --root-owner-group $DIR && cd ../..
