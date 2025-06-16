# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.StateTest do
  use ExUnit.Case, async: true
  doctest AriaEngine.State

  alias AriaEngine.State

  describe "basic state operations" do
    test "creates empty state" do
      state = State.new()
      assert state.data == %{}
      assert Map.has_key?(state.context, "@context")
    end

    test "creates state with custom context" do
      custom_context = %{"@context" => %{"custom" => "https://example.org/custom#"}}
      state = State.new(custom_context)
      assert state.context == custom_context
    end

    test "sets and gets objects" do
      state = State.new()
      |> State.set_object("location", "player", "room1")
      |> State.set_object("health", "player", 100)

      assert State.get_object(state, "location", "player") == "room1"
      assert State.get_object(state, "health", "player") == 100
      assert State.get_object(state, "nonexistent", "player") == nil
    end

    test "removes objects" do
      state = State.new()
      |> State.set_object("location", "player", "room1")
      |> State.remove_object("location", "player")

      assert State.get_object(state, "location", "player") == nil
    end
  end

  describe "set operations" do
    test "adds items to sets" do
      state = State.new()
      |> State.add_to_set("skills", "player", "combat")
      |> State.add_to_set("skills", "player", "magic")
      |> State.add_to_set("skills", "player", "combat")  # Duplicate should be ignored

      skills = State.get_object(state, "skills", "player")
      assert %MapSet{} = skills
      assert MapSet.member?(skills, "combat")
      assert MapSet.member?(skills, "magic")
      assert MapSet.size(skills) == 2
    end

    test "removes items from sets" do
      state = State.new()
      |> State.add_to_set("skills", "player", "combat")
      |> State.add_to_set("skills", "player", "magic")
      |> State.remove_from_set("skills", "player", "combat")

      skills = State.get_object(state, "skills", "player")
      assert %MapSet{} = skills
      refute MapSet.member?(skills, "combat")
      assert MapSet.member?(skills, "magic")
      assert MapSet.size(skills) == 1
    end

    test "removes object when set becomes empty" do
      state = State.new()
      |> State.add_to_set("skills", "player", "combat")
      |> State.remove_from_set("skills", "player", "combat")

      assert State.get_object(state, "skills", "player") == nil
    end

    test "checks if object is a set" do
      state = State.new()
      |> State.add_to_set("skills", "player", "combat")
      |> State.set_object("name", "player", "Alice")

      assert State.is_set?(state, "skills", "player")
      refute State.is_set?(state, "name", "player")
      refute State.is_set?(state, "nonexistent", "player")
    end
  end

  describe "list operations" do
    test "appends items to lists" do
      state = State.new()
      |> State.append_to_list("inventory", "player", "sword")
      |> State.append_to_list("inventory", "player", "shield")
      |> State.append_to_list("inventory", "player", "sword")  # Duplicates allowed

      inventory = State.get_object(state, "inventory", "player")
      assert inventory == ["sword", "shield", "sword"]
    end

    test "prepends items to lists" do
      state = State.new()
      |> State.append_to_list("inventory", "player", "sword")
      |> State.prepend_to_list("inventory", "player", "shield")

      inventory = State.get_object(state, "inventory", "player")
      assert inventory == ["shield", "sword"]
    end

    test "removes items from lists" do
      state = State.new()
      |> State.append_to_list("inventory", "player", "sword")
      |> State.append_to_list("inventory", "player", "shield")
      |> State.append_to_list("inventory", "player", "sword")
      |> State.remove_from_list("inventory", "player", "sword")  # Removes first occurrence

      inventory = State.get_object(state, "inventory", "player")
      assert inventory == ["shield", "sword"]
    end

    test "removes object when list becomes empty" do
      state = State.new()
      |> State.append_to_list("inventory", "player", "sword")
      |> State.remove_from_list("inventory", "player", "sword")

      assert State.get_object(state, "inventory", "player") == nil
    end

    test "checks if object is a list" do
      state = State.new()
      |> State.append_to_list("inventory", "player", "sword")
      |> State.set_object("name", "player", "Alice")

      assert State.is_list?(state, "inventory", "player")
      refute State.is_list?(state, "name", "player")
      refute State.is_list?(state, "nonexistent", "player")
    end
  end

  describe "JSON-LD serialization" do
    test "serializes empty state to JSON-LD" do
      state = State.new()
      {:ok, json_ld} = State.to_json_ld(state)

      assert json_ld["@type"] == "AriaEngineState"
      assert json_ld["@id"] == "_:state"
      assert Map.has_key?(json_ld, "@context")
      assert json_ld["triples"] == []
    end

    test "serializes simple objects to JSON-LD" do
      state = State.new()
      |> State.set_object("location", "player", "room1")
      |> State.set_object("health", "player", 100)

      {:ok, json_ld} = State.to_json_ld(state)

      triples = json_ld["triples"]
      assert length(triples) == 2

      location_triple = Enum.find(triples, fn t -> 
        t["predicate"] == "location" && t["subject"] == "player" 
      end)
      assert location_triple["object"] == "room1"

      health_triple = Enum.find(triples, fn t -> 
        t["predicate"] == "health" && t["subject"] == "player" 
      end)
      assert health_triple["object"] == 100
    end

    test "serializes sets to JSON-LD @set" do
      state = State.new()
      |> State.add_to_set("skills", "player", "combat")
      |> State.add_to_set("skills", "player", "magic")

      {:ok, json_ld} = State.to_json_ld(state)

      skills_triple = Enum.find(json_ld["triples"], fn t -> 
        t["predicate"] == "skills" && t["subject"] == "player" 
      end)

      assert Map.has_key?(skills_triple["object"], "@set")
      set_items = skills_triple["object"]["@set"]
      assert "combat" in set_items
      assert "magic" in set_items
      assert length(set_items) == 2
    end

    test "serializes lists to JSON-LD @list" do
      state = State.new()
      |> State.append_to_list("inventory", "player", "sword")
      |> State.append_to_list("inventory", "player", "shield")
      |> State.append_to_list("inventory", "player", "sword")

      {:ok, json_ld} = State.to_json_ld(state)

      inventory_triple = Enum.find(json_ld["triples"], fn t -> 
        t["predicate"] == "inventory" && t["subject"] == "player" 
      end)

      assert Map.has_key?(inventory_triple["object"], "@list")
      list_items = inventory_triple["object"]["@list"]
      assert list_items == ["sword", "shield", "sword"]
    end
  end

  describe "JSON-LD deserialization" do
    test "deserializes simple JSON-LD to state" do
      json_ld = %{
        "@context" => %{
          "@vocab" => "https://aria-engine.org/vocab#"
        },
        "@type" => "AriaEngineState",
        "@id" => "_:state",
        "triples" => [
          %{
            "predicate" => "location",
            "subject" => "player",
            "object" => "room1"
          },
          %{
            "predicate" => "health",
            "subject" => "player",
            "object" => 100
          }
        ]
      }

      {:ok, state} = State.from_json_ld(json_ld)

      assert State.get_object(state, "location", "player") == "room1"
      assert State.get_object(state, "health", "player") == 100
    end

    test "deserializes JSON-LD @set to MapSet" do
      json_ld = %{
        "@context" => %{
          "@vocab" => "https://aria-engine.org/vocab#"
        },
        "@type" => "AriaEngineState",
        "@id" => "_:state",
        "triples" => [
          %{
            "predicate" => "skills",
            "subject" => "player",
            "object" => %{
              "@set" => ["combat", "magic"]
            }
          }
        ]
      }

      {:ok, state} = State.from_json_ld(json_ld)

      skills = State.get_object(state, "skills", "player")
      assert %MapSet{} = skills
      assert MapSet.member?(skills, "combat")
      assert MapSet.member?(skills, "magic")
      assert MapSet.size(skills) == 2
    end

    test "deserializes JSON-LD @list to list" do
      json_ld = %{
        "@context" => %{
          "@vocab" => "https://aria-engine.org/vocab#"
        },
        "@type" => "AriaEngineState",
        "@id" => "_:state",
        "triples" => [
          %{
            "predicate" => "inventory",
            "subject" => "player",
            "object" => %{
              "@list" => ["sword", "shield", "sword"]
            }
          }
        ]
      }

      {:ok, state} = State.from_json_ld(json_ld)

      inventory = State.get_object(state, "inventory", "player")
      assert inventory == ["sword", "shield", "sword"]
    end

    test "handles invalid JSON-LD format" do
      invalid_json_ld = %{"invalid" => "format"}
      
      assert {:error, :invalid_json_ld_format} = State.from_json_ld(invalid_json_ld)
    end
  end

  describe "round-trip serialization" do
    test "preserves state through JSON-LD round-trip" do
      original_state = State.new()
      |> State.set_object("location", "player", "room1")
      |> State.set_object("health", "player", 100)
      |> State.add_to_set("skills", "player", "combat")
      |> State.add_to_set("skills", "player", "magic")
      |> State.append_to_list("inventory", "player", "sword")
      |> State.append_to_list("inventory", "player", "shield")
      |> State.append_to_list("inventory", "player", "sword")

      {:ok, json_ld} = State.to_json_ld(original_state)
      {:ok, restored_state} = State.from_json_ld(json_ld)

      # Check simple objects
      assert State.get_object(restored_state, "location", "player") == "room1"
      assert State.get_object(restored_state, "health", "player") == 100

      # Check sets
      original_skills = State.get_object(original_state, "skills", "player")
      restored_skills = State.get_object(restored_state, "skills", "player")
      assert MapSet.equal?(original_skills, restored_skills)

      # Check lists
      original_inventory = State.get_object(original_state, "inventory", "player")
      restored_inventory = State.get_object(restored_state, "inventory", "player")
      assert original_inventory == restored_inventory
    end
  end

  describe "data type preservation" do
    test "stores and retrieves lists maintaining list type" do
      original_list = ["sword", "shield", "potion"]
      
      state = State.new()
      |> State.set_object("inventory", "player", original_list)
      
      retrieved_list = State.get_object(state, "inventory", "player")
      
      # Verify it's still a list with the same content
      assert is_list(retrieved_list)
      assert retrieved_list == original_list
      assert length(retrieved_list) == 3
      assert Enum.at(retrieved_list, 0) == "sword"
      assert Enum.at(retrieved_list, 1) == "shield"
      assert Enum.at(retrieved_list, 2) == "potion"
    end

    test "stores and retrieves sets maintaining set type" do
      original_set = MapSet.new(["combat", "magic", "stealth"])
      
      state = State.new()
      |> State.set_object("skills", "player", original_set)
      
      retrieved_set = State.get_object(state, "skills", "player")
      
      # Verify it's still a MapSet with the same content
      assert %MapSet{} = retrieved_set
      assert MapSet.equal?(retrieved_set, original_set)
      assert MapSet.size(retrieved_set) == 3
      assert MapSet.member?(retrieved_set, "combat")
      assert MapSet.member?(retrieved_set, "magic")
      assert MapSet.member?(retrieved_set, "stealth")
    end

    test "stores and retrieves mixed data types in domain facts" do
      # Test various data types as domain facts
      player_location = "room1"
      player_health = 100
      player_inventory = ["sword", "key", "potion"]
      player_skills = MapSet.new(["combat", "magic"])
      connected_rooms = ["room2", "room3", "room4"]
      room_properties = %{light: true, dangerous: false, items: ["chest"]}
      
      state = State.new()
      |> State.add_domain_fact("location", "player", player_location)
      |> State.add_domain_fact("health", "player", player_health)
      |> State.add_domain_fact("inventory", "player", player_inventory)
      |> State.add_domain_fact("skills", "player", player_skills)
      |> State.add_domain_fact("connected", "room1", connected_rooms)
      |> State.add_domain_fact("properties", "room1", room_properties)
      
      # Verify all data types are preserved
      assert State.query_domain_fact(state, "location", "player") == player_location
      assert is_binary(State.query_domain_fact(state, "location", "player"))
      
      assert State.query_domain_fact(state, "health", "player") == player_health
      assert is_integer(State.query_domain_fact(state, "health", "player"))
      
      retrieved_inventory = State.query_domain_fact(state, "inventory", "player")
      assert is_list(retrieved_inventory)
      assert retrieved_inventory == player_inventory
      
      retrieved_skills = State.query_domain_fact(state, "skills", "player")
      assert %MapSet{} = retrieved_skills
      assert MapSet.equal?(retrieved_skills, player_skills)
      
      retrieved_connected = State.query_domain_fact(state, "connected", "room1")
      assert is_list(retrieved_connected)
      assert retrieved_connected == connected_rooms
      
      retrieved_properties = State.query_domain_fact(state, "properties", "room1")
      assert is_map(retrieved_properties)
      assert retrieved_properties == room_properties
    end

    test "handles empty lists and sets correctly" do
      empty_list = []
      empty_set = MapSet.new()
      
      state = State.new()
      |> State.set_object("empty_inventory", "player", empty_list)
      |> State.set_object("empty_skills", "player", empty_set)
      
      retrieved_list = State.get_object(state, "empty_inventory", "player")
      retrieved_set = State.get_object(state, "empty_skills", "player")
      
      assert is_list(retrieved_list)
      assert retrieved_list == []
      assert length(retrieved_list) == 0
      
      assert %MapSet{} = retrieved_set
      assert MapSet.size(retrieved_set) == 0
      assert MapSet.equal?(retrieved_set, MapSet.new())
    end
  end
end
