# Notex

[![Hex.pm](https://img.shields.io/hexpm/v/notex.svg)](https://hex.pm/packages/notex)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/notex)

A music theory library for Elixir — work with notes, scales, and scale types.

## Installation

Add `notex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:notex, "~> 0.1.0"}
  ]
end
```

## Quick Start

### Notes

Create notes with `Notex.Note.new/2` or the `~n` sigil:

```elixir
import Notex.Note

note = ~n[C4]
# => ~n[C4]

{:ok, note} = Notex.Note.new("G#", 5)
# => {:ok, ~n[G#5]}
```

Parse note strings:

```elixir
{:ok, note} = Notex.Note.parse("Ab3")
# => {:ok, ~n[G#3]}  (flats are normalized to sharps)
```

Transpose notes by semitones:

```elixir
import Notex.Note

Notex.Note.transpose!(~n[C4], 7)
# => ~n[G4]

Notex.Note.transpose!(~n[B4], 1)
# => ~n[C5]  (crosses octave boundary)
```

### Scales

Build scales from a tonic note and a scale type:

```elixir
import Notex.Note

Notex.Scale.notes!(~n[C4], :major)
# => [~n[C4], ~n[D4], ~n[E4], ~n[F4], ~n[G4], ~n[A4], ~n[B4]]

Notex.Scale.notes!(~n[A4], :minor)
# => [~n[A4], ~n[B4], ~n[C5], ~n[D5], ~n[E5], ~n[F5], ~n[G5]]
```

### Custom Scale Types

Define your own scale types by implementing the `Notex.ScaleType` behaviour:

```elixir
defmodule MyApp.MinorPentatonic do
  @behaviour Notex.ScaleType

  def name, do: "minor pentatonic"
  def relative_notes, do: [:one, :flat_three, :four, :five, :flat_seven]
end

import Notex.Note

Notex.Scale.notes!(~n[A4], MyApp.MinorPentatonic)
# => [~n[A4], ~n[C5], ~n[D5], ~n[E5], ~n[G5]]
```

## Documentation

Full documentation is available on [HexDocs](https://hexdocs.pm/notex).

## License

This project is licensed under the MIT License.
