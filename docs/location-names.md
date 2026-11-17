# 地区名称来源

地区目录保留原有 4,279 个节点的业务代码、层级、顺序、原始名称和 Latin 名称。界面通过 `localizedNames` 显示译名，不改变保存和提交的代码。

地区节点的英语、日语和韩语名称补充源自 [GeoNames 官方数据导出](https://download.geonames.org/export/dump/)（2026-10-06 快照），为 2,144 个明确匹配节点映射标准名称与语言别名。GeoNames 数据采用 [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/) 许可，署名 GeoNames；缺少日语或韩语别名时采用同一地理实体的英语名称或当地原名，并保留广东、广州、汕头、佛山已有译名。

日本栃木县的原始目录名称误写为“枥木”，原始名称和业务代码仍保留，六种语言的显示名称改为正确名称。该项对应 GeoNames 行政区记录 `1850310`，中文和日语写法另由[栃木县官方网站](https://www.pref.tochigi.lg.jp/index.html)核实。

国家元数据中 `GUF` 对应法属圭亚那（ISO `GF`），`GUY` 对应圭亚那（ISO `GY`），两者在六种语言显示名称及 ISO 代码上已区分，同时保留原始业务代码与层级；仅写作“圭亚那”或“Guiyana”的模糊自由文本不猜测归属。

纽约市 `USA/NY/QEE` 的英语显示名采用[纽约市官方网站](https://www.nyc.gov/main/about-our-content)使用的 `New York City`，以免与纽约州 `New York` 相同而在地址中合并。

仍有约 1,900 个旧目录节点无法唯一匹配，继续保留已有名称或 Latin 回退，不按猜测补译；无法唯一匹配的自由文本也保持原样。
