//
//  generics.swift
//
//  Created by Steve Leeke on 9/22/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l <= r
    case (nil, _?):
        return true
    default:
        return false
    }
}

func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}

func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

class Default<T>
{
    private var _value : T?
    {
        didSet {
            
        }
    }
    
    var value : T?
    {
        get {
            // Calls defaultValue EVERY TIME _value is nil
            return _value ?? defaultValue?()
        }
        set {
            _value = newValue
        }
    }
    
    var defaultValue : (()->T?)?
    
    init(_ defaultValue:(()->T?)? = nil)
    {
        self.defaultValue = defaultValue
    }
}

class OnNil<T>
{
    private var _value : T?
    {
        didSet {
            
        }
    }
    
    var value : T?
    {
        get {
            guard _value == nil else {
                return _value
            }
            
            // Loads _value when it is nil.
            _value = onNil?()
            
            return _value
        }
        set {
            _value = newValue
        }
    }
    
    var onNil : (()->T?)?
    
    init(_ onNil:(()->T?)? = nil)
    {
        self.onNil = onNil
    }
}

// Like a blocking Fetch
class OnNilGet<T>
{
    private var _value : T?
    {
        didSet {
            
        }
    }
    
    var value : T?
    {
        get {
            guard _value == nil else {
                return _value
            }
            
            // Loads _value when it is nil.
            _value = onNil?()
            
            return _value
        }
    }
    
    var onNil : (()->T?)?
    
    init(_ onNil:(()->T?)? = nil)
    {
        self.onNil = onNil
    }
    
    func clear()
    {
        _value = nil
    }
}

class Sync<T>
{
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: UUID().uuidString)
    }()
    
    private var _value:T?
    {
        didSet {
            
        }
    }
    
    var value:T?
    {
        set {
            queue.sync {
                _value = newValue
            }
        }
        get {
            return queue.sync {
                return _value
            }
        }
    }
}

class Setting<T>
{
    var isSetting : Bool = false
    
    var value:T?
    {
        didSet {
            
        }
    }
    
    // The variable setting, the argument to the setter function/closure, is itself a function/closure.
    //
    // The variable setting must be optional because it must be escaping, which optional functions/closures are by default in Swift.
    //
    // I.e the setter function/closure is assumed to be a closure from which setting, the closure after setter() below, escapes.
    //
    // Because we assume setting is escaping from setter we can't use Sync in this case because we don't block on setter.
    //
    
    func set(setter : ((_ setting:((T?)->())?)->()))
    {
        isSetting = true
        setter( // setting:
        { (value:T?) in
            self.value = value
            self.isSetting = false
        })
    }
}

// CAN LEAD TO BAD PERFORMANCE
// if used for large numbers of shadowed scalars
class Shadowed<T>
{
    private var _value : T?
    {
        didSet {
            onDidSet?(_value,oldValue)
        }
    }

    var value : T?
    {
        get {
            guard onGet == nil else {
                return onGet?(_value)
            }

            if _value == nil, onNil != nil {
                _value = onNil?()
            }

            return _value ?? defaultValue?()
        }
        set {
            guard onSet == nil else {
                _value = onSet?(newValue)
                return
            }

            _value = newValue
        }
    }

    func clear()
    {
        _value = nil
    }

    var defaultValue : (()->T?)?

    var onGet : ((T?)->T?)?

    var onSet : ((T?)->T?)?

    var onNil : (()->T?)?

    var onDidSet : ((T?,T?)->())?

    init(_ defaultValue:(()->T?)? = nil,onGet:((T?)->T?)? = nil,onSet:((T?)->T?)? = nil,onNil:(()->T?)? = nil,onDidSet:((T?,T?)->())? = nil)
    {
        self.defaultValue = defaultValue
    }
}

// BAD PERFORMANCE
//class Shadowed<T>
//{
//    private var _backingStore : T?
//    {
//        didSet {
//            if let didSet = didSet {
//                didSet(_backingStore,oldValue)
//            } else {
//                if _backingStore == nil, oldValue != nil {
//                    load()
//                }
//            }
//        }
//    }
//
//    private var get : (()->(T?))?
////    private var pre : (()->Bool)?
////    private var toSet : ((T?)->(T?))?
//    private var didSet : ((T?,T?)->())?
//
//    init(get:(()->(T?))?,
////         toSet:((T?)->(T?))? = nil,
//         didSet:((T?,T?)->())? = nil
//        ) // pre:(()->Bool)? = nil,
//    {
//        self.get = get
////        self.toSet = toSet
////        self.pre = pre
//        self.didSet = didSet
//    }
//
//    var value : T?
//    {
//        get {
//            guard _backingStore == nil else {
//                return _backingStore
//            }
//
//            // If didSet is nil this prevents recursion
////            if let pre = pre, pre() {
////                return nil
////            }
//
//            load()
//
//            return _backingStore
//        }
//        set {
////            if let toSet = toSet {
////                _backingStore = toSet(newValue)
////            } else {
////                _backingStore = newValue
////            }
//            _backingStore = newValue
//        }
//    }
//
//    func load()
//    {
//        _backingStore = get?()
//    }
//
////    func clear()
////    {
////        _backingStore = nil
////    }
//}

class Cached<T> {
    @objc func freeMemory()
    {
        cache.clear() // = [String:T]()
    }
    
    var index:(()->String?)?
    
    // Make thread safe?
    var cache = ThreadSafeDictionary<T>() // [String:T]
    
    // if index DOES NOT produce the full key
    subscript(key:String?) -> T?
    {
        get {
            guard let key = key else {
                return nil
            }
            
            if let index = self.index?() {
                return cache[index+":"+key]
            } else {
                return cache[key]
            }
        }
        set {
            guard let key = key else {
                return
            }
            
            if let index = self.index?() {
                cache[index+":"+key] = newValue
            } else {
                cache[key] = newValue
            }
        }
    }
    
    // if index DOES produce the full key
    var indexValue:T?
    {
        get {
            if let index = self.index?() {
                return cache[index]
            } else {
                return nil
            }
        }
        set {
            if let index = self.index?() {
                cache[index] = newValue
            }
        }
    }
    
    init(index:(()->String?)?)
    {
        self.index = index
        
        Thread.onMainThread {
            NotificationCenter.default.addObserver(self, selector: #selector(self.freeMemory), name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FREE_MEMORY), object: nil)
        }
    }
    
    deinit {
        
    }
}

class BoundsCheckedArray<T>
{
    private var storage = [T]()
    
    func sorted(_ sort:((T,T)->Bool)) -> [T]
    {
        guard let getIt = getIt else {
            return storage.sorted(by: sort)
        }
        
        let sorted = getIt().sorted(by: sort)

        return sorted
    }
    
    func filter(_ fctn:((T)->Bool)) -> [T]
    {
        guard let getIt = getIt else {
            return storage.filter(fctn)
        }
        
        let filtered = getIt().filter(fctn)

        return filtered
    }
    
    var count : Int
    {
        guard let getIt = getIt else {
            return storage.count
        }
        
        return getIt().count
    }
    
    func clear()
    {
        storage = [T]()
    }
    
    var getIt:(()->([T]))?
    
    init(getIt:(()->([T]))?)
    {
        self.getIt = getIt
    }
    
    subscript(key:Int) -> T?
    {
        get {
            if let array = getIt?() {
                if key >= 0,key < array.count {
                    return array[key]
                }
            } else {
                if key >= 0,key < storage.count {
                    return storage[key]
                }
            }
            
            return nil
        }
        set {
            guard getIt == nil else {
                return
            }
            
            guard let newValue = newValue else {
                if key >= 0,key < storage.count {
                    storage.remove(at: key)
                }
                return
            }
            
            if key >= 0,key < storage.count {
                storage[key] = newValue
            }
            
            if key == storage.count {
                storage.append(newValue)
            }
        }
    }
}

class ThreadSafeArray<T>
{
    private var storage = [T]()
    
    func sorted(sort:((T,T)->Bool)) -> [T]
    {
        return storage.sorted(by: sort)
    }
    
    var copy : [T]?
    {
        get {
            return queue.sync {
                return storage.count > 0 ? storage : nil
            }
        }
    }
    
    var reversed : [T]?
    {
        get {
            return queue.sync {
                return storage.count > 0 ? storage.reversed() : nil
            }
        }
    }
    
    var count : Int
    {
        get {
            return storage.count
        }
    }
    
    var isEmpty : Bool
    {
        return storage.isEmpty
    }
    
    func clear()
    {
        queue.sync {
            self.storage = [T]()
        }
    }
    
    func append(_ item:T)
    {
        storage.append(item)
    }
    
    func update(storage:Any?)
    {
        queue.sync {
            guard let storage = storage as? [T] else {
                return
            }
            
            self.storage = storage
        }
    }

    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: name ?? UUID().uuidString)
    }()
    
    var name : String?
    
    init(name:String? = nil)
    {
        self.name = name
    }
    
    subscript(key:Int) -> T?
    {
        get {
            return queue.sync {
                if key >= 0,key < storage.count {
                    return storage[key]
                }
                
                return nil
            }
        }
        set {
            queue.sync {
                guard let newValue = newValue else {
                    if key >= 0,key < storage.count {
                        storage.remove(at: key)
                    }
                    return
                }
                
                if key >= 0,key < storage.count {
                    storage[key] = newValue
                }
                
                if key == storage.count {
                    storage.append(newValue)
                }
            }
        }
    }
}

class ThreadSafeDictionary<T>
{
    private var storage = [String:T]()
    
    var count : Int
    {
        get {
            return queue.sync {
                return storage.count
            }
        }
    }
    
    var copy : [String:T]?
    {
        get {
            return queue.sync {
                return storage.count > 0 ? storage : nil
            }
        }
    }

    var isEmpty : Bool
    {
        return queue.sync {
            return storage.isEmpty
        }
    }
    
    var values : [T]
    {
        get {
            return queue.sync {
                return Array(storage.values)
            }
        }
    }
    
    var keys : [String]
    {
        get {
            return queue.sync {
                return Array(storage.keys)
            }
        }
    }
    
    func clear()
    {
        queue.sync {
            self.storage = [String:T]()
        }
    }
    
    func update(storage:Any?)
    {
        queue.sync {
            guard let storage = storage as? [String:T] else {
                return
            }
            
            self.storage = storage
        }
    }
    
    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: name ?? UUID().uuidString)
    }()
    
    var name : String?
    
    init(name:String? = nil)
    {
        self.name = name
    }
    
    subscript(key:String?) -> T?
    {
        get {
            return queue.sync {
                guard let key = key else {
                    return nil
                }
                
                return storage[key]
            }
        }
        set {
            queue.sync {
                guard let key = key else {
                    return
                }

                storage[key] = newValue
            }
        }
    }
}

class ThreadSafeDictionaryOfDictionaries<T>
{
    private var storage = [String:[String:T]]()
    
    var count : Int
    {
        get {
            return queue.sync {
                return storage.count
            }
        }
    }
    
    var copy : [String:[String:T]]?
    {
        get {
            return queue.sync {
                return storage.count > 0 ? storage : nil
            }
        }
    }
    
    var isEmpty : Bool
    {
        return queue.sync {
            return storage.isEmpty
        }
    }
    
    var values : [[String:T]]
    {
        get {
            return queue.sync {
                return Array(storage.values)
            }
        }
    }
    
    var keys : [String]
    {
        get {
            return queue.sync {
                return Array(storage.keys)
            }
        }
    }
    
    func clear()
    {
        queue.sync {
            self.storage = [String:[String:T]]()
        }
    }
    
    func update(storage:Any?)
    {
        queue.sync {
            guard let storage = storage as? [String:[String:T]] else {
                return
            }
            
            self.storage = storage
        }
    }
    
    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: name ?? UUID().uuidString)
        }()
    
    var name : String?
    
    init(name:String? = nil)
    {
        self.name = name
    }
    
    subscript(outer:String?) -> [String:T]?
    {
        get {
            return queue.sync {
                guard let outer = outer else {
                    return nil
                }
                
                return storage[outer]
            }
        }
        set {
            queue.sync {
                guard let outer = outer else {
                    return
                }
                
                storage[outer] = newValue
            }
        }
    }
    
    func set(_ outer:String?, _ inner:String?, value:T?)
    {
        queue.sync {
            guard let outer = outer else {
                return
            }
            
            guard let inner = inner else {
                return
            }
            
            if storage[outer] == nil {
                storage[outer] = [String:T]()
            }
            
            storage[outer]?[inner] = value
        }
    }
    
    func get(_ outer:String?, _ inner:String?) -> T?
    {
        return queue.sync {
            guard let outer = outer else {
                return nil
            }
            
            guard let inner = inner else {
                return nil
            }
            
            return storage[outer]?[inner]
        }
    }
    
    subscript(outer:String?,inner:String?) -> T?
    {
        get {
            return queue.sync {
                guard let outer = outer else {
                    return nil
                }
                
                guard let inner = inner else {
                    return nil
                }
                
                return storage[outer]?[inner]
            }
        }
        set {
            queue.sync {
                guard let outer = outer else {
                    return
                }
                
                guard let inner = inner else {
                    return
                }
                
                if storage[outer] == nil {
                    storage[outer] = [String:T]()
                }
                
                storage[outer]?[inner] = newValue
            }
        }
    }
}

class ThreadSafeDictionaryOfDictionariesOfDictionaries<T>
{
    private var storage = [String:[String:[String:T]]]()
    
    var count : Int
    {
        get {
            return queue.sync {
                return storage.count
            }
        }
    }
    
    var copy : [String:[String:[String:T]]]?
    {
        get {
            return queue.sync {
                return storage.count > 0 ? storage : nil
            }
        }
    }
    
    var isEmpty : Bool
    {
        return queue.sync {
            return storage.isEmpty
        }
    }
    
    var values : [[String:[String:T]]]
    {
        get {
            return queue.sync {
                return Array(storage.values)
            }
        }
    }
    
    var keys : [String]
    {
        get {
            return queue.sync {
                return Array(storage.keys)
            }
        }
    }
    
    func clear()
    {
        queue.sync {
            self.storage = [String:[String:[String:T]]]()
        }
    }
    
    func update(storage:Any?)
    {
        queue.sync {
            guard let storage = storage as? [String:[String:[String:T]]] else {
                return
            }
            
            self.storage = storage
        }
    }
    
    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: name ?? UUID().uuidString)
        }()
    
    var name : String?
    
    init(name:String? = nil)
    {
        self.name = name
    }
    
    func set(_ outer:String?, _ middle:String?, _ inner:String?, value:T?)
    {
        queue.sync {
            guard let outer = outer else {
                return
            }
            
            guard let middle = middle else {
                return
            }
            
            guard let inner = inner else {
                return
            }
            
            if storage[outer] == nil {
                storage[outer] = [String:[String:T]]()
            }
            
            if storage[outer]?[middle] == nil {
                storage[outer]?[middle] = [String:T]()
            }
            
            storage[outer]?[middle]?[inner] = value
        }
    }
    
    func get(_ outer:String?, _ middle:String?, _ inner:String?) -> T?
    {
        return queue.sync {
            guard let outer = outer else {
                return nil
            }
            
            guard let middle = middle else {
                return nil
            }

            guard let inner = inner else {
                return nil
            }
            
            return storage[outer]?[middle]?[inner]
        }
    }
    
    subscript(outer:String?) -> [String:[String:T]]?
    {
        get {
            return queue.sync {
                guard let outer = outer else {
                    return nil
                }
                
                return storage[outer]
            }
        }
        set {
            queue.sync {
                guard let outer = outer else {
                    return
                }
                
                storage[outer] = newValue
            }
        }
    }
    
    subscript(outer:String?,middle:String?) -> [String:T]?
    {
        get {
            return queue.sync {
                guard let outer = outer else {
                    return nil
                }
                
                guard let middle = middle else {
                    return nil
                }
                
                return storage[outer]?[middle]
            }
        }
        set {
            queue.sync {
                guard let outer = outer else {
                    return
                }
                
                guard let middle = middle else {
                    return
                }
                
                storage[outer]?[middle] = newValue
            }
        }
    }
    
    subscript(outer:String?,middle:String?,inner:String?) -> T?
    {
        get {
            return queue.sync {
                guard let outer = outer else {
                    return nil
                }
                
                guard let middle = middle else {
                    return nil
                }
                
                guard let inner = inner else {
                    return nil
                }
                
                return storage[outer]?[middle]?[inner]
            }
        }
        set {
            queue.sync {
                guard let outer = outer else {
                    return
                }
                
                guard let middle = middle else {
                    return
                }
                
                guard let inner = inner else {
                    return
                }
                
                if storage[outer] == nil {
                    storage[outer] = [String:[String:T]]()
                }
                
                if storage[outer]?[middle] == nil {
                    storage[outer]?[middle] = [String:T]()
                }
                
                storage[outer]?[middle]?[inner] = newValue
            }
        }
    }
}

class Fetch<T>
{
    private lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "Fetch" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        operationQueue.cancelAllOperations()
    }
    
    init(name:String? = nil,fetch:(()->(T?))? = nil)
    {
        self.name = name
        self.fetch = fetch
    }
    
    var fetch : (()->(T?))?
    
    var store : ((T?)->())?
    var retrieve : (()->(T?))?
    
    var name : String?
    
    var didSet : ((T?)->())?
    var cache : T?
    {
        didSet {
            didSet?(cache)
        }
    }
    
    func clear()
    {
        queue.sync {
            cache = nil
        }
    }
    
    lazy private var queue : DispatchQueue = {
        return DispatchQueue(label: name ?? UUID().uuidString)
    }()
    
    func load()
    {
        queue.sync {
            guard cache == nil else {
                return
            }
            
            cache = retrieve?()
            
            guard cache == nil else {
                return
            }
            
            self.cache = self.fetch?()
            
            store?(self.cache)
        }
    }
    
    func fill()
    {
        operationQueue.addOperation {
            self.load()
        }
    }
    
    var result:T?
    {
        get {
            load()
            
            return cache
        }
    }
}

protocol Size
{
    var _fileSize : Int? { get set }
    var fileSize : Int? { get set }
}

// It would nice if properties that were FetchCodable were kept track of so the class would know
// how to get the size of all the cache files or to delete them, or to clear all the cache properties to reduce memory usage
// without having to keep track of each individual proeprty, e.g. a FetchCodable index whenever a class (or struct)
// uses one(?) or more FetchCodable properties.

class FetchCodable<T:Codable> : Fetch<T>, Size
{
    var fileSystemURL : URL?
    {
        get {
            return name?.fileSystemURL
        }
    }
    
//    var fileSize = Shadowed<Int>()

    // Awful performance as a class and couldn't get a struct to work
//    lazy var fileSize:Shadowed<Int> = { [weak self] in
//        let shadowed = Shadowed<Int>(get:{
//            return self.fileSystemURL?.fileSize
//        })
//
//        return shadowed
//    }()

    // Guess we use the var _foo/var foo shadow pattern
    internal var _fileSize : Int?
    var fileSize : Int?
    {
        get {
            guard let fileSize = _fileSize else {
                _fileSize = fileSystemURL?.fileSize
                return _fileSize
            }

            return fileSize
        }
        set {
            _fileSize = newValue
        }
    }
    
//    var fileSize : Int?
//    {
//        get {
//            return fileSystemURL?.fileSize
//        }
//    }
    
    func delete(block:Bool)
    {
        clear()
        fileSize = nil
//        fileSize.value = nil
        fileSystemURL?.delete(block:block)
    }
    
    // name MUST be unique to ever INSTANCE, not just the class!
    override init(name: String?, fetch: (() -> (T?))? = nil)
    {
        super.init(name: name, fetch: fetch)

        store = { [weak self] (t:T?) in
            guard Globals.shared.cacheDownloads else {
                return
            }

            guard let t = t else {
                return
            }

            guard let fileSystemURL = self?.fileSystemURL else {
                return
            }

            let dict = ["value":t]
            
            do {
                let data = try JSONEncoder().encode(dict)
//                print("able to encode T: \(fileSystemURL.lastPathComponent)")

                do {
                    try data.write(to: fileSystemURL)
//                    print("able to write T to the file system: \(fileSystemURL.lastPathComponent)")
                    self?.fileSize = fileSystemURL.fileSize
                } catch let error {
//                    print("unable to write T to the file system: \(fileSystemURL.lastPathComponent)")
                    NSLog("unable to write T to the file system: \(fileSystemURL.lastPathComponent)", error.localizedDescription)
                }
            } catch let error {
//                print("unable to encode T: \(fileSystemURL.lastPathComponent)")
                NSLog("unable to encode T: \(fileSystemURL.lastPathComponent)", error.localizedDescription)
            }
        }

        retrieve = { [weak self] in
            guard Globals.shared.cacheDownloads else {
                return nil
            }

            guard let fileSystemURL = self?.fileSystemURL else {
                return nil
            }

            do {
                let data = try Data(contentsOf: fileSystemURL)
//                print("able to read T from storage: \(fileSystemURL.lastPathComponent)")

                do {
                    let dict = try JSONDecoder().decode([String:T].self, from: data)
//                    print("able to decode T from storage: \(fileSystemURL.lastPathComponent)")
                    return dict["value"]
                } catch let error {
//                    print("unable to decode T from storage: \(fileSystemURL.lastPathComponent)")
                    NSLog("unable to decode T from storage: \(fileSystemURL.lastPathComponent)", error.localizedDescription)
                }
            } catch let error {
//                print("unable to read T from storage: \(fileSystemURL.lastPathComponent)")
                NSLog("unable to read T from storage: \(fileSystemURL.lastPathComponent)", error.localizedDescription)
            }

            return nil
        }
    }
}
