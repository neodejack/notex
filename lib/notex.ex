defmodule Notex do
  @moduledoc """
  A music theory library for Elixir.

  Notex provides primitives for working with musical notes, scales, and scale types.

  ## Modules

    * `Notex.Note` — create, parse, compare, and transpose musical notes.
    * `Notex.Scale` — build scale note lists from a tonic note and a scale type.
    * `Notex.ScaleType` — behaviour for defining custom scale types.

  ## Quick Example

      use Notex

      # Create a note with the ~n sigil
      note = ~n[C4]

      # Transpose up a perfect fifth (7 semitones)
      Notex.Note.transpose!(note, 7)
      #=> ~n[G4]

      # Build a C major scale
      Notex.Scale.notes!(~n[C4], :major)
      #=> [~n[C4], ~n[D4], ~n[E4], ~n[F4], ~n[G4], ~n[A4], ~n[B4]]

  ## Usage

      use Notex

  This imports the `~n` sigil and the `is_interval/1` guard.
  """

  defmacro __using__(_opts) do
    quote do
      import Notex.Note, only: [sigil_n: 2]
      import Notex.Constant, only: [is_interval: 1]
    end
  end
end
