# Litcovers Project Guide

## Commands
- Setup: `mix setup` (get deps, setup DB, build assets)
- Run server: `mix phx.server`
- Tests: `mix test` (all tests)
- Single test: `mix test test/path/to/test_file.exs:line_number`
- Format code: `mix format`
- Compile: `mix compile`
- Check for compilation warnings: `mix compile --warnings-as-errors`
- DB migrations: `mix ecto.migrate`

## Code Style
- Naming: snake_case for variables/functions, PascalCase for modules
- Imports: Group by type (Phoenix, Ecto, stdlib)
- Error handling: Prefer `with` statements for multiple operations
- Validation: Use Ecto changesets for data validation
- Logging: Use Logger with appropriate levels (info/warn/error)
- Documentation: Use `@doc` and `@moduledoc` with examples
- Elixir pipes: Use `|>` for multi-step operations
- Schema struct usage: Always define schemas with typed fields

## Structure
- Context modules organize business logic
- LiveView for interactive features
- Error responses standardized with detailed messages
- Follow Phoenix 1.7 component conventions