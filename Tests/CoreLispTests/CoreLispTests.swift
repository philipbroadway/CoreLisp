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

@MainActor
@Test func arithmeticCore() async throws {
    let cases: [(String, String)] = [
         ("(mod 7 3)", "1"),
         ("(rem 7 3)", "1"),
         ("(abs -5)", "5"),
         ("(min 1 2 3)", "1"),
         ("(max 1 2 3)", "3"),
         ("(1+ 41)", "42"),
         ("(1- 42)", "41"),
    ]
    try await evaluateCases(cases)
}

@MainActor
@Test func comparisonCore() async throws {
    let cases: [(String, String)] = [
         ("(= 3 3)", "T"),
         ("(< 1 2)", "T"),
         ("(> 2 1)", "T"),
         ("(<= 2 2)", "T"),
         ("(>= 2 2)", "T"),
         ("(eq 'a 'a)", "T"),
         ("(equal '(1 2) '(1 2))", "T"),
         ("(eql 42 42)", "T"),
    ]
    try await evaluateCases(cases)
}

@MainActor
@Test func typePredicates() async throws {
    let cases: [(String, String)] = [
         ("(atom 'a)", "T"),
         ("(listp '(1 2))", "T"),
         ("(null '())", "T"),
         ("(numberp 42)", "T"),
         ("(symbolp 'x)", "T"),
    ]
    try await evaluateCases(cases)
}

@MainActor
@Test func controlFlowCore() async throws {
    let cases: [(String, String)] = [
         ("(if t 1 2)", "1"),
         ("(if nil 1 2)", "2"),
         ("(cond ((= 1 2) 'no) ((= 2 2) 'yes))", "YES"),
         ("(and t t)", "T"),
         ("(or nil 'x)", "X"),
         ("(not nil)", "T"),
    ]
    try await evaluateCases(cases)
}

@MainActor
@Test func bindingAndFunctions() async throws {
    let cases: [(String, String)] = [
         ("(let ((x 2)) x)", "2"),
         ("(let* ((x 2) (y (+ x 1))) y)", "3"),
         ("(setq x 5)", "5"),
         ("((lambda (x) (+ x 1)) 41)", "42"),
        // ("(defun add1 (x) (+ x 1)) (add1 41)", "42"),
    ]
    try await evaluateCases(cases)
}

@MainActor
@Test func evalAndFuncall() async throws {
    let cases: [(String, String)] = [
        // ("(funcall #'+ 1 2)", "3"),
        // ("(apply #'+ '(1 2))", "3"),
        // ("(eval '(+ 1 2))", "3"),
    ]
    try await evaluateCases(cases)
}

@MainActor
@Test func symbolCore() async throws {
    let cases: [(String, String)] = [
        // ("(symbol-name 'foo)", "\"FOO\""),
        // ("(symbol-package 'foo)", "COMMON-LISP"),
        // ("(keywordp :bar)", "T"),
    ]
    try await evaluateCases(cases)
}

@MainActor
func evaluateCases(_ cases: [(String, String)]) async throws {
    for (code, expected) in cases {
        var tokens = Array(tokenize(code).reversed())
        let expr   = try parse(tokens: &tokens)
        let value  = try eval(expr, in: global)
        #expect(value.description == expected,
                "Expected \(expected) from \(code), got \(value)")
    }
}
