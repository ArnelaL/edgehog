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

defmodule Edgehog.Campaigns.Telemetry do
  @moduledoc """
  Emits the telemetry events of the campaigns feature.

  Events can be emitted on the following topics:

  - `[:edgehog, :campaigns, :campaign, :started]` when a campaign starts,
    i.e. when its configuration is frozen and its targets begin to receive
    operations. Measurements contain `count` (always `1`), `targets` (number
    of targets), `max_in_progress_operations` (number of targets that can be
    active at the same time), `target_groups` (number of device groups of the
    campaign channel), `max_retries` (the `request_retries` of the mechanism)
    and `max_failure_percentage` (rounded to a whole percent). Metadata contains `tenant_slug`,
    `mechanism_type`, `request_retries`, `request_timeout_seconds`.
  """

  @campaign_started [:edgehog, :campaigns, :campaign, :started]

  def campaign_started_event, do: @campaign_started

  @doc """
  Emits the campaign started event.

  The campaign must have the `:tenant`, `:total_target_count` and
  `channel: :target_groups` fields loaded.
  """
  def campaign_started(campaign) do
    %{type: mechanism_type, value: mechanism} = campaign.campaign_mechanism

    measurements = %{
      count: 1,
      targets: campaign.total_target_count,
      max_in_progress_operations: mechanism.max_in_progress_operations,
      target_groups: length(campaign.channel.target_groups),
      max_retries: mechanism.request_retries,
      max_failure_percentage: round(mechanism.max_failure_percentage)
    }

    metadata = %{
      tenant_slug: campaign.tenant.slug,
      mechanism_type: mechanism_type,
      request_retries: mechanism.request_retries,
      request_timeout_seconds: mechanism.request_timeout_seconds
    }

    :telemetry.execute(@campaign_started, measurements, metadata)
  end
end
