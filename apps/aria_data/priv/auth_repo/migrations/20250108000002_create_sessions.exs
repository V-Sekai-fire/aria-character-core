defmodule AriaData.AuthRepo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :string, null: false
      add :refresh_token, :string
      add :user_agent, :string
      add :ip_address, :string
      add :expires_at, :utc_datetime, null: false
      add :last_activity_at, :utc_datetime
      add :metadata, :map, default: %{}
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:sessions, [:token])
    create unique_index(:sessions, [:refresh_token])
    create index(:sessions, [:user_id])
    create index(:sessions, [:expires_at])
    create index(:sessions, [:last_activity_at])
  end
end
