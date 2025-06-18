//
//  LispEnvironment.swift
//  CoreLisp
//
//  Created by philipbroadway on 6/17/25.
//

import Foundation

final public class LispEnvironment {
    private var values: [LispSymbol: LispValue] = [:]
    private let parent: LispEnvironment?

    init(parent: LispEnvironment? = nil) {
        self.parent = parent
    }

    func define(_ symbol: LispSymbol, value: LispValue) {
        values[symbol] = value
    }

    func set(_ symbol: LispSymbol, value: LispValue) throws {
        if values.keys.contains(symbol) {
            values[symbol] = value
        } else if let parent {
            try parent.set(symbol, value: value)
        } else {
            throw EvalError.unboundSymbol(symbol.name)
        }
    }

    func get(_ symbol: LispSymbol) throws -> LispValue {
        if let val = values[symbol] {
            return val
        } else if let parent {
            return try parent.get(symbol)
        } else {
            throw EvalError.unboundSymbol(symbol.name)
        }
    }
}

public func car1(_ list: LispValue) throws -> LispValue {
    guard case let .cons(car, _) = list else {
        throw EvalError.invalidForm("Expected at least one element")
    }
    return car
}

public func car2(_ list: LispValue) throws -> LispValue? {
    guard case let .cons(_, cdr) = list else { return nil }
    guard case let .cons(car2, _) = cdr else { return nil }
    return car2
}

public func car3(_ list: LispValue) throws -> LispValue? {
    guard case let .cons(_, cdr) = list else { return nil }
    guard case let .cons(_, cdr2) = cdr else { return nil }
    guard case let .cons(car3, _) = cdr2 else { return nil }
    return car3
}

public func carN(_ list: LispValue, n: Int) throws -> LispValue {
    var current = list
    var index = 0
    while index < n {
        guard case let .cons(_, cdr) = current else {
            throw EvalError.invalidForm("Expected at least \(n + 1) elements")
        }
        current = cdr
        index += 1
    }
    guard case let .cons(car, _) = current else {
        throw EvalError.invalidForm("Expected at least \(n + 1) elements")
    }
    return car
}

public func listToArray(_ list: LispValue) throws -> [LispValue] {
    var result: [LispValue] = []
    var current = list
    while case let .cons(car, cdr) = current {
        result.append(car)
        current = cdr
    }
    if case .nil = current {
        return result
    } else {
        throw EvalError.invalidForm("Improper list")
    }
}

public func eval(_ value: LispValue, in env: LispEnvironment) throws -> LispValue {
    switch value {
        case .number, .string, .character, .function, .nil:
            return value

        case .symbol(let sym):
            return try env.get(sym)

        case .cons(let car, let cdr):
            // Handle special forms before evaluating car
            if case let .symbol(sym) = car {
                switch sym.name.uppercased() {
                    case "QUOTE":
                        return try car1(cdr)
                    case "SETQ":
                        let nameSym = try car1(cdr)
                        guard case let .symbol(s) = nameSym else {
                            throw EvalError.invalidArgument("SETQ expects symbol")
                        }
                        let val = try car2(cdr).map { try eval($0, in: env) } ?? .nil
                        env.define(s, value: val)
                        return val
                    case "IF":
                        let testExpr = try car1(cdr)
                            let thenExpr = try car2(cdr)
                            let elseExpr = try car3(cdr) // can be nil
                            let testValue = try eval(testExpr, in: env)
                            if !testValue.isNil {
                                return try thenExpr.map { try eval($0, in: env) } ?? .nil
                            } else {
                                return try elseExpr.map { try eval($0, in: env) } ?? .nil
                            }
                    default:
                        break
                }
            }
            let head = try eval(car, in: env)
            switch head {
                case .function(let fn):
                    let args = try listToArray(cdr).map { try eval($0, in: env) }
                    return try fn(args)
                default:
                    throw EvalError.notAFunction
            }

        default:
            throw EvalError.invalidForm("Unexpected form")
    }
}

public enum EvalError: Error, CustomStringConvertible {
    case notAFunction
    case unboundSymbol(String)
    case invalidForm(String)
    case invalidArgument(String)

    public var description: String {
        switch self {
            case .notAFunction: return "Not a function"
            case .unboundSymbol(let s): return "Unbound symbol: \(s)"
            case .invalidForm(let s): return "Invalid form: \(s)"
            case .invalidArgument(let s): return "Invalid argument: \(s)"
        }
    }
}
