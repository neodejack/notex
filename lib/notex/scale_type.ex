defmodule Notex.ScaleType do
  @moduledoc """
  Behaviour for defining musical scale types.

  A scale type defines the interval pattern of a scale using relative note names
  (e.g. `:one`, `:three`, `:five`). Implement this behaviour to create custom
  scale types that can be used with `Notex.Scale.notes/2`.

  ## Built-in Scale Types

    * `Notex.ScaleType.Major` — major scale (1 2 3 4 5 6 7)
    * `Notex.ScaleType.Minor` — natural minor scale (1 2 b3 4 5 b6 b7)

  ## Defining a Custom Scale Type

  Implement the `c:name/0` and `c:relative_notes/0` callbacks:

      defmodule MyApp.MajorPentatonic do
        @behaviour Notex.ScaleType

        def name, do: "major pentatonic"
        def relative_notes, do: [:one, :two, :three, :five, :six]
      end

  Then you can use it with `Notex.Scale`:

      Notex.Scale.notes!(Notex.Note.new!("C", 4), MyApp.MajorPentatonic)
  """

  alias Notex.Constant

  @doc """
  Returns the human-readable name of the scale type (e.g. `"major"`).
  """
  @callback name() :: String.t()

  @doc """
  Returns the list of relative note atoms defining the scale's interval pattern.

  Available atoms to use in the callback

  | Atom             | Semitones | Interval  |
  | ---------------- | --------- | --------- |
  | `:one`           | 0         | 1         |
  | `:sharp_one`     | 1         | #1        |
  | `:flat_two`      | 1         | b2        |
  | `:two`           | 2         | 2         |
  | `:sharp_two`     | 3         | #2        |
  | `:flat_three`    | 3         | b3        |
  | `:three`         | 4         | 3         |
  | `:four`          | 5         | 4         |
  | `:sharp_four`    | 6         | #4        |
  | `:flat_five`     | 6         | b5        |
  | `:five`          | 7         | 5         |
  | `:sharp_five`    | 8         | #5        |
  | `:flat_six`      | 8         | b6        |
  | `:six`           | 9         | 6         |
  | `:sharp_six`     | 10        | #6        |
  | `:flat_seven`    | 10        | b7        |
  | `:seven`         | 11        | 7         |
  """
  @callback relative_notes() :: [atom()]

  # TODO: see if there is a way to emit warning if user custom_scale_type.relative_notes() not in Constant.relative_notes() |> Map.keys()

  @doc """
  Returns the relative note name strings for the given `scale_type` module.

  ## Examples

      iex> Notex.ScaleType.relative_notes(Notex.ScaleType.Major)
      ["1", "2", "3", "4", "5", "6", "7"]

  """
  @spec relative_notes(module()) :: [binary()]
  def relative_notes(scale_type) when is_atom(scale_type) do
    for r <- scale_type.relative_notes() do
      Map.fetch!(Constant.relative_names(), r)
    end
  end

  @doc """
  Returns the semitone intervals for the given `scale_type` module.

  ## Examples

      iex> Notex.ScaleType.relative_semitones(Notex.ScaleType.Major)
      [0, 2, 4, 5, 7, 9, 11]

  """
  @spec relative_semitones(module()) :: [integer()]
  def relative_semitones(scale_type) when is_atom(scale_type) do
    for r <- scale_type.relative_notes() do
      Map.fetch!(Constant.relative_semitones(), r)
    end
  end
end
