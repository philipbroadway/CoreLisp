//
//  CoreLisp.swift
//  CoreLisp
//
//  Created by philipbroadway on 6/17/25.
//

public let kCommonLisp = "COMMON-LISP"

public func lispEqual(_ a: LispValue, _ b: LispValue) -> Bool {
    switch (a, b) {
        case let (.cons(car1, cdr1), .cons(car2, cdr2)):
            return lispEqual(car1, car2) && lispEqual(cdr1, cdr2)
        default:
            return a == b
    }
}

public func lispEql(_ a: LispValue, _ b: LispValue) -> Bool {
    switch (a, b) {
        case let (.number(an), .number(bn)):
            return an == bn
        case let (.character(ac), .character(bc)):
            return ac == bc
        case let (.symbol(asym), .symbol(bsym)):
            return asym == bsym
        case (.nil, .nil):
            return true
        default:
            return false
    }
}

@MainActor
let global: LispEnvironment = {
    
    let env = LispEnvironment()
    
    env.define(LispSymbol(name: "T", package: kCommonLisp), value: .t)
    
    env.define(
        LispSymbol(name: "+", package: kCommonLisp),
        value: .function { args in

            if args.isEmpty {
                return .number(.integer(0))
            }

            var acc = try LispNumeric(args[0])
            for value in args.dropFirst() {
                acc = numericAdd(acc, try LispNumeric(value))
            }

            return acc.toLispValue()
        }
    )
    
    env.define(
        LispSymbol(name: "-", package: kCommonLisp),
        value: .function { args in

            if args.isEmpty {
                return .number(.integer(0))
            }

            if args.count == 1 {
                let neg = numericSub(.integer(0), try LispNumeric(args[0]))
                return neg.toLispValue()
            }

            var acc = try LispNumeric(args[0])
            for v in args.dropFirst() {
                acc = numericSub(acc, try LispNumeric(v))
            }
            return acc.toLispValue()
        }
    )
    
    env.define(
        LispSymbol(name: "*", package: kCommonLisp),
        value: .function { args in
            
            if args.isEmpty {
                return .number(.integer(1))
            }

            var acc = try LispNumeric(args[0])
            for v in args.dropFirst() {
                acc = numericMul(acc, try LispNumeric(v))
            }
            return acc.toLispValue()
        }
    )
    
    env.define(
        LispSymbol(name: "/", package: kCommonLisp),
        value: .function { args in
            // (/)  ⇒ 1
            if args.isEmpty {
                return .number(.integer(1))
            }

            if args.count == 1 {
                let r = numericDiv(.integer(1), try LispNumeric(args[0]))
                return r.asCanonical().toLispValue()
            }

            var acc = try LispNumeric(args[0])
            for v in args.dropFirst() {
                acc = numericDiv(acc, try LispNumeric(v))
            }
            return acc.asCanonical().toLispValue()
        }
    )
    
    env.define(LispSymbol(name: "MOD", package: kCommonLisp), value: .function({ args in
        guard args.count == 2 else {
            throw LispError.arity(expected: 2, got: args.count)
        }
        let dividend = try LispNumeric(args[0])
        let divisor = try LispNumeric(args[1])
        
        switch (dividend, divisor) {
            case let (.integer(a), .integer(b)):
                guard b != 0 else {
                    throw LispError.eval("MOD: division by zero")
                }
                return .number(.integer(a % b))
            case let (.float(a), .float(b)):
                guard b != 0 else {
                    throw LispError.eval("MOD: division by zero")
                }
                return .number(.float(a.truncatingRemainder(dividingBy: b)))
            case let (.integer(a), .float(b)):
                guard b != 0 else {
                    throw LispError.eval("MOD: division by zero")
                }
                return .number(.float(Double(a).truncatingRemainder(dividingBy: b)))
            case let (.float(a), .integer(b)):
                guard b != 0 else {
                    throw LispError.eval("MOD: division by zero")
                }
                return .number(.float(a.truncatingRemainder(dividingBy: Double(b))))
            default:
                throw LispError.eval("MOD: unsupported numeric types")
        }
    }))
    
    env.define(LispSymbol(name: "REM", package: kCommonLisp), value: .function({ args in
        guard args.count == 2 else {
            throw LispError.arity(expected: 2, got: args.count)
        }
        let dividend = try LispNumeric(args[0])
        let divisor = try LispNumeric(args[1])
        
        switch (dividend, divisor) {
        case let (.integer(a), .integer(b)):
            guard b != 0 else {
                throw LispError.eval("REM: division by zero")
            }
            let rem = a % b
            return .number(.integer(rem))
        case let (.float(a), .float(b)):
            guard b != 0 else {
                throw LispError.eval("REM: division by zero")
            }
            let rem = a.truncatingRemainder(dividingBy: b)
            return .number(.float(rem))
        case let (.integer(a), .float(b)):
            guard b != 0 else {
                throw LispError.eval("REM: division by zero")
            }
            let rem = Double(a).truncatingRemainder(dividingBy: b)
            return .number(.float(rem))
        case let (.float(a), .integer(b)):
            guard b != 0 else {
                throw LispError.eval("REM: division by zero")
            }
            let rem = a.truncatingRemainder(dividingBy: Double(b))
            return .number(.float(rem))
        default:
            throw LispError.eval("REM: unsupported numeric types")
        }
    }))
    
    env.define(LispSymbol(name: "ABS", package: kCommonLisp), value: .function({ args in
        guard args.count == 1 else {
            throw LispError.arity(expected: 1, got: args.count)
        }
        let number = try LispNumeric(args[0])
        switch number {
            case .integer(let value):
                return .number(.integer(abs(value)))
            case .float(let value):
                return .number(.float(abs(value)))
            default:
                throw LispError.eval("ABS expects a numeric argument, got: \(args[0])")
        }
    }))
    
    env.define(LispSymbol(name: "MIN", package: kCommonLisp), value: .function({ args in
        guard !args.isEmpty else {
            throw LispError.arity(expected: 1, got: 0)
        }
        var minValue = try LispNumeric(args[0])
        for arg in args.dropFirst() {
            let num = try LispNumeric(arg)
            switch (minValue, num) {
            case let (.integer(a), .integer(b)):
                minValue = .integer(Swift.min(a, b))
            case let (.float(a), .float(b)):
                minValue = .float(Swift.min(a, b))
            case let (.integer(a), .float(b)):
                minValue = .float(Swift.min(Double(a), b))
            case let (.float(a), .integer(b)):
                minValue = .float(Swift.min(a, Double(b)))
            default:
                throw LispError.eval("MIN: unsupported numeric types")
            }
        }
        return minValue.toLispValue()
    }))
    
    env.define(LispSymbol(name: "MAX", package: kCommonLisp), value: .function({ args in
        guard !args.isEmpty else {
            throw LispError.arity(expected: 1, got: 0)
        }
        var maxValue = try LispNumeric(args[0])
        for arg in args.dropFirst() {
            let num = try LispNumeric(arg)
            switch (maxValue, num) {
            case let (.integer(a), .integer(b)):
                maxValue = .integer(Swift.max(a, b))
            case let (.float(a), .float(b)):
                maxValue = .float(Swift.max(a, b))
            case let (.integer(a), .float(b)):
                maxValue = .float(Swift.max(Double(a), b))
            case let (.float(a), .integer(b)):
                maxValue = .float(Swift.max(a, Double(b)))
            default:
                throw LispError.eval("MAX: unsupported numeric types")
            }
        }
        return maxValue.toLispValue()
    }))
    
    env.define(LispSymbol(name: "1+", package: kCommonLisp), value: .function({ args in
        guard args.count == 1 else {
            throw LispError.arity(expected: 1, got: args.count)
        }
        let num = try LispNumeric(args[0])
        switch num {
        case .integer(let value):
            return .number(.integer(value + 1))
        case .float(let value):
            return .number(.float(value + 1.0))
        default:
            throw LispError.eval("1+ expects a numeric argument, got: \(args[0])")
        }
    }))
    
    env.define(LispSymbol(name: "1-", package: kCommonLisp), value: .function({ args in
        guard args.count == 1 else {
            throw LispError.arity(expected: 1, got: args.count)
        }
        let num = try LispNumeric(args[0])
        switch num {
        case .integer(let value):
            return .number(.integer(value - 1))
        case .float(let value):
            return .number(.float(value - 1.0))
        default:
            throw LispError.eval("1- expects a numeric argument, got: \(args[0])")
        }
    }))
    
    env.define(LispSymbol(name: "=", package: kCommonLisp), value: .function({ args in
        if args.count <= 1 {
            return .t // true for 0 or 1 arguments
        }
        let first = try LispNumeric(args[0])
        for value in args.dropFirst() {
            let num = try LispNumeric(value)
            switch (first, num) {
                case let (.integer(a), .integer(b)):
                    if a != b { return .nil }
                case let (.float(a), .float(b)):
                    if a != b { return .nil }
                case let (.integer(a), .float(b)):
                    if Double(a) != b { return .nil }
                case let (.float(a), .integer(b)):
                    if a != Double(b) { return .nil }
                default:
                    throw LispError.eval("=: unsupported numeric types")
            }
        }
        return .t
    }))
    
    env.define(LispSymbol(name: "<", package: kCommonLisp), value: .function({ args in
        if args.count <= 1 {
            return .t // true for 0 or 1 arguments
        }
        var prev = try LispNumeric(args[0])
        for value in args.dropFirst() {
            let next = try LispNumeric(value)
            switch (prev, next) {
            case let (.integer(a), .integer(b)):
                if !(a < b) { return .nil }
            case let (.float(a), .float(b)):
                if !(a < b) { return .nil }
            case let (.integer(a), .float(b)):
                if !(Double(a) < b) { return .nil }
            case let (.float(a), .integer(b)):
                if !(a < Double(b)) { return .nil }
            default:
                throw LispError.eval("<: unsupported numeric types")
            }
            prev = next
        }
        return .t
    }))

    env.define(LispSymbol(name: ">", package: kCommonLisp), value: .function({ args in
        if args.count <= 1 {
            return .t // true for 0 or 1 arguments
        }
        var prev = try LispNumeric(args[0])
        for value in args.dropFirst() {
            let next = try LispNumeric(value)
            switch (prev, next) {
                case let (.integer(a), .integer(b)):
                    if !(a > b) { return .nil }
                case let (.float(a), .float(b)):
                    if !(a > b) { return .nil }
                case let (.integer(a), .float(b)):
                    if !(Double(a) > b) { return .nil }
                case let (.float(a), .integer(b)):
                    if !(a > Double(b)) { return .nil }
                default:
                    throw LispError.eval(">: unsupported numeric types")
            }
            prev = next
        }
        return .t
    }))
    
    env.define(LispSymbol(name: "<=", package: kCommonLisp), value: .function({ args in
        if args.count <= 1 {
            return .t // true for 0 or 1 arguments
        }
        var prev = try LispNumeric(args[0])
        for value in args.dropFirst() {
            let next = try LispNumeric(value)
            switch (prev, next) {
                case let (.integer(a), .integer(b)):
                    if !(a <= b) { return .nil }
                case let (.float(a), .float(b)):
                    if !(a <= b) { return .nil }
                case let (.integer(a), .float(b)):
                    if !(Double(a) <= b) { return .nil }
                case let (.float(a), .integer(b)):
                    if !(a <= Double(b)) { return .nil }
                default:
                    throw LispError.eval("<=: unsupported numeric types")
            }
            prev = next
        }
        return .t
    }))
    
    env.define(LispSymbol(name: ">=", package: kCommonLisp), value: .function({ args in
        if args.count <= 1 {
            return .t // true for 0 or 1 arguments
        }
        var prev = try LispNumeric(args[0])
        for value in args.dropFirst() {
            let next = try LispNumeric(value)
            switch (prev, next) {
                case let (.integer(a), .integer(b)):
                    if !(a >= b) { return .nil }
                case let (.float(a), .float(b)):
                    if !(a >= b) { return .nil }
                case let (.integer(a), .float(b)):
                    if !(Double(a) >= b) { return .nil }
                case let (.float(a), .integer(b)):
                    if !(a >= Double(b)) { return .nil }
                default:
                    throw LispError.eval(">=: unsupported numeric types")
            }
            prev = next
        }
        return .t
    }))

    env.define(LispSymbol(name: "EQ", package: kCommonLisp), value: .function({ args in
        guard args.count == 2 else {
            throw LispError.arity(expected: 2, got: args.count)
        }
        return args[0] == args[1] ? .t : .nil
    }))

    env.define(LispSymbol(name: "EQL", package: kCommonLisp), value: .function({ args in
        guard args.count == 2 else {
            throw LispError.arity(expected: 2, got: args.count)
        }
        return lispEql(args[0], args[1]) ? .t : .nil
    }))

    env.define(LispSymbol(name: "EQUAL", package: kCommonLisp), value: .function({ args in
        guard args.count == 2 else {
            throw LispError.arity(expected: 2, got: args.count)
        }
        return lispEqual(args[0], args[1]) ? .t : .nil
    }))
    
    env.define(LispSymbol(name: "LIST", package: kCommonLisp), value: .function({ args in
        return args.reversed().reduce(.nil) { acc, next in
            .cons(car: next, cdr: acc)
        }
    }))
    
    env.define(LispSymbol(name: "CONS", package: kCommonLisp), value: .function({ args in
        guard args.count == 2 else {
            throw LispError.arity(expected: 2, got: args.count)
        }
        return .cons(car: args[0], cdr: args[1])
    }))

    env.define(LispSymbol(name: "CDR", package: kCommonLisp), value: .function({ args in
        guard args.count == 1 else {
            throw LispError.arity(expected: 1, got: args.count)
        }

        guard case let .cons(_, cdr) = args[0] else {
            throw LispError.eval("CDR expected a cons cell, got \(args[0])")
        }

        return cdr
    }))
    
    env.define(LispSymbol(name: "CAR", package: kCommonLisp), value: .function({ args in
        guard args.count == 1 else {
            throw LispError.arity(expected: 1, got: args.count)
        }

        guard case let .cons(car, _) = args[0] else {
            throw LispError.eval("CAR expected a cons cell, got \(args[0])")
        }

        return car
    }))
    
    env.define(LispSymbol(name: "LENGTH", package: kCommonLisp), value: .function({ args in
        guard args.count == 1 else {
            throw LispError.arity(expected: 1, got: args.count)
        }

        var count = 0
        var current = args[0]

        while true {
            switch current {
                case .cons(_, let cdr):
                    count += 1
                    current = cdr
                case .nil:
                    return .number(.integer(count))
                default:
                    throw LispError.eval("LENGTH expects a proper list, got: \(current)")
            }
        }
    }))
    
    env.define(LispSymbol(name: "ATOM", package: kCommonLisp), value: .function({ args in
        guard args.count == 1 else {
            throw LispError.arity(expected: 1, got: args.count)
        }
        switch args[0] {
            case .cons:
                return .nil
            default:
                return .t
        }
    }))

    env.define(LispSymbol(name: "LISTP", package: kCommonLisp), value: .function({ args in
        guard args.count == 1 else {
            throw LispError.arity(expected: 1, got: args.count)
        }
        switch args[0] {
            case .cons, .nil:
                return .t
            default:
                return .nil
        }
    }))

    env.define(LispSymbol(name: "NUMBERP", package: kCommonLisp), value: .function({ args in
        guard args.count == 1 else {
            throw LispError.arity(expected: 1, got: args.count)
        }
        switch args[0] {
            case .number:
                return .t
            default:
                return .nil
        }
    }))

    env.define(LispSymbol(name: "SYMBOLP", package: kCommonLisp), value: .function({ args in
        guard args.count == 1 else {
            throw LispError.arity(expected: 1, got: args.count)
        }
        switch args[0] {
            case .symbol:
                return .t
            default:
                return .nil
        }
    }))
    
    env.define(LispSymbol(name: "NULL", package: kCommonLisp), value: .function({ args in
        guard args.count == 1 else {
            throw LispError.arity(expected: 1, got: args.count)
        }
        switch args[0] {
            case .nil:
                return .t
            default:
                return .nil
        }
    }))

    env.define(LispSymbol(name: "KEYWORDP", package: kCommonLisp), value: .function({ args in
        guard args.count == 1 else {
            throw LispError.arity(expected: 1, got: args.count)
        }
        guard case let .symbol(sym) = args[0] else {
            throw LispError.typeError(expected: "symbol", got: args[0])
        }
        return sym.isKeyword ? .t : .nil
    }))

    env.define(LispSymbol(name: "SYMBOL-NAME", package: kCommonLisp), value: .function({ args in
        guard args.count == 1 else {
            throw LispError.arity(expected: 1, got: args.count)
        }
        guard case let .symbol(sym) = args[0] else {
            throw LispError.typeError(expected: "symbol", got: args[0])
        }
        return .string(sym.name)
    }))

    env.define(LispSymbol(name: "SYMBOL-PACKAGE", package: kCommonLisp), value: .function({ args in
        guard args.count == 1 else {
            throw LispError.arity(expected: 1, got: args.count)
        }
        guard case let .symbol(sym) = args[0] else {
            throw LispError.typeError(expected: "symbol", got: args[0])
        }
        return .symbol(LispSymbol(name: sym.package, package: kCommonLisp))
    }))

    return env
}()
