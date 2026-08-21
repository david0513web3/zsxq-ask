# zsxq-ask · 知识星球自动提问（加密分发）

知识星球（zsxq）答疑帖 / 问题收集帖**自动抢位跟帖**的 Claude Code skill。
config 驱动，一套代码适配任意星球：星球 id、署名、提问帖特征词、有效槽位数、抢位窗口、提问频率限制全在 `config.json`。

本仓库只放**加密包**，源码不明文入库。

```
install.sh          一键部署脚本（解密 → 装到 Claude Code / Codex / Hermes）
zsxq_ask.zip.enc    AES-256-CBC 加密的 skill 包（需密码）
```

## 部署

**A. 本地包部署**（把 `install.sh` 和 `zsxq_ask.zip.enc` 发给对方，放同一文件夹）：

```bash
cd 放这两个文件的文件夹
PASS=<部署密码> bash install.sh
```

**B. 一条命令部署**（仓库为 public 时可用）：

```bash
PASS=<部署密码> bash -c "$(curl -fsSL https://raw.githubusercontent.com/david0513web3/zsxq-ask/main/install.sh)"
```

装完三步走：

```bash
zsxq-cli auth login        # 扫码登录星球账号
zsxq-cli group +list       # 查目标星球 group-id
# 编辑 ~/.claude/skills/知识星球自动提问/config.json 填 group_id 和昵称
```

然后在 Claude Code 里说「准备星球提问」。详细说明见包内 `README-给小伙伴.md`。

## 环境要求

macOS / Linux · Python 3.9+ · Node.js（`npm install -g zsxq-cli`）· openssl 支持 `-pbkdf2`

## 换密码

```bash
NEW=$(openssl rand -hex 16)
openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:$OLD -in zsxq_ask.zip.enc -out old.zip
openssl enc -aes-256-cbc -pbkdf2 -pass pass:$NEW -in old.zip -out zsxq_ask.zip.enc
git commit -am "rotate password" && git push
```
