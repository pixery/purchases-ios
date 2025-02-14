//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriberAttributesManagerIntegrationTests.swift
//
//  Created by Nacho Soto on 4/1/22.

@testable import RevenueCat

import Nimble
import XCTest

// swiftlint:disable:next type_name
class SubscriberAttributesManagerIntegrationTests: BaseBackendIntegrationTests {

    func testNothingToSync() {
        expect(Purchases.shared.syncSubscriberAttributesIfNeeded()) == 0
    }

    func testSyncOneAttribute() async throws {
        Purchases.shared.setEmail("test@revenuecat.com")

        let errors = await self.syncAttributes()
        verifyAttributesSyncedWithNoErrors(errors, 1)
    }

    func testSettingTheSameAttributeDoesNotNeedToChangeIt() async throws {
        let email = "test@revenuecat.com"
        Purchases.shared.setEmail(email)

        var errors = await self.syncAttributes()
        verifyAttributesSyncedWithNoErrors(errors, 1)

        Purchases.shared.setEmail(email)
        errors = await self.syncAttributes()
        verifyAttributesSyncedWithNoErrors(errors, 0)
    }

    func testChangingEmailSyncsIt() async throws {
        Purchases.shared.setEmail("test@revenuecat.com")

        var errors = await self.syncAttributes()
        verifyAttributesSyncedWithNoErrors(errors, 1)

        Purchases.shared.setEmail("test2@revenuecat.com")
        errors = await self.syncAttributes()
        verifyAttributesSyncedWithNoErrors(errors, 1)
    }

    func testSyncInvalidEmail() async throws {
        Purchases.shared.setEmail("invalid @ email @.com")

        let errors = await self.syncAttributes()
        expect(errors).to(haveCount(1))

        let error = try XCTUnwrap(errors.first ?? nil) as NSError
        expect(error.domain) == RCPurchasesErrorCodeDomain
        expect(error.code) == ErrorCode.invalidSubscriberAttributesError.rawValue
        expect(error.subscriberAttributesErrors) == [
            "$email": "Email address is not a valid email."
        ]
    }

    func testLogInGetsNewAttributes() async throws {
        Purchases.shared.setEmail("test@revenuecat.com")

        var errors = await self.syncAttributes()
        verifyAttributesSyncedWithNoErrors(errors, 1)

        _ = try await Purchases.shared.logIn(UUID().uuidString)

        Purchases.shared.setEmail("test@revenuecat.com")

        errors = await self.syncAttributes()
        verifyAttributesSyncedWithNoErrors(errors, 1)
    }

    func testPushTokenWithInvalidTokenDoesNotFail() async throws {
        Purchases.shared.setPushToken("invalid token".asData)

        let errors = await self.syncAttributes()
        verifyAttributesSyncedWithNoErrors(errors, 1)
    }

    func testSetCustomAttributes() async throws {
        Purchases.shared.setAttributes([
            "custom_key": "random value",
            "locale": Locale.current.identifier
        ])

        let errors = await self.syncAttributes()
        verifyAttributesSyncedWithNoErrors(errors, 1) // 1 user with 2 attributes
    }

    func testSetMultipleAttributes() async throws {
        Purchases.shared.setDisplayName("Tom Hanks")
        Purchases.shared.setPhoneNumber("4157689215")

        let errors = await self.syncAttributes()
        verifyAttributesSyncedWithNoErrors(errors, 1) // 1 user with 2 attributes
    }

    func testSetAttributesForMultipleUsers() async throws {
        _ = try await Purchases.shared.logIn(UUID().uuidString)
        Purchases.shared.setDisplayName("User 1")

        _ = try await Purchases.shared.logIn(UUID().uuidString)
        Purchases.shared.setDisplayName("User 2")

        let errors = await self.syncAttributes()
        verifyAttributesSyncedWithNoErrors(errors, 2)
    }

}

private extension SubscriberAttributesManagerIntegrationTests {

    func syncAttributes() async -> [Error?] {
        return await withCheckedContinuation { continuation in
            var errors: [Error?] = []

            Purchases.shared.syncSubscriberAttributesIfNeeded(
                syncedAttribute: { errors.append($0) },
                completion: { continuation.resume(returning: errors) }
            )
        }
    }

    private func verifyAttributesSyncedWithNoErrors(
        _ errors: [Error?],
        _ expectedCount: Int,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file, line: line,
            errors
        ).to(
            haveCount(expectedCount),
            description: "Incorrect number of attributes"
        )
        expect(
            file: file, line: line,
            errors
        ).toNot(
            containElementSatisfying { $0 != nil },
            description: "Encountered errors: \(errors)"
        )
    }

}
