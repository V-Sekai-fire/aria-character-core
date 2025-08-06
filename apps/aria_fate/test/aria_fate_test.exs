defmodule AriaFateTest do
  use ExUnit.Case
  doctest AriaFate

  alias AriaFate.Character

  test "generates a basic character" do
    assert {:ok, character} = AriaFate.generate_character()
    assert %Character{} = character
    assert character.refresh == 3
    assert is_binary(character.name)
    assert is_binary(character.high_concept)
    assert is_binary(character.trouble)
  end

  test "generates character with constraints" do
    constraints = %{
      concept: "Space Pilot",
      trouble: "Wanted by the Empire",
      name: "Han Solo"
    }

    assert {:ok, character} = AriaFate.generate_character(constraints)
    assert character.name == "Han Solo"
    assert character.high_concept == "Space Pilot"
    assert character.trouble == "Wanted by the Empire"
  end

  test "validates character" do
    character = Character.new(%{
      high_concept: "Test Hero",
      trouble: "Test Trouble"
    })

    assert {:ok, %{valid: true}} = AriaFate.validate_character(character)
  end

  test "exports character to markdown" do
    character = Character.new(%{
      name: "Test Character",
      high_concept: "Test Hero",
      trouble: "Test Trouble"
    })

    assert {:ok, markdown} = AriaFate.export_character(character, :markdown)
    assert String.contains?(markdown, "# Test Character")
    assert String.contains?(markdown, "**High Concept:** Test Hero")
  end
end
