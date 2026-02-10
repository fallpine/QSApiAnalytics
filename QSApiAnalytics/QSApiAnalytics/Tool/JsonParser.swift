//
//  JsonParser.swift
//  QSApiAnalytics
//
//  Created by ht on 2026/2/10.
//

import UIKit

class JsonParser {
    /// 对象转Json字符串
    ///
    /// - Parameter obj: 对象
    /// - Returns: Json字符串
    static func dictToJsonString(_ dict: Dictionary<String, Any>) -> String? {
        var jsonString: String?
        
        let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted)
        if jsonData != nil {
            jsonString = String.init(data: jsonData!, encoding: String.Encoding.utf8)
        }
        
        return jsonString
    }

}
