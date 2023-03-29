defmodule Litcovers.CampaignTest do
  use Litcovers.DataCase

  alias Litcovers.Campaign

  describe "referrals" do
    alias Litcovers.Campaign.Referral

    import Litcovers.CampaignFixtures

    @invalid_attrs %{code: nil, discount: nil, host: nil}

    test "list_referrals/0 returns all referrals" do
      referral = referral_fixture()
      assert Campaign.list_referrals() == [referral]
    end

    test "get_referral!/1 returns the referral with given id" do
      referral = referral_fixture()
      assert Campaign.get_referral!(referral.id) == referral
    end

    test "create_referral/1 with valid data creates a referral" do
      valid_attrs = %{code: "some code", discount: 120.5, host: "some host"}

      assert {:ok, %Referral{} = referral} = Campaign.create_referral(valid_attrs)
      assert referral.code == "some code"
      assert referral.discount == 120.5
      assert referral.host == "some host"
    end

    test "create_referral/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Campaign.create_referral(@invalid_attrs)
    end

    test "update_referral/2 with valid data updates the referral" do
      referral = referral_fixture()
      update_attrs = %{code: "some updated code", discount: 456.7, host: "some updated host"}

      assert {:ok, %Referral{} = referral} = Campaign.update_referral(referral, update_attrs)
      assert referral.code == "some updated code"
      assert referral.discount == 456.7
      assert referral.host == "some updated host"
    end

    test "update_referral/2 with invalid data returns error changeset" do
      referral = referral_fixture()
      assert {:error, %Ecto.Changeset{}} = Campaign.update_referral(referral, @invalid_attrs)
      assert referral == Campaign.get_referral!(referral.id)
    end

    test "delete_referral/1 deletes the referral" do
      referral = referral_fixture()
      assert {:ok, %Referral{}} = Campaign.delete_referral(referral)
      assert_raise Ecto.NoResultsError, fn -> Campaign.get_referral!(referral.id) end
    end

    test "change_referral/1 returns a referral changeset" do
      referral = referral_fixture()
      assert %Ecto.Changeset{} = Campaign.change_referral(referral)
    end
  end
end
