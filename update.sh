#!/bin/sh
dpkg-scanpackages --multiversion . /dev/null > Packages
cat Packages | xz > Packages.xz
apt-ftparchive\
 -o APT::FTPArchive::Release::Origin="jjolano"\
 -o APT::FTPArchive::Release::Label="jjolano"\
 -o APT::FTPArchive::Release::Suite="stable"\
 -o APT::FTPArchive::Release::Version="2.0"\
 -o APT::FTPArchive::Release::Codename="ios"\
 -o APT::FTPArchive::Release::Architectures="iphoneos-arm"\
 -o APT::FTPArchive::Release::Components="main"\
 -o APT::FTPArchive::Release::Description="personal tweak repository"\
 release . > Release
