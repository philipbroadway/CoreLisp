//
//  LispValue.swift
//  CoreLisp
//
//  Created by philipbroadway on 6/17/25.
//
import Foundation

public enum LispNumber: Equatable {
    case integer(Int)
    case float(Double)
    case ratio(numerator: Int, denominator: Int)
    
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

extension LispValue: Equatable {
    public static func == (lhs: LispValue, rhs: LispValue) -> Bool {
        switch (lhs, rhs) {
        case let (.symbol(a), .symbol(b)):
            return a == b
        case let (.number(a), .number(b)):
            return a == b
        case let (.string(a), .string(b)):
            return a == b
        case let (.character(a), .character(b)):
            return a == b
        case let (.cons(car1, cdr1), .cons(car2, cdr2)):
            return car1 == car2 && cdr1 == cdr2
        case (.function(_), .function(_)):
            // No meaningful equality for functions
            return false
        case (.nil, .nil):
            return true
        default:
            return false
        }
    }
}

extension LispValue {
    var isNil: Bool {
        if case .nil = self { return true }
        return false
    }

    @MainActor public static let t = LispValue.symbol(LispSymbol(name: "T", package: kCommonLisp))
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
            case .cons(_, _):
                return consToString(self)
            case .function:
                return "#<function>"
            case .nil:
                return "()"
        }
    }
}

//public func consToString(_ cons: LispValue) -> String {
//    var parts: [String] = []
//    var current = cons
//    while case let .cons(car, cdr) = current {
//        parts.append(car.description)
//        current = cdr
//    }
//    if case .nil = current {
//        return "(" + parts.joined(separator: " ") + ")"
//    } else {
//        return "(" + parts.joined(separator: " ") + " . " + current.description + ")"
//    }
//}

func consToString(_ cons: LispValue) -> String {
    // detect one‐element lists for quote/quasiquote/unquote
    if case let .cons(car, cdr) = cons,
       case .symbol(let sym) = car,
       case let .cons(inner, tail) = cdr,
       case .nil = tail {
        switch sym.name.uppercased() {
        case "QUOTE":
            return "'\(inner.description)"
        case "QUASIQUOTE":
            return "`\(inner.description)"
        case "UNQUOTE":
            return ",\(inner.description)"
        case "UNQUOTE-SPLICING":
            return ",@\(inner.description)"
        default:
            break
        }
    }

    // fallback to a plain list printer
    var parts: [String] = []
    var current = cons
    while case let .cons(carElement, rest) = current {
        parts.append(carElement.description)
        current = rest
    }
    if case .nil = current {
        return "(" + parts.joined(separator: " ") + ")"
    } else {
        return "(" + parts.joined(separator: " ") + " . " + current.description + ")"
    }
}
