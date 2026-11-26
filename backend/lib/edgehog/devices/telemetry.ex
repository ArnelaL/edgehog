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

defmodule Edgehog.Devices.Telemetry do
  @moduledoc """
  Emits the telemetry events of the devices fleet.

  Events can be emitted on the following topics:

  - `[:edgehog, :devices, :total_changed]` when a device is created or
    destroyed. Measurements contain `delta` (`1` or `-1`). Metadata contains
    `tenant_slug`.
  - `[:edgehog, :devices, :connected_changed]` when a device goes online or
    offline, including when an online device is destroyed. Measurements
    contain `delta` (`1` or `-1`). Metadata contains `tenant_slug`.
  """

  @total_changed [:edgehog, :devices, :total_changed]
  @connected_changed [:edgehog, :devices, :connected_changed]

  def total_changed_event, do: @total_changed

  def connected_changed_event, do: @connected_changed

  def device_created(tenant_slug), do: execute(@total_changed, 1, tenant_slug)

  def device_destroyed(tenant_slug), do: execute(@total_changed, -1, tenant_slug)

  def device_connected(tenant_slug), do: execute(@connected_changed, 1, tenant_slug)

  def device_disconnected(tenant_slug), do: execute(@connected_changed, -1, tenant_slug)

  defp execute(event, delta, tenant_slug) do
    :telemetry.execute(event, %{delta: delta}, %{tenant_slug: tenant_slug})
  end
end
