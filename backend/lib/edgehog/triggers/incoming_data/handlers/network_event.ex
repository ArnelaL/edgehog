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

defmodule Edgehog.Triggers.IncomingData.Handlers.NetworkEvent do
  @moduledoc """
  Network Event handler
  """
  @behaviour Ash.Astarte.Triggers.HandlerBehavior

  alias Edgehog.Containers
  alias Edgehog.Containers.Calculations.ResourceEvents
  alias Edgehog.Containers.Network.Deployment.Types.Event
  alias Edgehog.Devices
  alias EdgehogWeb.Endpoint

  @impl Ash.Astarte.Triggers.HandlerBehavior
  def handle_event(event, _opts, context) do
    %{realm_id: realm_id, device_id: device_id, timestamp: timestamp, tenant: tenant} = context

    "/" <> network_id = event.path

    %{
      "status" => status,
      "message" => message
    } = event.value

    add_info = Map.get(event.value, "addInfo", [])

    with {:ok, device} <- Devices.fetch_device_by_identity(device_id, realm_id, tenant: tenant),
         {:ok, network_deployment} <-
           Containers.fetch_network_deployment(network_id, device.id, tenant: tenant) do
      raw_event = %{
        status: status,
        message: message,
        add_info: add_info,
        timestamp: timestamp
      }

      payload =
        network_deployment
        |> ResourceEvents.cast_event!(raw_event, Event)
        |> Map.put(:__type__, Event.graphql_type([]))

      topic = "#{tenant.tenant_id}:network:#{network_deployment.id}"

      Absinthe.Subscription.publish(Endpoint, payload,
        network_deployment_events: topic,
        container_deployment_events: topic,
        release_deployment_events: topic
      )

      :ok
    end
  end
end
