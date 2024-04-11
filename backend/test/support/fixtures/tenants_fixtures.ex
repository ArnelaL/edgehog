#
# This file is part of Edgehog.
#
# Copyright 2021 SECO Mind Srl
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

defmodule Edgehog.TenantsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Edgehog.Tenants` context.
  """

  @doc """
  Generate a unique tenant name.
  """
  def unique_tenant_name, do: "Tenant #{System.unique_integer([:positive])}"

  @doc """
  Generate a unique tenant slug.
  """
  def unique_tenant_slug, do: "tenant-#{System.unique_integer([:positive])}"

  @doc """
  Generate a tenant.
  """
  def tenant_fixture(opts \\ []) do
    public_key =
      X509.PrivateKey.new_ec(:secp256r1)
      |> X509.PublicKey.derive()
      |> X509.PublicKey.to_pem()

    params =
      opts
      |> Enum.into(%{
        name: unique_tenant_name(),
        slug: unique_tenant_slug(),
        public_key: public_key
      })

    Edgehog.Tenants.Tenant
    |> Ash.Changeset.for_create(:create, params)
    |> Ash.create!()
  end
end
