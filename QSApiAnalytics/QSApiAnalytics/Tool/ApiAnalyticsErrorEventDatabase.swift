//
//  ApiAnalyticsErrorEventDatabase.swift
//  QSApiAnalytics
//
//  Created by ht on 2025/12/31.
//

#if os(iOS) && canImport(WCDBSwift)
import Foundation
import WCDBSwift


private let kDbName = "ApiAnalyticsErrorEventDbName"
private let kDbTable = "ApiAnalyticsErrorEventTable"

/// 打点失败事件数据库。
///
/// 负责保存请求失败的打点事件，并提供查询、删除能力给网络恢复重试流程使用。
class ApiAnalyticsErrorEventDatabase {
    // MARK: - Func
    /// 初始化数据库连接。
    private func initDataBase() {
        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let pathUrl = documentsURL.appendingPathComponent("\(kDbName).db")
            database = Database.init(withFileURL: pathUrl)
        }
    }
    
    /// 创建失败事件表。
    private func createTable() {
        do {
            try database?.create(table: kDbTable, of: ApiAnalyticsErrorEventModel.self)
        } catch let error {
            myPrint("Create table failed: \(error.localizedDescription)")
        }
    }
    
    /// 插入失败事件模型。
    /// - Parameter data: 待插入的失败事件数据库模型。
    /// - Returns: 插入是否成功。
    func insert(data: ApiAnalyticsErrorEventModel) -> Bool {
        return databaseQueue.sync {
            insertEvent(data)
        }
    }
    
    /// 将失败事件 JSON 字符串插入数据库。
    /// - Parameter json: `ApiAnalyticsModel` 序列化后的 JSON 字符串。
    /// - Returns: 插入是否成功。
    func insertEventJSON(_ json: String) -> Bool {
        let model = ApiAnalyticsErrorEventModel()
        model.data = json
        return insert(data: model)
    }
    
    /// 在数据库队列中执行插入。
    /// - Parameter data: 待插入的失败事件数据库模型。
    /// - Returns: 插入是否成功。
    private func insertEvent(_ data: ApiAnalyticsErrorEventModel) -> Bool {
        do {
            try database?.insertOrReplace(objects: [data], intoTable: kDbTable)
            return true
        } catch let error {
            myPrint("Insert or replace data failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 删除失败事件模型。
    /// - Parameter data: 待删除的失败事件数据库模型。
    /// - Returns: 删除是否成功。
    func delete(data: ApiAnalyticsErrorEventModel) -> Bool {
        return deleteEvent(data)
    }
    
    /// 删除失败事件模型。
    /// - Parameter data: 待删除的失败事件数据库模型。
    /// - Returns: 删除是否成功。
    func deleteEvent(_ data: ApiAnalyticsErrorEventModel) -> Bool {
        return databaseQueue.sync {
            deleteEventOnQueue(data)
        }
    }
    
    /// 在数据库队列中执行删除。
    /// - Parameter data: 待删除的失败事件数据库模型。
    /// - Returns: 删除是否成功。
    private func deleteEventOnQueue(_ data: ApiAnalyticsErrorEventModel) -> Bool {
        do {
            try database?.delete(fromTable: kDbTable, where: ApiAnalyticsErrorEventModel.Properties.identifier == (data.identifier ?? -1))
            return true
        } catch let error {
            myPrint("Delete failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 查询全部失败事件。
    /// - Returns: 失败事件列表。
    func getDatas() -> [ApiAnalyticsErrorEventModel]? {
        return getAllEvents()
    }
    
    /// 查询全部失败事件，并按自增 ID 升序返回。
    /// - Returns: 失败事件列表。
    func getAllEvents() -> [ApiAnalyticsErrorEventModel] {
        return databaseQueue.sync {
            guard let database = database else { return [] }
            do {
                // 必须指定models的类型，不然后面的getObjects无法确定具体类型会报错
                let models: [ApiAnalyticsErrorEventModel] = try database.getObjects(fromTable: kDbTable,
                                                                                    orderBy: [ApiAnalyticsErrorEventModel.Properties.identifier.asOrder(by: .ascending)])
                return models
            } catch let error {
                myPrint("Query failed: \(error.localizedDescription)")
                return []
            }
        }
    }
    
    /// Debug 环境下输出数据库调试日志。
    private func myPrint(_ items: Any...) {
#if DEBUG
        print(items)
#endif
    }
    
    // MARK: - Property
    /// WCDB 数据库实例。
    private var database: Database?
    /// 保证数据库读写串行执行的队列。
    private let databaseQueue = DispatchQueue(label: "com.qs.apiAnalytics.errorEventDatabase")
    
    // MARK: - 单例
    /// 单例缓存实例。
    private static var _sharedInstance: ApiAnalyticsErrorEventDatabase?
    /// 全局数据库单例。
    public static var shared: ApiAnalyticsErrorEventDatabase {
        guard let instance = _sharedInstance else {
            _sharedInstance = ApiAnalyticsErrorEventDatabase()
            return _sharedInstance!
        }
        
        return instance
    }
    
    /// 创建数据库实例并初始化表结构。
    private init() {
        // 初始化数据库
        initDataBase()
        // 创建表
        createTable()
    }
}

/// 打点失败事件数据库表模型。
final class ApiAnalyticsErrorEventModel: TableCodable {

    /// WCDB 字段映射。
    enum CodingKeys: String, CodingTableKey {
        typealias Root = ApiAnalyticsErrorEventModel
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        /// 自增主键。
        case identifier = "id"
        /// 失败事件 JSON 数据。
        case data = "data"
        
        /// 字段约束配置。
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                .identifier: ColumnConstraintBinding(isPrimary: true, isAutoIncrement: true)
            ]
        }
    }
    
    /// 自增主键。
    var identifier: Int? = nil
    /// 失败事件 JSON 数据。
    var data: String? = nil
 
}
#endif // os(iOS) && canImport(WCDBSwift)
