#
# This file is part of Edgehog.
#
# Copyright 2026 SECO Mind Srl
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

defmodule Edgehog.Devices.PromExPluginTest do
  use Edgehog.DataCase, async: false

  import Edgehog.AstarteFixtures
  import Edgehog.DevicesFixtures
  import Edgehog.TenantsFixtures

  alias Edgehog.Astarte.Device.DeviceStatus
  alias Edgehog.Devices.Device
  alias Edgehog.Devices.PromExPlugin
  alias Edgehog.Forwarder.Telemetry

  describe "device fleet metrics" do
    setup do
      [devices, _] = PromExPlugin.event_metrics([])
      assert PromExPlugin in Edgehog.PromEx.plugins()

      start_supervised!(
        {TelemetryMetricsPrometheus.Core,
         name: :fleet_metrics_test,
         metrics: devices.metrics,
         require_seconds: false,
         start_async: false}
      )

      %{tenant: tenant_fixture(), other_tenant: tenant_fixture()}
    end

    test "tracks created, updated and destroyed devices per tenant", %{
      tenant: tenant,
      other_tenant: other_tenant
    } do
      online = device_fixture(tenant: tenant, online: true)
      offline = device_fixture(tenant: tenant, online: false)
      device_fixture(tenant: other_tenant, online: true)

      assert_fleet(tenant, connected: 1, total: 2)
      assert_fleet(other_tenant, connected: 1, total: 1)

      set_online(offline, tenant, true)
      assert_fleet(tenant, connected: 2, total: 2)

      # Setting the same status again doesn't change the counters
      set_online(offline, tenant, true)
      assert_fleet(tenant, connected: 2, total: 2)

      set_online(online, tenant, false)
      assert_fleet(tenant, connected: 1, total: 2)

      Ash.destroy!(offline, tenant: tenant)
      assert_fleet(tenant, connected: 0, total: 1)

      Ash.destroy!(online, tenant: tenant)
      assert_fleet(tenant, connected: 0, total: 0)
      assert_fleet(other_tenant, connected: 1, total: 1)
    end

    test "tracks devices upserted from Astarte data", %{tenant: tenant} do
      realm = realm_fixture(tenant: tenant)
      device_id = random_device_id()

      stub(DeviceStatus, :get, fn _client, _device_id ->
        {:ok, device_status_fixture(%{online: true})}
      end)

      upsert_from_astarte(tenant, realm, device_id, true)
      assert_fleet(tenant, connected: 1, total: 1)

      upsert_from_astarte(tenant, realm, device_id, true)
      assert_fleet(tenant, connected: 1, total: 1)

      upsert_from_astarte(tenant, realm, device_id, false)
      assert_fleet(tenant, connected: 0, total: 1)

      # Once the status is read, the stored status is the reported one
      stub(DeviceStatus, :get, fn _client, _device_id ->
        {:ok, device_status_fixture(%{online: false})}
      end)

      upsert_from_astarte(tenant, realm, random_device_id(), false)
      assert_fleet(tenant, connected: 0, total: 2)
    end

    test "doesn't count a device whose creation is rolled back", %{tenant: tenant} do
      device = device_fixture(tenant: tenant, online: true)

      assert {:error, _} =
               Device
               |> Ash.Changeset.for_create(
                 :create,
                 %{
                   device_id: device.device_id,
                   name: "dup",
                   realm_id: device.realm_id,
                   online: true
                 },
                 tenant: tenant
               )
               |> Ash.create()

      assert_fleet(tenant, connected: 1, total: 1)
    end
  end

  test "counts requested and connected forwarder sessions per tenant" do
    tenant_a = tenant_fixture()
    tenant_b = tenant_fixture()

    [_, metrics] = PromExPlugin.event_metrics([])

    start_supervised!(
      {TelemetryMetricsPrometheus.Core,
       name: :fleet_forwarder_requests_test,
       metrics: metrics.metrics,
       require_seconds: false,
       start_async: false}
    )

    Telemetry.session_requested(tenant_a)
    Telemetry.session_requested(tenant_a)
    Telemetry.session_requested(tenant_b)
    Telemetry.session_connected(tenant_a)

    lines =
      :fleet_forwarder_requests_test
      |> TelemetryMetricsPrometheus.Core.scrape()
      |> String.split("\n")

    assert ~s(edgehog_fleet_forwarder_sessions_requested_total{tenant_slug="#{tenant_a.slug}"} 2) in lines

    assert ~s(edgehog_fleet_forwarder_sessions_requested_total{tenant_slug="#{tenant_b.slug}"} 1) in lines

    assert ~s(edgehog_fleet_forwarder_sessions_connected_total{tenant_slug="#{tenant_a.slug}"} 1) in lines
  end

  defp set_online(device, tenant, online) do
    device
    |> Ash.Changeset.for_update(:from_device_status, %{online: online}, tenant: tenant)
    |> Ash.update!()
  end

  defp upsert_from_astarte(tenant, realm, device_id, connected) do
    Device
    |> Ash.Changeset.for_create(
      :from_astarte_data,
      %{realm_id: realm.id, device_id: device_id, connected: connected},
      tenant: tenant
    )
    |> Ash.create!()
  end

  defp assert_fleet(tenant, connected: connected, total: total) do
    lines = :fleet_metrics_test |> TelemetryMetricsPrometheus.Core.scrape() |> String.split("\n")
    labels = ~s(tenant_slug="#{tenant.slug}")

    assert ~s(edgehog_fleet_connected_devices{#{labels}} #{connected}) in lines
    assert ~s(edgehog_fleet_total_devices{#{labels}} #{total}) in lines
  end
end
