# oh-my-zsh-x

基于 [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) 的个人化配置仓库。框架（framework）与配置（configuration）分离：

- **框架**：Oh My Zsh 上游（upstream），由官方 `omz update` 机制维护
- **配置**：本仓库，包含自定义主题、`.zshrc` 模板与一键安装/更新脚本

## 目录结构

```text
oh-my-zsh-x/
├── README.md
├── install.sh                 # 一键安装脚本
├── update.sh                  # 更新脚本（配置 + 框架）
├── zshrc.zsh-template         # .zshrc 配置模板
└── custom/                    # = $ZSH_CUSTOM，自定义目录
    └── themes/
        └── astro.zsh-theme    # 自定义 prompt 主题
```

## 一键安装

在**新机器**上，克隆本仓库并运行安装脚本：

```sh
git clone <repo-url> ~/work/me/oh-my-zsh-x
cd ~/work/me/oh-my-zsh-x
sh install.sh
```

安装脚本会完成：

1. 浅克隆（shallow clone）官方 Oh My Zsh 到 `~/.oh-my-zsh`
2. 把 `zshrc.zsh-template` 部署为 `~/.zshrc`（自动替换 `ZSH` 与 `ZSH_CUSTOM` 路径）
3. 将本仓库的 `custom/` 目录作为 `$ZSH_CUSTOM`
4. 创建 `~/.zshrc_custom`（自定义 profile 挂载点）
5. 交互式询问是否将默认 shell 切换为 zsh

### 无人值守安装

```sh
sh install.sh --unattended
```

等价于 `CHSH=no RUNZSH=no KEEP_ZSHRC=yes`，适用于自动化部署。

### 安装到自定义路径

```sh
ZSH=/opt/oh-my-zsh sh install.sh
```

### 可配置项

| 环境变量 | 默认值 | 说明 |
| --- | --- | --- |
| `ZSH` | `$HOME/.oh-my-zsh` | Oh My Zsh 安装路径 |
| `REPO` | `ohmyzsh/ohmyzsh` | 克隆来源仓库 |
| `REMOTE` | `https://github.com/${REPO}.git` | 完整 git 地址 |
| `BRANCH` | `master` | 检出分支 |
| `CHSH` | `yes` | 是否切换默认 shell |
| `RUNZSH` | `yes` | 安装后是否启动 zsh |
| `KEEP_ZSHRC` | `no` | 是否保留已有 `.zshrc` |

命令行参数：`--skip-chsh`、`--keep-zshrc`、`--unattended`。

## 更新

```sh
sh update.sh
```

分两层更新，互不干扰：

1. **配置层**：`git pull` 拉取本仓库最新自定义内容
2. **框架层**：调用官方 `tools/upgrade.sh` 更新 Oh My Zsh

## 自定义说明

### 修改主题

编辑 `custom/themes/astro.zsh-theme` 后执行：

```sh
omz reload
```

### 新增自定义内容

按 Oh My Zsh 约定，在 `custom/` 下添加：

- `custom/*.zsh`：顶层配置，启动时自动加载（如 `aliases.zsh`）
- `custom/plugins/<name>/<name>.plugin.zsh`：自定义插件，放入 `plugins=()` 后生效
- `custom/themes/<name>.zsh-theme`：自定义主题，`ZSH_THEME="<name>"` 后生效

> 同名文件会**覆盖**内置内容（先加载 `$ZSH_CUSTOM`，再加载 `$ZSH`）。

### 个人配置

`.zshrc` 模板末尾会 `source ~/.zshrc_custom`，不随本仓库版本管理、不想进 git 的个人配置（如本机专属别名）可放入该文件。

## 卸载

Oh My Zsh 自带卸载脚本：

```sh
sh ~/.oh-my-zsh/tools/uninstall.sh
```

会恢复安装前的 `.zshrc` 与默认 shell。

## 备份与恢复

- 安装时已有 `.zshrc` 会备份为 `.zshrc.pre-oh-my-zsh`（更早的备份带时间戳后缀）
- 本仓库即配置的完整备份：换机只需 `git clone` + `sh install.sh`
