//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OSVersion.swift
//
//  Created by Nacho Soto on 4/13/22.

import Foundation
import UIKit

/// The equivalent version for the current device running tests.
/// Examples:
///     - `tvOS 15.1` maps to `.iOS15`
///     - `iOS 14.3` maps to `.iOS14`
///     - `macCatalyst 15.2` maps to `.iOS15`
enum OSVersionEquivalent: Int {

    case iOS12 = 12
    case iOS13 = 13
    case iOS14 = 14
    case iOS15 = 15

}

extension OSVersionEquivalent {

    static var current: Self {
        get throws {
            #if os(macOS)
                // Not currently supported
                // Must convert e.g.: macOS 10.15 to iOS 13
                throw Error.unknownOS()
            #else
                // Note: this is either iOS/tvOS/macCatalyst
                // They all share equivalent versions

                let majorVersion = ProcessInfo().operatingSystemVersion.majorVersion

                if let equivalent = Self(rawValue: majorVersion) {
                    return equivalent
                } else {
                    throw Error.unknownOS()
                }
            #endif
        }
    }

}

private extension OSVersionEquivalent {

    private enum Error: Swift.Error {

        case unknownOS(systemName: String, version: String)

        static func unknownOS() -> Self {
            let device = UIDevice.current

            return .unknownOS(systemName: device.systemName, version: device.systemVersion)
        }

    }

}
