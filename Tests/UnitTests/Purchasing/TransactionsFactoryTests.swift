//
//  CustomerInfoHelperTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Nimble
@testable import RevenueCat
import XCTest

class TransactionsFactoryTests: TestCase {

    func testNonSubscriptionsIsCorrectlyCreated() throws {
        let nonSubscriptionTransactions = try TransactionsFactory.nonSubscriptionTransactions(
            withSubscriptionsData: Self.sampleTransactions
        )
        expect(nonSubscriptionTransactions.count) == 5

        try Self.sampleTransactions.forEach { productId, transactionsData in
            let filteredTransactions = nonSubscriptionTransactions
                .filter { $0.productIdentifier == productId }

            expect(filteredTransactions.count) == transactionsData.count

            try transactionsData.forEach { dictionary in
                let transactionId = try XCTUnwrap(dictionary["id"] as? String)
                let containsTransaction = filteredTransactions
                    .contains { $0.transactionIdentifier == transactionId }

                expect(containsTransaction) == true
            }
        }

    }

    func testNonSubscriptionsIsEmptyIfThereAreNoNonSubscriptions() {
        let list = TransactionsFactory.nonSubscriptionTransactions(withSubscriptionsData: [:])
        expect(list).to(beEmpty())
    }

    func testBuildsCorrectlyEvenIfSomeTransactionsCantBeBuilt() throws {
        let identifier = "lifetime_access"
        let transactionIdentifier = "d6c097ba74"
        let date = "2018-07-11T18:36:20Z"
        let subscriptionsData = [
            identifier: [
                [
                    "id": transactionIdentifier,
                    "is_sandbox": true,
                    "original_purchase_date": "2018-07-11T18:36:20Z",
                    "purchase_date": date,
                    "store": "app_store"
                ]
            ],
            "invalid_non_transaction": [
                [
                    "ioasgioaew": 0832
                ]
            ]
        ]

        let nonSubscriptionTransactions = try TransactionsFactory.nonSubscriptionTransactions(
            withSubscriptionsData: subscriptionsData
        )
        expect(nonSubscriptionTransactions.count) == 1

        let transaction = try XCTUnwrap(nonSubscriptionTransactions.first)

        expect(transaction.productIdentifier) == identifier
        expect(transaction.purchaseDate.timeIntervalSinceReferenceDate).to(beCloseTo(
            ISO8601DateFormatter.default.date(from: date)!.timeIntervalSinceReferenceDate
        ))
        expect(transaction.transactionIdentifier) == transactionIdentifier
        expect(transaction.quantity) == 1
    }

}

private extension TransactionsFactoryTests {

    static let sampleTransactions = [
        "100_coins": [
            [
                "id": "72c26cc69c",
                "is_sandbox": true,
                "original_purchase_date": "1990-08-30T02:40:36Z",
                "purchase_date": "2019-07-11T18:36:20Z",
                "store": "app_store"
            ], [
                "id": "6229b0bef1",
                "is_sandbox": true,
                "original_purchase_date": "2019-11-06T03:26:15Z",
                "purchase_date": "2019-11-06T03:26:15Z",
                "store": "play_store"
            ]],
        "500_coins": [
            [
                "id": "d6c007ba74",
                "is_sandbox": true,
                "original_purchase_date": "2019-07-11T18:36:20Z",
                "purchase_date": "2019-07-11T18:36:20Z",
                "store": "play_store"
            ], [
                "id": "5b9ba226bc",
                "is_sandbox": true,
                "original_purchase_date": "2019-07-26T22:10:27Z",
                "purchase_date": "2019-07-26T22:10:27Z",
                "store": "app_store"
            ]],
        "lifetime_access": [
            [
                "id": "d6c097ba74",
                "is_sandbox": true,
                "original_purchase_date": "2018-07-11T18:36:20Z",
                "purchase_date": "2018-07-11T18:36:20Z",
                "store": "app_store"
            ]]
    ]

}

private extension TransactionsFactory {

    static func nonSubscriptionTransactions(
        withSubscriptionsData data: [String: Any]
    ) throws -> [StoreTransaction] {
        let data = try JSONSerialization.data(withJSONObject: data)
        let transactions: LossyArrayDictionary<CustomerInfoResponse.Transaction> = try JSONDecoder.default.decode(
            jsonData: data
        )

        return Self.nonSubscriptionTransactions(withSubscriptionsData: transactions.wrappedValue)
    }

}
