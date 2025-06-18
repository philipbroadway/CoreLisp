//
//  LispValue.swift
//  CoreLisp
//
//  Created by philipbroadway on 6/17/25.
//
import Foundation

public enum LispNumber {
    case integer(Int)
    case float(Double)
    case ratio(numerator: Int, denominator: Int)
}

extension LispNumber {
    func asNumeric() -> LispNumeric {
        switch self {
            case .integer(let i): return .integer(i)
            case .float(let f): return .float(f)
            case .ratio(let n, let d): return .ratio(n, d)
        }
    }
}

public struct LispSymbol: Hashable {
    let name: String
    let package: String // default: "COMMON-LISP", "USER", etc.
    var isKeyword: Bool {
        package == "KEYWORD"
    }
}

indirect public enum LispValue {
    case symbol(LispSymbol)
    case number(LispNumber)
    case string(String)
    case character(Character)
    case cons(car: LispValue, cdr: LispValue)
    case function(([LispValue]) throws -> LispValue)
    case `nil`
}

extension LispValue: CustomStringConvertible {
    public var description: String {
        switch self {
            case .symbol(let sym):
                return sym.isKeyword ? ":\(sym.name)" : sym.name
            case .number(let num):
                switch num {
                    case .integer(let i): return String(i)
                    case .float(let f): return String(f)
                    case .ratio(let n, let d): return "\(n)/\(d)"
                }
            case .string(let s):
                return "\"\(s)\""
            case .character(let c):
                return "#\\\(c)"
            case .cons(let car, let cdr):
                return consToString(self)
            case .function:
                return "#<function>"
            case .nil:
                return "NIL"
        }
    }
}

public func consToString(_ cons: LispValue) -> String {
    var parts: [String] = []
    var current = cons
    while case let .cons(car, cdr) = current {
        parts.append(car.description)
        current = cdr
    }
    if case .nil = current {
        return "(" + parts.joined(separator: " ") + ")"
    } else {
        return "(" + parts.joined(separator: " ") + " . " + current.description + ")"
    }
}
