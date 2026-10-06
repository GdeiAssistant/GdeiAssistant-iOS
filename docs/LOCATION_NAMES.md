# 地区名称来源

地区目录保留原有 4,279 个节点的业务代码、层级、顺序、原始名称和 Latin 名称。界面通过 `localizedNames` 显示译名，不改变保存和提交的代码。

2026-10-06 更新使用 [GeoNames 官方数据导出](https://download.geonames.org/export/dump/)中的标准名称和语言别名，为明确匹配的 2,144 个地区节点补充英语、日语和韩语名称。GeoNames 数据采用 [Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/)许可，署名：GeoNames；本目录将其名称按已有地区代码映射，并在缺少日语或韩语别名时采用该来源的英语名称或当地原名。此前已核实的广东、广州、汕头和佛山译名继续保留。

日本栃木县的原始目录名称误写为“枥木”，原始名称和业务代码仍保留，六种语言的显示名称改为正确名称。该项对应 GeoNames 行政区记录 `1850310`，中文和日语写法另由[栃木县官方网站](https://www.pref.tochigi.lg.jp/index.html)核实。

另修正一项国家数据：原目录把 `GUF` 与 `GUY` 都标为圭亚那、ISO `GY`。按 [GeoNames 官方国家目录](https://download.geonames.org/export/dump/countryInfo.txt)，`GUF` 对应法属圭亚那（French Guiana），ISO 改为 `GF` 并补正六种语言的显示名称；`GUY` 仍对应圭亚那（Guyana）、ISO `GY`。这是一项来源数据纠正，原始名称、业务代码和层级继续保留；仅包含“圭亚那”或“Guiyana”的模糊自由文本不猜测归属。

纽约市 `USA/NY/QEE` 的英语显示名采用[纽约市官方网站](https://www.nyc.gov/main/about-our-content)使用的 `New York City`，以免与纽约州 `New York` 相同而在地址中合并。

仍有约 1,900 个旧目录节点无法在本次来源中唯一匹配，继续保留已有名称或 Latin 回退，未按猜测补译。这份目录不代表全球名称已经人工核译完毕；无法唯一匹配的自由文本也保持原样。
