# This file is part of Edgehog.
#
# Copyright 2023 - 2026 SECO Mind Srl
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

defmodule Edgehog.Tenants.Reconciler.AstarteResources do
  @moduledoc """
  Elixir representation of astarte resources

  The module loads the resources in the appropriate folders and loads them into
  standard elixir data structures.
  """

  @interfaces_glob "priv/astarte_resources/interfaces/majors/*.json"
  @delivery_policies_glob "priv/astarte_resources/delivery_policies/*.json.eex"
  @triggers_glob "priv/astarte_resources/trigger_templates/*.json.eex"

  @interfaces Path.wildcard(@interfaces_glob)
  @delivery_policies Path.wildcard(@delivery_policies_glob)
  @trigger_templates Path.wildcard(@triggers_glob)

  @resources_hash :erlang.md5(@interfaces ++ @delivery_policies ++ @trigger_templates)

  def __mix_recompile__? do
    current =
      Path.wildcard(@interfaces_glob) ++
        Path.wildcard(@delivery_policies_glob) ++
        Path.wildcard(@triggers_glob)

    :erlang.md5(current) != @resources_hash
  end

  def load_interfaces do
    Enum.map(@interfaces, fn interface ->
      interface
      |> File.read!()
      |> Jason.decode!()
    end)
  end

  def load_delivery_policies do
    Enum.map(@delivery_policies, &File.read!/1)
  end

  def load_trigger_templates do
    Enum.map(@trigger_templates, &File.read!/1)
  end
end
