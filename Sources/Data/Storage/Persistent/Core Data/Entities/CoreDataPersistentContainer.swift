#if canImport(Foundation) && canImport(CoreData) && canImport(Combine)

import Foundation
import CoreData
import Combine

extension String {
    fileprivate static let contextProvider = "ContextProvider"
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public protocol CoreDataPersistentContainer: Sendable {
    
    func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, Error?) -> Void)
    func contextForWriting() -> AnyPublisher<NSManagedObjectContext, Error>
    func contextForReading() -> AnyPublisher<NSManagedObjectContext, Error>
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public class PersistentContainer: NSPersistentContainer, CoreDataPersistentContainer, @unchecked Sendable {
    
    enum PersistentContainerError: Error {
        case writeUnavailable
        case readUnavailable
        case saveFailure(error: Error?)
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var writeContext: NSManagedObjectContext?
    private var readContexts = [NSManagedContextScope: NSManagedObjectContext]()
    private var lastUsedContexts = [NSManagedContextScope: Date]()
    private let readContextsQueue = DispatchQueue(label: "PersistentContainer.\(UUID().uuidString).ReadContexts")
    private let readContextTimeOut: TimeInterval = 5 * 60
    
    public override func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, Error?) -> Void) {
        super.loadPersistentStores { [weak self] in
            self?.writeContext = self?.newBackgroundContext()
            self?.handleSave()
            self?.startDestroyTimer()
            self?.viewContext.performAndWait { [weak self] in
                self?.viewContext.userInfo[String.contextProvider] = { [weak self] in self as NSManagedContextProvider?}
            }
            block($0, $1)
        }
    }
    
    public override func newBackgroundContext() -> NSManagedObjectContext {
        let context = super.newBackgroundContext()
        context.performAndWait {
            context.userInfo[String.contextProvider] = { [weak self] in self as NSManagedContextProvider? }
        }
        return context
    }
    
    private func startDestroyTimer() {
        Timer.publish(every: readContextTimeOut, on: .main, in: .common)
                .autoconnect()
                .receive(on: readContextsQueue)
                .map { [weak self] _ -> [NSManagedContextScope: Date] in
                    // If self is nil, return an empty dictionary.
                    return self?.lastUsedContexts ?? [:]
                }
                .map { [weak self] in
                    // If self is nil, return an empty filter result.
                    guard let self = self else { return [NSManagedContextScope: Date]() }
                    return $0.filter { Date().timeIntervalSince($0.value) >= self.readContextTimeOut }
                }
                .map { $0.keys }
                .sink { [weak self] scopes in
                    guard let self = self else { return }
                    scopes.forEach {
                        self.readContexts[$0] = nil
                        self.lastUsedContexts[$0] = nil
                    }
                }
                .store(in: &cancellables)
    }
    
    public func contextForWriting() -> AnyPublisher<NSManagedObjectContext, Error> {
        Future { [weak self] promise in
            guard let writeContext = self?.writeContext else {
                promise(.failure(PersistentContainerError.writeUnavailable))
                return
            }
            DispatchQueue.main.async {
                writeContext.perform {
                    promise(.success(writeContext))
                }
            }
           
        }.receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    private func backgroundContext() -> NSManagedObjectContext {
        let context = newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    public func contextForReading() -> AnyPublisher<NSManagedObjectContext, Error> {
        let context = backgroundContext()
        return Future { promise in
            DispatchQueue.main.async {
                context.perform {
                    promise(.success(context))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private func handleSave() {
        guard let writeContext = writeContext else { return }
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave, object: writeContext)
            .sink { [weak self] note in
                self?.viewContext.perform {
                    self?.viewContext.mergeChanges(fromContextDidSave: note)
                }
            }
            .store(in: &cancellables)
    }
}

extension PersistentContainer: NSManagedContextProvider {
    
    func context(for scope: NSManagedContextScope) -> NSManagedObjectContext? {
        switch scope {
        case .main:
            return viewContext
        case .write:
            return writeContext
        default:
            return readContextsQueue.sync {
                if readContexts[scope] == nil {
                    readContexts[scope] = backgroundContext()
                }
                lastUsedContexts[scope] = Date()
                return readContexts[scope]!
            }
        }
    }
}

extension NSManagedObjectContext {
    func context(for scope: NSManagedContextScope) -> NSManagedObjectContext? {
        (userInfo[String.contextProvider] as? (() -> NSManagedContextProvider?))?()?.context(for: scope)
    }
}

#endif
