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

defmodule Edgehog.Containers.DeploymentResources do
  @moduledoc """
  Shared helpers for loading and collecting unique child resources of release
  and container deployments.
  """

  alias Edgehog.Containers.Container
  alias Edgehog.Containers.Release

  @container_child_resources_load [
    :id,
    :container_id,
    image_deployment: [:id, :image_id],
    network_deployments: [:id, :network_id],
    volume_deployments: [:id, :volume_id],
    file_binds: [:id],
    env_files: [:id]
  ]

  @release_child_resources_load [
    container_deployments: @container_child_resources_load
  ]

  def release_child_resources_load, do: @release_child_resources_load

  def container_child_resources_load, do: @container_child_resources_load

  def collect_unique_resources(%Release.Deployment{} = deployment) do
    container_deployments = Enum.uniq_by(deployment.container_deployments, & &1.id)

    %{
      deployment: [deployment],
      container: container_deployments,
      image:
        container_deployments
        |> Enum.map(& &1.image_deployment)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq_by(& &1.id),
      volume:
        container_deployments
        |> Enum.flat_map(& &1.volume_deployments)
        |> Enum.uniq_by(& &1.id),
      network:
        container_deployments
        |> Enum.flat_map(& &1.network_deployments)
        |> Enum.uniq_by(& &1.id),
      env_file:
        container_deployments
        |> Enum.flat_map(& &1.env_files)
        |> Enum.uniq_by(& &1.id),
      file_bind:
        container_deployments
        |> Enum.flat_map(& &1.file_binds)
        |> Enum.uniq_by(& &1.id)
    }
  end

  def collect_unique_resources(%Container.Deployment{} = container_deployment) do
    %{
      container: [container_deployment],
      image:
        if(container_deployment.image_deployment,
          do: [container_deployment.image_deployment],
          else: []
        ),
      volume: Enum.uniq_by(container_deployment.volume_deployments, & &1.id),
      network: Enum.uniq_by(container_deployment.network_deployments, & &1.id),
      env_file: Enum.uniq_by(container_deployment.env_files, & &1.id),
      file_bind: Enum.uniq_by(container_deployment.file_binds, & &1.id)
    }
  end
end
