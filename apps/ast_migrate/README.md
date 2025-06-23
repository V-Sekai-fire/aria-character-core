# AST Migrate

A powerful AST-based code migration tool for Elixir projects. This tool allows you to define transformation rules and apply them systematically across your codebase with Git integration for safe, trackable migrations.

## Features

- **AST-based transformations**: Work directly with Elixir's Abstract Syntax Tree for precise code modifications
- **Rule-based system**: Define reusable transformation rules
- **Git integration**: Automatic commit creation with detailed migration history
- **Safe migrations**: Clean working tree validation and rollback capabilities
- **Extensible**: Easy to add new transformation rules

## Installation

Clone this repository and install dependencies:

```bash
cd apps/ast_migrate
mix deps.get
mix compile
```

## Usage

### Basic Migration

Apply a transformation rule to your project:

```bash
# From the ast_migrate directory
mix ast.simple --rule unit_test_improvements --target /path/to/your/project
```

### Available Commands

- `mix ast.simple` - Apply a single transformation rule
- `mix ast.commit` - Apply transformations with automatic Git commits

### Available Rules

- `unit_test_improvements` - Improve test readability by extracting variables and adding assertions

#### Unit Test Improvements Rule

This rule demonstrates AST transformation capabilities while providing useful improvements to test code:

**Transformations Applied:**

1. **Extract intermediate variables in assertions:**

   ```elixir
   # Before
   assert some_function(arg) == expected

   # After
   result = some_function(arg)
   assert result == expected
   ```

2. **Add missing assertions to bare function calls:**

   ```elixir
   # Before
   test "some test" do
     some_function()
   end

   # After
   test "some test" do
     result = some_function()
     assert result
   end
   ```

## Creating Custom Rules

1. Create a new module in `lib/ast_migrate/rules/`
2. Implement the `AstMigrate.Rules.Behaviour`
3. Define your transformation logic

Example:

```elixir
defmodule AstMigrate.Rules.MyCustomRule do
  @behaviour AstMigrate.Rules.Behaviour

  @impl true
  def transform(ast) do
    # Your transformation logic here
    ast
  end

  @impl true
  def description do
    "Description of what this rule does"
  end
end
```

## Git Integration

The tool integrates with Git to provide safe migrations:

- Validates clean working tree before starting
- Creates commits for each transformation
- Provides rollback capabilities
- Maintains detailed migration history

## Development

Run tests:

```bash
mix test
```

Format code:

```bash
mix format
```

Run quality checks:

```bash
mix quality
```

## License

MIT License - see LICENSE.md for details.
