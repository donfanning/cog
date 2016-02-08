defmodule Integration.RuleTest do
  use Cog.AdapterCase, adapter: "test"
  import ExUnit.Assertions

  setup do
    user = user("belf", first_name: "Buddy", last_name: "Elf")
    |> with_chat_handle_for("test")
    |> with_permission("operable:manage_commands")

    group = group("ops")
    :ok = Groupable.add_to(user, group)

    role = role("admin")
    :ok = Permittable.grant_to(user, role)

    {:ok, %{user: user, group: group, role: role}}
  end

  test "error when unknown options for rules command", %{user: user} do
    response = send_message(user, "@bot: operable:rules --doit 'when command is operable:st-echo must have operable:st-echo'")

    assert response["data"]["response"] == "@belf Whoops! An error occurred. I am not sure what action you want me to take using `rules`"
  end

  test "adding a rule for a command", %{user: user} do
    response = send_message(user, "@bot: operable:rules --add 'when command is operable:st-echo must have operable:st-echo'")
    assert response["data"]["response"] == "@belf Whoops! An error occurred. \n* Rule already exists\n\n"

    # Drop the rule, then add it back
    response = send_message(user, "@bot: operable:rules --drop --for-command=\"operable:st-echo\"")
    assert response["data"]["response"] == "Dropped all rules for command `operable:st-echo`:\n* when command is operable:st-echo must have operable:st-echo\n"

    response = send_message(user, "@bot: operable:rules --add --for-command=operable:st-echo --permission=operable:st-echo")
    assert response["data"]["response"] == "Success! Added new rule \"when command is operable:st-echo must have operable:st-echo\""
  end

  test "dropping a rule via the command name", %{user: user} do
    response = send_message(user, "@bot: operable:rules --drop --for-command=\"operable:st-echo\"")
    assert response["data"]["response"] == "Dropped all rules for command `operable:st-echo`:\n* when command is operable:st-echo must have operable:st-echo\n"

    response = send_message(user, "@bot: operable:rules --drop --for-command=\"operable:st-echo\"")
    assert response["data"]["response"] == "There are no rules for command operable:st-echo"
  end

  test "error when dropping unknown id for rules command", %{user: user} do
    response = send_message(user, "@bot: operable:rules --drop --id=\"12345678-abcd-90ef-1234-567890abcdef\"")
    assert response["data"]["response"] == "@belf Whoops! An error occurred. There are no rules with id 12345678-abcd-90ef-1234-567890abcdef"
  end

  test "error when dropping rule with no options", %{user: user} do
    response = send_message(user, "@bot: operable:rules --drop")
    assert response["data"]["response"] == "@belf Whoops! An error occurred. ERROR! In order to drop rules you must pass either `--id` or `--for-command`"
  end

  test "listing rules", %{user: user} do
    response = send_message(user, "@bot: operable:rules --list")
    assert response["data"]["response"] == "@belf Whoops! An error occurred. ERROR! You must specify a command using the --for-command option."

    response = send_message(user, "@bot: operable:rules --list --for-command=\"operable:st-echo\"")
    decoded_response = Poison.decode!(response["data"]["response"])
    assert decoded_response["command"] == "operable:st-echo"
  end

  test "dropping a rule via a rule id", %{user: user} do
    response = send_message(user, "@bot: operable:rules --list --for-command=\"operable:st-echo\"")
    decoded_response = Poison.decode!(response["data"]["response"])
    assert decoded_response["id"] != nil

    response = send_message(user, "@bot: operable:rules --drop --id=\"#{decoded_response["id"]}\"")
    assert response["data"]["response"] == "Dropped rule with id `#{decoded_response["id"]}`:\n* when command is operable:st-echo must have operable:st-echo\n"
  end
end
