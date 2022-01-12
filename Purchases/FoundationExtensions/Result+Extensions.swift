//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Result+Extensions.swift
//
//  Created by Nacho Soto on 12/1/21.

extension Result {

    // swiftlint:disable:next identifier_name
    var rc_value: Success? {
        switch self {
        case let .success(value): return value
        case .failure: return nil
        }
    }

    // swiftlint:disable:next identifier_name
    var rc_error: Failure? {
        switch self {
        case .success: return nil
        case let .failure(error): return error
        }
    }
}
