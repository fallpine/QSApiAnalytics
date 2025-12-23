//
//  ApiAnalyticsModel.swift
//  QSApiAnalytics
//
//  Created by MacM2 on 12/23/25.
//

import Foundation

public struct ApiAnalyticsModel {
    var sessionId: String
    var eventCode: String
    var eventName: String
    var eventType: ApiAnalyticsType
    var timestamp: TimeInterval
    var belongPage: String?
    var extra: Dictionary<String, Any>?
}

/// 打点事件类型
public enum ApiAnalyticsType {
    case appIn
    case appOut
    case pageIn
    case pageOut
    case click
    case valueChange
    case load
    case show
    case close
    case state
    case error
    
    var typeCode: String {
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
    
    // firebase打点的数据类型
    var firebaseTypeCode: String {
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
            return "vc"
        case .click:
            return "clk"
        case .load:
            return "ld"
        case .show:
            return "in"
        case .close:
            return "out"
        case .state:
            return ""
        case .error:
            return "err"
        }
    }
    
    var eventNamePrefix: String {
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
