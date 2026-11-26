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

defmodule Edgehog.Devices.Device.Changes.EmitFleetTelemetry do
  @moduledoc """
  Emits the fleet telemetry when a device is created or destroyed, or when its
  `online` status changes.

  The previous state is read before the write (locking the row) so that
  upserts, which don't expose the old values, are tracked as well. Events are
  emitted only once the transaction has been committed.
  """

  use Ash.Resource.Change

  alias Edgehog.Devices.Device
  alias Edgehog.Devices.Telemetry
  alias Edgehog.Tenants.Tenant

  require Ash.Query

  @previous_state_key :fleet_telemetry_previous_state

  @impl Ash.Resource.Change
  def change(%{action: %{type: :create}} = changeset, _opts, _context) do
    changeset
    |> Ash.Changeset.before_action(&store_previous_state/1)
    |> Ash.Changeset.after_transaction(&emit_on_write/2)
  end

  def change(%{action: %{type: :update}} = changeset, _opts, _context) do
    changeset
    |> Ash.Changeset.before_action(&store_previous_state/1)
    |> Ash.Changeset.after_transaction(&emit_on_write/2)
  end

  def change(%{action: %{type: :destroy}} = changeset, _opts, _context) do
    changeset
    |> Ash.Changeset.before_action(&store_previous_state/1)
    |> Ash.Changeset.after_transaction(&emit_on_destroy/2)
  end

  @impl Ash.Resource.Change
  def atomic(_changeset, _opts, _context), do: {:not_atomic, "emits telemetry"}

  defp store_previous_state(changeset) do
    previous_state =
      case changeset.action do
        %{type: type} when type in [:update, :destroy] ->
          fetch_previous_state(changeset, id: changeset.data.id)

        %{upsert?: true} ->
          fetch_previous_state(changeset, upsert_identity(changeset))

        _ ->
          nil
      end

    Ash.Changeset.put_context(changeset, @previous_state_key, previous_state)
  end

  defp upsert_identity(changeset) do
    [
      realm_id: Ash.Changeset.get_attribute(changeset, :realm_id),
      device_id: Ash.Changeset.get_attribute(changeset, :device_id)
    ]
  end

  defp fetch_previous_state(changeset, filter) do
    query =
      Device
      |> Ash.Query.filter(^filter)
      |> Ash.Query.select([:id, :online])
      |> Ash.Query.lock("FOR UPDATE")

    case Ash.read_one(query, tenant: changeset.tenant, authorize?: false) do
      {:ok, nil} -> nil
      {:ok, device} -> %{online: device.online}
      {:error, error} -> raise error
    end
  end

  defp emit_on_write(changeset, {:ok, device} = result) do
    previous_state = Map.get(changeset.context, @previous_state_key)
    tenant_slug = tenant_slug(changeset, device)

    if is_nil(previous_state), do: Telemetry.device_created(tenant_slug)

    case {previous_online?(previous_state), device.online} do
      {false, true} -> Telemetry.device_connected(tenant_slug)
      {true, false} -> Telemetry.device_disconnected(tenant_slug)
      _ -> :ok
    end

    result
  end

  defp emit_on_write(_changeset, result), do: result

  defp emit_on_destroy(changeset, {:ok, device} = result) do
    tenant_slug = tenant_slug(changeset, device)

    Telemetry.device_destroyed(tenant_slug)

    if previous_online?(Map.get(changeset.context, @previous_state_key)),
      do: Telemetry.device_disconnected(tenant_slug)

    result
  end

  defp emit_on_destroy(_changeset, result), do: result

  defp previous_online?(%{online: online}), do: online
  defp previous_online?(nil), do: false

  defp tenant_slug(%{tenant: %Tenant{slug: slug}}, _device), do: slug

  defp tenant_slug(_changeset, device) do
    device
    |> Ash.load!(:tenant, authorize?: false)
    |> Map.fetch!(:tenant)
    |> Map.fetch!(:slug)
  end
end
