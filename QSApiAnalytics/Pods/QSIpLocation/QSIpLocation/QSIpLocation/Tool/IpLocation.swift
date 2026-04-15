//
//  IpLocation.swift
//  QSIpLocation
//
//  Created by MacM2 on 12/23/25.
//

import Foundation

public class IpLocation {
    // MARK: - Func
    public static func getIpLocation(completion: @escaping (IpLocationModel?) -> Void) {

        let now = Date().timeIntervalSince1970

        // 1️⃣ 检查缓存是否过期
        let loadTime = UserDefaults.standard.double(forKey: locationTimeKey)
        if now - loadTime > cacheDuration {
            UserDefaults.standard.removeObject(forKey: locationKey)
        }

        // 2️⃣ 读取缓存
        if let jsonStr = UserDefaults.standard.string(forKey: locationKey),
           let data = jsonStr.data(using: .utf8),
           let model = try? JSONDecoder().decode(IpLocationModel.self, from: data) {
            completion(model)
            return
        }

        // 3️⃣ 获取公网 IP
        getPublicIp { ip in
            guard let ip = ip else {
                completion(nil)
                return
            }

            // 4️⃣ 请求地理信息
            let urlStr = "http://ip-api.com/json/\(ip)"
            guard let url = URL(string: urlStr) else {
                completion(nil)
                return
            }

            var request = URLRequest(url: url)
            request.timeoutInterval = 10

            URLSession.shared.dataTask(with: request) { data, _, error in
                guard error == nil,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: json)
                    let model = try JSONDecoder().decode(IpLocationModel.self, from: jsonData)

                    // 5️⃣ 存缓存
                    if let str = String(data: jsonData, encoding: .utf8) {
                        UserDefaults.standard.set(str, forKey: locationKey)
                        UserDefaults.standard.set(now, forKey: locationTimeKey)
                    }

                    DispatchQueue.main.async {
                        completion(model)
                    }

                } catch {
                    DispatchQueue.main.async { completion(nil) }
                }

            }.resume()
        }
    }

    // MARK: - 获取公网 IP
    private static func getPublicIp(completion: @escaping (String?) -> Void) {

        let now = Date().timeIntervalSince1970

        // 1️⃣ 检查缓存
        let loadTime = UserDefaults.standard.double(forKey: ipTimeKey)
        if now - loadTime > cacheDuration {
            UserDefaults.standard.removeObject(forKey: ipKey)
        }

        if let ip = UserDefaults.standard.string(forKey: ipKey) {
            completion(ip)
            return
        }

        // 2️⃣ 多接口容错
        let endpoints = [
            "https://ifconfig.me/ip",
            "https://icanhazip.com",
            "https://checkip.amazonaws.com"
        ]

        fetchIp(from: endpoints, index: 0, completion: completion)
    }

    private static func fetchIp(from endpoints: [String], index: Int, completion: @escaping (String?) -> Void) {

        if index >= endpoints.count {
            completion(nil)
            return
        }

        guard let url = URL(string: endpoints[index]) else {
            fetchIp(from: endpoints, index: index + 1, completion: completion)
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let data = data,
               error == nil,
               let ip = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !ip.isEmpty {

                // 存缓存
                UserDefaults.standard.set(ip, forKey: ipKey)
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: ipTimeKey)

                DispatchQueue.main.async {
                    completion(ip)
                }
            } else {
                // 尝试下一个
                fetchIp(from: endpoints, index: index + 1, completion: completion)
            }
        }.resume()
    }
    
    // MARK: - Property
    private static let locationKey = "kIpLocationModelKey"
    private static let locationTimeKey = "kIpLocationModelLoadTimeKey"

    private static let ipKey = "kPublicIpKey"
    private static let ipTimeKey = "kPublicIpLoadTimeKey"

    private static let cacheDuration: TimeInterval = 60 * 60 * 24 // 24小时
}
