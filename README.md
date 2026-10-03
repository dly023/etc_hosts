# etc_hosts

维护一份可直接追加到系统 `/etc/hosts` 的纯文本映射，以及安装、卸载、校验和刷新脚本。

当前 `hosts` 来源于 2026-10-04 对 [Radios Argentinas - Radio Latina 101.1](https://www.radios-argentinas.org/radio-latina-1011) 的 Chrome CDP 请求记录。条目覆盖站点、页面资源、歌曲历史接口、电台播放流及页面中观察到的其他请求主机名。

## 文件

- `hosts`：标准 hosts 格式，一行一个 IPv4/IPv6 地址及主机名。`/etc/hosts` 不支持 `*.example.com` 这样的通配符；每个实际使用的子域名都要单独列出。
- `scripts/install.sh`：备份系统 hosts 文件，并用仓库中的映射替换本仓库管理区块。
- `scripts/uninstall.sh`：备份系统 hosts 文件，并只移除本仓库管理区块。
- `scripts/check.sh`：检查地址格式、主机名格式及重复主机名。
- `scripts/refresh.py`：通过 Google DNS-over-HTTPS 更新 `hosts` 中每个主机名的 IPv4 解析结果。刷新前请先检查 diff。

## 使用

检查仓库文件：

```sh
./scripts/check.sh
```

安装到本机：

```sh
sudo ./scripts/install.sh
```

macOS 会刷新系统 DNS 缓存。其他 Unix 系统请按发行版需要刷新 DNS 缓存。

卸载本仓库的映射：

```sh
sudo ./scripts/uninstall.sh
```

更新 DNS 快照：

```sh
python3 scripts/refresh.py
./scripts/check.sh
git diff -- hosts
```

## 维护说明

hosts 是静态映射。CDN、流媒体和第三方 API 的地址可能变化；若页面资源失效，先运行刷新脚本、审阅变更，再安装更新后的映射。刷新脚本只查询 A 记录，保留 hosts 文件中的注释和主机名，并为每个主机名写入 DNS 返回的 IPv4 地址。

hosts 只影响域名解析，不会自动关闭浏览器或系统代理，也不能绕过网络层封锁。若应用被设置为强制代理，还需在代理配置中把相应域名设为直连。

当前列表包含广告和统计请求域名。维护时可根据需求审阅或删减这些条目；删除某个请求域名不会影响 hosts 文件对其他主机名的解析。
