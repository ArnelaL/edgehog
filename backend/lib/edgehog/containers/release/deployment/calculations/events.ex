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

defmodule Edgehog.Containers.Release.Deployment.Calculations.Events do
  @moduledoc false
  use Ash.Resource.Calculation

  alias Ash.Resource.Calculation
  alias Edgehog.Containers.Calculations.ResourceEvents
  alias Edgehog.Containers.Container
  alias Edgehog.Containers.DeploymentResources
  alias Edgehog.Containers.EnvFile
  alias Edgehog.Containers.FileBind
  alias Edgehog.Containers.Image
  alias Edgehog.Containers.Network
  alias Edgehog.Containers.Release
  alias Edgehog.Containers.Volume

  @resource_configs %{
    deployment: {
      "io.edgehog.devicemanager.apps.DeploymentEvent",
      :id,
      Release.Deployment.Types.Event,
      :deployment_event
    },
    container: {
      "io.edgehog.devicemanager.apps.ContainerEvent",
      :container_id,
      Container.Deployment.Types.Event,
      :container_deployment_event
    },
    image: {
      "io.edgehog.devicemanager.apps.ImageEvent",
      :image_id,
      Image.Deployment.Types.Event,
      :image_deployment_event
    },
    volume: {
      "io.edgehog.devicemanager.apps.VolumeEvent",
      :volume_id,
      Volume.Deployment.Types.Event,
      :volume_deployment_event
    },
    network: {
      "io.edgehog.devicemanager.apps.NetworkEvent",
      :network_id,
      Network.Deployment.Types.Event,
      :network_deployment_event
    },
    env_file: {
      "io.edgehog.devicemanager.apps.EnvFileEvent",
      :id,
      EnvFile.Types.Event,
      :env_file_event
    },
    file_bind: {
      "io.edgehog.devicemanager.apps.FileBindEvent",
      :id,
      FileBind.Types.Event,
      :file_bind_event
    }
  }

  @impl Calculation
  def load(_query, _opts, _context) do
    [:id, device: [:device_id, :appengine_client]] ++
      DeploymentResources.release_child_resources_load()
  end

  @impl Calculation
  def calculate(deployments, opts, context) do
    args = Map.get(context, :arguments, %{})
    limit = Map.get(args, :limit) || Keyword.get(opts, :limit)
    only_errors? = Map.get(args, :only_errors, false)

    # Only push limit down to Astarte when not filtering in Elixir;
    # otherwise Astarte could return only recent non-error events and miss an older error.
    astarte_query = if only_errors?, do: [], else: maybe_add_limit([], limit)

    Enum.map(deployments, fn deployment ->
      calculate_for_deployment(deployment, astarte_query, only_errors?, limit)
    end)
  end

  defp calculate_for_deployment(
         %{device: %{appengine_client: nil}},
         _query,
         _only_errors?,
         _limit
       ),
       do: nil

  defp calculate_for_deployment(deployment, query, only_errors?, limit) do
    %{device_id: device_id, appengine_client: appengine_client} = deployment.device

    {events, any_ok?} =
      deployment
      |> DeploymentResources.collect_unique_resources()
      |> Enum.reduce({[], false}, fn {resource_type, records}, acc ->
        fetch_category_events(appengine_client, device_id, resource_type, records, query, acc)
      end)

    if any_ok? do
      events
      |> maybe_filter_errors(only_errors?)
      |> Enum.sort(&compare_events_desc/2)
      |> maybe_take_limit(limit)
    else
      nil
    end
  end

  defp fetch_category_events(appengine_client, device_id, resource_type, records, query, acc) do
    config = Map.fetch!(@resource_configs, resource_type)

    Enum.reduce(records, acc, fn record, {events_acc, ok?} ->
      fetch_events(
        appengine_client,
        device_id,
        record,
        config,
        query,
        events_acc,
        ok?
      )
    end)
  end

  defp fetch_events(
         appengine_client,
         device_id,
         record,
         {interface, resource_id_key, event_type, union_tag},
         query,
         events_acc,
         ok?
       ) do
    case ResourceEvents.fetch_events(
           appengine_client,
           device_id,
           record,
           interface,
           resource_id_key,
           event_type,
           query
         ) do
      {:ok, fetched_events} ->
        wrapped = Enum.map(fetched_events, &%Ash.Union{type: union_tag, value: &1})
        {wrapped ++ events_acc, true}

      {:error, _reason} ->
        {events_acc, ok?}
    end
  end

  defp compare_events_desc(%Ash.Union{value: %{timestamp: nil}}, %Ash.Union{
         value: %{timestamp: nil}
       }),
       do: true

  defp compare_events_desc(%Ash.Union{value: %{timestamp: nil}}, _), do: false
  defp compare_events_desc(_, %Ash.Union{value: %{timestamp: nil}}), do: true

  defp compare_events_desc(%Ash.Union{value: %{timestamp: ts_a}}, %Ash.Union{
         value: %{timestamp: ts_b}
       }) do
    DateTime.compare(ts_a, ts_b) != :lt
  end

  defp maybe_filter_errors(events, false), do: events

  defp maybe_filter_errors(events, true) do
    Enum.filter(events, fn %Ash.Union{value: %{status: status}} -> status == :error end)
  end

  defp maybe_take_limit(events, nil), do: events
  defp maybe_take_limit(events, limit), do: Enum.take(events, limit)

  defp maybe_add_limit(opts, nil), do: opts
  defp maybe_add_limit(opts, limit), do: [{:limit, limit} | opts]
end
