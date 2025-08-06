# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTownTest do
  use ExUnit.Case
  doctest AriaTown.NPCManager
  doctest AriaTown.TimeManager
  doctest AriaTown.PersistenceManager

  test "application components are running" do
    # Check that the main GenServers are running
    assert Process.whereis(AriaTown.NPCManager) != nil
    assert Process.whereis(AriaTown.TimeManager) != nil
    assert Process.whereis(AriaTown.PersistenceManager) != nil
  end

  test "PersistenceManager basic operations" do
    # Test the trigger_save function
    assert AriaTown.PersistenceManager.trigger_save() == :ok
  end

  test "NPCManager basic operations" do
    # Test listing NPCs (should be empty initially)
    initial_npcs = AriaTown.NPCManager.list_npcs()

    # Test spawning an NPC
    {:ok, npc} = AriaTown.NPCManager.spawn_npc(%{name: "Test NPC"})
    assert npc.name == "Test NPC"
    assert npc.id =~ "npc_"

    # Test getting the NPC
    retrieved_npc = AriaTown.NPCManager.get_npc(npc.id)
    assert retrieved_npc.id == npc.id

    # Test updating the NPC
    {:ok, updated_npc} = AriaTown.NPCManager.update_npc(npc.id, %{state: :active})
    assert updated_npc.state == :active

    # Test listing NPCs (should now have our test NPC)
    current_npcs = AriaTown.NPCManager.list_npcs()
    assert length(current_npcs) == length(initial_npcs) + 1

    # Test despawning the NPC
    assert AriaTown.NPCManager.despawn_npc(npc.id) == :ok
    assert AriaTown.NPCManager.get_npc(npc.id) == nil

    # Verify NPC list is back to initial state
    final_npcs = AriaTown.NPCManager.list_npcs()
    assert length(final_npcs) == length(initial_npcs)
  end
end
