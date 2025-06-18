public let kCommonLisp = "COMMON-LISP"

@MainActor
let global: LispEnvironment = {
    
    let env = LispEnvironment()
    
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
    
    return env
}()
