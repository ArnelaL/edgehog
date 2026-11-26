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

defmodule EdgehogWeb.Schema.Mutation.UpdateTenantConfigTest do
  use EdgehogWeb.GraphqlCase, async: true

  test "update tenant config", %{tenant: tenant} do
    result =
      update_tenant_config_mutation(tenant: tenant, enforce_allowed_registries: true)

    tenant_id = AshGraphql.Resource.encode_relay_id(tenant)

    assert %{
             data: %{
               "updateTenantConfig" => %{
                 "result" => %{
                   "id" => ^tenant_id,
                   "config" => %{"enforceAllowedRegistries" => true}
                 }
               }
             }
           } = result
  end

  defp update_tenant_config_mutation(opts) do
    default_document = """
    mutation UpdateTenantConfig($input: UpdateTenantConfigInput!) {
      updateTenantConfig(input: $input) {
        result {
            id
            config {
              enforceAllowedRegistries
            }
          }
        }
     }
    """

    {tenant, opts} = Keyword.pop!(opts, :tenant)

    input = %{
      "config" => %{
        "enforceAllowedRegistries" => opts[:enforce_allowed_registries]
      }
    }

    variables = %{"input" => input}
    document = Keyword.get(opts, :document, default_document)

    Absinthe.run!(document, EdgehogWeb.Schema,
      variables: variables,
      context: %{tenant: tenant}
    )
  end
end
