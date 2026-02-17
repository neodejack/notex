# AGENTS.md — Notex

## Build & Test
- `mix compile` — compile the project
- `mix test` — run all tests
- `mix test test/notex/note_test.exs` — run a single test file
- `mix test test/notex/note_test.exs:9` — run a single test (line number)
- `mix format` — auto-format (uses Styler plugin)
- `mix credo` — linter; `mix dialyzer` — static type analysis

## Architecture
Elixir library (no Phoenix/Ecto/DB) for music theory: notes, scales, and scale types.
- `Notex.Note` — core struct (`note_name`, `octave`); parsing, transposition, comparison, `~n` sigil
- `Notex.Scale` — builds scale note lists from a tonic `Note` + a `ScaleType` module
- `Notex.ScaleType` — behaviour (`name/0`, `relative_notes/0`); built-in impls in `scale_type/`
- `Notex.Constant` — module-attribute lookup tables for note names, semitones, enharmonics

## Code Style
- Elixir 1.19 / OTP 28. Formatter: `mix format` with `Styler` plugin — always run before committing.
- Use `@spec` typespecs on all public functions. Use `@moduledoc false` on internal modules.
- Pattern: `foo/N` returns `{:ok, val} | {:error, String.t()}`; `foo!/N` raises `ArgumentError`.
- Aliases use `alias Notex.Module` (one per line); import only in tests. No `use` except `ExUnit.Case`.
- Tests: `use ExUnit.Case, async: true`. Group with `describe`. Match on structs directly in assertions.
