//
//  Error.swift
//  MozoSDK
//
//  Created by Hoang Nguyen on 9/5/18.
//

import Foundation
public enum ConnectionError: Error {
    case network(error: Error)
    case noInternetConnection
    case requestTimedOut
    case requestNotFound
    case unknowError
    case authenticationRequired
    case internalServerError
    case badRequest
}

extension ConnectionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .network:
            return "Network error"
        case .noInternetConnection:
            return "No Internet Connection"
        case .requestTimedOut:
            return "The request timed out"
        case .requestNotFound:
            return "404 Not Found"
        case .unknowError:
            return "Unknow error"
        case .authenticationRequired:
            return "Authentication Required"
        case .internalServerError:
            return "Internal Server error"
        case .badRequest:
            return "Bad request"
        }
    }
}

extension ConnectionError : Equatable {
    public static func == (leftSide: ConnectionError, rightSide: ConnectionError) -> Bool {
        return leftSide.errorDescription == rightSide.errorDescription
    }
}

public enum SystemError: Error {
    case incorrectURL
    case incorrectCodeExchangeRequest
    case noAuthen
}

extension SystemError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .incorrectURL:
            return "Incorrect URL"
        case .incorrectCodeExchangeRequest:
            return "Incorrect Code Exchange Request"
        case .noAuthen:
            return "User is an anonymous user."
        }
    }
}
