defmodule CritWeb.Usables.BlockingAuthorizationTest do
  use CritWeb.ConnCase
  alias CritWeb.Usables.AnimalController
  alias Crit.Users.PermissionList

  test "how an unlogged-in user is blocked", %{conn: conn} do

    assert_authorization_failures(conn,
      [&(get &1, AnimalController.path(:bulk_create_form)), 
       &(post &1, AnimalController.path(:bulk_create, params: %{})),
      ])
  end

  describe "how logged-in user without permissions is blocked" do

    setup %{conn: conn} do
      no_access = %PermissionList{manage_animals: false}
      [conn: logged_in_with_permissions(conn, no_access)]
    end

    test "blocked", %{conn: conn} do
      assert_authorization_failures(conn,
        [&(get &1, AnimalController.path(:bulk_create_form)), 
         &(post &1, AnimalController.path(:bulk_create, params: %{})),
        ])
    end
  end
end
