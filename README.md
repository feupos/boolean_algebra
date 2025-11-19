# Boolean Algebra

A comprehensive Elixir library for boolean algebra simplification, manipulation, and minimization. This project demonstrates core functional programming principles while providing practical utility for digital logic and computer science applications.

## Features

- **Expression Parsing**: Parse boolean expressions from text strings.
- **Algebraic Simplification**: Simplify expressions using the **Quine-McCluskey algorithm** and **Petrick's method** for finding prime implicants and minimal covers.
- **Evaluation**: Evaluate boolean expressions with specific variable assignments.
- **Truth Tables**: Generate truth tables for any boolean expression.
- **Web Interface**: A Phoenix LiveView application to visualize simplification and minimization.


## Usage

### Expression Simplification

The `BooleanAlgebra` module provides a high-level interface for simplifying expressions.

```elixir
# Simple simplification
BooleanAlgebra.simplify("A AND TRUE")
# => "A"

# Applying De Morgan's laws
BooleanAlgebra.simplify("NOT (A OR B)")
# => "NOT A AND NOT B"

# Complex simplification
BooleanAlgebra.simplify("(A OR B) AND A")
# => "A"
```

### Evaluation

Evaluate expressions by providing a map of variable values.

```elixir
BooleanAlgebra.eval("A AND B", %{"A" => true, "B" => true})
# => true

BooleanAlgebra.eval("A OR B", %{"A" => false, "B" => false})
# => false
```

### Truth Tables

Generate a truth table for an expression.

```elixir
BooleanAlgebra.truth_table("A XOR B")
# Returns a list of maps representing the truth table rows
```

## Web Interface

This project includes a Phoenix LiveView web interface for interactive experimentation.

To start the web server:

1.  Install dependencies: `mix setup`
2.  Start the server: `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Functional Programming Concepts

This library showcases Elixir's strengths in:

-   **Pattern Matching**: Extensively used for AST traversal and transformation rules.
-   **Recursion**: Used for navigating tree structures and implementing iterative algorithms like QMC.
-   **Immutability**: All transformations produce new data structures without side effects.
-   **Pipelines**: Complex operations are composed of smaller, reusable functions.

## Testing

Run the test suite to verify correctness:

```bash
mix test
```
