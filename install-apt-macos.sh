#!/bin/bash
# 刀刀 2026-04
# 脚本用于在本地 macOS 上安装和配置 apt (Procursus)
# 适用于M系芯片的macOS
# 感谢 zhaonan
# 原始脚本源自 https://github.com/miticollo/miticollo.github.io/blob/main/.github/workflows/update-packages-file.yml

set -e

echo "开始安装 apt (Procursus) 到本地 macOS..."

# 检查是否已安装 Procursus
if [ -d "/opt/procursus" ]; then
  echo "检测到已存在 /opt/procursus 目录。"
  echo "正在删除旧的 Procursus 安装..."
  sudo rm -rf /opt/procursus
  echo "已删除旧的 /opt/procursus 目录，准备安装新的。"
fi

echo "步骤 1: 检查并安装必要依赖..."

# 定义需要检查的依赖包
REQUIRED_PACKAGES=("dpkg-dev" "git" "xz-utils" "bzip2" "gzip" "lzma" "zstd")

# 检查 Homebrew 是否可用
if ! command -v brew &> /dev/null; then
  echo "错误: Homebrew 未安装，请先安装 Homebrew"
  echo "国内源安装 Homebrew: /bin/bash -c \"\$(curl -fsSL https://gitee.com/ineo6/homebrew-install/raw/master/install.sh)\""
  echo "官方源安装 Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  exit 1
fi

# 检查并安装每个依赖
MISSING_PACKAGES=()
for pkg in "${REQUIRED_PACKAGES[@]}"; do
  case "$pkg" in
    "dpkg-dev")
      if ! command -v dpkg &> /dev/null; then
        MISSING_PACKAGES+=("$pkg")
      else
        echo "✓ $pkg (dpkg) 已找到"
      fi
      ;;
    "git")
      if ! command -v git &> /dev/null; then
        MISSING_PACKAGES+=("$pkg")
      else
        echo "✓ $pkg 已找到"
      fi
      ;;
    "xz-utils")
      if ! command -v xz &> /dev/null; then
        MISSING_PACKAGES+=("$pkg")
      else
        echo "✓ $pkg 已找到"
      fi
      ;;
    "bzip2")
      if ! command -v bunzip2 &> /dev/null; then
        MISSING_PACKAGES+=("$pkg")
      else
        echo "✓ $pkg 已找到"
      fi
      ;;
    "gzip")
      if ! command -v gunzip &> /dev/null; then
        MISSING_PACKAGES+=("$pkg")
      else
        echo "✓ $pkg 已找到"
      fi
      ;;
    "lzma")
      if ! command -v unlzma &> /dev/null && ! command -v xz &> /dev/null; then
        MISSING_PACKAGES+=("$pkg")
      else
        echo "✓ $pkg 已找到"
      fi
      ;;
    "zstd")
      if ! command -v zstd &> /dev/null; then
        MISSING_PACKAGES+=("$pkg")
      else
        echo "✓ $pkg 已找到"
      fi
      ;;
  esac
done

# 安装缺失的依赖
if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
  echo "正在安装缺失的依赖: ${MISSING_PACKAGES[*]}"
  brew install "${MISSING_PACKAGES[@]}"
else
  echo "所有必要依赖已满足！"
fi

echo "步骤 2: 下载并解压 Procursus 引导文件..."
dir=$(mktemp -d /tmp/XXXX)
echo "创建临时目录: $dir"
cd "${dir}"
echo "当前工作目录: $(pwd)"

# 下载文件
echo "正在下载 ARM bootstrap.tar.zst..."
curl -L https://apt.procurs.us/bootstraps/big_sur/bootstrap-darwin-arm64.tar.zst -o bootstrap.tar.zst

# 检查下载是否成功
if [ -f "bootstrap.tar.zst" ]; then
  echo "下载成功，文件大小: $(ls -lh bootstrap.tar.zst | awk '{print $5}')"
else
  echo "下载失败，退出脚本"
  exit 1
fi

# 解压文件
echo "正在解压 bootstrap.tar.zst..."
zstd -dk bootstrap.tar.zst

# 检查解压是否成功
if [ -f "bootstrap.tar" ]; then
  echo "解压成功，文件大小: $(ls -lh bootstrap.tar | awk '{print $5}')"
else
  echo "解压失败，退出脚本"
  exit 1
fi

# 解压到根目录
echo "正在安装到 /opt/procursus..."
sudo tar -xvpkf ./bootstrap.tar -C / || :

# 删除临时文件
echo "正在清理临时文件..."
rm -f bootstrap.tar.zst bootstrap.tar
echo "已删除 bootstrap.tar.zst 和 bootstrap.tar"

# 检查文件是否已删除
if [ -f "bootstrap.tar.zst" ] || [ -f "bootstrap.tar" ]; then
  echo "警告: 临时文件删除失败"
  ls -la
else
  echo "临时文件删除成功"
fi

cd -
echo "正在删除临时目录: $dir"
rm -vrf "${dir}"

# 检查目录是否已删除
if [ -d "$dir" ]; then
  echo "警告: 临时目录删除失败"
else
  echo "临时目录删除成功"
fi

echo "步骤 3: 将 Procursus 添加到 PATH 和相关环境变量..."

# 定义一个函数来检查并添加到配置文件
add_to_profile() {
  local line="$1"
  local profile_file="$2"
  
  # 展开 ~ 为用户主目录
  profile_file="${profile_file/#\~/$HOME}"
  
  if [ -f "$profile_file" ]; then
    if ! grep -Fxq "$line" "$profile_file"; then
      echo "$line" >> "$profile_file"
      echo "已添加到 $profile_file: $line"
    else
      echo "$profile_file 中已存在，跳过: $line"
    fi
  else
    echo "$profile_file 不存在，创建并添加: $line"
    # 确保目录存在
    dirname "$profile_file" | xargs mkdir -p
    echo "$line" > "$profile_file"
  fi
}

# 导出完整的 PATH 到当前会话
export PATH=/opt/procursus/sbin:/opt/procursus/bin:/opt/procursus/local/sbin:/opt/procursus/local/bin:$HOME/bin:$PATH
echo "已设置当前会话 PATH: /opt/procursus/sbin:/opt/procursus/bin:/opt/procursus/local/sbin:/opt/procursus/local/bin:$HOME/bin:$PATH"

# 添加到 bash_profile
add_to_profile "export PATH=/opt/procursus/sbin:/opt/procursus/bin:/opt/procursus/local/sbin:/opt/procursus/local/bin:\$HOME/bin:\$PATH" "~/.bash_profile"

# 添加到 zshrc
add_to_profile "export PATH=/opt/procursus/sbin:/opt/procursus/bin:/opt/procursus/local/sbin:/opt/procursus/local/bin:\$HOME/bin:\$PATH" "~/.zshrc"

# 处理 CPATH
case ":$CPATH:" in
  *:/opt/procursus/include:*) echo "/opt/procursus/include 已在当前 CPATH 中";;
  *) echo "将 /opt/procursus/include 添加到当前 CPATH";
     export CPATH=$CPATH:/opt/procursus/include;;
esac
add_to_profile "export CPATH=\$CPATH:/opt/procursus/include" "~/.bash_profile"
add_to_profile "export CPATH=\$CPATH:/opt/procursus/include" "~/.zshrc"

# 处理 LIBRARY_PATH
case ":$LIBRARY_PATH:" in
  *:/opt/procursus/lib:*) echo "/opt/procursus/lib 已在当前 LIBRARY_PATH 中";;
  *) echo "将 /opt/procursus/lib 添加到当前 LIBRARY_PATH";
     export LIBRARY_PATH=$LIBRARY_PATH:/opt/procursus/lib;;
esac
add_to_profile "export LIBRARY_PATH=\$LIBRARY_PATH:/opt/procursus/lib" "~/.bash_profile"
add_to_profile "export LIBRARY_PATH=\$LIBRARY_PATH:/opt/procursus/lib" "~/.zshrc"

echo "步骤 4: 创建 APT 沙箱用户..."
getHiddenUserUid()
{
  local __UIDS=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -ugr)
  local __NewUID
  for __NewUID in $__UIDS
  do
      if [[ $__NewUID -lt 499 ]] ; then
          break;
      fi
  done
  echo $((__NewUID+1))
}

if ! id _apt &>/dev/null; then
  # 添加 APT 方法的无特权用户
  echo "创建 APT 沙箱用户 _apt..."
  sudo dscl . -create /Users/_apt UserShell /usr/bin/false
  sudo dscl . -create /Users/_apt NSFHomeDirectory /var/empty
  sudo dscl . -create /Users/_apt PrimaryGroupID -1
  sudo dscl . -create /Users/_apt UniqueID $(getHiddenUserUid)
  sudo dscl . -create /Users/_apt RealName "APT Sandbox User"
else
  echo "APT 沙箱用户已存在，跳过创建"
fi

echo "步骤 5: 更新引导..."
sudo apt-get -y update
sudo apt-get -y -o DPkg::Options::=--force-confdef --allow-downgrades dist-upgrade || :

echo "步骤 6: 安装必要的软件包..."
sudo apt-get install -o DPkg::Options::=--force-confdef -y apt-utils zstd lz4 xz-utils

# 检查 Homebrew 是否已安装
if command -v brew &> /dev/null; then
  echo "安装 gnupg..."
  brew install -v gnupg
else
  echo "警告: Homebrew 未安装，跳过 gnupg 安装"
  echo "请手动安装 Homebrew 后再运行 'brew install gnupg'"
fi

echo "安装完成！"
echo "请执行以下命令使环境变量生效："
echo "  对于 bash: source ~/.bash_profile"
echo "  对于 zsh:  source ~/.zshrc 或重启终端"
echo "现在可以使用 'apt' 命令来管理软件包了。"

# 验证 apt 命令是否可用
echo "验证 apt 命令..."
if command -v apt &> /dev/null; then
  echo "✓ apt 命令可用！"
  echo "apt 版本: $(apt --version | head -n1)"
else
  echo "✗ apt 命令不可用，请确保环境变量已正确设置"
  echo "请尝试重启终端或手动执行: source ~/.zshrc"
fi
