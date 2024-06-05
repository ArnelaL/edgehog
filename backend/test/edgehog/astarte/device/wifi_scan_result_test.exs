#
# This file is part of Edgehog.
#
# Copyright 2021,2022 SECO Mind Srl
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

defmodule Edgehog.Astarte.Device.WiFiScanResultTest do
  use Edgehog.DataCase, async: true

  alias Astarte.Client.AppEngine
  alias Edgehog.Astarte.Device.WiFiScanResult

  import Edgehog.AstarteFixtures
  import Edgehog.DevicesFixtures
  import Edgehog.TenantsFixtures

  @moduletag :ported_to_ash

  describe "system_status" do
    import Tesla.Mock

    setup do
      tenant = tenant_fixture()
      cluster = cluster_fixture()
      realm = realm_fixture(cluster_id: cluster.id, tenant: tenant)
      device = device_fixture(realm_id: realm.id, tenant: tenant)

      {:ok, appengine_client} =
        AppEngine.new(cluster.base_api_url, realm.name, private_key: realm.private_key)

      {:ok, cluster: cluster, realm: realm, device: device, appengine_client: appengine_client}
    end

    test "get/2 correctly parses wifi scan result data", %{
      device: device,
      appengine_client: appengine_client
    } do
      response = %{
        "data" => %{
          "ap" => [
            %{
              "channel" => 11,
              "connected" => false,
              "essid" => nil,
              "macAddress" => "01:23:45:67:89:ab",
              "rssi" => -43,
              "timestamp" => "2021-11-15 11:44:57.432516Z"
            },
            %{
              "channel" => 12,
              "connected" => true,
              "essid" => "My WiFi",
              "macAddress" => "11:22:33:44:55:66",
              "rssi" => -32,
              "timestamp" => "2021-11-15 11:44:57.432516Z"
            },
            %{
              "channel" => 4,
              "essid" => "Old WiFi",
              "macAddress" => "aa:bb:cc:ee:dd:ff",
              "rssi" => -40,
              "timestamp" => "2021-11-14 10:44:57.432516Z"
            }
          ]
        }
      }

      mock(fn
        %{method: :get, url: _api_url} ->
          json(response)
      end)

      assert {:ok, wifi_scan_results} = WiFiScanResult.get(appengine_client, device.device_id)

      assert wifi_scan_results == [
               %WiFiScanResult{
                 channel: 11,
                 connected: false,
                 essid: nil,
                 mac_address: "01:23:45:67:89:ab",
                 rssi: -43,
                 timestamp: ~U[2021-11-15 11:44:57.432516Z]
               },
               %WiFiScanResult{
                 channel: 12,
                 connected: true,
                 essid: "My WiFi",
                 mac_address: "11:22:33:44:55:66",
                 rssi: -32,
                 timestamp: ~U[2021-11-15 11:44:57.432516Z]
               },
               %WiFiScanResult{
                 channel: 4,
                 connected: nil,
                 essid: "Old WiFi",
                 mac_address: "aa:bb:cc:ee:dd:ff",
                 rssi: -40,
                 timestamp: ~U[2021-11-14 10:44:57.432516Z]
               }
             ]
    end
  end
end
