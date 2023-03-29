defmodule LitcoversWeb.ReferralLiveTest do
  use LitcoversWeb.ConnCase

  import Phoenix.LiveViewTest
  import Litcovers.CampaignFixtures

  @create_attrs %{code: "some code", discount: 120.5, host: "some host"}
  @update_attrs %{code: "some updated code", discount: 456.7, host: "some updated host"}
  @invalid_attrs %{code: nil, discount: nil, host: nil}

  defp create_referral(_) do
    referral = referral_fixture()
    %{referral: referral}
  end

  describe "Index" do
    setup [:create_referral]

    test "lists all referrals", %{conn: conn, referral: referral} do
      {:ok, _index_live, html} = live(conn, ~p"/referrals")

      assert html =~ "Listing Referrals"
      assert html =~ referral.code
    end

    test "saves new referral", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/referrals")

      assert index_live |> element("a", "New Referral") |> render_click() =~
               "New Referral"

      assert_patch(index_live, ~p"/referrals/new")

      assert index_live
             |> form("#referral-form", referral: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#referral-form", referral: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/referrals")

      html = render(index_live)
      assert html =~ "Referral created successfully"
      assert html =~ "some code"
    end

    test "updates referral in listing", %{conn: conn, referral: referral} do
      {:ok, index_live, _html} = live(conn, ~p"/referrals")

      assert index_live |> element("#referrals-#{referral.id} a", "Edit") |> render_click() =~
               "Edit Referral"

      assert_patch(index_live, ~p"/referrals/#{referral}/edit")

      assert index_live
             |> form("#referral-form", referral: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#referral-form", referral: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/referrals")

      html = render(index_live)
      assert html =~ "Referral updated successfully"
      assert html =~ "some updated code"
    end

    test "deletes referral in listing", %{conn: conn, referral: referral} do
      {:ok, index_live, _html} = live(conn, ~p"/referrals")

      assert index_live |> element("#referrals-#{referral.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#referrals-#{referral.id}")
    end
  end

  describe "Show" do
    setup [:create_referral]

    test "displays referral", %{conn: conn, referral: referral} do
      {:ok, _show_live, html} = live(conn, ~p"/referrals/#{referral}")

      assert html =~ "Show Referral"
      assert html =~ referral.code
    end

    test "updates referral within modal", %{conn: conn, referral: referral} do
      {:ok, show_live, _html} = live(conn, ~p"/referrals/#{referral}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Referral"

      assert_patch(show_live, ~p"/referrals/#{referral}/show/edit")

      assert show_live
             |> form("#referral-form", referral: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#referral-form", referral: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/referrals/#{referral}")

      html = render(show_live)
      assert html =~ "Referral updated successfully"
      assert html =~ "some updated code"
    end
  end
end
