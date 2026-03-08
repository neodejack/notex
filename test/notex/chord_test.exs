defmodule Notex.ChordTest do
  use ExUnit.Case, async: true

  import Notex.Chord

  test "basic test" do
    chord =
      new()
      |> add_interval(:one)
      |> add_interval(:three)
      |> add_interval(:five)
      |> set_voicing(:one, [-1, 0])
      |> omit_interval(:three)
      |> add_interval(:four)

    chord
    |> build()
    |> dbg()

    chord
    |> set_voicing(:six, [0])
    |> build()
    |> dbg()
  end
end
