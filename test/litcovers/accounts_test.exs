defmodule Litcovers.AccountsTest do
  use Litcovers.DataCase

  alias Litcovers.Accounts

  describe "feedbacks" do
    alias Litcovers.Accounts.Feedback

    import Litcovers.AccountsFixtures

    @invalid_attrs %{rating: nil, text: nil}

    test "list_feedbacks/0 returns all feedbacks" do
      feedback = feedback_fixture()
      assert Accounts.list_feedbacks() == [feedback]
    end

    test "get_feedback!/1 returns the feedback with given id" do
      feedback = feedback_fixture()
      assert Accounts.get_feedback!(feedback.id) == feedback
    end

    test "create_feedback/1 with valid data creates a feedback" do
      valid_attrs = %{rating: 42, text: "some text"}

      assert {:ok, %Feedback{} = feedback} = Accounts.create_feedback(valid_attrs)
      assert feedback.rating == 42
      assert feedback.text == "some text"
    end

    test "create_feedback/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_feedback(@invalid_attrs)
    end

    test "update_feedback/2 with valid data updates the feedback" do
      feedback = feedback_fixture()
      update_attrs = %{rating: 43, text: "some updated text"}

      assert {:ok, %Feedback{} = feedback} = Accounts.update_feedback(feedback, update_attrs)
      assert feedback.rating == 43
      assert feedback.text == "some updated text"
    end

    test "update_feedback/2 with invalid data returns error changeset" do
      feedback = feedback_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_feedback(feedback, @invalid_attrs)
      assert feedback == Accounts.get_feedback!(feedback.id)
    end

    test "delete_feedback/1 deletes the feedback" do
      feedback = feedback_fixture()
      assert {:ok, %Feedback{}} = Accounts.delete_feedback(feedback)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_feedback!(feedback.id) end
    end

    test "change_feedback/1 returns a feedback changeset" do
      feedback = feedback_fixture()
      assert %Ecto.Changeset{} = Accounts.change_feedback(feedback)
    end
  end
end
