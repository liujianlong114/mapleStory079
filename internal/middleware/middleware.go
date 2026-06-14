package middleware

// 中间件集合的入口文件。
// 所有具体中间件实现位于同包下的其他文件：
//   - cors.go       : CORS 跨域处理
//   - jwt_auth.go   : 简单 token 认证与会话黑名单
//   - rate_limit.go : IP + 端点限流
//   - request_id.go : 链路追踪 request id
//   - logger.go     : 请求日志
//   - recovery.go   : panic 恢复，避免服务进程被拉倒
