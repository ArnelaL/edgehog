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

defmodule EdgehogWeb.Controllers.AstarteTriggerController.ForwarderSessionStateTest do
  use EdgehogWeb.ConnCase, async: true

  import Edgehog.AstarteFixtures
  import Edgehog.DevicesFixtures

  alias Edgehog.Forwarder.Telemetry

  describe "process_event/2 for forwarder session state" do
    setup %{tenant: tenant} do
      cluster = cluster_fixture()
      realm = realm_fixture(cluster_id: cluster.id, tenant: tenant)
      device = device_fixture(realm_id: realm.id, tenant: tenant)

      :telemetry_test.attach_event_handlers(self(), [Telemetry.session_connected_event()])

      {:ok, realm: realm, device: device}
    end

    test "emits the telemetry when a session is reported as connected", context do
      %{conn: conn, realm: realm, device: device, tenant: tenant} = context

      assert response(post_event(conn, realm, device, tenant, "/token/status", "Connected"), 200)

      assert_receive {[:edgehog, :forwarder, :session, :connected], _ref, %{count: 1},
                      %{tenant_slug: slug}}

      assert slug == tenant.slug
    end

    test "ignores sessions that are still connecting", context do
      %{conn: conn, realm: realm, device: device, tenant: tenant} = context

      assert response(post_event(conn, realm, device, tenant, "/token/status", "Connecting"), 200)

      refute_receive {[:edgehog, :forwarder, :session, :connected], _, _, _}
    end
  end

  defp post_event(conn, realm, device, tenant, path, value) do
    event = %{
      device_id: device.device_id,
      event: %{
        type: "incoming_data",
        interface: "io.edgehog.devicemanager.ForwarderSessionState",
        path: path,
        value: value
      },
      timestamp: DateTime.to_iso8601(DateTime.utc_now())
    }

    conn
    |> put_req_header("astarte-realm", realm.name)
    |> post(Routes.astarte_trigger_path(conn, :process_event, tenant.slug), event)
  end
end
