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

@MainActor
public func eval(_ value: LispValue, in env: LispEnvironment) throws -> LispValue {
    switch value {
        case .number, .string, .character, .function, .nil:
            return value

        case .symbol(let sym):
            if sym.package == "KEYWORD" {
                return .symbol(sym)
            }
            return try env.get(sym)

        case .cons(let car, let cdr):
            // Handle special forms before evaluating car
            if case let .symbol(sym) = car {
                switch sym.name.uppercased() {
                    case "QUOTE":
                        return try car1(cdr)
                    case "QUASIQUOTE":
                        let qqExpr = try car1(cdr)
                        return try quasiquoteExpand(qqExpr, env: env, level: 1)
                    case "SETQ":
                        var lastValue: LispValue = .nil
                        var args = cdr
                        while case let .cons(symExpr, rest1) = args, case let .cons(valExpr, rest2) = rest1 {
                            guard case let .symbol(s) = symExpr else {
                                throw EvalError.invalidArgument("SETQ expects symbol")
                            }
                            let val = try eval(valExpr, in: env)
                            env.define(s, value: val)
                            lastValue = val
                            args = rest2
                        }
                        if case .nil = args {
                            return lastValue
                        } else {
                            throw EvalError.invalidForm("SETQ expects pairs of symbol and value")
                        }
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
                    case "COND":
                        var clauseList = cdr
                        while case let .cons(clause, rest) = clauseList {
                            guard case let .cons(testExpr, results) = clause else {
                                throw EvalError.invalidForm("COND clause must be a list")
                            }
                            let testValue = try eval(testExpr, in: env)
                            if !testValue.isNil {
                                // Evaluate result forms, if any
                                if case .nil = results {
                                    return testValue
                                } else {
                                    var resultVal: LispValue = .nil
                                    var currentResults = results
                                    while case let .cons(resultExpr, more) = currentResults {
                                        resultVal = try eval(resultExpr, in: env)
                                        currentResults = more
                                    }
                                    return resultVal
                                }
                            }
                            clauseList = rest
                        }
                        return .nil
                    case "AND":
                        var result: LispValue = .t
                        var exprs = cdr
                        while case let .cons(expr, rest) = exprs {
                            result = try eval(expr, in: env)
                            if result.isNil {
                                return .nil
                            }
                            exprs = rest
                        }
                        return result
                    case "OR":
                        var exprs = cdr
                        while case let .cons(expr, rest) = exprs {
                            let result = try eval(expr, in: env)
                            if !result.isNil {
                                return result
                            }
                            exprs = rest
                        }
                        return .nil
                    case "NOT":
                        guard let arg = try car1(cdr) as LispValue? else {
                            throw EvalError.invalidForm("NOT expects one argument")
                        }
                        let value = try eval(arg, in: env)
                        return value.isNil ? .t : .nil
                    case "LET":
                        let bindings = try car1(cdr)
                        let body = try car2(cdr) ?? .nil
                        let newEnv = LispEnvironment(parent: env)
                        // Evaluate all bindings in outer env first
                        var binds: [(LispSymbol, LispValue)] = []
                        var bindList = bindings
                        while case let .cons(binding, rest) = bindList {
                            guard case let .cons(symExpr, bindCdr) = binding,
                                  case let .symbol(sym) = symExpr,
                                  let valExpr = try? car1(bindCdr) else {
                                throw EvalError.invalidForm("LET binding must be (symbol value)")
                            }
                            let value = try eval(valExpr, in: env)
                            binds.append((sym, value))
                            bindList = rest
                        }
                        // Define all in newEnv
                        for (sym, value) in binds {
                            newEnv.define(sym, value: value)
                        }
                        return try eval(body, in: newEnv)
                    case "LET*":
                        let bindings = try car1(cdr)
                        let body = try car2(cdr) ?? .nil
                        let currentEnv = LispEnvironment(parent: env)
                        var bindList = bindings
                        while case let .cons(binding, rest) = bindList {
                            guard case let .cons(symExpr, bindCdr) = binding,
                                  case let .symbol(sym) = symExpr,
                                  let valExpr = try? car1(bindCdr) else {
                                throw EvalError.invalidForm("LET* binding must be (symbol value)")
                            }
                            let value = try eval(valExpr, in: currentEnv)
                            currentEnv.define(sym, value: value)
                            bindList = rest
                        }
                        return try eval(body, in: currentEnv)
                    case "LAMBDA":
                        // Extract parameter list
                        let paramsList = try car1(cdr)
                        var params: [LispSymbol] = []
                        var temp = paramsList
                        while case let .cons(symExpr, rest) = temp {
                            guard case let .symbol(s) = symExpr else {
                                throw EvalError.invalidArgument("LAMBDA params must be symbols")
                            }
                            params.append(s)
                            temp = rest
                        }
                        // Everything after params is the body
                        let bodyList: LispValue
                        if case let .cons(_, rest) = cdr {
                            bodyList = rest
                        } else {
                            bodyList = .nil
                        }
                        var bodyExprs: [LispValue] = []
                        var curr = bodyList
                        while case let .cons(expr, more) = curr {
                            bodyExprs.append(expr)
                            curr = more
                        }
                        let closureEnv = env
                        return .function { args in
                            if args.count != params.count {
                                throw EvalError.invalidArgument("LAMBDA expected \(params.count) args, got \(args.count)")
                            }
                            let localEnv = LispEnvironment(parent: closureEnv)
                            for (param, value) in zip(params, args) {
                                localEnv.define(param, value: value)
                            }
                            var result: LispValue = .nil
                            for expr in bodyExprs {
                                result = try eval(expr, in: localEnv)
                            }
                            return result
                        }
                    case "DEFUN":
                        // Parse function name, parameter list, and body
                        let nameExpr = try car1(cdr)
                        guard case let .symbol(fnName) = nameExpr else {
                            throw EvalError.invalidForm("DEFUN expects function name as symbol")
                        }
                        let paramsList = try car2(cdr) ?? .nil
                        var params: [LispSymbol] = []
                        var temp = paramsList
                        while case let .cons(symExpr, rest) = temp {
                            guard case let .symbol(s) = symExpr else {
                                throw EvalError.invalidArgument("DEFUN params must be symbols")
                            }
                            params.append(s)
                            temp = rest
                        }
                        // Function body: everything after params
                        let bodyList: LispValue
                        if case let .cons(_, rest) = cdr, case let .cons(_, restBody) = rest {
                            bodyList = restBody
                        } else {
                            bodyList = .nil
                        }
                        var bodyExprs: [LispValue] = []
                        var curr = bodyList
                        while case let .cons(expr, more) = curr {
                            bodyExprs.append(expr)
                            curr = more
                        }
                        let closureEnv = env
                        let fnValue: LispValue = .function { args in
                            if args.count != params.count {
                                throw EvalError.invalidArgument("DEFUN expected \(params.count) args, got \(args.count)")
                            }
                            let localEnv = LispEnvironment(parent: closureEnv)
                            for (param, value) in zip(params, args) {
                                localEnv.define(param, value: value)
                            }
                            var result: LispValue = .nil
                            for expr in bodyExprs {
                                result = try eval(expr, in: localEnv)
                            }
                            return result
                        }
                        env.define(fnName, value: fnValue)
                        return fnValue
                    case "EVAL":
                        let expr = try car1(cdr)
                        let toEval = try eval(expr, in: env)
                        return try eval(toEval, in: env)
                    case "APPLY":
                        let fnExpr = try car1(cdr)
                        let argListExpr = try car2(cdr) ?? .nil
                        let fn = try eval(fnExpr, in: env)
                        let args = try listToArray(try eval(argListExpr, in: env))
                        guard case let .function(f) = fn else {
                            throw EvalError.notAFunction
                        }
                        return try f(args)

                    case "FUNCALL":
                        let fnExpr = try car1(cdr)
                        let argsList = try {
                            var current = cdr
                            var out: [LispValue] = []
                            var first = true
                            while case let .cons(expr, rest) = current {
                                if first {
                                    // skip the function form
                                    first = false
                                    current = rest
                                    continue
                                }
                                out.append(expr)
                                current = rest
                            }
                            return out
                        }()
                        let fn = try eval(fnExpr, in: env)
                        let evaledArgs = try argsList.map { try eval($0, in: env) }
                        guard case let .function(f) = fn else {
                            throw EvalError.notAFunction
                        }
                        return try f(evaledArgs)

                    case "FUNCTION":
                        let expr = try car1(cdr)
                        switch expr {
                        case let .symbol(s):
                            let fn = try env.get(s)
                            guard case .function = fn else {
                                throw EvalError.notAFunction
                            }
                            return fn
                        case let .cons(car, cdr):
                            // Support #'(lambda ...) as in (function (lambda (x) ...))
                            if case let .symbol(sym) = car, sym.name.uppercased() == "LAMBDA" {
                                // Evaluate .cons(car, cdr) as a lambda
                                let lambdaForm = LispValue.cons(car: car, cdr: cdr)
                                return try eval(LispValue.cons(car: car, cdr: cdr), in: env)
                            } else {
                                throw EvalError.invalidForm("FUNCTION expects a symbol or a lambda expression")
                            }
                        default:
                            throw EvalError.invalidForm("FUNCTION expects a symbol or a lambda expression")
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
    }
    // If value is a cons (list of forms), evaluate each in sequence and return the last result
    if case var .cons(expr, rest) = value {
        var result: LispValue = .nil
        var current: LispValue = value
        while case let .cons(form, next) = current {
            result = try eval(form, in: env)
            current = next
        }
        return result
    }
}

@MainActor
func quasiquoteExpand(
    _ form: LispValue,
    env: LispEnvironment,
    level: Int = 1
) throws -> LispValue {
    switch form {
    case let .cons(car, cdr):
        // Handle unquote / unquote-splicing / nested quasiquote
        if case let .symbol(sym) = car {
            switch sym.name.uppercased() {
            case "UNQUOTE":
                if level == 1 {
                    // evaluate ,(...)
                    return try eval( try car1(cdr), in: env )
                } else {
                    // deeper nesting → keep the syntax
                    let inner = try quasiquoteExpand( try car1(cdr), env: env, level: level - 1 )
                    return .cons(car: .symbol(sym),
                                 cdr: .cons(car: inner, cdr: .nil))
                }

            case "UNQUOTE-SPLICING":
                if level == 1 {
                    throw EvalError.invalidForm(",@ must appear inside a list")
                } else {
                    let inner = try quasiquoteExpand( try car1(cdr), env: env, level: level - 1 )
                    return .cons(car: .symbol(sym),
                                 cdr: .cons(car: inner, cdr: .nil))
                }

            case "QUASIQUOTE":
                // treat *this* backtick as a fresh quasiquote context,
                // so its commas will all be evaluated
                let inner = try car1(cdr)
                let expandedInner = try quasiquoteExpand(inner, env: env, level: 1)
                return .cons(car: .symbol(sym), cdr: .cons(car: expandedInner, cdr: .nil))

            default:
                break
            }
        }
        // For any other list, rebuild it, splicing as needed
        return try buildQQList(form, env: env, level: level)

    default:
        // Atom literal at any level (including top‐level): return as‐is
        return form
    }
}

// helper to map a list (LispValue list) applying closure on each element
fileprivate func mapList(_ list: LispValue, _ transform: (LispValue) throws -> LispValue) throws -> LispValue {
    var current = list
    var result: LispValue = .nil
    var elements: [LispValue] = []
    while case let .cons(car, cdr) = current {
        elements.append(try transform(car))
        current = cdr
    }
    if case .nil = current {
        for elem in elements.reversed() {
            result = LispValue.cons(car: elem, cdr: result)
        }
        return result
    } else {
        throw EvalError.invalidForm("Improper list")
    }
}

@MainActor
private func buildQQList(_ list: LispValue, env: LispEnvironment, level: Int) throws -> LispValue {
    var elements: [LispValue] = []
    var current = list

    while case let .cons(car, cdr) = current {
        if case let .cons(innerCar, innerCdr) = car,
           case let .symbol(sym) = innerCar,
           sym.name.uppercased() == "UNQUOTE-SPLICING",
           level == 1 {
            // handle ,@ splicing
            let spliceValue = try eval(try car1(innerCdr), in: env)
            let spliceArray = try listToArray(spliceValue)
            elements.append(contentsOf: spliceArray)
        } else {
            elements.append(try quasiquoteExpand(car, env: env, level: level))
        }
        current = cdr
    }

    // Reconstruct proper list
    return elements.reversed().reduce(.nil) { acc, next in
        .cons(car: next, cdr: acc)
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
