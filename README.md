# Boolean Algebra Simplification Library for Elixir

## Overview

This proposal outlines the development of a functional Elixir library for boolean algebra simplification and manipulation. The library will demonstrate core functional programming principles while providing practical utility for boolean expression processing, making it suitable for both educational and practical applications in digital logic, computer science, etc.

## Motivation

Boolean algebra is fundamental to digital logic, computer science, and formal verification. A well-designed library for boolean expression manipulation serves both educational and practical purposes while showcasing Elixir's strengths in pattern matching, recursion, and functional data structures.

## Main Objectives

### 1. Boolean Expression Simplification

The library will implement a comprehensive set of boolean algebra laws to perform expression simplification. These laws will be applied iteratively to reduce boolean expressions to their minimal form.

#### Identity Laws

These laws define the behavior of boolean operations with identity elements (0 and 1 / false and true):

- **A && 1 = A** (conjunction of a value with true preserves the value)
- **A && 0 = A** (disjunction of a value with false preserves the value)

#### Annulment Laws

These laws define absorbing the identity elements in boolean operations:

- **A && 0 = 0** (conjunction of a value with false always yields false)
- **A || 1 = 1** (disjunction of a value  with true always yields true)

#### Idempotent Laws

Idempotence means that applying an operation multiple times has the same effect as applying it once:

- **A && A = A** (conjunction of a value with itself yields the value)
- **A || A = A** (disjunction of a value ue with itself yields the value)

#### Complement Laws

- **A && !A = 0** (conjunction of a value with its negation is always false)
- **A || !A = 1** (disjunction of a value with its negation is always true)

#### Double Negation Law

- **!(!A) = A** (Double negation returns the original value)

#### De Morgan's Laws

These fundamental theorems describe how negation distributes over conjunction and disjunction operations:

- **!(A && B) = !A || !B** (The negation of a conjunction is the disjunction of the negations)
- **!(A || B) = !A && !B** (The negation of a disjunction is the conjunction of the negations)


#### Absorption Laws

These laws demonstrate how certain terms can be absorbed from expressions:

- **A || (A && B) = A** (When A is true, A conjunction B is redundant)
- **A && (A || B) = A** (When A is true and in disjunction with anything, conjunction with A yields A)

#### Commutative Laws

These laws state that the order of operands does not affect the result:

- **A && B = B && A** (conjunction is commutative)
- **A || B = B || A** (disjunction is commutative)

#### Associative Laws

These laws indicate that the grouping of operations does not affect the result:

- **(A && B) && C = A && (B && C)** (conjunction is associative)
- **(A || B) || C = A || (B || C)** (disjunction is associative)

#### Distributive Laws

These laws describe how operations distribute over each other:

- **A && (B || C) = (A && B) || (A && C)** (conjunction distributes over disjunction)
- **A || (B && C) = (A || B) && (A || C)** (disjunctoin distributes over conjunction)

#### Exclusive disjunction (XOR) Properties

While the exclusive disjunction is not a primitive boolean operation, it has important properties:

- **A XOR 0 = A** (exclusive disjunction with false is identity)
- **A XOR 1 = !A** (exclusive disjunction with true is negation)
- **A XOR A = 0** (exclusive disjunction with itself is false)
- **A XOR !A = 1** (exclusive disjunction with complement is true)
- **A XOR B = !AB || A!B** (exclusive disjunction can be expressed using conjuncitons, disjunctions and negations)

### 2. Token-Based Expression Parsing (Phase 1)

The initial implementation will focus on parsing expressions from token lists using Elixir atoms. This approach leverages Elixir's pattern matching capabilities and provides a clear intermediate representation.

**Token Format Examples:**
- `:a`, `:b`, `:c`, etc. - Variables
- `:and`, `:or`, `:xor`, `:not` - Operators
- `:true`, `:false` - Boolean constants
- `:lparen`, `:rparen` - Parentheses for grouping

**Example Token Sequences:**
```elixir
# Simple expression: A AND B
[:a, :and, :b]

# Expression with OR: A OR B
[:a, :or, :b]

# Expression with negation: NOT A
[:not, :a]

# Complex expression with grouping: (A XOR B) AND C
[:lparen, :a, :xor, :b, :rparen, :and, :c]

# Expression with constants: A AND FALSE
[:a, :and, :false]
```

### 3. Text-Based Expression Parsing (Phase 2)

After the token-based implementation is complete and tested, the library will be extended to support parsing expressions directly from text strings. This will involve:

- Lexical analysis (tokenization) to convert text into tokens
- Syntax analysis to build an Abstract Syntax Tree (AST)
- Support for common boolean expression notations

**Text Format Examples:**
```elixir
"a and b"
"a or b"
"not a"
"(a xor b) and c"
"a and false"
```

### 4. Abstract Syntax Tree (AST) Representation

The library should use an AST to represent boolean expressions internally. The AST can be implemented using Elixir's data structures, taking advantage of pattern matching for traversal and transformation.

## API Design and Usage Examples

### Phase 1: Token-Based Interface

```elixir
# Simplify expression from token list
# A AND TRUE simplifies to A
BooleanAlgebra.simplify([:a, :and, :true])
# => [:a]

# Complex expression: (A OR B) AND A simplifies to A (absorption law)
BooleanAlgebra.simplify([:lparen, :a, :or, :b, :rparen, :and, :a])
# => [:a]
```

### Phase 2: Text-Based Interface

```elixir
# Simplify expression from text string
BooleanAlgebra.simplify("a and true")
# => "a"

BooleanAlgebra.simplify("(a or b) and a")
# => "a"
```

### Additional Features

Once the implementation of the basic functionality is finished, the goal is to extend thit with the implementation of additional convenience features to further experiment with the Elxir programming, for ease of use and demonstration purposes, suchas implemengting a Web interface using Phoenix LiveView or similar framework in order to support an expression editor with a visualization of the simplification.

### Functional programming concepts

This project should demonstrates several key functional programming concepts, such as
- **Pattern Matching**: That can be used for AST traversal and transformation
- **Recursion**: Which is a good fit for tree-based data structure navigation
- **Immutability** and **Pure Functions**: All transformations produce new expressions without modifying originals, and the simplification rules should be deterministic with no side effects

### Expected results

1. A working Elixir library with documented API
2. Comprehensive test suite covering all simplification rules
3. Usage examples and documentation