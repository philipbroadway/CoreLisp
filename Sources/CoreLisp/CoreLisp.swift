// The Swift Programming Language
// https://docs.swift.org/swift-book

@MainActor
let global: LispEnvironment = {
    let env = LispEnvironment()
    
    env.define(LispSymbol(name: "+", package: "COMMON-LISP"), value:
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
    return env
}()
