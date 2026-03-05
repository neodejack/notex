defmodule Notex.ConstantTest do
  use ExUnit.Case, async: true
  use Notex

  describe "is_interval/1" do
    test "returns true for all valid interval ids" do
      valid_intervals = [
        :one,
        :sharp_one,
        :flat_two,
        :two,
        :sharp_two,
        :flat_three,
        :three,
        :four,
        :sharp_four,
        :flat_five,
        :five,
        :sharp_five,
        :flat_six,
        :six,
        :sharp_six,
        :flat_seven,
        :seven
      ]

      for interval <- valid_intervals do
        assert is_interval(interval), "expected #{inspect(interval)} to be a valid interval"
      end
    end

    test "returns false for invalid atoms" do
      refute is_interval(:invalid)
      refute is_interval(:eight)
      refute is_interval(:minor)
    end

    test "returns false for non-atom values" do
      refute is_interval("one")
      refute is_interval(1)
      refute is_interval(nil)
    end

    test "works in guard clauses" do
      assert guard_test(:five) == :valid
      assert guard_test(:nope) == :invalid
      assert guard_test(42) == :invalid
    end

    defp guard_test(value) when is_interval(value), do: :valid
    defp guard_test(_value), do: :invalid
  end
end
