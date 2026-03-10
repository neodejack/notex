defmodule Notex.ChordTest do
  use ExUnit.Case, async: true
  use Notex

  import Notex.Chord

  alias Notex.Chord

  describe "new/1" do
    test "builds when given a chord struct shape" do
      chord_shape = put_intervals(base(), :add_root, :one)

      {:ok, chord} = new(chord_shape)

      assert chord.voicings == [one: [0]]
    end

    test "keeps existing voicings from chord struct shape" do
      chord_shape = %{base() | voicings: [one: [0], five: [1]]}

      {:ok, chord} = new(chord_shape)

      assert chord.voicings == [one: [0], five: [1]]
    end

    test "builds when given a zero-arity function shape" do
      {:ok, chord} = new(&major/0)

      assert chord.voicings == [five: [0], three: [0], one: [0]]
    end

    defmodule CustomShape do
      @moduledoc false

      def power_chord do
        Chord.put_intervals(Chord.base(), :add_power, [:one, :five])
      end
    end

    test "builds when given an MFA tuple shape" do
      {:ok, chord} = new({Notex.ChordTest.CustomShape, :power_chord, []})

      assert chord.voicings == [five: [0], one: [0]]
    end

    test "raises when shape function does not return chord struct" do
      assert_raise MatchError, fn ->
        new(fn -> :not_a_chord end)
      end
    end

    test "raises for unsupported chord shape" do
      assert_raise FunctionClauseError, fn ->
        apply(Chord, :new, [:major])
      end
    end
  end

  describe "put_intervals/3" do
    test "adds a single interval with default voicing" do
      {:ok, chord} =
        base()
        |> put_intervals(:add_root, :one)
        |> build()

      assert chord.voicings == [one: [0]]
    end

    test "adds a list of intervals with default voicing" do
      {:ok, chord} =
        base()
        |> put_intervals(:add_triad, [:one, :three, :five])
        |> build()

      assert chord.voicings == [five: [0], three: [0], one: [0]]
    end

    test "registers one step for list intervals" do
      chord = put_intervals(base(), :add_triad, [:one, :three, :five])

      assert [{:add_triad, step}] = chord.steps
      assert is_function(step, 1)
    end

    test "empty list is a no-op" do
      chord = put_intervals(base(), :add_root, :one)

      nooped = put_intervals(chord, :noop, [])

      assert length(nooped.steps) == length(chord.steps)

      {:ok, built_chord} =
        base()
        |> put_intervals(:noop, [])
        |> build()

      assert built_chord.voicings == []
    end

    test "accepts binary name and converts to atom" do
      {:ok, chord} =
        base()
        |> put_intervals("add_root", :one)
        |> build()

      assert chord.voicings == [one: [0]]
    end
  end

  describe "put_intervals/4" do
    test "adds a single interval with custom voicing" do
      {:ok, chord} =
        base()
        |> put_intervals(:add_root, :one, [-1, 0])
        |> build()

      assert chord.voicings == [one: [-1, 0]]
    end

    test "adds a list of intervals with custom voicing" do
      {:ok, chord} =
        base()
        |> put_intervals(:add_triad, [:one, :three, :five], [-1, 0, 1])
        |> build()

      assert chord.voicings == [five: [-1, 0, 1], three: [-1, 0, 1], one: [-1, 0, 1]]
    end

    test "registers one step for list intervals with custom voicing" do
      chord = put_intervals(base(), :add_triad, [:one, :three, :five], [-1, 0, 1])

      assert [{:add_triad, step}] = chord.steps
      assert is_function(step, 1)
    end

    test "overwrites an existing interval" do
      {:ok, chord} =
        base()
        |> put_intervals(:add_root, :one, [0])
        |> put_intervals(:widen_root, :one, [-1, 0])
        |> build()

      assert chord.voicings == [one: [-1, 0]]
    end

    test "accepts binary name with custom voicing" do
      {:ok, chord} =
        base()
        |> put_intervals("add_root", :one, [-1, 0])
        |> build()

      assert chord.voicings == [one: [-1, 0]]
    end

    test "two list calls with same name register one step per call" do
      chord =
        base()
        |> put_intervals(:triad, [:one, :three, :five])
        |> put_intervals(:triad, [:seven])

      assert 2 == Enum.count(chord.steps, fn {step_name, _step} -> step_name == :triad end)

      {:ok, built_chord} = build(chord)

      assert built_chord.voicings == [seven: [0], five: [0], three: [0], one: [0]]
    end
  end

  describe "update_voicing/4" do
    test "updates an existing interval's voicing via callback" do
      {:ok, chord} =
        base()
        |> put_intervals(:add_root, :one, [0])
        |> update_voicing(:spread_root, :one, fn _existing -> [-1, 0, 1] end)
        |> build()

      assert chord.voicings == [one: [-1, 0, 1]]
    end

    test "callback receives the current voicing" do
      {:ok, chord} =
        base()
        |> put_intervals(:add_root, :one, [-1, 0])
        |> update_voicing(:extend_root, :one, fn existing -> existing ++ [1] end)
        |> build()

      assert chord.voicings == [one: [-1, 0, 1]]
    end

    test "returns error with step name when interval does not exist" do
      {:error, msg} =
        base()
        |> update_voicing(:bad_update, :five, fn v -> v end)
        |> build()

      assert msg ==
               "error when building step: :bad_update\ninterval :five does not exist in chord voicings"
    end

    test "multiple updates apply in order" do
      {:ok, chord} =
        base()
        |> put_intervals(:add_root, :one, [0])
        |> update_voicing(:replace, :one, fn _ -> [1] end)
        |> update_voicing(:prepend, :one, fn existing -> [-1 | existing] end)
        |> build()

      assert chord.voicings == [one: [-1, 1]]
    end

    test "accepts binary name and converts to atom in error" do
      {:error, msg} =
        base()
        |> update_voicing("my_step", :five, fn v -> v end)
        |> build()

      assert msg ==
               "error when building step: :my_step\ninterval :five does not exist in chord voicings"
    end

    test "accepts binary name and converts to atom on success" do
      {:ok, chord} =
        base()
        |> put_intervals(:add_root, :one, [0])
        |> update_voicing("spread_root", :one, fn _existing -> [-1, 0, 1] end)
        |> build()

      assert chord.voicings == [one: [-1, 0, 1]]
    end
  end

  describe "drop_intervals/3" do
    test "drops a single interval" do
      {:ok, chord} =
        base()
        |> put_intervals(:add_triad, [:one, :three, :five])
        |> drop_intervals(:remove_third, :three)
        |> build()

      assert chord.voicings == [five: [0], one: [0]]
    end

    test "drops a list of intervals" do
      {:ok, chord} =
        base()
        |> put_intervals(:add_triad, [:one, :three, :five])
        |> drop_intervals(:strip, [:three, :five])
        |> build()

      assert chord.voicings == [one: [0]]
    end

    test "registers one step for dropping a list of intervals" do
      chord =
        base()
        |> put_intervals(:add_triad, [:one, :three, :five])
        |> drop_intervals(:strip, [:three, :five])

      assert 1 == Enum.count(chord.steps, fn {step_name, _step} -> step_name == :strip end)
    end

    test "empty list is a no-op" do
      chord = put_intervals(base(), :add_root, :one)

      nooped = drop_intervals(chord, :noop, [])

      assert length(nooped.steps) == length(chord.steps)

      {:ok, built_chord} =
        chord
        |> drop_intervals(:noop, [])
        |> build()

      assert built_chord.voicings == [one: [0]]
    end

    test "accepts binary name and converts to atom" do
      {:ok, chord} =
        base()
        |> put_intervals(:add_triad, [:one, :three, :five])
        |> drop_intervals("remove_third", :three)
        |> build()

      assert chord.voicings == [five: [0], one: [0]]
    end
  end

  describe "notes/2" do
    test "auto-builds pending chord steps before deriving notes" do
      chord = put_intervals(base(), :add_triad, [:one, :three, :five])

      assert {:ok, notes} = Chord.notes(chord, ~n[C4])
      assert notes == [~n[G4], ~n[E4], ~n[C4]]
    end

    test "returns build errors from pending steps" do
      chord =
        update_voicing(base(), :bad_update, :five, fn voicing -> voicing end)

      assert {:error, reason} = Chord.notes(chord, ~n[C4])

      assert reason ==
               "error when building step: :bad_update\ninterval :five does not exist in chord voicings"
    end
  end
end
