# Changelog

## v0.18.1 (2025-05-17)
- fix SubscribeMessage module warning: clause will never match
- update deps

## v0.18.0 (2025-03-14)
- 解决在第三方平台下的 bugs
- 更新 `WeChat.Component` 模块文档

## v0.17.0 (2024-12-27)
- 不再推荐使用子模块的调用方式
- `gen_sub_module?` 默认值设置为 `false`
- `build_client` 时忽略重定义编译告警

## v0.16.1 (2024-12-24)
- 不再使用即将废弃的语法 `unless`
- 在定义 client 时对于未知属性 进行告警
- 修复一些企业微信场景下的 bug
- 更新依赖

## v0.16.0 (2024-07-31)
- 增加[电子发票接口](https://developers.weixin.qq.com/doc/offiaccount/WeChat_Invoice/E_Invoice/Instruction.html): `WeChat.EInvoice`
- 文档优化：所有文档内的链接 改为 完整链接
