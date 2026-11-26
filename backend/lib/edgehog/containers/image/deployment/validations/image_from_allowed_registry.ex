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

defmodule Edgehog.Containers.Image.Deployment.Validations.ImageFromAllowedRegistry do
  @moduledoc false

  use Ash.Resource.Validation

  alias Edgehog.Containers.AllowedRegistry
  alias Edgehog.Tenants.Tenant

  require Ash.Query

  @impl Ash.Resource.Validation
  def validate(changeset, _opts, %{tenant: tenant}) do
    image = Ash.Changeset.get_argument(changeset, :image)

    case tenant_config(tenant) do
      %{enforce_allowed_registries: true} ->
        validate_allowed_registry(image.registry_host, tenant)

      _ ->
        :ok
    end
  end

  defp validate_allowed_registry(registry_host, tenant) do
    if allowed_registry?(registry_host, tenant) do
      :ok
    else
      {:error, field: :image, message: registry_error_message(registry_host)}
    end
  end

  defp allowed_registry?(registry_host, tenant)
       when is_binary(registry_host) and not is_nil(tenant) do
    AllowedRegistry
    |> Ash.Query.filter(fragment("lower(?) = lower(?)", registry, ^registry_host))
    |> Ash.exists?(tenant: tenant, authorize?: false)
  end

  defp allowed_registry?(_registry_host, _tenant), do: false

  defp registry_error_message(registry_host) when is_binary(registry_host) do
    "Registry host #{registry_host} is not in the list of allowed registries."
  end

  defp registry_error_message(_registry_host) do
    "Registry host is not set for the image, and the tenant has enforce_allowed_registries enabled."
  end

  defp tenant_config(%Tenant{config: config}), do: config

  defp tenant_config(tenant_id) when is_integer(tenant_id) do
    case Ash.get(Tenant, tenant_id, authorize?: false) do
      {:ok, %Tenant{config: config}} -> config
      _ -> nil
    end
  end

  defp tenant_config(_tenant), do: nil
end
