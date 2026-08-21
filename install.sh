#!/usr/bin/env bash
# 知识星球自动提问 skill —— 加密包一键部署（Claude Code / Codex / Hermes 一装全通）
#
# 用法 A（本地包，仓库私有时用这个）：
#   把 install.sh 和 zsxq_ask.zip.enc 放同一个文件夹，然后
#   PASS=<密码> bash install.sh
#
# 用法 B（远程一条命令，需仓库为 public）：
#   PASS=<密码> bash -c "$(curl -fsSL https://raw.githubusercontent.com/david0513web3/zsxq-ask/main/install.sh)"
set -e
PASS="${PASS:-}"
if [ -z "$PASS" ]; then
  read -r -p "请输入部署密码: " PASS
fi
REPO='david0513web3/zsxq-ask'
BRANCH='main'
ENC='zsxq_ask.zip.enc'
SKILL_DIR_NAME='知识星球自动提问'
BASE_GH="https://raw.githubusercontent.com/$REPO/$BRANCH"
BASE_CDN="https://cdn.jsdelivr.net/gh/$REPO@$BRANCH"

# 找加密包：优先用 install.sh 同目录 / 当前目录的本地文件，否则去下载
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo .)"
WORK=/tmp/zsxq_ask_install
rm -rf "$WORK" && mkdir -p "$WORK" && cd "$WORK"

echo "→ 1/4 获取加密包"
if [ -f "$SRC_DIR/$ENC" ]; then
  cp "$SRC_DIR/$ENC" "$WORK/$ENC"
  echo "   ✓ 使用本地加密包 $SRC_DIR/$ENC"
elif [ -f "$OLDPWD/$ENC" ]; then
  cp "$OLDPWD/$ENC" "$WORK/$ENC"
  echo "   ✓ 使用本地加密包 $OLDPWD/$ENC"
else
  if ! curl -fsSL -o "$ENC" "$BASE_GH/$ENC"; then
    echo "   (GitHub 直连失败，切换 CDN)"
    curl -fsSL -o "$ENC" "$BASE_CDN/$ENC" || {
      echo "❌ 下载失败。若仓库是私有的，请向发送者要 $ENC 文件，和 install.sh 放同一个文件夹后重跑"; exit 1; }
  fi
  echo "   ✓ 已下载"
fi

echo "→ 2/4 解密"
openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$PASS" -in "$ENC" -out zsxq_ask.zip 2>/dev/null || {
  echo "❌ 解密失败：密码不对，或 openssl 版本过旧（需支持 -pbkdf2）"; exit 1; }

# 新机器可能装了 Claude Code 但还没有 skills 目录，自动补上
if [ ! -d "$HOME/.claude/skills" ] && { [ -d "$HOME/.claude" ] || command -v claude >/dev/null 2>&1; }; then
  mkdir -p "$HOME/.claude/skills"
  echo "   (已创建 ~/.claude/skills)"
fi
echo "→ 3/4 部署到本机所有 AI 客户端"
rm -rf unpack && mkdir unpack && unzip -o -q zsxq_ask.zip -d unpack/
installed=0
for dir in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.hermes/skills"; do
  if [ -d "$dir" ]; then
    # 保护已有配置和提问记录：升级安装时先备份，装完还原
    keep=""
    if [ -d "$dir/$SKILL_DIR_NAME" ]; then
      keep="$WORK/keep"; rm -rf "$keep"; mkdir -p "$keep"
      for f in config.json ask_log.json; do
        [ -f "$dir/$SKILL_DIR_NAME/$f" ] && cp "$dir/$SKILL_DIR_NAME/$f" "$keep/"
      done
      cp "$dir/$SKILL_DIR_NAME"/提问稿-*.md "$keep/" 2>/dev/null || true
      rm -rf "$dir/$SKILL_DIR_NAME"
    fi
    cp -R "unpack/$SKILL_DIR_NAME" "$dir/$SKILL_DIR_NAME"
    rm -rf "$dir/$SKILL_DIR_NAME/__pycache__"
    if [ -n "$keep" ]; then
      cp -R "$keep"/. "$dir/$SKILL_DIR_NAME"/ 2>/dev/null || true
      echo "   ✓ 已更新 ${dir} （保留原 config.json / ask_log.json / 提问稿）"
    else
      echo "   ✓ 已装到 ${dir}"
    fi
    installed=1
  fi
done
if [ "$installed" != "1" ]; then
  echo "❌ 未检测到任何 AI 客户端的 skills 目录（~/.claude/skills / ~/.codex/skills / ~/.hermes/skills）"
  echo "   请先安装 Claude Code 并至少启动过一次，或手动 mkdir -p ~/.claude/skills 后重跑"
  exit 1
fi

echo "→ 4/4 检查 zsxq-cli"
if command -v zsxq-cli >/dev/null 2>&1; then
  echo "   ✓ zsxq-cli 已存在"
else
  echo "   安装 zsxq-cli..."
  if ! npm install -g zsxq-cli 2>/dev/null; then
    npm install -g --prefix ~/.npm-global zsxq-cli 2>/dev/null || {
      echo "⚠️  自动安装 zsxq-cli 失败（可能没装 Node.js）。装好 Node 后手动跑：npm install -g zsxq-cli"; }
    export PATH="$HOME/.npm-global/bin:$PATH"
    echo "   (已装到 ~/.npm-global/bin，若提示找不到命令，重开终端即可)"
  fi
fi

echo ""
echo "✅ 部署完成。接下来三步："
echo "  1) zsxq-cli auth login          # 扫码登录你的星球账号"
echo "  2) zsxq-cli group +list         # 查目标星球的 group-id"
echo "  3) 编辑 ~/.claude/skills/$SKILL_DIR_NAME/config.json"
echo "     填 planet.group_id 和 planet.nick（你的星球昵称），"
echo "     并按你星球的规则改 slot_limit（前几名有效）和 grab 窗口（提问帖几点发）"
echo ""
echo "然后在 Claude Code 里说「准备星球提问」即可。详见 README-给小伙伴.md"
