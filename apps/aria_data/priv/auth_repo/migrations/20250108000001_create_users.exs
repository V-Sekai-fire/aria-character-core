defmodule AriaData.AuthRepo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :password_hash, :string
      add :first_name, :string
      add :last_name, :string
      add :display_name, :string
      add :avatar_url, :string
      add :email_verified_at, :utc_datetime
      add :locked_at, :utc_datetime
      add :last_sign_in_at, :utc_datetime
      add :current_sign_in_at, :utc_datetime
      add :sign_in_count, :integer, default: 0
      add :failed_attempts, :integer, default: 0
      add :unlock_token, :string
      add :confirmation_token, :string
      add :reset_password_token, :string
      add :reset_password_sent_at, :utc_datetime
      add :provider, :string
      add :provider_uid, :string
      add :provider_data, :map
      add :roles, {:array, :string}, default: ["user"]
      add :preferences, :map, default: %{}
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:provider, :provider_uid])
    create index(:users, [:email_verified_at])
    create index(:users, [:locked_at])
    create index(:users, [:last_sign_in_at])
    create index(:users, [:provider])
  end
end
