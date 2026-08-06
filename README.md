# oh-my-zsh-x

基于 [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) 的个人化配置仓库。框架（framework）与配置（configuration）分离：

- **框架**：Oh My Zsh 上游（upstream），由官方 `omz update` 机制维护
- **配置**：本仓库，包含自定义主题、`.zshrc` 模板与一键安装/更新脚本

## 目录结构

```text
oh-my-zsh-x/
├── README.md
├── templates/                     # 配置模板
│   └── zshrc.zsh-template         # .zshrc 配置模板
├── tools/                         # 脚本（与原版目录结构一致）
│   ├── install.sh                 # 一键安装脚本
│   ├── install-plugins.sh         # 社区插件安装/更新脚本
│   └── upgrade.sh                 # 更新脚本（配置 + 插件 + 框架）
└── custom/                        # = $ZSH_CUSTOM，自定义目录
```

## 一键安装

### 方式一：本地克隆

```sh
git clone https://github.com/arawlin/oh-my-zsh-x.git ~/.oh-my-zsh-x
cd ~/.oh-my-zsh-x
sh tools/install.sh
```

### 方式二：远程一键（推荐）

无需手动克隆，脚本会先把自己克隆到 `~/.oh-my-zsh-x`（可用 `OMZ_X_DIR` 覆盖），再继续安装：

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/arawlin/oh-my-zsh-x/main/tools/install.sh)"
```

安装脚本会完成：

1. **引导**：定位本仓库（远程运行时先自动克隆）
2. **部署配置层**：把 `templates/zshrc.zsh-template` 渲染为 `~/.zshrc`（自动替换 `ZSH` 与 `ZSH_CUSTOM` 路径）、将 `custom/` 作为 `$ZSH_CUSTOM`、创建 `~/.zshrc_custom`
3. **安装社区插件**：调用 `tools/install-plugins.sh`，把第三方插件克隆到 `$ZSH_CUSTOM/plugins/`（默认启用列表见「插件管理」）
4. **安装框架层**：委托官方 Oh My Zsh 安装脚本（`--keep-zshrc`，不会覆盖我们部署的 `.zshrc`），并交互询问是否切换默认 shell

### 无人值守安装

```sh
sh install.sh --unattended
```

参数透传给官方脚本：不切换 shell、不启动 zsh，适用于自动化部署。

### 可配置项

| 环境变量 | 默认值 | 说明 |
| --- | --- | --- |
| `OMZ_X_DIR` | `$HOME/.oh-my-zsh-x` | 本仓库位置（远程一键安装时的克隆目标） |
| `OMZ_X_REMOTE` | `https://github.com/arawlin/oh-my-zsh-x.git` | 引导克隆地址 |
| `ZSH` | `$HOME/.oh-my-zsh` | Oh My Zsh 安装路径 |
| `KEEP_ZSHRC` | `no` | 是否保留已有 `.zshrc` |
| `SKIP_PLUGINS` | `no` | 设为 `yes` 跳过社区插件安装 |
| `OMZ_INSTALLER` | 官方 install.sh URL | 官方安装脚本（本地测试可传文件路径） |

命令行参数：`--skip-chsh`、`--keep-zshrc`、`--unattended`（后两者透传官方）。

## 更新

```sh
sh tools/upgrade.sh
```

分三层更新，互不干扰：

1. **配置层**：`git pull` 拉取本仓库最新自定义内容（未配置远端或本地有冲突时跳过，不中断）
2. **插件层**：调用 `tools/install-plugins.sh` 增量更新 `custom/plugins/` 下的社区插件（只快进更新，失败不中断）
3. **框架层**：调用官方 `tools/upgrade.sh` 更新 Oh My Zsh

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

## 插件管理

默认启用的插件（定义在 `templates/zshrc.zsh-template` 的 `plugins=()`）：

- **内置插件**（零安装）：`git`、`history`、`colored-man-pages`、`z`、`extract`、`copybuffer`、`common-aliases`、`web-search`、`jsontools`、`fzf`、`vi-mode`、`history-substring-search`
- **社区插件**（安装时自动克隆）：`zsh-autosuggestions`、`zsh-completions`、`zsh-syntax-highlighting`
- **可选**：`sudo`、`colorize`（前者与 `vi-mode` 的 Esc 键冲突，后者依赖 `pygmentize`/`chroma`，故默认注释，取消注释即可启用）

社区插件统一克隆到 `custom/plugins/`（已在 `.gitignore` 中忽略，属本机状态、不进入版本库），由 `tools/install-plugins.sh` 管理：

- 安装时自动克隆缺失插件，`upgrade.sh` 时自动快进更新已有插件（幂等，可反复执行）
- 每个插件保留自己的上游 remote，独立更新，互不影响
- **新增社区插件**：编辑 `tools/install-plugins.sh` 的 `PLUGIN_SPECS`，加一行 `名称 仓库地址` 即可
- 因为插件目录不入库，`git pull` 本仓库永远不会因插件更新而产生冲突；框架层（`~/.oh-my-zsh`）由官方 `omz update` 维护，同样从不改动

依赖提示：

- `fzf` 插件需要系统安装 `fzf`（`brew install fzf` 或 `sudo apt install fzf`），`install-plugins.sh` 会检测并提示
- `colorize` 插件需要 `pygmentize`（`pip install pygments`）或 `chroma`

> 提示：`custom/plugins/` 已在 `.gitignore` 中忽略。若需将手写自定义插件纳入版本库，可用 `git add -f custom/plugins/<name>` 强制添加。

## 卸载

Oh My Zsh 自带卸载脚本：

```sh
sh ~/.oh-my-zsh/tools/uninstall.sh
```

会恢复安装前的 `.zshrc` 与默认 shell。

## 备份与恢复

- 安装时已有 `.zshrc` 会备份为 `.zshrc.pre-oh-my-zsh`（更早的备份带时间戳后缀）
- 本仓库即配置的完整备份：换机只需 `git clone` + `sh install.sh`
