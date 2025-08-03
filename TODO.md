# TODO

## Legend
- ✅ = Implemented
- ⚠️ = Partially present
- ❌ = Missing

## Core Language
- ✅ Lexical scope
- ❌ Dynamic scope via `special`
- ⚠️ REPL-driven development (basic eval, but no REPL loop)
- ✅ Homoiconicity (code as data)
- ✅ Macros (`defmacro`, `macroexpand`)
- ✅ Quasiquote / Unquote (`\``, `,`, `,@`)
- ❌ Multiple values
- ⚠️ Tail recursion support (relies on Swift optimizer)

## Data Types
- ✅ Integers
- ✅ Floats
- ✅ Ratios
- ❌ Complex numbers
- ✅ Characters
- ✅ Strings
- ✅ Symbols (with package field)
- ✅ Cons cells / lists
- ❌ Arrays & Vectors
- ❌ Hash tables
- ❌ Structures (`defstruct`)
- ❌ Classes & Objects (CLOS)

## Functions
- ✅ First-class functions
- ✅ Closures (lexical scope capture)
- ❌ Optional/keyword arguments
- ❌ Generic functions

## Control Flow
- ✅ `if`, `cond`
- ✅ `and`, `or`, `not`
- ✅ `progn`
- ❌ `block`, `return-from`
- ❌ `tagbody`, `go`
- ❌ `catch`, `throw`
- ❌ `unwind-protect`

## Binding & Eval
- ✅ `setq`
- ✅ `let`, `let*`
- ✅ `lambda`
- ✅ `defun`
- ✅ `apply`, `funcall`
- ✅ `eval`

## Iteration
- ✅ `loop`
- ❌ `dolist`, `dotimes`
- ❌ `mapcar`, `reduce`, etc.

## Condition System
- ❌ Conditions/signals/restarts

## Package System
- ⚠️ Packages/namespaces (symbol has `package` string, but no full system)

## Reader/Printer
- ⚠️ Reader macros (only `'`, `#'`, `` ` ``, `,`, `,@` parsed)
- ✅ Printer for lists, numbers, symbols, etc.

## Standard Library
- ❌ Sequence functions (`remove`, `subseq`, etc.)
- ❌ File & Stream IO
- ❌ Pathnames

## Meta
- ✅ `function` special form / `#'`
- ✅ `quote` special form / `'`

## Numerics
- ✅ `+`, `-`, `*`, `/`, comparisons
- ✅ `mod`, `rem`, `abs`, `min`, `max`, `1+`, `1-`
- ❌ `floor`, `ceiling`, `round`, `truncate`

## Miscellaneous
- ✅ Garbage collection (via Swift ARC)
- ❌ FFI (foreign function interface)
