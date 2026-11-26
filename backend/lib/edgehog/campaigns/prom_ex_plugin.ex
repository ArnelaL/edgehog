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

defmodule Edgehog.Campaigns.PromExPlugin do
  @moduledoc """
  PromEx plugin for the Edgehog campaigns feature.

  Every metric is a counter updated when a campaign starts, labeled by
  `tenant_slug` and `mechanism_type`:

  - `edgehog_campaigns_started_total`
  - `edgehog_campaigns_targets_total`: targets of the started campaigns
  - `edgehog_campaigns_max_in_progress_operations_total`: targets that can be
    active at the same time, summed over the started campaigns
  - `edgehog_campaigns_target_groups_total`: groups targeted by the started
    campaigns
  - `edgehog_campaigns_max_retries_total`: `request_retries` summed over the
    started campaigns
  - `edgehog_campaigns_max_failure_percentage_total`: `max_failure_percentage`
    summed over the started campaigns

  The averages per campaign are obtained dividing a metric by
  `edgehog_campaigns_started_total`.
  """

  use PromEx.Plugin

  alias Edgehog.Campaigns.Telemetry

  @tags [:tenant_slug, :mechanism_type]

  @impl PromEx.Plugin
  def event_metrics(_opts) do
    event = Telemetry.campaign_started_event()

    [
      Event.build(
        :campaigns_campaign_event_metrics,
        [
          counter([:edgehog, :campaigns, :started, :total],
            event_name: event,
            measurement: :count,
            description: "Number of campaigns started.",
            tags: @tags,
            tag_values: &Map.take(&1, @tags)
          )
          | Enum.map(sums(), &sum_metric(&1, event))
        ]
      )
    ]
  end

  defp sums do
    [
      {:targets, "Number of targets of the started campaigns."},
      {:max_in_progress_operations,
       "Number of targets that can be active at the same time in the started campaigns."},
      {:target_groups, "Number of device groups targeted by the started campaigns."},
      {:max_retries, "Request retries allowed by the started campaigns."},
      {:max_failure_percentage, "Maximum failure percentage of the started campaigns."}
    ]
  end

  defp sum_metric({measurement, description}, event) do
    sum([:edgehog, :campaigns, measurement, :total],
      event_name: event,
      measurement: measurement,
      description: description,
      tags: @tags,
      tag_values: &Map.take(&1, @tags),
      reporter_options: [prometheus_type: :counter]
    )
  end
end
