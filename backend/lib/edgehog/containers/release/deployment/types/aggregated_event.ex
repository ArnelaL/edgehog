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

defmodule Edgehog.Containers.Release.Deployment.Types.AggregatedEvent do
  @moduledoc false
  use Ash.Type.NewType,
    subtype_of: :union,
    constraints: [
      types: [
        deployment_event: [
          type: Edgehog.Containers.Release.Deployment.Types.Event
        ],
        container_deployment_event: [
          type: Edgehog.Containers.Container.Deployment.Types.Event
        ],
        image_deployment_event: [
          type: Edgehog.Containers.Image.Deployment.Types.Event
        ],
        volume_deployment_event: [
          type: Edgehog.Containers.Volume.Deployment.Types.Event
        ],
        network_deployment_event: [
          type: Edgehog.Containers.Network.Deployment.Types.Event
        ],
        env_file_event: [
          type: Edgehog.Containers.EnvFile.Types.Event
        ],
        file_bind_event: [
          type: Edgehog.Containers.FileBind.Types.Event
        ]
      ]
    ]

  use AshGraphql.Type

  @impl AshGraphql.Type
  def graphql_type(_), do: :deployment_resource_event

  @impl AshGraphql.Type
  def graphql_unnested_unions(_constraints) do
    [
      :deployment_event,
      :container_deployment_event,
      :image_deployment_event,
      :volume_deployment_event,
      :network_deployment_event,
      :env_file_event,
      :file_bind_event
    ]
  end
end
