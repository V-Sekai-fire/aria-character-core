defmodule AriaData.QueueRepo.Migrations.CreateObanTables do
  @moduledoc """
  Migration to create Oban job tables in the queue database.
  """
  
  use Ecto.Migration

  def up do
    Oban.Migration.up()
  end

  def down do
    Oban.Migration.down()
  end
end
