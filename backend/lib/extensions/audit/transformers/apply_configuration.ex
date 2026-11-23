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

defmodule Ash.Audit.Transformers.ApplyConfiguration do
  @moduledoc """
  An Ash Audit extension transformer that applies audit hooks to the actions
  resolved by `Ash.Audit.Transformers.ResolveConfiguration`.

  Create/update/destroy actions get an audit change attached
  (`Edgehog.Audit.Changes.RegisterEvent`), while manual actions get an
  audit preparation attached (`Edgehog.Audit.Preparations.RegisterEvent`): read
  and manual actions do not support `Ash.Resource.Change`s, but only
  `Ash.Resource.Preparation`s.
  """

  use Spark.Dsl.Transformer

  alias Ash.Audit.Info
  alias Ash.Resource.Builder
  alias Edgehog.Audit.Changes
  alias Edgehog.Audit.Preparations
  alias Spark.Dsl.Transformer

  @change_action_types [:create, :update, :destroy]
  @preparation_action_types [:action]

  @impl Spark.Dsl.Transformer
  def after?(Ash.Audit.Transformers.ResolveConfiguration), do: true
  def after?(_other), do: false

  @impl Spark.Dsl.Transformer
  def transform(dsl_state) do
    resolved_actions = Transformer.get_persisted(dsl_state, :resolved_audited_actions)
    opts = [actor?: Info.actor?(dsl_state)]

    dsl_state =
      Enum.reduce(resolved_actions, dsl_state, fn action, dsl_state ->
        field = entity_field(action.type)
        entities = Map.get(action, field, [])

        {:ok, auditor} = auditor(action.type, opts)

        resolved = resolve_entities(field, entities, auditor)

        Transformer.replace_entity(
          dsl_state,
          [:actions],
          Map.put(action, field, resolved),
          &(&1.name == action.name && &1.type == action.type)
        )
      end)

    {:ok, dsl_state}
  end

  defp entity_field(type) when type in @change_action_types, do: :changes
  defp entity_field(type) when type in @preparation_action_types, do: :preparations

  defp auditor(:action, opts) do
    Transformer.build_entity(
      Ash.Resource.Dsl,
      [:actions, :action],
      :prepare,
      preparation: {Preparations.RegisterEvent, opts}
    )
  end

  defp auditor(type, opts) when type in @change_action_types do
    Builder.build_action_change({Changes.RegisterEvent, opts})
  end

  defp resolve_entities(:changes, entities, auditor) do
    [auditor | entities]
  end

  defp resolve_entities(:preparations, entities, auditor) do
    entities ++ [auditor]
  end
end
