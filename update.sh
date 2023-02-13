#!/bin/sh
dpkg-scanpackages --multiversion root /dev/null > root/Packages
cat root/Packages | xz > root/Packages.xz
cat root/Packages | bzip2 > root/Packages.bz2
cat root/Packages | gzip > root/Packages.gz

cd rootless
dpkg-scanpackages --multiversion . /dev/null > Packages
cat Packages | xz > Package.xz
cat Packages | bzip2 > Packages.bz2
cat Packages | gzip > Packages.gz

cd ../
apt-ftparchive\
 -o APT::FTPArchive::Release::Origin="jjolano"\
 -o APT::FTPArchive::Release::Label="jjolano"\
 -o APT::FTPArchive::Release::Suite="stable"\
 -o APT::FTPArchive::Release::Version="2.1"\
 -o APT::FTPArchive::Release::Codename="ios"\
 -o APT::FTPArchive::Release::Architectures="iphoneos-arm"\
 -o APT::FTPArchive::Release::Components="main"\
 -o APT::FTPArchive::Release::Description="personal tweak repository"\
 release root > root/Release

apt-ftparchive\
 -o APT::FTPArchive::Release::Origin="jjolano (rootless)"\
 -o APT::FTPArchive::Release::Label="jjolano (rootless)"\
 -o APT::FTPArchive::Release::Suite="stable"\
 -o APT::FTPArchive::Release::Version="2.1"\
 -o APT::FTPArchive::Release::Codename="ios"\
 -o APT::FTPArchive::Release::Architectures="iphoneos-arm64"\
 -o APT::FTPArchive::Release::Components="main"\
 -o APT::FTPArchive::Release::Description="personal tweak repository"\
 release rootless > rootless/Release

git add .
git commit -m "update repo"
git push
