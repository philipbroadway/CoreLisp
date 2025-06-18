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
    
    return env
}()
