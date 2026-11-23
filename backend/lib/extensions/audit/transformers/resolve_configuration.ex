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

defmodule Ash.Audit.Transformers.ResolveConfiguration do
  @moduledoc """
  An Ash Audit extension transformer that resolves the configuration and produces
  the list of audited actions.

  Flow:
  - collects the actions whose type belongs to the `action_types`
  - collects the actions named in the `actions`, whatever their type is
  - merges the two lists, removing duplicates
  """

  use Spark.Dsl.Transformer

  alias Ash.Audit.Info
  alias Spark.Dsl.Transformer

  @valid_action_types [:create, :update, :destroy, :action]

  @impl Spark.Dsl.Transformer
  def after?(Ash.Resource.Transformers.DefaultAccept), do: true
  def after?(Ash.Resource.Transformers.SetPrimaryActions), do: true
  def after?(_other), do: false

  @impl Spark.Dsl.Transformer
  def transform(dsl_state) do
    action_types = Info.action_types(dsl_state)
    actions = Info.actions(dsl_state)

    resolved =
      Enum.uniq(
        resolve_actions_of_types(dsl_state, action_types) ++ resolve_actions(dsl_state, actions)
      )

    dsl_state
    |> Transformer.persist(:resolved_audited_actions, resolved)
    |> then(&{:ok, &1})
  end

  defp resolve_actions_of_types(dsl_state, types) do
    case Enum.reject(types, &(&1 in @valid_action_types)) do
      [] ->
        dsl_state
        |> Ash.Resource.Info.actions()
        |> Enum.filter(fn action -> action.type in types end)

      unknown ->
        raise Spark.Error.DslError,
          path: [:audit_log],
          message:
            "unsupported action types #{inspect(unknown)}, expected one of #{inspect(@valid_action_types)}"
    end
  end

  defp resolve_actions(dsl_state, actions) do
    Enum.reduce(actions, [], &validate_action_exists(dsl_state, &1, &2))
  end

  defp validate_action_exists(dsl_state, action, validated) do
    case Ash.Resource.Info.action(dsl_state, action) do
      nil ->
        raise Spark.Error.DslError,
          path: [:audit_log],
          message: "no action named #{inspect(action)} on this resource"

      %{type: action_type} when action_type not in @valid_action_types ->
        raise Spark.Error.DslError,
          path: [:audit_log],
          message:
            "unsupported type #{inspect(action_type)} for action #{inspect(action)} on this resource"

      action ->
        [action | validated]
    end
  end
end
