import Foundation
import CoreData

/// Core Data persistence manager
class CoreDataManager {
    static let shared = CoreDataManager()

    private init() {
        print("✅ Core Data initialized")
    }

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WorkoutModel")

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
            print("✅ Core Data store loaded at: \(description.url?.path ?? "unknown")")
        }

        // Enable automatic merging
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Background Context

    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }

    // MARK: - Save Context

    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("❌ Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func saveBackgroundContext(_ context: NSManagedObjectContext) async throws {
        try await context.perform {
            if context.hasChanges {
                try context.save()
            }
        }
    }

    // MARK: - Fetch Operations

    func fetch<T: NSManagedObject>(
        entityType: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) -> [T] {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: entityType))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors

        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("❌ Fetch error: \(error)")
            return []
        }
    }

    // MARK: - Delete Operations

    func delete<T: NSManagedObject>(_ object: T) throws {
        viewContext.delete(object)
        try viewContext.save()
    }

    func deleteAll<T: NSManagedObject>(entityType: T.Type) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entityType))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        try viewContext.execute(deleteRequest)
        try viewContext.save()
    }
}
