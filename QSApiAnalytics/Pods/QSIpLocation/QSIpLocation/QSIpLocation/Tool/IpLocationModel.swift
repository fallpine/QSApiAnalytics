//
//  IpLocationModel.swift
//  QSIpLocation
//
//  Created by MacM2 on 12/23/25.
//

public class IpLocationModel: Decodable {
    public var countryCode: String?
    public var isp: String?
    public var org: String?
    public var city: String?
    public var region: String?
    public var regionName: String?
    public var timezone: String?
    public var country: String?
    public var lon: Double?
    public var lat: Double?
    public var zip: String?
    public var query: String?
}
