//
//  ApiAnalyticsErrorEventDatabase.swift
//  QSApiAnalytics
//
//  Created by ht on 2025/12/31.
//

#if os(iOS)
import WCDBSwift
#endif // os(iOS)

private let kDbName = "ApiAnalyticsErrorEventDbName"
private let kDbTable = "ApiAnalyticsErrorEventTable"

class ApiAnalyticsErrorEventDatabase {
#if os(iOS)
    // MARK: - Func
    /// 初始化数据库
    private func initDataBase() {
        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let pathUrl = documentsURL.appendingPathComponent("\(kDbName).db")
            database = Database.init(withFileURL: pathUrl)
        }
    }
    
    /// 创建表
    private func createTable() {
        do {
            try database?.create(table: kDbTable, of: ApiAnalyticsErrorEventModel.self)
        } catch let error {
            myPrint("Create table failed: \(error.localizedDescription)")
        }
    }
    
    /// 插入数据
    func insert(data: ApiAnalyticsErrorEventModel) -> Bool {
        do {
            try database?.insertOrReplace(objects: [data], intoTable: kDbTable)
            return true
        } catch let error {
            myPrint("Insert or replace data failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 删除数据
    func delete(data: ApiAnalyticsErrorEventModel) -> Bool {
        do {
            try database?.delete(fromTable: kDbTable, where: ApiAnalyticsErrorEventModel.Properties.identifier == (data.identifier ?? -1))
            return true
        } catch let error {
            myPrint("Delete failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 查询数据
    func getDatas() -> [ApiAnalyticsErrorEventModel]? {
        guard let database = database else { return nil }
        do {
            // 必须指定models的类型，不然后面的getObjects无法确定具体类型会报错
            let models: [ApiAnalyticsErrorEventModel] = try database.getObjects(fromTable: kDbTable)
            return models
        } catch let error {
            myPrint("Query failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func myPrint(_ items: Any...) {
#if DEBUG
        print(items)
#endif
    }
    
    // MARK: - Property
    private var database: Database?
    
    // MARK: - 单例
    private static var _sharedInstance: ApiAnalyticsErrorEventDatabase?
    public static var shared: ApiAnalyticsErrorEventDatabase {
        guard let instance = _sharedInstance else {
            _sharedInstance = ApiAnalyticsErrorEventDatabase()
            return _sharedInstance!
        }
        
        return instance
    }
    
    private init() {
        // 初始化数据库
        initDataBase()
        // 创建表
        createTable()
    }
#endif // os(iOS)
}

final class ApiAnalyticsErrorEventModel: TableCodable {
#if os(iOS)
    enum CodingKeys: String, CodingTableKey {
        typealias Root = ApiAnalyticsErrorEventModel
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        case identifier = "id"
        case data = "data"
        
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                .identifier: ColumnConstraintBinding(isPrimary: true, isAutoIncrement: true)
            ]
        }
    }
    
    // 主键
    var identifier: Int? = nil
    // url
    var data: String? = nil
#endif // os(iOS)
}
