//
//  CoreDataEntityRegistrarError.swift
//  persistence
//
//  Created by Robert Nash on 01/01/2025.
//

import Foundation

public enum CoreDataEntityRegistrarError: LocalizedError {
    
    case notFound
    case alreadyExists
    case unexpectedError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "The record with the given identifier could not be found."
        case .alreadyExists:
            return "A record with the given identifier already exists."
        case .unexpectedError(let error):
            return "An unknown error occurred: \(error)"
        }
    }
}
