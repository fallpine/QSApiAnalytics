//
//  ApiAnalyticsModel.swift
//  QSApiAnalytics
//
//  Created by MacM2 on 12/23/25.
//

import Foundation

/// 打点事件数据模型。
///
/// 该模型既用于实时接口请求，也用于失败事件落库后的重试恢复。
public struct ApiAnalyticsModel: Codable {
    /// 当前会话 ID。
    public var sessionId: String
    /// 事件编码，用于唯一标识业务事件。
    public var eventCode: String
    /// 事件名称，用于展示或服务端可读描述。
    public var eventName: String
    /// 事件类型。
    public var eventType: ApiAnalyticsType
    /// 事件发生时间，单位为毫秒时间戳。
    public var timestamp: TimeInterval
    /// 当前事件所属页面编码。
    public var belongPage: String?
    /// 事件扩展参数。
    public var extra: Dictionary<String, String>?
}

/// 打点事件类型
public enum ApiAnalyticsType: String, Codable {
    /// 应用进入。
    case appIn
    /// 应用退出。
    case appOut
    /// 页面进入。
    case pageIn
    /// 页面离开。
    case pageOut
    /// 点击事件。
    case click
    /// 值改变事件。
    case valueChange
    /// 加载事件。
    case load
    /// 显示事件。
    case show
    /// 关闭事件。
    case close
    /// 状态事件。
    case state
    /// 错误事件。
    case error
    
    /// 服务端接口需要的事件类型编码。
    public var typeCode: String {
        switch self {
        case .appIn:
            return "in"
        case .appOut:
            return "out"
        case .pageIn:
            return "in"
        case .pageOut:
            return "out"
        case .valueChange:
            return "click"
        case .click:
            return "click"
        case .load:
            return "load"
        case .show:
            return "in"
        case .close:
            return "out"
        case .state:
            return "load"
        case .error:
            return "error"
        }
    }
    
    /// 根据事件类型生成服务端展示名称前缀。
    public var eventNamePrefix: String {
        switch self {
        case .appIn:
            return "@name"
        case .appOut:
            return "@name"
        case .pageIn:
            return "进入-【@name】"
        case .pageOut:
            return "离开-【@name】"
        case .valueChange:
            return "值改变-@name"
        case .click:
            return "点击-@name"
        case .load:
            return "加载-@name"
        case .show:
            return "显示-【@name】"
        case .close:
            return "关闭-【@name】"
        case .state:
            return "状态-@name"
        case .error:
            return "错误-@name"
        }
    }
}
