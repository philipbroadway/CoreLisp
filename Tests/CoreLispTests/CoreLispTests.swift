import Testing
@testable import CoreLisp

@MainActor
@Test func addition() async throws {
    var tokens = Array(tokenize("(+ 1 2)").reversed())
    let expr = try parse(tokens: &tokens)
    print(expr)
    
    let result = try eval(expr, in: global)
    print(result)
    
    #expect(result.description == "3.0")
}

@MainActor
@Test func subtraction() async throws {
    
}
