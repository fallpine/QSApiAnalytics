# QSApiAnalytics

QSApiAnalytics 是一个用于 iOS / watchOS 项目的 API 打点组件，支持应用、页面、点击、加载、展示、关闭、状态、错误等事件上报。

iOS 端在事件上报失败时会将事件保存到本地数据库，并在网络恢复后自动重试。

## 安装

通过 CocoaPods 引入：

```ruby
pod 'QSApiAnalytics'
```

然后执行：

```bash
pod install
```

最低系统版本：

- iOS 15.0+
- watchOS 10.0+

## 初始化

使用前需要先完成初始化，建议在应用启动后尽早调用：

```swift
import QSApiAnalytics

ApiAnalytics.shared.initialize(
    userid: "user_id",
    api: "https://example.com/api/analytics",
    systemVersion: UIDevice.current.systemVersion,
    appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
    ignoreFailedEventCodes: []
)
```

参数说明：

- `userid`：用户唯一标识。
- `api`：打点接口地址，必须是合法的 HTTP 或 HTTPS URL。
- `systemVersion`：系统版本。
- `appVersion`：应用版本。
- `ignoreFailedEventCodes`：请求失败时不需要本地保存和重试的事件编码。

## 上报事件

调用 `addEvent` 上报打点事件：

```swift
ApiAnalytics.shared.addEvent(
    code: "home_button_click",
    name: "首页按钮",
    timestamp: nil,
    type: .click,
    belongPage: "home",
    extra: [
        "buttonId": "start"
    ],
    onSuccess: {
        print("打点成功")
    },
    onError: { event in
        print("打点失败：\(event.eventCode)")
    }
)
```

`timestamp` 传 `nil` 时会自动使用当前毫秒时间戳。

## 常用事件类型

```swift
.appIn       // 应用进入
.appOut      // 应用退出
.pageIn      // 页面进入
.pageOut     // 页面离开
.click       // 点击事件
.valueChange // 值改变事件
.load        // 加载事件
.show        // 显示事件
.close       // 关闭事件
.state       // 状态事件
.error       // 错误事件
```

当上报 `.pageIn` 事件时，组件会自动为上一个页面补充一次 `.pageOut` 事件。

## 页面恢复

可以保存当前页面信息，并在需要时恢复页面进入打点：

```swift
let pageData = ApiAnalytics.shared.getCurrentPageData()

ApiAnalytics.shared.returnToPage(pageData: pageData)
```

## 会话管理

如需重新生成会话 ID，可以调用：

```swift
ApiAnalytics.shared.updateSessionId()
```

## 注意事项

- 必须先调用 `initialize`，否则事件不会发送。
- `api` 必须是合法的 HTTP 或 HTTPS 地址。
- iOS 端依赖 WCDBSwift 保存失败事件，网络恢复后会自动重试。
- Debug 环境下会输出部分调试日志，Release 环境不会输出。
