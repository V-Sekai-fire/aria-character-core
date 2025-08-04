# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AstMigrateTest do
  use ExUnit.Case, async: true
  alias AstMigrate

  describe "list_rules/0" do
    test "returns empty list when no rules are implemented" do
      rules = AstMigrate.list_rules()
      assert rules == []
    end
  end

  describe "rule_info/1" do
    test "returns error for unknown rule" do
      assert {:error, "Unknown rule: unknown_rule"} = AstMigrate.rule_info(:unknown_rule)
    end
  end

  describe "apply_rule/2" do
    test "returns error for unknown rule" do
      assert {:error, "Unknown rule: unknown_rule"} =
        AstMigrate.apply_rule(:unknown_rule, files: [])
    end
  end
end
