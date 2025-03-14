# Changelog

## [0.18.0]
- 解决在第三方平台下的 bugs
- 更新 `WeChat.Component` 模块文档

## [0.17.0]
- 不再推荐使用子模块的调用方式
- `gen_sub_module?` 默认值设置为 `false`
- `build_client` 时忽略重定义编译告警

## [0.16.1]
- 不再使用即将废弃的语法 `unless`
- 在定义 client 时对于未知属性 进行告警
- 修复一些企业微信场景下的 bug
- 更新依赖

## [0.16.0]
- 增加[电子发票接口](https://developers.weixin.qq.com/doc/offiaccount/WeChat_Invoice/E_Invoice/Instruction.html): `WeChat.EInvoice`
- 文档优化：所有文档内的链接 改为 完整链接
