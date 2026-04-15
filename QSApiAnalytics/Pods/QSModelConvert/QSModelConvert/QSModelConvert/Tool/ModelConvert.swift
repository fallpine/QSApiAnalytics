//
//  ModelConvert.swift
//  QSModelConvert
//
//  Created by MacM2 on 12/23/25.
//

import Foundation

public class ModelConvert {
    /// 将字典转换为Model
    public static func jsonToModel<T: Decodable>(_ json: Any,
                                                 modelType: T.Type) -> T? {
        if !JSONSerialization.isValidJSONObject(json) {
            return nil
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: json)
            let decodedObject = try JSONDecoder().decode(T.self, from: data)
            return decodedObject
        } catch {
            myPrint("转换失败: \(error)")
            return nil
        }
    }
    
    /// 将字典data转换为Model
    public static func dataToModel<T: Decodable>(_ data: Data,
                                                 modelType: T.Type) -> T? {
        do {
            let decodedObject = try JSONDecoder().decode(T.self, from: data)
            return decodedObject
        } catch {
            myPrint("转换失败: \(error)")
            return nil
        }
    }
    
    /// 将字典字符串转换为Model
    public static func stringToModel<T: Decodable>(_ string: String,
                                                   modelType: T.Type) -> T? {
        
        guard let data: Data = string.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data,
                                                           options: JSONSerialization.ReadingOptions.mutableContainers) else {
            myPrint("转换失败")
            return nil
        }
        return jsonToModel(json, modelType: modelType)
    }
    
    /// 将Model转换为字典
    public static func modelToJSON<T: Encodable>(_ model: T) -> Dictionary<String, Any>? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // 可选：格式化输出
            let jsonData = try encoder.encode(model)
            let dict = try? JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as? Dictionary<String, Any>
            return dict
        } catch {
            myPrint("转换为 JSON 数据失败: \(error)")
            return nil
        }
    }
    
    private static func myPrint(_ items: Any...) {
#if DEBUG
        print(items)
#endif
    }
}
