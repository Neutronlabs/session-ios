@testable import SignalServiceKit
import XCTest
import Curve25519Kit

class LK001UpdateFriendRequestStatusStorageTest : XCTestCase {

    private var storage: OWSPrimaryStorage { OWSPrimaryStorage.shared() }

    override func setUp() {
        super.setUp()

        ClearCurrentAppContextForTests()
        SetCurrentAppContext(TestAppContext())
        MockSSKEnvironment.activate()

        let identityManager = OWSIdentityManager.shared()
        let seed = Randomness.generateRandomBytes(16)!
        let keyPair = Curve25519.generateKeyPair(fromSeed: seed + seed)
        let databaseConnection = identityManager.value(forKey: "dbConnection") as! YapDatabaseConnection
        databaseConnection.setObject(keyPair, forKey: OWSPrimaryStorageIdentityKeyStoreIdentityKey, inCollection: OWSPrimaryStorageIdentityKeyStoreCollection)
        TSAccountManager.sharedInstance().phoneNumberAwaitingVerification = keyPair.hexEncodedPublicKey
        TSAccountManager.sharedInstance().didRegister()
    }

    func test_shouldMigrateFriendRequestStatusCorrectly() {
        typealias ThreadFriendRequestStatus = NSInteger
        let friendRequestMappings: [ThreadFriendRequestStatus:LKFriendRequestStatus] = [
            0 : .none,
            1 : .requestSending,
            2 : .requestSent,
            3 : .requestReceived,
            4 : .friends,
            5 : .requestExpired
        ]

        var hexEncodedPublicKeyMapping: [String:ThreadFriendRequestStatus] = [:]
        for (threadFriendRequestStatus, _) in friendRequestMappings {
            let hexEncodedPublicKey = Curve25519.generateKeyPair().hexEncodedPublicKey
            hexEncodedPublicKeyMapping[hexEncodedPublicKey] = threadFriendRequestStatus
        }

        storage.dbReadWriteConnection.readWrite { transaction in
            for (hexEncodedPublicKey, friendRequestStatus) in hexEncodedPublicKeyMapping {
                let thread = TSContactThread.getOrCreateThread(withContactId: hexEncodedPublicKey, transaction: transaction)
                thread.friendRequestStatus = friendRequestStatus
                thread.save(with: transaction)
            }
        }

        // Wait for the migration to complete
        let migration = self.expectation(description: "Migration")
        LK001UpdateFriendRequestStatusStorage().runUp {
            migration.fulfill()
        }
        wait(for: [ migration ], timeout: 5)

        storage.dbReadWriteConnection.readWrite { transaction in
            for (hexEncodedPublicKey, threadFriendRequestStatus) in hexEncodedPublicKeyMapping {
                let expectedFriendRequestStatus = friendRequestMappings[threadFriendRequestStatus]!
                let friendRequestStatus = self.storage.getFriendRequestStatus(for: hexEncodedPublicKey, transaction: transaction)
                XCTAssertEqual(friendRequestStatus, expectedFriendRequestStatus, "Expected friend request status \(friendRequestStatus.rawValue) to match \(expectedFriendRequestStatus.rawValue).")
            }
        }
    }

}
