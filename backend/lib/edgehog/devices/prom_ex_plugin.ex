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

defmodule Edgehog.Devices.PromExPlugin do
  @moduledoc """
  PromEx plugin for tenant fleet metrics.

  Device metrics are driven by the telemetry events emitted when a device is
  created, destroyed, connects or disconnects, so that no change is missed
  between two polls. Forwarder sessions are stored only on Astarte, so they are
  counted from the events emitted when they are requested and when the device
  reports them as connected.
  """

  use PromEx.Plugin

  alias Edgehog.Devices.Telemetry
  alias Edgehog.Forwarder.Telemetry, as: ForwarderTelemetry

  @impl PromEx.Plugin
  def event_metrics(_opts) do
    [
      Event.build(
        :fleet_device_event_metrics,
        [
          sum([:edgehog, :fleet, :connected_devices],
            event_name: Telemetry.connected_changed_event(),
            measurement: :delta,
            tags: [:tenant_slug],
            description: "Number of connected devices managed by a tenant.",
            reporter_options: [prometheus_type: :gauge]
          ),
          sum([:edgehog, :fleet, :total_devices],
            event_name: Telemetry.total_changed_event(),
            measurement: :delta,
            tags: [:tenant_slug],
            description: "Total number of devices managed by a tenant.",
            reporter_options: [prometheus_type: :gauge]
          )
        ]
      ),
      Event.build(
        :fleet_forwarder_session_event_metrics,
        [
          counter([:edgehog, :fleet, :forwarder_sessions, :requested, :total],
            event_name: ForwarderTelemetry.session_requested_event(),
            measurement: :count,
            tags: [:tenant_slug],
            description: "Number of forwarder sessions requested to devices of a tenant."
          ),
          counter([:edgehog, :fleet, :forwarder_sessions, :connected, :total],
            event_name: ForwarderTelemetry.session_connected_event(),
            measurement: :count,
            tags: [:tenant_slug],
            description:
              "Number of forwarder sessions reported as connected by devices of a tenant."
          )
        ]
      )
    ]
  end
end
