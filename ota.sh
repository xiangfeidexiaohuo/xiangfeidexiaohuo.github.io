#!/bin/bash

# sudo apt update && sudo apt install -y dpkg-dev apt-utils git xz-utils bzip2 gzip lzma zstd
# 使用 Python 生成 Packages 文件，避免某些特殊情况下的编码问题
# 一般情况下，不要使用这个脚本，请使用 update.sh

echo "=== 开始处理 iOS 越狱源 ==="

# 1. 删除旧文件
echo "1、删除旧版Packages文件"
rm -f Packages Packages.* Release

# 2. 生成 Packages 文件
echo "2、生成 Packages 文件"
python3 << 'EOF'
import os
import subprocess
import hashlib

# 扫描目录
directories = ["roothide", "rootless", "rootful"]
packages = []

def get_control_info(deb_path):
    """从 deb 包中提取 control 信息"""
    temp_dir = "temp_control"
    os.makedirs(temp_dir, exist_ok=True)
    
    # 提取 control 文件
    result = subprocess.run(["dpkg-deb", "-e", deb_path, temp_dir], capture_output=True)
    if result.returncode != 0:
        if os.path.exists(temp_dir):
            import shutil
            shutil.rmtree(temp_dir)
        return None
    
    control_path = os.path.join(temp_dir, "control")
    if not os.path.exists(control_path):
        if os.path.exists(temp_dir):
            import shutil
            shutil.rmtree(temp_dir)
        return None
    
    # 读取 control 文件
    try:
        with open(control_path, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
    except Exception as e:
        print(f"读取 control 文件失败: {e}")
        if os.path.exists(temp_dir):
            import shutil
            shutil.rmtree(temp_dir)
        return None
    
    # 解析 control 文件
    info = {}
    for line in content.split('\n'):
        line = line.strip()
        if not line:
            continue
        if ':' in line:
            key, value = line.split(':', 1)
            info[key.strip()] = value.strip()
    
    # 清理临时目录
    if os.path.exists(temp_dir):
        import shutil
        shutil.rmtree(temp_dir)
    
    return info

def calculate_hashes(file_path):
    """计算文件的各种哈希值"""
    hashes = {}
    try:
        with open(file_path, 'rb') as f:
            content = f.read()
            hashes['Size'] = str(len(content))
            hashes['MD5sum'] = hashlib.md5(content).hexdigest()
            hashes['SHA1'] = hashlib.sha1(content).hexdigest()
            hashes['SHA256'] = hashlib.sha256(content).hexdigest()
    except Exception as e:
        print(f"计算哈希值失败: {e}")
    return hashes

# 扫描所有 deb 包
for directory in directories:
    if not os.path.exists(directory):
        print(f"目录 {directory} 不存在，跳过")
        continue
    
    print(f"扫描目录: {directory}")
    for deb_file in os.listdir(directory):
        if not deb_file.endswith('.deb'):
            continue
        
        deb_path = os.path.join(directory, deb_file)
        print(f"处理: {deb_path}")
        
        info = get_control_info(deb_path)
        if not info:
            print(f"无法获取 {deb_file} 的信息，跳过")
            continue
        
        # 添加文件信息
        info['Filename'] = deb_path
        info.update(calculate_hashes(deb_path))
        
        packages.append(info)

# 生成 Packages 文件
with open('Packages', 'w', encoding='utf-8') as f:
    for pkg in packages:
        for key, value in pkg.items():
            f.write(f"{key}: {value}\n")
        f.write('\n')

print(f"生成完成，共处理 {len(packages)} 个包")
EOF

# 3. 生成压缩文件
echo "3、生成压缩文件"
cat Packages | xz > Packages.xz
cat Packages | bzip2 > Packages.bz2
cat Packages | gzip > Packages.gz
cat Packages | lzma > Packages.lzma
cat Packages | zstd > Packages.zst

# 4. 生成 Release 文件
echo "4、生成 Release 文件"
apt-ftparchive\
 -o APT::FTPArchive::Release::Origin="刀刀源"\
 -o APT::FTPArchive::Release::Label="刀刀源"\
 -o APT::FTPArchive::Release::Suite="stable"\
 -o APT::FTPArchive::Release::Version="1.0"\
 -o APT::FTPArchive::Release::Codename="ios"\
 -o APT::FTPArchive::Release::Architectures="iphoneos-arm iphoneos-arm64 iphoneos-arm64e"\
 -o APT::FTPArchive::Release::Components="main"\
 -o APT::FTPArchive::Release::Description="刀刀个人插件源~"\
 release . > Release

# 5. 推送提交
echo "5、推送提交"
git add .
git commit -s -m "sync repo"
git push

echo "=== 处理完成 ==="
