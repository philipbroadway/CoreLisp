import Testing
@testable import CoreLisp

@MainActor
@Test("Quote")
func quoteTest() async throws {
    var tokens = Array(tokenize("'(1 2 3)").reversed())
    let expr = try parse(tokens: &tokens)
    let result = try eval(expr, in: global)
    #expect(result.description == "(1 2 3)")
}

@MainActor
@Test func addition() async throws {
    
    let tests = ["(+ 1.0 2)", "(+ 2 1)", "(+ 1 (+ 2 1))"]
    let answers = ["3.0", "3", "4"]
    
    for (index, test) in tests.enumerated() {
        
        var tokens = Array(tokenize(test).reversed())
        let expr = try parse(tokens: &tokens)
        
        let result = try eval(expr, in: global)
        
        #expect(result.description == answers[index])
    }
}

@MainActor
@Test func subtraction() async throws {
    
    let tests = ["(- 1.0 2)", "(- 2 1)"]
    let answers = ["-1.0", "1"]
    
    for (index, test) in tests.enumerated() {
        
        var tokens = Array(tokenize(test).reversed())
        let expr = try parse(tokens: &tokens)
        
        let result = try eval(expr, in: global)
        #expect(result.description == answers[index])
    }
}

@MainActor
@Test func multiplication() async throws {
    
    let tests = ["(* 1 2)", "(* 2.0 2)"]
    let answers = ["2", "4.0"]
    
    for (index, test) in tests.enumerated() {
        
        var tokens = Array(tokenize(test).reversed())
        let expr = try parse(tokens: &tokens)
        
        let result = try eval(expr, in: global)
        #expect(result.description == answers[index])
    }
}

@MainActor
@Test func division() async throws {
    
    let tests = ["(/ 1 1)", "(/ 2.0 1)", "(/ 3 2)"]
    let answers = ["1", "2.0", "3/2"]
    
    for (index, test) in tests.enumerated() {
        
        var tokens = Array(tokenize(test).reversed())
        let expr = try parse(tokens: &tokens)
        
        let result = try eval(expr, in: global)
        #expect(result.description == answers[index])
    }
}

