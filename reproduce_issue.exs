# reproduce_issue.exs
alias BooleanAlgebra.Simplifier
alias BooleanAlgebra.Formatter
alias BooleanAlgebra.Parser
alias BooleanAlgebra.Lexer

input = "((x & y & z) | (u & v)) & ((x | !y | !z) | (u & v))"
{:ok, ast} = BooleanAlgebra.parse(input)

IO.puts("Input: #{input}")

# 1. Using simplify/1 (what tests likely use)
simplified_ast = Simplifier.simplify(ast)
simplified_str = Formatter.to_string(simplified_ast)
IO.puts("simplify/1 result: #{simplified_str}")

# 2. Using simplify_with_details/1 (what web interface uses)
{simplified_ast_details, _details} = Simplifier.simplify_with_details(ast)
simplified_str_details = Formatter.to_string(simplified_ast_details)
IO.puts("simplify_with_details/1 result: #{simplified_str_details}")

if simplified_str != simplified_str_details do
  IO.puts("\nDISCREPANCY DETECTED!")
else
  IO.puts("\nNo discrepancy.")
end
