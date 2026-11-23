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

defmodule Ash.Audit do
  @moduledoc """
  An Ash auditing plugin.

  This extension allows to setup audit events on a resource:

  -  `Ash.Audit.Transformers.ResolveConfiguration` resolves the action types
     and actions
  -  `Ash.Audit.Transformers.ApplyConfiguration`:
       - for create, update, destroy, adds a change at the beginning of the action
         that calls `Edgehog.Audit.AuditService` to register the event
       - for manual actions, it does the same through a preparation

  The event contains the actor only if the extension is configured to do so.

  ## Example

  ```elixir
  audit_log do
    # audit only updates, and named create/destroy actions, skipping any other
    # create/destroy action of the resource
    action_types [:update]
    actions [:create_manual, :destroy_if_dangling]
  end
  ```
  """

  alias Ash.Audit.Transformers

  @audit_log %Spark.Dsl.Section{
    name: :audit_log,
    describe: """
    Configures what is audited on the resource.
    """,
    schema: [
      action_types: [
        type: {:list, :atom},
        default: [:create, :update, :destroy],
        doc:
          "Whitelist of action types that should be included in the audit logs. Defaults to `[:create, :update, :destroy]`."
      ],
      actions: [
        type: {:list, :atom},
        default: [],
        doc:
          "Whitelist of actions that should be included in the audit logs, whatever their type is. Defaults to none."
      ],
      actor?: [
        type: :boolean,
        default: true,
        doc: "Whether to store the actor or not when possible."
      ]
    ],
    entities: []
  }

  # credo:disable-for-next-line
  use Spark.Dsl.Extension,
    transformers: [Transformers.ResolveConfiguration, Transformers.ApplyConfiguration],
    sections: [@audit_log]
end

defmodule Ash.Audit.Info do
  @moduledoc """
  Utility functions.

  They can return various information about the `audit_log` configuration section of a resource.
  """

  use Spark.InfoGenerator, extension: Ash.Audit, sections: [@audit_log]
  alias Spark.Dsl.Extension

  def actor?(dsl_state) do
    Extension.get_opt(dsl_state, [:audit_log], :actor?, true)
  end

  def action_types(dsl_state) do
    Extension.get_opt(dsl_state, [:audit_log], :action_types, [:create, :update, :destroy])
  end

  def actions(dsl_state) do
    Extension.get_opt(dsl_state, [:audit_log], :actions, [])
  end
end
