import Testing
@testable import CoreLisp

@MainActor
@Test func addition() async throws {
    
    let tests = ["(+ 1 2)", "(+ 2 1)"]
    let answers = ["3.0", "3.0"]
    
    for (index, test) in tests.enumerated() {
        
        var tokens = Array(tokenize(test).reversed())
        let expr = try parse(tokens: &tokens)
        
        let result = try eval(expr, in: global)
        
        #expect(result.description == answers[index])
    }
}

@MainActor
@Test func subtraction() async throws {
    
    let tests = ["(- 1 2)", "(- 2 1)"]
    let answers = ["-1.0", "1.0"]
    
    for (index, test) in tests.enumerated() {
        
        var tokens = Array(tokenize(test).reversed())
        let expr = try parse(tokens: &tokens)
        
        let result = try eval(expr, in: global)
        #expect(result.description == answers[index])
    }
}

@MainActor
@Test func multiplication() async throws {
    
    let tests = ["(* 1 2)", "(* 2 2)"]
    let answers = ["2.0", "4.0"]
    
    for (index, test) in tests.enumerated() {
        
        var tokens = Array(tokenize(test).reversed())
        let expr = try parse(tokens: &tokens)
        
        let result = try eval(expr, in: global)
        #expect(result.description == answers[index])
    }
}
