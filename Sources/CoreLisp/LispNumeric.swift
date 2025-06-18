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
        case let (.ratio(n1, d1), .ratio(n2, d2)):
            return makeRatio(n1 * d2 + n2 * d1, d1 * d2)
        case let (.integer(x), .ratio(n, d)),
             let (.ratio(n, d), .integer(x)):
            return makeRatio(n + x * d, d)
        default:
            return .float(a.toDouble() + b.toDouble())
    }
}

func numericSub(_ a: LispNumeric, _ b: LispNumeric) -> LispNumeric {
    switch (a, b) {

        case let (.integer(x), .integer(y)):
            return .integer(x - y)

        case let (.ratio(xn, xd), .ratio(yn, yd)):
            // x₁/y₁ − x₂/y₂ = (x₁·y₂ − x₂·y₁) / (y₁·y₂)
            return makeRatio(xn * yd - yn * xd, xd * yd)

        case let (.integer(x), .ratio(yn, yd)):
            // x − (yₙ / y_d) = (x·y_d − yₙ) / y_d
            return makeRatio(x * yd - yn, yd)

        case let (.ratio(xn, xd), .integer(y)):
            // (xₙ / x_d) − y = (xₙ − y·x_d) / x_d
            return makeRatio(xn - y * xd, xd)

        default:
            return .float(a.toDouble() - b.toDouble())
    }
}

func numericMul(_ a: LispNumeric, _ b: LispNumeric) -> LispNumeric {
    switch (a, b) {

        case let (.integer(x), .integer(y)):
            return .integer(x * y)

        case let (.ratio(xn, xd), .ratio(yn, yd)):
            // (xₙ / x_d) · (yₙ / y_d) = (xₙ·yₙ) / (x_d·y_d)
            return makeRatio(xn * yn, xd * yd)

        case let (.integer(x), .ratio(n, d)),
             let (.ratio(n, d), .integer(x)):
            return makeRatio(x * n, d)

        default:
            return .float(a.toDouble() * b.toDouble())
    }
}

func numericDiv(_ a: LispNumeric, _ b: LispNumeric) -> LispNumeric {
    switch (a, b) {
        case let (_, .integer(0)), let (_, .ratio(0, _)):
            fatalError("Division by zero")

        case let (.integer(x), .integer(y)):
            return makeRatio(x, y)

        case let (.ratio(n1, d1), .ratio(n2, d2)):
            return makeRatio(n1 * d2, d1 * n2)

        case let (.integer(x), .ratio(n, d)):
            return makeRatio(x * d, n)

        case let (.ratio(n, d), .integer(x)):
            return makeRatio(n, d * x)

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
    var x = abs(a), y = abs(b)
    while y != 0 { (x, y) = (y, x % y) }
    return x
}

func makeRatio(_ n: Int, _ d: Int) -> LispNumeric {
    precondition(d != 0, "Division by zero")

    let (num, den) = d < 0 ? (-n, -d) : (n, d)
    let g          = greatestCommonDivisor(num, den)

    let reducedNum = num / g
    let reducedDen = den / g
    return reducedDen == 1
        ? .integer(reducedNum)
        : .ratio(reducedNum, reducedDen)
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
