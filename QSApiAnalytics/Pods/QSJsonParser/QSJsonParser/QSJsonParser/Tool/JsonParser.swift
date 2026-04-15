//
//  JsonParser.swift
//  QSJsonParser
//
//  Created by MacM2 on 12/22/25.
//

import Foundation

public class JsonParser {
    /// 把JsonData转换为对象(数组或字典)
    ///
    /// - Parameter data: Json数据
    /// - Returns: Json对象
    public static func dataToJsonObject(data: Data) -> Any? {
        let jsonObj = try? JSONSerialization.jsonObject(with: data,
                                                        options: JSONSerialization.ReadingOptions.mutableContainers)
        
        return jsonObj
    }
    
    /// JsonString转换为字典
    ///
    /// - Parameter jsonString: Json字符串
    /// - Returns: 字典
    public static func jsonStringToDictionary(with jsonString: String) -> Dictionary<String, Any>? {
        let jsonData: Data = jsonString.data(using: .utf8)!
        return dataToJsonObject(data: jsonData) as? Dictionary<String, Any>
    }
    
    /// JsonString转换为数组
    ///
    /// - Parameter jsonString: Json字符串
    /// - Returns: 数组
    public static func jsonStringToArray(with jsonString: String) -> Array<Any>? {
        let jsonData: Data = jsonString.data(using: .utf8)!
        return dataToJsonObject(data: jsonData) as? Array<Any>
    }
    
    /// 对象转data
    /// - Parameter josnObject: 对象
    /// - Returns: data
    public static func objectToData(with josnObject: Any) -> Data? {
        if !JSONSerialization.isValidJSONObject(josnObject) {
            return nil
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: josnObject,
                                                      options: JSONSerialization.WritingOptions.prettyPrinted)
            return jsonData
        } catch {
            return nil
        }
    }
    
    /// 对象转Json字符串
    ///
    /// - Parameter obj: 对象
    /// - Returns: Json字符串
    public static func objectToString(with josnObject: Any) -> String? {
        if !JSONSerialization.isValidJSONObject(josnObject) {
            return nil
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: josnObject,
                                                      options: JSONSerialization.WritingOptions.prettyPrinted)
            let jsonString = String.init(data: jsonData,
                                         encoding: String.Encoding.utf8)
            return jsonString
        } catch {
            return nil
        }
    }
}
