---
name: darkingtail:smart-debug-logger
description: Add debug logging with context-aware prefixes (e.g., [AUTH-LOGIN], [API-REQUEST]) and provide cleanup capabilities. Use when adding debug logs, 加日志, 加调试, 添加日志, 打日志, console.log, removing temporary logging code, or 清理日志.
---

# 智能调试日志

## 核心规则

**所有调试日志必须添加基于上下文的语义化前缀**，格式：`[类别-具体操作]`

### ⚠️ 日志级别选择

**默认使用 `console.log`**，输出干净简洁，便于复制粘贴和分享。

**仅在需要查看调用栈时使用 `console.warn`/`console.error`**，如定位事件触发来源、追踪函数调用链等场景。

### ⚠️ 统一前缀原则

**在同一次调试会话中，必须使用相同的前缀**。这样便于：
- 快速过滤当前调试相关的所有日志
- 避免与其他模块或历史调试日志混淆
- 调试完成后一次性清理所有日志

**实践方法：**
1. 开始调试前，根据调试目标确定一个统一前缀（如 `[DEBUG-AUTH]`、`[DEBUG-CART]`）
2. 本次调试中所有新增的日志都使用这个前缀
3. 调试结束后，通过该前缀快速定位并清理所有相关日志

**示例：**
```javascript
// ✅ 同一次调试使用统一前缀
console.log('[DEBUG-LOGIN] 用户名:', username)
console.log('[DEBUG-LOGIN] 请求发送:', endpoint)
console.log('[DEBUG-LOGIN] 响应状态:', response.status)
console.log('[DEBUG-LOGIN] token 保存成功')

// ❌ 避免同一次调试使用不同前缀
console.log('[AUTH-LOGIN] 用户名:', username)
console.log('[API-REQUEST] 请求发送:', endpoint)
console.log('[API-RESPONSE] 响应状态:', response.status)
console.log('[AUTH-TOKEN] token 保存成功')
```

## 添加日志

### 前缀命名规范

前缀格式：`[主分类-子操作]`，全大写，用连字符分隔

### 常见前缀分类

#### 认证授权
```javascript
console.log('[AUTH-LOGIN] 用户登录请求:', username)
console.log('[AUTH-LOGOUT] 清理用户会话:', sessionId)
console.log('[AUTH-TOKEN] 刷新 token:', newToken)
console.log('[AUTH-PERMISSION] 权限检查:', userId, requiredPermission)
```

#### API/网络请求
```javascript
console.log('[API-REQUEST] 发起请求:', method, url, params)
console.log('[API-RESPONSE] 收到响应:', status, data)
console.log('[API-ERROR] 请求失败:', error.message)
console.log('[API-RETRY] 重试请求:', retryCount)
```

#### 数据处理
```javascript
console.log('[DATA-FETCH] 获取数据:', dataSource)
console.log('[DATA-TRANSFORM] 转换数据:', rawData, '->', transformedData)
console.log('[DATA-VALIDATE] 验证数据:', validationResult)
console.log('[DATA-CACHE] 缓存命中:', cacheKey)
```

#### 表单处理
```javascript
console.log('[FORM-SUBMIT] 提交表单:', formData)
console.log('[FORM-VALIDATE] 字段验证:', fieldName, isValid)
console.log('[FORM-CHANGE] 字段变更:', fieldName, oldValue, newValue)
console.log('[FORM-RESET] 重置表单')
```

#### 状态管理
```javascript
console.log('[STATE-UPDATE] 更新状态:', statePath, newValue)
console.log('[STATE-DISPATCH] 触发 action:', actionType, payload)
console.log('[STATE-SUBSCRIBE] 状态订阅:', subscriber)
```

#### 路由导航
```javascript
console.log('[ROUTE-NAVIGATE] 导航至:', targetRoute)
console.log('[ROUTE-GUARD] 路由守卫检查:', canActivate)
console.log('[ROUTE-PARAMS] 路由参数:', params)
```

#### 组件生命周期
```javascript
console.log('[COMPONENT-MOUNT] 组件挂载:', componentName, props)
console.log('[COMPONENT-UPDATE] 组件更新:', changedProps)
console.log('[COMPONENT-UNMOUNT] 组件卸载:', componentName)
console.log('[COMPONENT-ERROR] 组件错误:', error)
```

#### 文件操作
```javascript
console.log('[FILE-UPLOAD] 上传文件:', fileName, fileSize)
console.log('[FILE-DOWNLOAD] 下载文件:', url)
console.log('[FILE-PARSE] 解析文件:', fileType, content)
```

#### 数据库操作
```javascript
console.log('[DB-QUERY] 执行查询:', sql)
console.log('[DB-INSERT] 插入数据:', tableName, data)
console.log('[DB-UPDATE] 更新数据:', tableName, conditions)
console.log('[DB-DELETE] 删除数据:', tableName, id)
```

#### WebSocket
```javascript
console.log('[WS-CONNECT] 建立连接:', wsUrl)
console.log('[WS-MESSAGE] 收到消息:', message)
console.log('[WS-SEND] 发送消息:', data)
console.log('[WS-CLOSE] 关闭连接:', reason)
```

#### 性能监控
```javascript
console.log('[PERF-START] 开始计时:', operationName)
console.log('[PERF-END] 结束计时:', operationName, duration)
console.log('[PERF-MEMORY] 内存使用:', memoryUsage)
```

#### 业务逻辑（根据项目自定义）
```javascript
// 电商
console.log('[CART-ADD] 添加商品:', product)
console.log('[ORDER-CREATE] 创建订单:', orderData)
console.log('[PAYMENT-PROCESS] 处理支付:', paymentMethod, amount)

// 内容管理
console.log('[ARTICLE-PUBLISH] 发布文章:', articleId)
console.log('[MEDIA-UPLOAD] 上传媒体:', fileName)

// 社交应用
console.log('[POST-CREATE] 创建帖子:', content)
console.log('[COMMENT-ADD] 添加评论:', commentData)
```

### 命名原则

**✅ 好的前缀**
- `[AUTH-LOGIN]` - 清晰表达"认证-登录"
- `[API-RETRY]` - 明确表达"API-重试"
- `[FORM-VALIDATE]` - 准确表达"表单-验证"
- `[CART-CHECKOUT]` - 业务语义清晰

**❌ 避免的前缀**
- `[DEBUG]` - 太泛化，没有上下文
- `[TEST]` - 不明确
- `[LOG]` - 无意义
- `[TEMP]` - 太随意

## 清理日志

### 核心原则：只清理本次调试的日志

**清理时只移除本次调试会话使用的特定前缀**，不动其他前缀的日志。这样避免误删其他调试会话或其他开发者的日志。

### 方式 1：使用辅助脚本（推荐）

查看项目中的所有调试日志：
```bash
./scripts/find-debug-logs.sh
```

移除**指定前缀**的调试日志（带备份）：
```bash
# bash - 必须指定前缀
./scripts/remove-debug-logs.sh DEBUG-LOGIN

# PowerShell - 必须指定前缀
.\scripts\remove-debug-logs.ps1 DEBUG-LOGIN
```

### 方式 2：手动查找

查找**指定前缀**的日志：
```bash
# 查找特定前缀
grep -rn "\[DEBUG-LOGIN\]" src/

# 查找 Python
grep -rn "\[DEBUG-LOGIN\]" .
```

### 方式 3：让 Claude 清理

直接告诉 Claude：
```
清理 [DEBUG-LOGIN] 日志
```

Claude 会：
1. 回忆本次调试会话使用的前缀（如 `[DEBUG-LOGIN]`）
2. 使用 Grep 查找仅包含该前缀的日志
3. 逐个文件移除这些日志行
4. **不触碰其他前缀的日志**

## 控制台过滤

在浏览器开发者工具中：
```
// 只看认证相关
[AUTH-

// 只看 API 相关
[API-

// 只看特定操作
[AUTH-LOGIN]

// 组合过滤（使用正则）
[AUTH-|[API-
```

在命令行中：
```bash
# 实时过滤 Node.js 输出
npm run dev 2>&1 | grep '\[API-'

# 只看认证和 API
npm run dev 2>&1 | grep -E '\[(AUTH|API)-'
```

## 实现流程

### 添加日志时：

1. **分析代码上下文**
   - 这段代码在做什么？（登录、搜索、提交表单...）
   - 属于哪个模块？（认证、API、数据处理...）

2. **选择语义化前缀**
   - 主分类：AUTH / API / DATA / FORM / STATE / ROUTE / COMPONENT...
   - 具体操作：LOGIN / REQUEST / VALIDATE / SUBMIT / UPDATE...
   - 组合：`[主分类-具体操作]`

3. **添加描述性日志**
   - 简要说明这条日志的目的
   - 输出关键变量和状态

### 清理日志时：

1. **确认清理范围**
   - 回忆本次调试使用的统一前缀（如 `[DEBUG-LOGIN]`）
   - **只清理该前缀的日志，不动其他前缀**

2. **移除日志行**
   - 仅删除包含本次前缀的日志行
   - 保持代码格式整洁

3. **验证清理结果**
   - 确保本次前缀的日志全部移除
   - 确认其他前缀的日志未被影响

## 使用示例

### 场景 1：添加登录调试日志

用户说：
> 帮我在登录函数里加几个日志调试一下

Claude 添加（使用统一前缀 `[DEBUG-LOGIN]`）：
```javascript
async function handleLogin(credentials) {
  console.log('[DEBUG-LOGIN] 开始登录:', credentials.username)

  try {
    console.log('[DEBUG-LOGIN] 调用登录接口:', loginEndpoint)
    const response = await fetch(loginEndpoint, {
      method: 'POST',
      body: JSON.stringify(credentials)
    })
    console.log('[DEBUG-LOGIN] 登录接口响应:', response.status)

    const data = await response.json()
    console.log('[DEBUG-LOGIN] 保存用户 token')
    localStorage.setItem('token', data.token)

    console.log('[DEBUG-LOGIN] 跳转到首页')
    router.push('/home')
  } catch (error) {
    console.log('[DEBUG-LOGIN] 登录失败:', error.message)
  }
}
```

### 场景 2：清理调试日志

用户说：
> 调试完了，帮我清理日志

Claude 执行：
1. 回忆本次调试使用的前缀 `[DEBUG-LOGIN]`
2. 使用 Grep 仅查找包含 `[DEBUG-LOGIN]` 的日志
3. 使用 Edit 工具逐个移除这些日志行
4. 报告清理结果：
   ```
   已清理 [DEBUG-LOGIN] 前缀的 12 条调试日志：
   - src/auth/login.js: 6 条
   - src/api/request.js: 4 条
   - src/components/LoginForm.vue: 2 条
   （其他前缀的日志未受影响）
   ```

## 多语言支持

### Python
```python
print(f'[AUTH-LOGIN] 用户登录: {username}')
print(f'[API-REQUEST] 请求接口: {url}')
```

### Java
```java
System.out.println("[AUTH-LOGIN] 用户登录: " + username);
System.out.println("[API-REQUEST] 请求接口: " + url);
```

### Go
```go
fmt.Printf("[AUTH-LOGIN] 用户登录: %s\n", username)
fmt.Printf("[API-REQUEST] 请求接口: %s\n", url)
```

### Rust
```rust
println!("[AUTH-LOGIN] 用户登录: {}", username);
println!("[API-REQUEST] 请求接口: {}", url);
```
