//
//  LispTokenizer.swift
//  CoreLisp
//
//  Created by philipbroadway on 6/17/25.
//

import Foundation

public func tokenize(_ input: String) -> [String] {
    var tokens: [String] = []
    var current = ""

    let chars = Array(input)
    var i = 0

    while i < chars.count {
        let c = chars[i]

        switch c {
        case "(", ")", "'", "`":
            if !current.isEmpty {
                tokens.append(current)
                current = ""
            }
            tokens.append(String(c))
        case ",":
            if !current.isEmpty {
                tokens.append(current)
                current = ""
            }
            if i + 1 < chars.count, chars[i + 1] == "@" {
                tokens.append(",@")
                i += 1
            } else {
                tokens.append(",")
            }
        case " ", "\n", "\t":
            if !current.isEmpty {
                tokens.append(current)
                current = ""
            }
        default:
            current.append(c)
        }

        i += 1
    }

    if !current.isEmpty {
        tokens.append(current)
    }

    return tokens
}
