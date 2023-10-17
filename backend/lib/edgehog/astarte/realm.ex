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

defmodule Edgehog.Astarte.Realm do
  use Ecto.Schema
  import Ecto.Changeset
  import Edgehog.ChangesetValidation

  alias Edgehog.Astarte.Cluster
  alias Edgehog.Astarte.Device

  schema "realms" do
    field :name, :string
    field :private_key, :string
    field :tenant_id, :id
    belongs_to :cluster, Cluster
    has_many :devices, Device

    timestamps()
  end

  @doc false
  def changeset(realm, attrs) do
    realm
    |> cast(attrs, [:name, :private_key])
    |> validate_required([:name, :private_key])
    |> foreign_key_constraint(:cluster_id)
    |> unique_constraint([:name, :tenant_id])
    |> unique_constraint([:name, :cluster_id])
    |> validate_realm_name(:name)
    |> validate_pem_private_key(:private_key)
  end
end
