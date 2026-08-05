# oh-my-zsh-x

基于 [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) 的个人化配置仓库。框架（framework）与配置（configuration）分离：

- **框架**：Oh My Zsh 上游（upstream），由官方 `omz update` 机制维护
- **配置**：本仓库，包含自定义主题、`.zshrc` 模板与一键安装/更新脚本

## 目录结构

```text
oh-my-zsh-x/
├── README.md
├── install.sh                 # 一键安装脚本
├── upgrade.sh                 # 更新脚本（配置 + 框架）
├── zshrc.zsh-template         # .zshrc 配置模板
└── custom/                    # = $ZSH_CUSTOM，自定义目录
```

## 一键安装

### 方式一：本地克隆

```sh
git clone https://github.com/arawlin/oh-my-zsh-x.git ~/oh-my-zsh-x
cd ~/oh-my-zsh-x
sh install.sh
```

### 方式二：远程一键（推荐）

无需手动克隆，脚本会先把自己克隆到 `~/oh-my-zsh-x`（可用 `OMZ_X_DIR` 覆盖），再继续安装：

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/arawlin/oh-my-zsh-x/main/install.sh)"
```

安装脚本会完成：

1. **引导**：定位本仓库（远程运行时先自动克隆）
2. **部署配置层**：把 `zshrc.zsh-template` 渲染为 `~/.zshrc`（自动替换 `ZSH` 与 `ZSH_CUSTOM` 路径）、将 `custom/` 作为 `$ZSH_CUSTOM`、创建 `~/.zshrc_custom`
3. **安装框架层**：委托官方 Oh My Zsh 安装脚本（`--keep-zshrc`，不会覆盖我们部署的 `.zshrc`），并交互询问是否切换默认 shell

### 无人值守安装

```sh
sh install.sh --unattended
```

参数透传给官方脚本：不切换 shell、不启动 zsh，适用于自动化部署。

### 可配置项

| 环境变量 | 默认值 | 说明 |
| --- | --- | --- |
| `OMZ_X_DIR` | `$HOME/oh-my-zsh-x` | 本仓库位置（远程一键安装时的克隆目标） |
| `OMZ_X_REMOTE` | `https://github.com/arawlin/oh-my-zsh-x.git` | 引导克隆地址 |
| `ZSH` | `$HOME/.oh-my-zsh` | Oh My Zsh 安装路径 |
| `KEEP_ZSHRC` | `no` | 是否保留已有 `.zshrc` |
| `OMZ_INSTALLER` | 官方 install.sh URL | 官方安装脚本（本地测试可传文件路径） |

命令行参数：`--skip-chsh`、`--keep-zshrc`、`--unattended`（后两者透传官方）。

## 更新

```sh
sh upgrade.sh
```

分两层更新，互不干扰：

1. **配置层**：`git pull` 拉取本仓库最新自定义内容（未配置远端或本地有冲突时跳过，不中断）
2. **框架层**：调用官方 `tools/upgrade.sh` 更新 Oh My Zsh

> 注意：`upgrade.sh` 只更新**仓库内**的模板、主题与脚本，**不会**改动已部署的 `~/.zshrc`（它是安装时的渲染产物）。若模板有更新需要同步到本机，可删除 `~/.zshrc` 后重新运行 `sh install.sh`（旧文件会备份为 `.zshrc.pre-oh-my-zsh`）。

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
