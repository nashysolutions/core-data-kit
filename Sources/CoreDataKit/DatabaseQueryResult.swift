//
//  DatabaseQueryResult.swift
//  core-data-kit
//
//  Created by Robert Nash on 01/02/2025.
//

import Foundation

/// Represents the outcome of a database loading operation.
///
/// This enum models the result of fetching or interacting with a database,
/// capturing scenarios where the operation **succeeds, fails, or executes without a definitive result**.
///
/// - Generic Parameter `T`: The type of entity being loaded from the database.
public enum DatabaseQueryResult<T> {
    
    /// The operation completed successfully and returned the expected result.
    ///
    /// - Parameter value: The successfully loaded entity of type `T`.
    case success(T)

    /// The operation failed due to an error.
    ///
    /// - Parameter error: The encountered error.
    case failure(Error)
    
    /// The operation was performed but did not yield a meaningful result.
    ///
    /// This case is used when a database query executes successfully but finds **no relevant data**.
    /// Instead of treating it as an error, we record the time of execution to track when the last query occurred.
    ///
    /// - Parameter timestamp: The date and time when the operation was performed.
    case performed(Date)
}
