#
# This file is part of Edgehog.
#
# Copyright 2022 SECO Mind Srl
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
#

defmodule Edgehog.GroupsTest do
  use Edgehog.DataCase, async: true

  alias Edgehog.Groups

  describe "device_groups" do
    alias Edgehog.Groups.DeviceGroup
    alias Edgehog.Devices

    import Edgehog.AstarteFixtures
    import Edgehog.DevicesFixtures
    import Edgehog.GroupsFixtures

    @invalid_attrs %{handle: nil, name: nil, selector: nil}

    test "list_device_groups/0 returns all device_groups" do
      device_group = device_group_fixture()
      assert Groups.list_device_groups() == [device_group]
    end

    test "list_devices_in_group/0 returns empty list with no devices" do
      device_group = device_group_fixture()
      assert Groups.list_devices_in_group(device_group) == []
    end

    test "list_devices_in_group/0 returns devices matching the group selector" do
      device_group = device_group_fixture(selector: ~s<"foo" in tags>)

      realm =
        cluster_fixture()
        |> realm_fixture()

      {:ok, device_1} =
        device_fixture(realm)
        |> Devices.update_device(%{tags: ["foo", "baz"]})

      {:ok, _device_2} =
        device_fixture(realm, name: "Device 2", device_id: "9FXwmtRtRuqC48DEOjOj7Q")
        |> Devices.update_device(%{tags: ["bar"]})

      assert Groups.list_devices_in_group(device_group) == [device_1]
    end

    test "get_groups_for_device_ids/0 returns a device id -> groups map" do
      device_group_foo =
        device_group_fixture(name: "Foo", handle: "foo", selector: ~s<"foo" in tags>)

      device_group_baz =
        device_group_fixture(name: "Baz", handle: "baz", selector: ~s<"baz" in tags>)

      device_group_bar =
        device_group_fixture(name: "Bar", handle: "bar", selector: ~s<"bar" in tags>)

      realm =
        cluster_fixture()
        |> realm_fixture()

      {:ok, device_1} =
        device_fixture(realm)
        |> Devices.update_device(%{tags: ["foo", "baz"]})

      {:ok, device_2} =
        device_fixture(realm, name: "Device 2", device_id: "9FXwmtRtRuqC48DEOjOj7Q")
        |> Devices.update_device(%{tags: ["baz"]})

      {:ok, device_3} =
        device_fixture(realm, name: "Device 3", device_id: "FMFTT25iQ7eod3KlojoFMg")
        |> Devices.update_device(%{tags: ["bar"]})

      {:ok, device_4} =
        device_fixture(realm, name: "Device 4", device_id: "SSshD9aaQWa2ce0Ic327qw")
        |> Devices.update_device(%{tags: ["fizz"]})

      device_ids = [
        device_1.id,
        device_2.id,
        device_3.id,
        device_4.id
      ]

      result = Groups.get_groups_for_device_ids(device_ids)

      assert Map.get(result, device_1.id) |> length() == 2

      device_1_groups = Map.get(result, device_1.id)

      assert device_group_foo in device_1_groups
      assert device_group_baz in device_1_groups

      assert [device_group_baz] == Map.get(result, device_2.id)
      assert [device_group_bar] == Map.get(result, device_3.id)
      assert [] == Map.get(result, device_4.id)
    end

    test "get_groups_for_device_ids/1 ignores devices that are not requested" do
      device_group_foo =
        device_group_fixture(name: "Foo", handle: "foo", selector: ~s<"foo" in tags>)

      realm =
        cluster_fixture()
        |> realm_fixture()

      {:ok, device_1} =
        device_fixture(realm)
        |> Devices.update_device(%{tags: ["foo", "baz"]})

      {:ok, device_2} =
        device_fixture(realm, name: "Device 2", device_id: "9FXwmtRtRuqC48DEOjOj7Q")
        |> Devices.update_device(%{tags: ["foo", "baz"]})

      device_ids = [device_1.id]

      result = Groups.get_groups_for_device_ids(device_ids)

      assert [device_group_foo] == Map.get(result, device_1.id)
      refute Map.has_key?(result, device_2.id)
    end

    test "get_groups_for_device_ids/0 reuses the same groups in the result map, without copying them" do
      _device_group_foo =
        device_group_fixture(name: "Foo", handle: "foo", selector: ~s<"foo" in tags>)

      realm =
        cluster_fixture()
        |> realm_fixture()

      {:ok, device_1} =
        device_fixture(realm)
        |> Devices.update_device(%{tags: ["foo"]})

      {:ok, device_2} =
        device_fixture(realm, name: "Device 2", device_id: "9FXwmtRtRuqC48DEOjOj7Q")
        |> Devices.update_device(%{tags: ["foo"]})

      device_ids = [
        device_1.id,
        device_2.id
      ]

      result = Groups.get_groups_for_device_ids(device_ids)

      [device_group_foo_d1] = Map.get(result, device_1.id)
      [device_group_foo_d2] = Map.get(result, device_2.id)

      assert :erts_debug.same(device_group_foo_d1, device_group_foo_d2)
    end

    test "fetch_device_group/1 returns the device_group with given id" do
      device_group = device_group_fixture()
      assert Groups.fetch_device_group(device_group.id) == {:ok, device_group}
    end

    test "fetch_device_group/1 returns {:error, :not_found} for unexisting device group" do
      assert Groups.fetch_device_group(12_421) == {:error, :not_found}
    end

    test "create_device_group/1 with valid data creates a device_group" do
      valid_attrs = %{handle: "test-devices", name: "Test Devices", selector: ~s<"test" in tags>}

      assert {:ok, %DeviceGroup{} = device_group} = Groups.create_device_group(valid_attrs)
      assert device_group.handle == "test-devices"
      assert device_group.name == "Test Devices"
      assert device_group.selector == ~s<"test" in tags>
    end

    test "create_device_group/1 with empty data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Groups.create_device_group(@invalid_attrs)
    end

    test "create_device_group/1 with invalid handle returns error changeset" do
      attrs = %{handle: "invalid handle", name: "Test Devices", selector: ~s<"test" in tags>}

      assert {:error, %Ecto.Changeset{}} = Groups.create_device_group(attrs)
    end

    test "create_device_group/1 with invalid selector returns error changeset" do
      attrs = %{handle: "test-devices", name: "Test Devices", selector: "invalid selector"}

      assert {:error, %Ecto.Changeset{}} = Groups.create_device_group(attrs)
    end

    test "update_device_group/2 with valid data updates the device_group" do
      device_group = device_group_fixture()

      update_attrs = %{
        handle: "updated-test-devices",
        name: "Updated Test Devices",
        selector: ~s<"test" in tags and attributes["custom:is_updated"] == true>
      }

      assert {:ok, %DeviceGroup{} = device_group} =
               Groups.update_device_group(device_group, update_attrs)

      assert device_group.handle == "updated-test-devices"
      assert device_group.name == "Updated Test Devices"

      assert device_group.selector ==
               ~s<"test" in tags and attributes["custom:is_updated"] == true>
    end

    test "update_device_group/2 with empty data returns error changeset" do
      device_group = device_group_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Groups.update_device_group(device_group, @invalid_attrs)

      assert {:ok, device_group} == Groups.fetch_device_group(device_group.id)
    end

    test "update_device_group/1 with invalid handle returns error changeset" do
      device_group = device_group_fixture()

      attrs = %{handle: "invalid updated handle"}

      assert {:error, %Ecto.Changeset{}} = Groups.update_device_group(device_group, attrs)

      assert {:ok, device_group} == Groups.fetch_device_group(device_group.id)
    end

    test "update_device_group/1 with invalid selector returns error changeset" do
      device_group = device_group_fixture()

      attrs = %{selector: "invalid updated selector"}

      assert {:error, %Ecto.Changeset{}} = Groups.update_device_group(device_group, attrs)

      assert {:ok, device_group} == Groups.fetch_device_group(device_group.id)
    end

    test "delete_device_group/1 deletes the device_group" do
      device_group = device_group_fixture()
      assert {:ok, %DeviceGroup{}} = Groups.delete_device_group(device_group)
      assert {:error, :not_found} == Groups.fetch_device_group(device_group.id)
    end

    test "change_device_group/1 returns a device_group changeset" do
      device_group = device_group_fixture()
      assert %Ecto.Changeset{} = Groups.change_device_group(device_group)
    end
  end
end
