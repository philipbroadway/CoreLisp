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

@MainActor
@Test
func numericRegression() async throws {

    // (form, expected description)
    let cases: [(String, String)] = [
        // ---------- + ----------
        ("(+)",              "0"),
        ("(+ 1 2 3)",        "6"),
        ("(+ 1.5 2.5)",      "4.0"),

        // ---------- - ----------
        ("(- 5)",            "-5"),
        ("(- 7 2)",          "5"),
        ("(- 10 3 2)",       "5"),

        // ---------- * ----------
        ("(*)",              "1"),
        ("(* 2 3 4)",        "24"),
        ("(* 1.5 2)",        "3.0"),

        // ---------- / ----------
        ("(/)",              "1"),
        ("(/ 2)",            "1/2"),
        ("(/ 6 3)",          "2"),
        ("(/ 3 2)",          "3/2"),   // stays a ratio
        ("(/ 12 3 2)",       "2")
    ]

    for (form, expected) in cases {
        var tokens = Array(tokenize(form).reversed())
        let expr   = try parse(tokens: &tokens)
        let value  = try eval(expr, in: global)

        #expect(value.description == expected,
                "Expected \(expected) from \(form), got \(value)")
    }
}

@MainActor
@Test
func listRegression() async throws {

    // (form, expected printer output, optional predicate)

    typealias Case = (code: String,
                      expectedPrint: String,
                      extraCheck: ((LispValue) -> Bool)?)

    let cases: [Case] = [

        // ---------- quote ----------
        ("'a",                 "A",           nil),
        ("'(1 2 3)",           "(1 2 3)",     nil),
        ("'(1 . 2)",           "(1 . 2)",     nil),

        // ---------- list ----------
        ("(list)",             "()",          nil),
        ("(list 1 2 3)",       "(1 2 3)",     nil),

        // ---------- cons ----------
        ("(cons 1 2)",         "(1 . 2)",     nil),
        ("(cons 1 '(2 3))",    "(1 2 3)",     nil),

        // ---------- car / cdr ----------
        ("(car '(1 2 3))",     "1",           nil),
        ("(cdr '(1 2 3))",     "(2 3)",       nil),
        ("(car '(1 . 2))",     "1",           nil),
        ("(cdr '(1 . 2))",     "2",           nil),

        // ---------- length ----------
        ("(length '(1 2 3))",  "3",           nil),
        ("(length '())",       "0",           nil),

        // An internal-structure sanity check:
        ("(cons 4 '(5 6))",    "(4 5 6)",     { val in
            if case let .cons(car, _) = val { return car.description == "4" }
            return false
        })
    ]

    for c in cases {
        var tokens = Array(tokenize(c.code).reversed())
        let expr   = try parse(tokens: &tokens)
        let value  = try eval(expr, in: global)

        #expect(value.description == c.expectedPrint,
                "Expected \(c.expectedPrint) from \(c.code), got \(value)")

        if let check = c.extraCheck {
            #expect(check(value), "Internal structure check failed for \(c.code)")
        }
    }
}
