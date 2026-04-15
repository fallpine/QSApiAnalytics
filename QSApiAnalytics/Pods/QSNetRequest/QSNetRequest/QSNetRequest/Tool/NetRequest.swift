//
//  NetRequest.swift
//  QSNetRequest
//
//  Created by MacM2 on 12/22/25.
//

import Alamofire
import QSJsonParser

public enum NetRequestError: Error {
    case urlError
    case jsonParseError
}

public class NetRequest {
    /// 发起请求(返回Json)
    ///
    /// - Parameters:
    ///   - urlString: url
    ///   - methodType: 请求方式
    ///   - paraDict: 请求参数
    ///   - encoding: 编码方式
    ///   - headers: 请求头
    ///   - successHandler: 成功
    ///   - errorHandler: 失败
    public static func requestJson(urlString: String,
                                   methodType: HTTPMethod,
                                   paraDict: Dictionary<String, Any>?,
                                   encoding: ParameterEncoding = URLEncoding.default,
                                   headers: HTTPHeaders? = nil,
                                   onSuccess: @escaping ((Any) -> ()),
                                   onError: @escaping ((Error, Int?) -> ())) {
        guard let requestUrl = URL.init(string: urlString) else {
            myPrint("error: 请求地址错误")
            onError(NetRequestError.urlError, nil)
            return
        }
        
        // 请求
        AF.request(requestUrl,
                   method: methodType,
                   parameters: paraDict,
                   encoding: encoding,
                   headers: headers,
                   requestModifier: { $0.timeoutInterval = 30 })
        .responseData(completionHandler: { response in
            switch response.result {
                case .success(let data):
                    if let json = JsonParser.dataToJsonObject(data: data) {
                        onSuccess(json)
                    } else {
                        myPrint(requestUrl, "error: 转换json失败", data.count)
                        onError(NetRequestError.jsonParseError, nil)
                    }
                    
                case .failure(let err):
                    myPrint("error: \(err)", urlString, response.response?.statusCode ?? "")
                    onError(err, response.response?.statusCode)
            }
        })
    }
    
    /// 发起请求(返回Data)
    ///
    /// - Parameters:
    ///   - urlString: url
    ///   - methodType: 请求方式
    ///   - paraDict: 请求参数
    ///   - encoding: 编码方式
    ///   - headers: 请求头
    ///   - successHandler: 成功
    ///   - errorHandler: 失败
    public static func requestData(urlString: String,
                                   methodType: HTTPMethod,
                                   paraDict: Dictionary<String, Any>?,
                                   encoding: ParameterEncoding = URLEncoding.default,
                                   headers: HTTPHeaders? = nil,
                                   onSuccess: @escaping ((Data) -> ()),
                                   onError: @escaping ((Error, Int?) -> ())) {
        guard let requestUrl = URL.init(string: urlString) else {
            myPrint("error: 请求地址错误")
            onError(NetRequestError.urlError, nil)
            return
        }
        
        // 请求
        AF.request(requestUrl,
                   method: methodType,
                   parameters: paraDict,
                   encoding: encoding,
                   headers: headers,
                   requestModifier: { $0.timeoutInterval = 30 })
        .responseData(completionHandler: { response in
            switch response.result {
                case .success(let data):
                    onSuccess(data)
                    
                case .failure(let err):
                    myPrint("error: \(err)", urlString, response.response?.statusCode ?? "")
                    onError(err, response.response?.statusCode)
            }
        })
    }
    
    /// 下载
    /// - Parameters:
    ///   - urlString: 下载地址
    ///   - successHandler: 成功回调
    ///   - errorHandler: 失败回调
    ///   - progressHandler: 进度回调
    public static func download(urlString: String,
                                headers: HTTPHeaders? = nil,
                                onSuccess: @escaping (Data) -> Void,
                                onError: @escaping (Error, Int?) -> Void,
                                onProgress: @escaping (Double) -> Void) {
        AF.request(urlString, headers: headers)
            .downloadProgress { progress in
                let progressValue = progress.fractionCompleted
                onProgress(progressValue)
            }
            .responseData { response in
                switch response.result {
                    case .success(let data):
                        onSuccess(data)
                    case .failure(let err):
                        myPrint("error: \(err)", urlString, response.response?.statusCode ?? "")
                        onError(err, response.response?.statusCode)
                }
            }
    }
    
    /// 表单上传
    public static func upload(urlString: String,
                              paraDict: Dictionary<String, URL>?,
                              headers: Dictionary<String, String>? = nil,
                              onSuccess: @escaping ((Data) -> ()),
                              onError: @escaping ((Error, Int?) -> ())) {
        
        guard let url = URL.init(string: urlString) else {
            myPrint("error: 请求地址错误")
            onError(NetRequestError.urlError, nil)
            return
        }
        
        var requestHeaders = [HTTPHeader]()
        if let headers = headers {
            for (key, value) in headers {
                let header = HTTPHeader.init(name: key, value: value)
                requestHeaders.append(header)
            }
        }
        
        // Prepare the URL
        AF.upload(multipartFormData: { multipartFormData in
            if let dict = paraDict {
                for (key, value) in dict {
                    multipartFormData.append(value, withName: key)
                }
            }
        },
                  to: url,
                  headers: HTTPHeaders.init(requestHeaders))
        .responseData { response in
            
            switch response.result {
                case .success(let data):
                    onSuccess(data)
                    
                case .failure(let err):
                    myPrint("error: \(err)", urlString, response.response?.statusCode ?? "")
                    onError(err, response.response?.statusCode)
            }
        }
    }
    
    private static func myPrint(_ items: Any...) {
#if DEBUG
        print(items)
#endif
    }
}
