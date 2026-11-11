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

defmodule EdgehogWeb.Schema.Query.ContainerResourceEventsTest do
  use EdgehogWeb.GraphqlCase, async: true

  import Edgehog.ContainersFixtures
  import Edgehog.DevicesFixtures
  import Edgehog.FilesFixtures

  alias Edgehog.Astarte.Device.ResourceEvent
  alias Edgehog.Containers.EnvFile

  @aggregated_events_fragment """
  events {
    __typename
    ... on DeploymentEvent {
      resourceId
      deploymentStatus: status
      message
      addInfo
      timestamp
    }
    ... on ContainerDeploymentEvent {
      resourceId
      containerStatus: status
      message
      addInfo
      timestamp
    }
    ... on ImageDeploymentEvent {
      resourceId
      imageStatus: status
      message
      addInfo
      timestamp
    }
    ... on VolumeDeploymentEvent {
      resourceId
      volumeStatus: status
      message
      addInfo
      timestamp
    }
    ... on NetworkDeploymentEvent {
      resourceId
      networkStatus: status
      message
      addInfo
      timestamp
    }
    ... on EnvFileEvent {
      resourceId
      envFileStatus: status
      message
      addInfo
      timestamp
    }
    ... on FileBindEvent {
      resourceId
      fileBindStatus: status
      message
      addInfo
      timestamp
    }
  }
  """

  setup %{tenant: tenant} do
    app = application_fixture(tenant: tenant)
    network = network_fixture(tenant: tenant)
    volume = volume_fixture(tenant: tenant)
    image = image_fixture(tenant: tenant)

    container_params = [
      image: image,
      volumes: [{volume, "/data"}],
      networks: [network]
    ]

    release =
      release_fixture(
        application_id: app.id,
        tenant: tenant,
        containers: 1,
        container_params: container_params
      )

    device = device_fixture(tenant: tenant)

    deployment =
      deployment_fixture(device_id: device.id, release_id: release.id, tenant: tenant)

    [container_deployment] =
      deployment
      |> Ash.load!(
        [
          container_deployments: [
            :image_deployment,
            :volume_deployments,
            :network_deployments
          ]
        ],
        tenant: tenant
      )
      |> Map.fetch!(:container_deployments)

    [volume_deployment] = container_deployment.volume_deployments
    [network_deployment] = container_deployment.network_deployments

    env_file =
      EnvFile
      |> Ash.Changeset.for_create(
        :create,
        %{
          container_deployment_id: container_deployment.id,
          device_id: device.id,
          file_name: ".env"
        },
        tenant: tenant
      )
      |> Ash.create!()

    file_mount =
      file_mount_fixture(
        tenant: tenant,
        container_id: container_deployment.container_id,
        mountpoint: "/etc/app.conf"
      )

    file_download_request = manual_file_download_request_fixture(tenant: tenant)

    file_bind =
      file_bind_fixture(
        tenant: tenant,
        container_deployment_id: container_deployment.id,
        file_mount_id: file_mount.id,
        file_download_request_id: file_download_request.id
      )

    %{
      deployment: deployment,
      device: device,
      container_deployment: container_deployment,
      image_deployment: container_deployment.image_deployment,
      volume_deployment: volume_deployment,
      network_deployment: network_deployment,
      container_id: container_deployment.container_id,
      image_id: container_deployment.image_deployment.image_id,
      volume_id: volume_deployment.volume_id,
      network_id: network_deployment.network_id,
      env_file: env_file,
      file_bind: file_bind
    }
  end

  test "returns aggregated events on deployment sorted newest first and per-resource events", %{
    tenant: tenant,
    deployment: deployment,
    device: device,
    container_deployment: container_deployment,
    image_deployment: image_deployment,
    volume_deployment: volume_deployment,
    network_deployment: network_deployment,
    container_id: container_id,
    image_id: image_id,
    volume_id: volume_id,
    network_id: network_id,
    env_file: env_file,
    file_bind: file_bind
  } do
    device_id = device.device_id
    deployment_id = deployment.id
    env_file_id = env_file.id
    file_bind_id = file_bind.id

    # 7 calls for deployment.events + 6 calls for child resource events
    expect(ResourceEvent, :get, 13, fn _client, ^device_id, interface, resource_id, [] ->
      case {interface, resource_id} do
        {"io.edgehog.devicemanager.apps.DeploymentEvent", ^deployment_id} ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Starting",
               message: "Deployment starting",
               add_info: ["release=1.0.0"],
               timestamp: ~U[2026-03-19 09:54:00Z]
             },
             %ResourceEvent.Data{
               status: "Started",
               message: "Deployment started",
               add_info: [],
               timestamp: ~U[2026-03-19 10:03:00Z]
             }
           ]}

        {"io.edgehog.devicemanager.apps.ContainerEvent", ^container_id} ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Create",
               message: "Container created",
               add_info: ["id=123"],
               timestamp: ~U[2026-03-19 10:00:00Z]
             },
             %ResourceEvent.Data{
               status: "ExecCreate",
               message: "Exec created",
               add_info: [],
               timestamp: ~U[2026-03-19 10:01:00Z]
             },
             %ResourceEvent.Data{
               status: "HealthStatus",
               message: "Healthy",
               add_info: nil,
               timestamp: ~U[2026-03-19 10:02:00Z]
             }
           ]}

        {"io.edgehog.devicemanager.apps.ImageEvent", ^image_id} ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Pull",
               message: "Image pulled",
               add_info: ["tag=latest"],
               timestamp: ~U[2026-03-19 09:59:00Z]
             }
           ]}

        {"io.edgehog.devicemanager.apps.VolumeEvent", ^volume_id} ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Mount",
               message: "Volume mounted",
               add_info: ["/data"],
               timestamp: ~U[2026-03-19 09:58:00Z]
             }
           ]}

        {"io.edgehog.devicemanager.apps.NetworkEvent", ^network_id} ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Connect",
               message: "Network connected",
               add_info: ["driver=bridge"],
               timestamp: ~U[2026-03-19 09:57:00Z]
             }
           ]}

        {"io.edgehog.devicemanager.apps.EnvFileEvent", ^env_file_id} ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Error",
               message: "Env file created",
               add_info: [".env"],
               timestamp: ~U[2026-03-19 09:56:00Z]
             }
           ]}

        {"io.edgehog.devicemanager.apps.FileBindEvent", ^file_bind_id} ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Error",
               message: "Bind mount failed",
               add_info: ["permission denied"],
               timestamp: ~U[2026-03-19 09:55:00Z]
             }
           ]}
      end
    end)

    document = """
    query($id: ID!) {
      deployment(id: $id) {
        #{@aggregated_events_fragment}
        containerDeployments {
          edges {
            node {
              events {
                resourceId
                status
                message
                addInfo
                timestamp
              }
              imageDeployment {
                events {
                  resourceId
                  status
                  message
                  addInfo
                  timestamp
                }
              }
              volumeDeployments {
                edges {
                  node {
                    events {
                      resourceId
                      status
                      message
                      addInfo
                      timestamp
                    }
                  }
                }
              }
              networkDeployments {
                edges {
                  node {
                    events {
                      resourceId
                      status
                      message
                      addInfo
                      timestamp
                    }
                  }
                }
              }
              envFiles {
                events {
                  resourceId
                  status
                  message
                  addInfo
                  timestamp
                }
              }
              fileBinds {
                events {
                  resourceId
                  status
                  message
                  addInfo
                  timestamp
                }
              }
            }
          }
        }
      }
    }
    """

    id = AshGraphql.Resource.encode_relay_id(deployment)
    container_deployment_relay_id = AshGraphql.Resource.encode_relay_id(container_deployment)
    image_deployment_relay_id = AshGraphql.Resource.encode_relay_id(image_deployment)
    volume_deployment_relay_id = AshGraphql.Resource.encode_relay_id(volume_deployment)
    network_deployment_relay_id = AshGraphql.Resource.encode_relay_id(network_deployment)
    env_file_relay_id = AshGraphql.Resource.encode_relay_id(env_file)
    file_bind_relay_id = AshGraphql.Resource.encode_relay_id(file_bind)

    result =
      [tenant: tenant, id: id, document: document]
      |> get_deployment()
      |> extract_result!()

    assert [
             %{
               "__typename" => "DeploymentEvent",
               "resourceId" => ^id,
               "deploymentStatus" => "STARTED",
               "message" => "Deployment started",
               "addInfo" => [],
               "timestamp" => "2026-03-19T10:03:00Z"
             },
             %{
               "__typename" => "ContainerDeploymentEvent",
               "resourceId" => ^container_deployment_relay_id,
               "containerStatus" => "HEALTH_STATUS",
               "message" => "Healthy",
               "addInfo" => [],
               "timestamp" => "2026-03-19T10:02:00Z"
             },
             %{
               "__typename" => "ContainerDeploymentEvent",
               "resourceId" => ^container_deployment_relay_id,
               "containerStatus" => "EXEC_CREATE",
               "message" => "Exec created",
               "addInfo" => [],
               "timestamp" => "2026-03-19T10:01:00Z"
             },
             %{
               "__typename" => "ContainerDeploymentEvent",
               "resourceId" => ^container_deployment_relay_id,
               "containerStatus" => "CREATE",
               "message" => "Container created",
               "addInfo" => ["id=123"],
               "timestamp" => "2026-03-19T10:00:00Z"
             },
             %{
               "__typename" => "ImageDeploymentEvent",
               "resourceId" => ^image_deployment_relay_id,
               "imageStatus" => "PULL",
               "message" => "Image pulled",
               "addInfo" => ["tag=latest"],
               "timestamp" => "2026-03-19T09:59:00Z"
             },
             %{
               "__typename" => "VolumeDeploymentEvent",
               "resourceId" => ^volume_deployment_relay_id,
               "volumeStatus" => "MOUNT",
               "message" => "Volume mounted",
               "addInfo" => ["/data"],
               "timestamp" => "2026-03-19T09:58:00Z"
             },
             %{
               "__typename" => "NetworkDeploymentEvent",
               "resourceId" => ^network_deployment_relay_id,
               "networkStatus" => "CONNECT",
               "message" => "Network connected",
               "addInfo" => ["driver=bridge"],
               "timestamp" => "2026-03-19T09:57:00Z"
             },
             %{
               "__typename" => "EnvFileEvent",
               "resourceId" => ^env_file_relay_id,
               "envFileStatus" => "ERROR",
               "message" => "Env file created",
               "addInfo" => [".env"],
               "timestamp" => "2026-03-19T09:56:00Z"
             },
             %{
               "__typename" => "FileBindEvent",
               "resourceId" => ^file_bind_relay_id,
               "fileBindStatus" => "ERROR",
               "message" => "Bind mount failed",
               "addInfo" => ["permission denied"],
               "timestamp" => "2026-03-19T09:55:00Z"
             },
             %{
               "__typename" => "DeploymentEvent",
               "resourceId" => ^id,
               "deploymentStatus" => "STARTING",
               "message" => "Deployment starting",
               "addInfo" => ["release=1.0.0"],
               "timestamp" => "2026-03-19T09:54:00Z"
             }
           ] = result["events"]

    assert [%{"node" => container_node}] = result["containerDeployments"]["edges"]

    assert [
             %{
               "resourceId" => ^container_deployment_relay_id,
               "status" => "CREATE",
               "message" => "Container created",
               "addInfo" => ["id=123"],
               "timestamp" => "2026-03-19T10:00:00Z"
             },
             %{
               "resourceId" => ^container_deployment_relay_id,
               "status" => "EXEC_CREATE",
               "message" => "Exec created",
               "addInfo" => [],
               "timestamp" => "2026-03-19T10:01:00Z"
             },
             %{
               "resourceId" => ^container_deployment_relay_id,
               "status" => "HEALTH_STATUS",
               "message" => "Healthy",
               "addInfo" => [],
               "timestamp" => "2026-03-19T10:02:00Z"
             }
           ] = container_node["events"]

    assert [
             %{
               "resourceId" => ^image_deployment_relay_id,
               "status" => "PULL",
               "message" => "Image pulled",
               "addInfo" => ["tag=latest"],
               "timestamp" => "2026-03-19T09:59:00Z"
             }
           ] = container_node["imageDeployment"]["events"]

    assert [
             %{
               "node" => %{
                 "events" => [
                   %{
                     "resourceId" => ^volume_deployment_relay_id,
                     "status" => "MOUNT",
                     "message" => "Volume mounted",
                     "addInfo" => ["/data"],
                     "timestamp" => "2026-03-19T09:58:00Z"
                   }
                 ]
               }
             }
           ] = container_node["volumeDeployments"]["edges"]

    assert [
             %{
               "node" => %{
                 "events" => [
                   %{
                     "resourceId" => ^network_deployment_relay_id,
                     "status" => "CONNECT",
                     "message" => "Network connected",
                     "addInfo" => ["driver=bridge"],
                     "timestamp" => "2026-03-19T09:57:00Z"
                   }
                 ]
               }
             }
           ] = container_node["networkDeployments"]["edges"]

    assert [
             %{
               "events" => [
                 %{
                   "resourceId" => ^env_file_relay_id,
                   "status" => "ERROR",
                   "message" => "Env file created",
                   "addInfo" => [".env"],
                   "timestamp" => "2026-03-19T09:56:00Z"
                 }
               ]
             }
           ] = container_node["envFiles"]

    assert [
             %{
               "events" => [
                 %{
                   "resourceId" => ^file_bind_relay_id,
                   "status" => "ERROR",
                   "message" => "Bind mount failed",
                   "addInfo" => ["permission denied"],
                   "timestamp" => "2026-03-19T09:55:00Z"
                 }
               ]
             }
           ] = container_node["fileBinds"]
  end

  test "deduplicates shared resources across multiple containers in a release", %{
    tenant: tenant
  } do
    app = application_fixture(tenant: tenant)
    shared_image = image_fixture(tenant: tenant)
    shared_network = network_fixture(tenant: tenant)
    shared_volume = volume_fixture(tenant: tenant)

    release =
      release_fixture(
        application_id: app.id,
        tenant: tenant,
        containers: 2,
        container_params: [
          image: shared_image,
          networks: [shared_network],
          volumes: [{shared_volume, "/data"}]
        ]
      )

    device = device_fixture(tenant: tenant)

    deployment =
      deployment_fixture(device_id: device.id, release_id: release.id, tenant: tenant)

    device_id = device.device_id

    # 1 deployment + 2 containers + 1 shared image + 1 shared network + 1 shared volume = 6 calls
    expect(ResourceEvent, :get, 6, fn _client, ^device_id, interface, _resource_id, [] ->
      case interface do
        "io.edgehog.devicemanager.apps.ImageEvent" ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Pull",
               message: "Shared image pulled",
               add_info: [],
               timestamp: ~U[2026-03-19 10:00:00Z]
             }
           ]}

        "io.edgehog.devicemanager.apps.NetworkEvent" ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Connect",
               message: "Shared network connected",
               add_info: [],
               timestamp: ~U[2026-03-19 10:01:00Z]
             }
           ]}

        "io.edgehog.devicemanager.apps.VolumeEvent" ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Mount",
               message: "Shared volume mounted",
               add_info: [],
               timestamp: ~U[2026-03-19 10:02:00Z]
             }
           ]}

        _ ->
          {:ok, []}
      end
    end)

    document = """
    query($id: ID!) {
      deployment(id: $id) {
        #{@aggregated_events_fragment}
      }
    }
    """

    id = AshGraphql.Resource.encode_relay_id(deployment)

    result =
      [tenant: tenant, id: id, document: document]
      |> get_deployment()
      |> extract_result!()

    assert [
             %{
               "__typename" => "VolumeDeploymentEvent",
               "volumeStatus" => "MOUNT",
               "message" => "Shared volume mounted"
             },
             %{
               "__typename" => "NetworkDeploymentEvent",
               "networkStatus" => "CONNECT",
               "message" => "Shared network connected"
             },
             %{
               "__typename" => "ImageDeploymentEvent",
               "imageStatus" => "PULL",
               "message" => "Shared image pulled"
             }
           ] = result["events"]
  end

  test "returns empty list when Astarte returns no events", %{
    tenant: tenant,
    deployment: deployment,
    device: device
  } do
    device_id = device.device_id

    # 7 calls for deployment.events + 1 call for containerDeployment.events
    expect(ResourceEvent, :get, 8, fn _client, ^device_id, _interface, _resource_id, [] ->
      {:ok, []}
    end)

    document = """
    query($id: ID!) {
      deployment(id: $id) {
        #{@aggregated_events_fragment}
        containerDeployments {
          edges {
            node {
              events {
                status
                message
                timestamp
              }
            }
          }
        }
      }
    }
    """

    id = AshGraphql.Resource.encode_relay_id(deployment)

    result =
      [tenant: tenant, id: id, document: document]
      |> get_deployment()
      |> extract_result!()

    assert result["events"] == []

    assert [%{"node" => %{"events" => []}}] =
             result["containerDeployments"]["edges"]
  end

  test "returns nil when Astarte returns an error", %{
    tenant: tenant,
    deployment: deployment,
    device: device
  } do
    device_id = device.device_id

    # 7 calls for deployment.events + 1 call for containerDeployment.events
    expect(ResourceEvent, :get, 8, fn _client, ^device_id, _interface, _resource_id, [] ->
      {:error, :astarte_error}
    end)

    document = """
    query($id: ID!) {
      deployment(id: $id) {
        #{@aggregated_events_fragment}
        containerDeployments {
          edges {
            node {
              events {
                status
                message
                timestamp
              }
            }
          }
        }
      }
    }
    """

    id = AshGraphql.Resource.encode_relay_id(deployment)

    result =
      [tenant: tenant, id: id, document: document]
      |> get_deployment()
      |> extract_result!()

    assert result["events"] == nil

    assert [%{"node" => %{"events" => nil}}] =
             result["containerDeployments"]["edges"]
  end

  test "supports limit argument on deployment events and pushes limit to Astarte", %{
    tenant: tenant,
    deployment: deployment,
    device: device
  } do
    device_id = device.device_id

    expect(ResourceEvent, :get, 7, fn _client, ^device_id, interface, _resource_id, [limit: 2] ->
      case interface do
        "io.edgehog.devicemanager.apps.DeploymentEvent" ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Started",
               message: "Deployment started",
               add_info: [],
               timestamp: ~U[2026-03-19 10:03:00Z]
             }
           ]}

        "io.edgehog.devicemanager.apps.ContainerEvent" ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Start",
               message: "Container started",
               add_info: [],
               timestamp: ~U[2026-03-19 10:02:00Z]
             }
           ]}

        "io.edgehog.devicemanager.apps.ImageEvent" ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Pull",
               message: "Image pulled",
               add_info: [],
               timestamp: ~U[2026-03-19 10:01:00Z]
             }
           ]}

        _ ->
          {:ok, []}
      end
    end)

    document = """
    query($id: ID!) {
      deployment(id: $id) {
        events(limit: 2) {
          __typename
          ... on DeploymentEvent {
            deploymentStatus: status
            message
          }
          ... on ContainerDeploymentEvent {
            containerStatus: status
            message
          }
          ... on ImageDeploymentEvent {
            imageStatus: status
            message
          }
        }
      }
    }
    """

    id = AshGraphql.Resource.encode_relay_id(deployment)

    result =
      [tenant: tenant, id: id, document: document]
      |> get_deployment()
      |> extract_result!()

    assert [
             %{
               "__typename" => "DeploymentEvent",
               "deploymentStatus" => "STARTED",
               "message" => "Deployment started"
             },
             %{
               "__typename" => "ContainerDeploymentEvent",
               "containerStatus" => "START",
               "message" => "Container started"
             }
           ] = result["events"]
  end

  test "supports onlyErrors and limit arguments without truncating errors at Astarte", %{
    tenant: tenant,
    deployment: deployment,
    device: device
  } do
    device_id = device.device_id

    # When onlyErrors is true, limit must NOT be pushed to Astarte so newer non-error events
    # cannot hide an earlier error event.
    expect(ResourceEvent, :get, 7, fn _client, ^device_id, interface, _resource_id, [] ->
      case interface do
        "io.edgehog.devicemanager.apps.DeploymentEvent" ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Stopped",
               message: "Deployment stopped",
               add_info: [],
               timestamp: ~U[2026-03-19 10:05:00Z]
             },
             %ResourceEvent.Data{
               status: "Error",
               message: "Older deployment error",
               add_info: [],
               timestamp: ~U[2026-03-19 10:01:00Z]
             }
           ]}

        "io.edgehog.devicemanager.apps.ImageEvent" ->
          {:ok,
           [
             %ResourceEvent.Data{
               status: "Error",
               message: "Latest image pull error",
               add_info: ["manifest unknown"],
               timestamp: ~U[2026-03-19 10:03:00Z]
             }
           ]}

        _ ->
          {:ok, []}
      end
    end)

    document = """
    query($id: ID!) {
      deployment(id: $id) {
        events(onlyErrors: true, limit: 1) {
          __typename
          ... on DeploymentEvent {
            deploymentStatus: status
            message
            addInfo
          }
          ... on ImageDeploymentEvent {
            imageStatus: status
            message
            addInfo
          }
        }
      }
    }
    """

    id = AshGraphql.Resource.encode_relay_id(deployment)

    result =
      [tenant: tenant, id: id, document: document]
      |> get_deployment()
      |> extract_result!()

    assert [
             %{
               "__typename" => "ImageDeploymentEvent",
               "imageStatus" => "ERROR",
               "message" => "Latest image pull error",
               "addInfo" => ["manifest unknown"]
             }
           ] = result["events"]
  end

  defp get_deployment(opts) do
    {tenant, opts} = Keyword.pop!(opts, :tenant)
    document = Keyword.fetch!(opts, :document)
    id = Keyword.fetch!(opts, :id)
    extra_variables = Keyword.get(opts, :variables, %{})
    variables = Map.put(extra_variables, "id", id)

    Absinthe.run!(document, EdgehogWeb.Schema,
      variables: variables,
      context: %{tenant: tenant, actor: %{}}
    )
  end

  defp extract_result!(result) do
    refute :errors in Map.keys(result)
    assert %{data: %{"deployment" => deployment}} = result
    assert deployment

    deployment
  end
end
