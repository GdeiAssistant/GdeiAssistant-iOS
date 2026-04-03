import Foundation

enum TestLifetimeRetainer {
    private static var retainedObjects: [AnyObject] = []

    static func retain(_ object: AnyObject) {
        retainedObjects.append(object)
    }
}
