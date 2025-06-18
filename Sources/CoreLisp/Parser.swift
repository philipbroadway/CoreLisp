//
//  Parser.swift
//  CoreLisp
//
//  Created by philipbroadway on 6/17/25.
//

import Foundation

public enum ParseError: Error {
    case unexpectedEndOfInput
    case unexpectedToken(String)
    case expectedDot
}

public func makeQuoteForm(_ name: String, tokens: inout [String]) throws -> LispValue {
    let quoted = try parse(tokens: &tokens)
    let sym = LispValue.symbol(LispSymbol(name: name, package: "COMMON-LISP"))
    return .cons(car: sym, cdr: .cons(car: quoted, cdr: .nil))
}

public func parse(tokens: inout [String]) throws -> LispValue {
    guard let token = tokens.popLast() else {
        throw ParseError.unexpectedEndOfInput
    }

    switch token {
    case "(":
        return try parseList(&tokens)
    case "'":
        return try makeQuoteForm("QUOTE", tokens: &tokens)
    case "#\\":
        guard let next = tokens.popLast() else { throw ParseError.unexpectedEndOfInput }
        return .character(Character(next))
    case "`":
        return try makeQuoteForm("QUASIQUOTE", tokens: &tokens)
    case ",":
        return try makeQuoteForm("UNQUOTE", tokens: &tokens)
    case ",@":
        return try makeQuoteForm("UNQUOTE-SPLICING", tokens: &tokens)
    default:
        return parseAtom(token)
    }
}

public func parseList(_ tokens: inout [String]) throws -> LispValue {
    if tokens.last == ")" {
        tokens.removeLast()
        return .nil
    }

    let car = try parse(tokens: &tokens)

    if tokens.last == "." {
        tokens.removeLast() // eat dot
        let cdr = try parse(tokens: &tokens)
        guard tokens.popLast() == ")" else {
            throw ParseError.unexpectedToken("Expected closing ) after dotted pair")
        }
        return .cons(car: car, cdr: cdr)
    } else {
        let cdr = try parseList(&tokens)
        return .cons(car: car, cdr: cdr)
    }
}

public func parseAtom(_ token: String) -> LispValue {
    if let intVal = Int(token) {
        return .number(.integer(intVal))
    } else if let doubleVal = Double(token) {
        return .number(.float(doubleVal))
    } else if token.uppercased() == "NIL" {
        return .nil
    } else if token.uppercased() == "T" {
        return .symbol(LispSymbol(name: "T", package: "COMMON-LISP"))
    } else if token.hasPrefix(":") {
        return .symbol(LispSymbol(name: String(token.dropFirst()), package: "KEYWORD"))
    } else {
        return .symbol(LispSymbol(name: token.uppercased(), package: "COMMON-LISP"))
    }
}
