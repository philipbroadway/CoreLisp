public let kCommonLisp = "COMMON-LISP"

@MainActor
let global: LispEnvironment = {
    
    let env = LispEnvironment()
    
    env.define(LispSymbol(name: "+", package: kCommonLisp), value:
        .function { args in
            let nums = try args.map {
                guard case let .number(n) = $0 else {
                    throw EvalError.invalidArgument("Expected number")
                }
                switch n {
                    case .integer(let i): return Double(i)
                    case .float(let f): return f
                    case .ratio(let n, let d): return Double(n) / Double(d)
                }
            }
            return .number(.float(nums.reduce(0, +)))
        })
    
    env.define(LispSymbol(name: "-", package: kCommonLisp), value: .function({ args in
        let nums = try args.map {
            guard case let .number(n) = $0 else {
                throw EvalError.invalidArgument("Expected number")
            }
            switch n {
                case .integer(let i): return Double(i)
                case .float(let f): return f
                case .ratio(let n, let d): return Double(n) / Double(d)
            }
        }
        guard let first = nums.first else {
            throw EvalError.invalidArgument("Expected at least one number")
        }
        let result: Double
        if nums.count == 1 {
            result = -first
        } else {
            result = nums.dropFirst().reduce(first, -)
        }
        return .number(.float(result))
    }))
    
    env.define(LispSymbol(name: "*", package: kCommonLisp), value: .function({ args in
        
        let nums = try args.map {
            guard case let .number(n) = $0 else {
                throw EvalError.invalidArgument("Expected number")
            }
            switch n {
                case .integer(let i): return Double(i)
                case .float(let f): return f
                case .ratio(let n, let d): return Double(n) / Double(d)
            }
        }
        return .number(.float(nums.reduce(1, *)))
    }))
    
    return env
}()
