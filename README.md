# Rclone Magisk Module

This Magisk module integrates Rclone with FUSE support into Android, allowing you to manage remote storage mounts seamlessly. It includes scripts for managing Rclone services and automating tasks during boot and runtime.

本 Magisk 模块将 Rclone（支持 FUSE 3.17.x）集成到 Android，实现远程存储的无缝挂载与自动化管理。包含服务脚本，可在开机和运行时自动管理 Rclone 任务。

## Features / 功能

- **FUSE Integration**: Mount remote storage as local directories using Rclone with FUSE 3.17.x. (通过 Rclone + FUSE 挂载远程存储为本地目录)
- **Automated Boot Mounts**: Automatically mount configured remotes during system boot. (系统启动时自动挂载配置的远程存储)
- **Web GUI Management**: Start and manage the Rclone Web GUI. (一键启动 Rclone Web GUI，网页管理)
- **Customizable Configuration**: Easily configure Rclone options via environment variables.  (通过环境变量灵活配置 Rclone 选项)
- **RClone Sync**: sync service (支持自动同步任务)

* Click the action button to start the web server for configuration  
  * 点击 action 启动 web server 网页配置
* Automatically mount all configured remotes at boot  
  * 开机自动挂载所有配置
* Configuration directory:  
  * 配置文件夹:
    * `/data/adb/modules/rclone/conf/rclone.conf` - Main config (use `rclone-config` to edit)  
      * 配置文件 (可使用 rclone-config 配置)
    * `/data/adb/modules/rclone/conf/env` - Custom environment variables and flags  
      * 自定义参数和 Flag
    * `/data/adb/modules/rclone/conf/htpasswd` - Web GUI username/password  
      * web 账号密码
    * `/data/adb/modules/rclone/conf/sync` - Sync jobs config file  
      * 同步任务配置文件

## Scripts / 脚本

### `rclone-config`

Opens the Rclone configuration interface.  

打开 Rclone 配置界面。

#### Usage / 用法:
```bash
rclone-config
```

---

### `rclone-web`

Starts the Rclone Web GUI with predefined options. 

启动 Rclone Web GUI 并使用预设参数。

#### Usage / 用法:
```bash
rclone-web --rc-addres=:8080
```

---

### `rclone-sync`

Runs Rclone sync jobs defined in the configuration file.

执行配置文件中定义的 Rclone 同步任务。
#### Usage / 用法:
```bash
rclone-sync remote:/path /local/path [options]
```

---

### `rclone-kill-all`

Unmounts all Rclone mount points and kills all Rclone-related processes.  

卸载所有 Rclone 挂载点并终止相关进程。

#### Usage / 用法:
```bash
rclone-kill-all
```

---


## Rclone Sync Configuration / Rclone 同步配置说明 (WIP)

### Sync Config File (`RCLONESYNC_CONF`) / 同步配置文件

You can define automatic rclone sync jobs in the `/data/adb/modules/rclone/conf/sync` file. 
You can also set the `RCLONESYNC_CONF` environment variable to use a custom path.  
Each line represents a sync job, format:  

你可以通过配置 `/data/adb/modules/rclone/conf/sync` 文件，定义需要自动同步的 rclone 任务。
你也可以通过设置环境变量 `RCLONESYNC_CONF` 指定其他路径。
每一行代表一个同步任务，格式如下：

```
<remote>:<remote_path> <local_path> [optional options/可选参数]
```

- `<remote>:<remote_path>`: rclone remote name and path / rclone 配置的远程名及其路径
- `<local_path>`: local target path / 本地目标路径
- `[optional options]`: additional rclone sync options / 支持的其他参数

### Example / 示例

```
gdrive:/Documents "/sdcard/My Documents"
onedrive:/Photos "/sdcard/OneDrive Photos" --delete-excluded
mybox:/Backup "/data/backup" --dry-run
```

**Notes / 注意：**
- If the path contains spaces, wrap it in double quotes `"`  
  路径中如有空格，请用英文双引号 `"` 包裹
- Lines starting with `#` are comments and will be skipped  
  以 `#` 开头的行为注释，会被自动跳过
- Each sync job runs in background with low priority, logs to `/data/local/tmp/rclone_sync.log` by default  
  每个同步任务会在后台以低优先级执行，默认日志输出到 `/data/local/tmp/rclone_sync.log`

---

## Automated Updates / 自动更新

Daily automated workflow checks for new Rclone releases and creates pull requests with version updates.  
每日自动检查 Rclone 新版本并创建更新 PR。

---

## Contributing / 贡献

Contributions are welcome! Please ensure that your changes are well-documented and tested.  

欢迎贡献！请确保你的更改有良好文档和测试。

---

## License / 许可证

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.  

本项目采用 MIT License，详见 [LICENSE](LICENSE)。
