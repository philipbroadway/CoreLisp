//
//  LispNumeric.swift
//  CoreLisp
//
//  Created by philipbroadway on 6/17/25.
//

public enum LispNumeric {
    case integer(Int)
    case ratio(Int, Int)
    case float(Double)

    init(_ value: LispValue) throws {
        guard case let .number(n) = value else {
            throw EvalError.invalidArgument("Expected number")
        }
        switch n {
            case .integer(let i): self = .integer(i)
            case .float(let f): self = .float(f)
            case .ratio(let n, let d): self = .ratio(n, d)
        }
    }

    func toDouble() -> Double {
        switch self {
            case .integer(let i): return Double(i)
            case .float(let f): return f
            case .ratio(let n, let d): return Double(n) / Double(d)
        }
    }

    func toLispValue() -> LispValue {
        switch self {
            case .integer(let i): return .number(.integer(i))
            case .float(let f): return .number(.float(f))
            case .ratio(let n, let d): return .number(.ratio(numerator: n, denominator: d))
        }
    }
}

func numericAdd(_ a: LispNumeric, _ b: LispNumeric) -> LispNumeric {
    switch (a, b) {
        case let (.integer(x), .integer(y)):
            return .integer(x + y)
        case let (.ratio(xn, xd), .ratio(yn, yd)):
            return .ratio(xn * yd + yn * xd, xd * yd)
        default:
            return .float(a.toDouble() + b.toDouble())
    }
}

public func numericSub(_ a: LispNumeric, _ b: LispNumeric) -> LispNumeric {
    switch (a, b) {
        case let (.integer(x), .integer(y)):
            return .integer(x - y)
        case let (.float(x), .integer(y)):
            return .float(x - Double(y))
        case let (.integer(x), .float(y)):
            return .float(Double(x) - y)
        case let (.float(x), .float(y)):
            return .float(x - y)
        case let (.ratio(xn, xd), .integer(y)):
            let n = xn - y * xd
            return simplifyRatio(numerator: n, denominator: xd).asNumeric()
        case let (.integer(x), .ratio(yn, yd)):
            let n = x * yd - yn
            return simplifyRatio(numerator: n, denominator: yd).asNumeric()
        case let (.ratio(xn, xd), .ratio(yn, yd)):
            let n = xn * yd - yn * xd
            let d = xd * yd
            return simplifyRatio(numerator: n, denominator: d).asNumeric()
        case let (.ratio(_, _), .float(y)):
            return .float(a.toDouble() - y)
        case let (.float(x), .ratio(_, _)):
            return .float(x - b.toDouble())
    }
}
func numericMul(_ a: LispNumeric, _ b: LispNumeric) -> LispNumeric {
    switch (a, b) {
        case let (.integer(x), .integer(y)):
            return .integer(x * y)
        case let (.ratio(xn, xd), .ratio(yn, yd)):
            return .ratio(xn * yn, xd * yd)
        default:
            return .float(a.toDouble() * b.toDouble())
    }
}

func numericDiv(_ a: LispNumeric, _ b: LispNumeric) -> LispNumeric {
    switch (a, b) {
        case let (.integer(x), .integer(y)):
            return .ratio(x, y)
        case let (.ratio(xn, xd), .ratio(yn, yd)):
            return .ratio(xn * yd, xd * yn)
        default:
            return .float(a.toDouble() / b.toDouble())
    }
}

public func simplifyRatio(numerator: Int, denominator: Int) -> LispNumber {
    if denominator == 0 {
        fatalError("Division by zero")
    }
    if numerator == 0 {
        return .integer(0)
    }

    let gcd = greatestCommonDivisor(numerator, denominator)
    if gcd == 0 {
        return .integer(0)
    }

    let n = numerator / gcd
    let d = denominator / gcd

    return d == 1 ? .integer(n) : .ratio(numerator: n, denominator: d)
}

public func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
    var a = abs(a)
    var b = abs(b)
    while b != 0 {
        let temp = b
        b = a % b
        a = temp
    }
    return a
}

public extension LispNumeric {
    /// Convert ratios with denominator 1 to integers
    func asCanonical() -> LispNumeric {
        if case let .ratio(n, d) = self, d == 1 {
            return .integer(n)
        }
        return self
    }
}
