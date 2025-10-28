## Boolean Algebra Library for Elixir

The proposal is to create a simple functional Elixir library for boolean algebra simplification. 
The library would be used to demonstrate core functional programming principles while providing practical utility for boolean expression processing.

## Motivation

Boolean algebra is fundamental to digital logic, computer science, and formal verification. A well-designed library for boolean expression manipulation can serve both educational and practical purposes, while showcasing Elixir's strengths in pattern matching, recursion, and data structures.

## Main Objectives

**Boolean Simplification**

- Implement boolean algebra laws that can be used to perform boolean expression simplification.

1. **Identity Laws**
   - a & 1 = a
   - a | 0 = a

2. **Null Laws**
   - a & 0 = 0
   - a | 1 = 1

3. **Idempotent Laws**
   - a & a = a
   - a | a = a

4. **Complement Laws**
   - a & !a = 0
   - a | !a = 1

5. **Double Negation**
   - !!a = a

6. **De Morgan's Laws**
   - !(a & b) = !a | !b
   - !(a | b) = !a & !b

7. **Absorption Laws**
   - a & (a | b) = a
   - a | (a & b) = a

8. **XOR Laws**
   - a ^ 0 = a
   - a ^ 1 = !a
   - a ^ a = 0

**Possible aditional features**

- Output simplification operations step by step.
    
- Generate truth tables from expressions.

- Parse boolean expressions from text.

- Use an Abstract Syntax Tree to perform the expression conversion.

## Expected results

1. A working Elixir library with documented API
2. Comprehensive test suite covering all simplification rules
3. Usage examples and documentation
