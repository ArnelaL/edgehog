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

defmodule Edgehog.Triggers.IncomingData.Handlers.ForwarderSessionState do
  @moduledoc """
  Forwarder session state handler.
  """
  @behaviour Ash.Astarte.Triggers.HandlerBehavior

  alias Edgehog.Forwarder.Telemetry

  @impl Ash.Astarte.Triggers.HandlerBehavior
  def handle_event(%{path: path, value: "Connected"}, _opts, %{tenant: tenant}) do
    case String.split(path, "/", trim: true) do
      [_session_token, "status"] -> Telemetry.session_connected(tenant)
      _ -> :ok
    end
  end

  def handle_event(_event, _opts, _context), do: :ok
end
