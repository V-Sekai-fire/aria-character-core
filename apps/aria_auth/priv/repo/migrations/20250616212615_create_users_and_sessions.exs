# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuth.Repo.Migrations.CreateUsersAndSessions do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :email_verified_at, :utc_datetime
      add :confirmation_token, :string
      add :reset_password_token, :string
      add :reset_password_sent_at, :utc_datetime
      add :locked_at, :utc_datetime
      add :failed_attempts, :integer, default: 0
      add :unlock_token, :string
      add :provider, :string
      add :provider_uid, :string
      add :sign_in_count, :integer, default: 0
      add :current_sign_in_at, :utc_datetime
      add :last_sign_in_at, :utc_datetime

      timestamps()
    end

    create unique_index(:users, [:email])

    create table(:sessions) do
      add :token, :string, null: false
      add :refresh_token, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :last_activity_at, :utc_datetime, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:sessions, [:token])
    create unique_index(:sessions, [:refresh_token])
  end
end
