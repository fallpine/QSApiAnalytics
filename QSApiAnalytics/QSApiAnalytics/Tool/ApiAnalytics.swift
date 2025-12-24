//
//  ApiAnalytics.swift
//  QSApiAnalytics
//
//  Created by MacM2 on 12/23/25.
//

import Foundation
import Alamofire
import QSIpLocation

public class ApiAnalytics {
    // MARK: - Func
    public func initialize(userid: String,
                           api: String,
                           systemVersion: String,
                           appVersion: String) {
        self.userid = userid
        self.api = api
        self.systemVersion = systemVersion
        self.appVersion = appVersion
    }
    
    /// 打点
    public func addEvent(code: String,
                         name: String,
                         timestamp: TimeInterval?,
                         type: ApiAnalyticsType,
                         belongPage: String?,
                         extra: [String: Any]? = nil,
                         onError: ((ApiAnalyticsModel) -> Void)? = nil)
    {
        let newTimestamp = timestamp ?? getCurrentTimestamp()
        
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
           
            // 接口记录
            requestApi(sessionId: sessionId,
                       eventCode: code,
                       eventName: name,
                       timestamp: newTimestamp,
                       eventType: type,
                       belongPage: belongPage,
                       extra: extra) {
            } onFailure: { [weak self] in
                guard let `self` = self else { return }
                
                failedEventsLock.lock()
                let model = ApiAnalyticsModel(sessionId: sessionId,
                                          eventCode: code,
                                          eventName: name,
                                          eventType: type,
                                          timestamp: newTimestamp,
                                          belongPage: belongPage,
                                          extra: extra)
                failedEvents.append(model)
                failedEventsLock.unlock()
                onError?(model)
            }
        }
    }
    
    /// 获取当前时间戳
    public func getCurrentTimestamp() -> TimeInterval {
        return Date().timeIntervalSince1970 * 1000
    }
    
    /// 更新sessionId
    public func updateSessionId() {
        sessionId = UUID().uuidString
    }
    
    /// 获取当前页面信息
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
    
    /// 返回当前页面
    public func returnToPage(pageData: [String: Any]?) {
        if let code = pageData?["code"] as? String,
           let name = pageData?["name"] as? String
        {
            if code.isEmpty {
                return
            }
            let extra = pageData?["extra"] as? [String: Any]
            
            addEvent(code: code,
                     name: name,
                     timestamp: nil,
                     type: .pageIn,
                     belongPage: code,
                     extra: extra)
        }
    }
    
    /// 重新发送失败的事件
    private func resendFailedEvents() {
        if isSending { return }
        if failedEvents.isEmpty { return }
        
        isSending = true
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            while true {
                failedEventsLock.lock()
                guard !failedEvents.isEmpty else {
                    failedEventsLock.unlock()
                    break
                }
                let model = failedEvents.removeFirst()
                failedEventsLock.unlock()
                
                requestApi(sessionId: model.sessionId,
                           eventCode: model.eventCode,
                           eventName: model.eventName,
                           timestamp: model.timestamp,
                           eventType: model.eventType,
                           belongPage: model.belongPage,
                           extra: model.extra) {
                    // 成功无需处理
                } onFailure: { [weak self] in
                    guard let self = self else { return }
                    
                    failedEventsLock.lock()
                    failedEvents.append(model)
                    failedEventsLock.unlock()
                }
            }
        }
    }
    
    /// 打点事件
    /// - Parameters:
    ///   - sessionId: 会话id
    ///   - eventCode: 事件Code
    ///   - eventName: 事件名
    ///   - eventType: 事件类型
    ///   - belongPage: 属于哪个页面
    ///   - extra: 额外数据
    ///   - completion: 完成回调
    private func requestApi(sessionId: String,
                            eventCode: String,
                            eventName: String,
                            timestamp: TimeInterval,
                            eventType: ApiAnalyticsType,
                            belongPage: String?,
                            extra: [String: Any]?,
                            onSuccess: @escaping (() -> Void),
                            onFailure: @escaping (() -> Void)) {
        IpLocation.getIpLocation { [weak self] model in
            guard let `self` = self else { return }
            
            var extraContent = ""
            if extra != nil {
                extraContent = objectToJsonString(extra!) ?? ""
            }
            
            let name = eventType.eventNamePrefix.replacingOccurrences(of: "@name", with: eventName)
            var paraDict = [
                "sessionId": sessionId,
                "uuid": userid,
                "eventCode": eventCode,
                "eventName": name,
                "eventType": eventType.typeCode,
                "eventTime": timestamp,
                "userIp": model?.ip ?? "",
                "countryCode": model?.country ?? "",
                "cityCode": model?.city ?? "",
                "systemVersion": systemVersion,
                "appVersion": appVersion,
                "attrPage": belongPage ?? "",
                "eventContent": extraContent,
            ] as [String : Any]
            
#if DEBUG
            paraDict["env"] = "dev"
#else
            paraDict["env"] = "prd"
#endif
            
            guard let requestUrl = URL.init(string: api) else {
                return
            }
            
            // 请求
            AF.request(requestUrl,
                       method: .post,
                       parameters: paraDict,
                       encoding: JSONEncoding.prettyPrinted)
            .responseData(completionHandler: { [weak self] response in
                switch response.result {
                case .success(_):
                    self?.myPrint("打点：", eventCode, name, eventType.typeCode, belongPage ?? "", extraContent)
                    onSuccess()
                    
                case .failure(let err):
                    self?.myPrint("打点：", err.localizedDescription)
                    onFailure()
                }
            })
        }
    }
    
    /// 对象转Json字符串
    ///
    /// - Parameter obj: 对象
    /// - Returns: Json字符串
    private func objectToJsonString(_ obj: Any) -> String? {
        var jsonString: String?
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: obj, options: JSONSerialization.WritingOptions.prettyPrinted) {
            jsonString = String.init(data: jsonData, encoding: String.Encoding.utf8)
        }
        
        guard var jsonString = jsonString else { return nil }
        
        // 去掉字符串中的空格
        let range: NSRange = NSRange.init(location: 0, length: jsonString.count)
        jsonString = jsonString.replacingOccurrences(of: " ", with: "", options: String.CompareOptions.literal, range: Range.init(range, in: jsonString))
        // 去掉字符串中的换行符
        let range1: NSRange = NSRange.init(location: 0, length: jsonString.count)
        jsonString = jsonString.replacingOccurrences(of: "\n", with: "", options: String.CompareOptions.literal, range: Range.init(range1, in: jsonString))
        
        return jsonString
    }
    
    /// 监听网络状态
    private func networkReachabilityChanged() {
#if os(iOS)
        networkReachabilityManager = NetworkReachabilityManager()
        
        networkReachabilityManager?.startListening(onUpdatePerforming: { [weak self] status in
            switch status {
            case .reachable(_):
                self?.resendFailedEvents()
                
            default:
                break
            }
        })
#endif
    }
    
    private func myPrint(_ items: Any...) {
#if DEBUG
        print(items)
#endif
    }
    
    // MARK: - Property
#if os(iOS)
    private var networkReachabilityManager: NetworkReachabilityManager?
#endif
    private var userid = ""
    private var api = ""
    private var systemVersion = ""
    private var appVersion = ""
    private var sessionId = UUID().uuidString
    
    public var currentPageCode = ""
    private var currentPageName = ""
    private var currentPageExtra: [String: Any]?
    
    // 发送失败的点
    private var failedEvents = [ApiAnalyticsModel]()
    private var isSending = false
    private let failedEventsLock = NSLock()
    
    // MARK: - 单例
    private static var _sharedInstance: ApiAnalytics?
    public static var shared: ApiAnalytics {
        guard let instance = _sharedInstance else {
            _sharedInstance = ApiAnalytics()
            return _sharedInstance!
        }
        
        return instance
    }
    
    private init() {
        // 网络状态改变
        networkReachabilityChanged()
    }
}
