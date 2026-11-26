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

defmodule Edgehog.Campaigns.Campaign.Changes.EmitStartedTelemetry do
  @moduledoc """
  Emits the campaign started telemetry once the campaign has been marked as
  in progress and the transaction has been committed.
  """

  use Ash.Resource.Change

  alias Edgehog.Campaigns.Telemetry

  @impl Ash.Resource.Change
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_transaction(changeset, fn _changeset, result ->
      with {:ok, campaign} <- result do
        campaign
        |> Ash.load!([:tenant, :total_target_count, channel: :target_groups])
        |> Telemetry.campaign_started()
      end

      result
    end)
  end
end
