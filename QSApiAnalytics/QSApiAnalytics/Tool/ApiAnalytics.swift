//
//  ApiAnalytics.swift
//  QSApiAnalytics
//
//  Created by MacM2 on 12/23/25.
//

import Foundation
import Alamofire
import QSIpLocation
import QSModelConvert
import QSJsonParser

/// API 打点管理器。
///
/// 使用前需要先调用 `initialize(userid:api:systemVersion:appVersion:ignoreFailedEventCodes:)`
/// 完成配置初始化。普通打点请求失败后会落库保存，网络恢复时会自动重试。
public class ApiAnalytics {
    // MARK: - Func
    /// 初始化打点配置。
    /// - Parameters:
    ///   - userid: 用户唯一标识。
    ///   - api: 打点接口地址，必须为合法的 HTTP 或 HTTPS URL。
    ///   - systemVersion: 系统版本。
    ///   - appVersion: 应用版本。
    ///   - ignoreFailedEventCodes: 请求失败时不需要落库重试的事件编码列表。
    public func initialize(userid: String,
                           api: String,
                           systemVersion: String,
                           appVersion: String,
                           ignoreFailedEventCodes: [String]) {
        self.userid = userid
        self.api = api
        self.systemVersion = systemVersion
        self.appVersion = appVersion
        self.ignoreFailedEventCodes = ignoreFailedEventCodes
        isInitialized = true
        
#if os(iOS) && canImport(WCDBSwift)
        retryErrorEventsIfNeeded()
#endif
    }
    
    /// 记录并上报一个打点事件。
    ///
    /// 当事件上报失败且事件编码不在忽略列表中时，会将事件保存到本地数据库，
    /// 等待网络恢复后自动重试。
    /// - Parameters:
    ///   - code: 事件编码。
    ///   - name: 事件名称。
    ///   - timestamp: 事件时间戳，单位为毫秒；传 `nil` 时使用当前时间。
    ///   - type: 事件类型。
    ///   - belongPage: 事件所属页面编码。
    ///   - extra: 事件扩展参数。
    ///   - onSuccess: 请求成功回调。
    ///   - onError: 请求失败或配置不可用回调。
    public func addEvent(code: String,
                         name: String,
                         timestamp: TimeInterval?,
                         type: ApiAnalyticsType,
                         belongPage: String?,
                         extra: [String: String]? = nil,
                         onSuccess: (() -> Void)? = nil,
                         onError: ((ApiAnalyticsModel) -> Void)? = nil)
    {
        let newTimestamp = timestamp ?? getCurrentTimestamp()
        let event = ApiAnalyticsModel(sessionId: sessionId,
                                      eventCode: code,
                                      eventName: name,
                                      eventType: type,
                                      timestamp: newTimestamp,
                                      belongPage: belongPage,
                                      extra: extra)
        
        guard canSendEvent else {
            onError?(event)
            return
        }
        
        guard currentRequestURL != nil else {
            onError?(event)
            return
        }
        
        if type == .pageIn {
            // 退出上一个页面
            if !currentPageCode.isEmpty {
                addEvent(code: currentPageCode,
                         name: currentPageName,
                         timestamp: newTimestamp - 1,
                         type: .pageOut,
                         belongPage: currentPageCode,
                         extra: nil)
            }
            
            // 记录新页面
            currentPageCode = code
            currentPageName = name
            currentPageExtra = extra
        }
        
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            
            sendEvent(event, persistOnFailure: true) {
                onSuccess?()
            } onFailure: {
                onError?(event)
            }
        }
    }
    
    /// 获取当前时间戳。
    /// - Returns: 当前毫秒时间戳。
    public func getCurrentTimestamp() -> TimeInterval {
        return Date().timeIntervalSince1970 * 1000
    }
    
    /// 更新当前会话 ID。
    public func updateSessionId() {
        sessionId = UUID().uuidString
    }
    
    /// 获取当前页面信息。
    /// - Returns: 当前页面编码、名称和扩展参数；没有页面记录时返回 `nil`。
    public func getCurrentPageData() -> [String: Any]? {
        if currentPageCode.isEmpty {
            return nil
        }
        return [
            "code": currentPageCode,
            "name": currentPageName,
            "extra": currentPageExtra as Any,
        ]
    }
    
    /// 恢复到指定页面并补充页面进入打点。
    /// - Parameter pageData: `getCurrentPageData()` 返回的页面信息。
    public func returnToPage(pageData: [String: Any]?) {
        if let code = pageData?["code"] as? String,
           let name = pageData?["name"] as? String
        {
            if code.isEmpty {
                return
            }
            let extra = pageData?["extra"] as? [String: String]
            
            addEvent(code: code,
                     name: name,
                     timestamp: nil,
                     type: .pageIn,
                     belongPage: code,
                     extra: extra)
        }
    }
    
#if os(iOS) && canImport(WCDBSwift)
    /// 在网络可用且配置已初始化时，串行重试本地保存的失败事件。
    ///
    /// 重试过程中不会再次落库，避免同一条失败事件重复增长。
    private func retryErrorEventsIfNeeded() {
        retryQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.canSendEvent else { return }
            guard self.currentRequestURL != nil else { return }
            guard self.isNetworkReachable else { return }
            guard !self.isRetryingFailedEvents else { return }
            
            self.isRetryingFailedEvents = true
            defer {
                self.isRetryingFailedEvents = false
            }
            
            let models = ApiAnalyticsErrorEventDatabase.shared.getAllEvents()
            guard !models.isEmpty else {
                return
            }
            
            for model in models {
                guard self.isNetworkReachable else {
                    return
                }
                
                guard let data = model.data,
                      let dataModel = ModelConvert.stringToModel(data, modelType: ApiAnalyticsModel.self) else {
                    _ = ApiAnalyticsErrorEventDatabase.shared.deleteEvent(model)
                    continue
                }
                
                let semaphore = DispatchSemaphore(value: 0)
                var retrySucceeded = false
                
                self.sendEvent(dataModel, persistOnFailure: false) {
                    retrySucceeded = true
                    semaphore.signal()
                } onFailure: {
                    semaphore.signal()
                }
                
                semaphore.wait()
                
                if retrySucceeded {
                    _ = ApiAnalyticsErrorEventDatabase.shared.deleteEvent(model)
                }
            }
        }
    }
#endif // os(iOS) && canImport(WCDBSwift)
    
    /// 发送打点事件，并根据需要在失败时落库。
    /// - Parameters:
    ///   - event: 待发送事件。
    ///   - persistOnFailure: 请求失败时是否保存到本地数据库。
    ///   - onSuccess: 请求成功回调。
    ///   - onFailure: 请求失败回调。
    private func sendEvent(_ event: ApiAnalyticsModel,
                           persistOnFailure: Bool,
                           onSuccess: @escaping (() -> Void),
                           onFailure: @escaping (() -> Void)) {
        guard canSendEvent, currentRequestURL != nil else {
            onFailure()
            return
        }
        
        requestApi(event: event) { [weak self] in
            self?.myPrint("打点：", event.eventCode, event.eventName, event.eventType.typeCode, event.belongPage ?? "")
            onSuccess()
        } onFailure: { [weak self] in
            guard let self = self else {
                onFailure()
                return
            }
            
            if persistOnFailure {
                self.saveFailedEventIfNeeded(event)
            }
            
            onFailure()
        }
    }
    
    /// 根据忽略列表判断是否需要保存失败事件，并执行落库。
    /// - Parameter event: 请求失败的打点事件。
    private func saveFailedEventIfNeeded(_ event: ApiAnalyticsModel) {
        guard !ignoreFailedEventCodes.contains(event.eventCode) else {
            return
        }
        
#if os(iOS) && canImport(WCDBSwift)
        if let modelDict = ModelConvert.modelToJSON(event),
           let jsonStr = JsonParser.objectToString(with: modelDict) {
            _ = ApiAnalyticsErrorEventDatabase.shared.insertEventJSON(jsonStr)
        }
#endif
    }
    
    /// 调用远端打点接口。
    /// - Parameters:
    ///   - event: 待发送事件。
    ///   - onSuccess: 请求成功回调。
    ///   - onFailure: 请求失败回调。
    private func requestApi(event: ApiAnalyticsModel,
                            onSuccess: @escaping (() -> Void),
                            onFailure: @escaping (() -> Void)) {
        IpLocation.getIpLocation { [weak self] model in
            guard let `self` = self else { return }
            
            var extraContent = ""
            if let extra = event.extra {
                extraContent = JsonParser.objectToString(with: extra) ?? ""
            }
            
            let name = event.eventType.eventNamePrefix.replacingOccurrences(of: "@name", with: event.eventName)
            var paraDict = [
                "sessionId": event.sessionId,
                "uuid": userid,
                "eventCode": event.eventCode,
                "eventName": name,
                "eventType": event.eventType.typeCode,
                "eventTime": event.timestamp,
                "userIp": model?.query ?? "",
                "countryCode": model?.country ?? "",
                "cityCode": model?.city ?? "",
                "systemVersion": systemVersion,
                "appVersion": appVersion,
                "attrPage": event.belongPage ?? "",
                "eventContent": extraContent,
            ] as [String : Any]
            
#if DEBUG
            paraDict["env"] = "dev"
#else
            paraDict["env"] = "prd"
#endif
            
            guard let requestUrl = currentRequestURL else {
                onFailure()
                return
            }
            
            // 请求
            AF.request(requestUrl,
                       method: .post,
                       parameters: paraDict,
                       encoding: JSONEncoding.prettyPrinted)
            .validate(statusCode: 200..<300)
            .responseData(completionHandler: { [weak self] response in
                switch response.result {
                case .success(_):
                    self?.myPrint("打点：", event.eventCode, name, event.eventType.typeCode, event.belongPage ?? "", extraContent)
                    onSuccess()
                    
                case .failure(let err):
                    self?.myPrint("打点：", err.localizedDescription)
                    onFailure()
                }
            })
        }
    }
    
    /// 监听网络状态变化。
    ///
    /// 网络恢复可用时会触发失败事件重试。
    private func networkReachabilityChanged() {
#if os(iOS)
        networkReachabilityManager = NetworkReachabilityManager()
        
        networkReachabilityManager?.startListening(onUpdatePerforming: { [weak self] status in
            switch status {
            case .reachable(_):
                self?.isNetworkReachable = true
#if canImport(WCDBSwift)
                self?.retryErrorEventsIfNeeded()
#endif
            case .notReachable:
                self?.isNetworkReachable = false
                
            default:
                break
            }
        })
#endif // os(iOS)
    }
    
    /// Debug 环境下输出调试日志。
    private func myPrint(_ items: Any...) {
#if DEBUG
        print(items)
#endif
    }
    
    /// 当前配置是否满足发送打点的基本条件。
    private var canSendEvent: Bool {
        return isInitialized && !userid.isEmpty && !api.isEmpty
    }
    
    /// 当前配置的请求 URL。
    private var currentRequestURL: URL? {
        guard let url = URL(string: api),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host?.isEmpty == false else {
            return nil
        }
        return url
    }
    
    // MARK: - Property
#if os(iOS)
    /// Alamofire 网络状态监听器。
    private var networkReachabilityManager: NetworkReachabilityManager?
    /// 当前网络是否可用。
    private var isNetworkReachable = true
#endif
#if os(iOS) && canImport(WCDBSwift)
    /// 失败事件重试串行队列。
    private let retryQueue = DispatchQueue(label: "com.qs.apiAnalytics.retryQueue")
    /// 是否正在重试失败事件。
    private var isRetryingFailedEvents = false
#endif
    /// 是否已完成初始化。
    private var isInitialized = false
    /// 用户唯一标识。
    private var userid = ""
    /// 打点接口地址。
    private var api = ""
    /// 系统版本。
    private var systemVersion = ""
    /// 应用版本。
    private var appVersion = ""
    /// 请求失败时不落库的事件编码列表。
    private var ignoreFailedEventCodes = [String]()
    /// 当前会话 ID。
    private var sessionId = UUID().uuidString
    
    /// 当前页面编码。
    public var currentPageCode = ""
    /// 当前页面名称。
    private var currentPageName = ""
    /// 当前页面扩展参数。
    private var currentPageExtra: [String: String]?
    
    // MARK: - 单例
    /// 单例缓存实例。
    private static var _sharedInstance: ApiAnalytics?
    /// 全局打点管理器单例。
    public static var shared: ApiAnalytics {
        guard let instance = _sharedInstance else {
            _sharedInstance = ApiAnalytics()
            return _sharedInstance!
        }
        
        return instance
    }
    
    /// 创建打点管理器并启动网络状态监听。
    private init() {
        // 网络状态改变
        networkReachabilityChanged()
    }
}
