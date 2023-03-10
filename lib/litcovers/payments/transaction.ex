defmodule Litcovers.Payments.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :amount, :integer
    field :currency, :string
    field :description, :string
    field :payment_service, :string
    field :tnx_id, :string

    field :status, Ecto.Enum,
      values: [:pending, :succeeded, :canceled, :waiting_for_capture],
      default: :pending

    field :paid, :boolean, default: false
    belongs_to :user, Litcovers.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:amount, :currency, :payment_service, :description, :tnx_id, :status, :paid])
    |> validate_required([:amount, :currency, :tnx_id, :status, :paid])
  end
end
