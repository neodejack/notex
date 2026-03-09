defmodule Notex.ScaleType do
  @moduledoc """
  Behaviour for defining musical scale types.

  A scale type defines the interval pattern of a scale using interval note names
  (e.g. `:one`, `:three`, `:five`). Implement this behaviour to create custom
  scale types that can be used with `Notex.Scale.notes/2`.

  ## Built-in Scale Types

    * `Notex.ScaleType.Major` — major scale (1 2 3 4 5 6 7)
    * `Notex.ScaleType.Minor` — natural minor scale (1 2 b3 4 5 b6 b7)

  ## Defining a Custom Scale Type

  Use `use Notex.ScaleType` and implement the `c:name/0` and `c:intervals/0` callbacks.
  The `use` macro registers a compile-time check that warns if `intervals/0` returns
  invalid interval atoms.

      defmodule MyApp.MajorPentatonic do
        use Notex.ScaleType

        def name, do: "major pentatonic"
        def intervals, do: [:one, :two, :three, :five, :six]
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
  Returns the list of interval note atoms defining the scale's interval pattern.

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
  @callback intervals() :: [Constant.interval_id()]

  @doc """
  Sets up the `Notex.ScaleType` behaviour and registers a compile-time check
  that warns if `intervals/0` returns atoms not in `Notex.Constant.interval_ids/0`.

  Use `use Notex.ScaleType` instead of `@behaviour Notex.ScaleType`:

      defmodule MyApp.MajorPentatonic do
        use Notex.ScaleType

        def name, do: "major pentatonic"
        def intervals, do: [:one, :two, :three, :five, :six]
      end
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour Notex.ScaleType
      @after_compile {Notex.ScaleType, :__validate_intervals__}
    end
  end

  @doc false
  def __validate_intervals__(env, _bytecode) do
    module = env.module
    valid_ids = Constant.interval_ids()
    intervals = module.intervals()
    invalid = Enum.reject(intervals, &(&1 in valid_ids))

    if invalid != [] do
      IO.warn(
        "#{inspect(module)}.intervals/0 contains invalid interval ids: #{inspect(invalid)}. " <>
          "Valid ids are: #{inspect(valid_ids)}"
      )
    end
  end

  @doc """
  Returns the interval note name strings for the given `scale_type` module.

  ## Examples

      iex> Notex.ScaleType.intervals(Notex.ScaleType.Major)
      ["1", "2", "3", "4", "5", "6", "7"]

  """
  @spec intervals(module()) :: [binary()]
  def intervals(scale_type) when is_atom(scale_type) do
    for r <- scale_type.intervals() do
      Map.fetch!(Constant.interval_names(), r)
    end
  end

  @doc """
  Returns the semitone intervals for the given `scale_type` module.

  ## Examples

      iex> Notex.ScaleType.interval_semitones(Notex.ScaleType.Major)
      [0, 2, 4, 5, 7, 9, 11]

  """
  @spec interval_semitones(module()) :: [integer()]
  def interval_semitones(scale_type) when is_atom(scale_type) do
    for r <- scale_type.intervals() do
      Map.fetch!(Constant.interval_semitones(), r)
    end
  end
end
