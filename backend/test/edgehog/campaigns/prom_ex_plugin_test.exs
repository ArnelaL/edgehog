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

defmodule Edgehog.Campaigns.PromExPluginTest do
  use Edgehog.DataCase, async: false

  import Edgehog.CampaignsFixtures

  alias Edgehog.Campaigns
  alias Edgehog.Campaigns.PromExPlugin

  setup do
    %{tenant: Edgehog.TenantsFixtures.tenant_fixture()}
  end

  test "exports the campaign configuration when a campaign starts", %{tenant: tenant} do
    start_metrics()

    campaign =
      campaign_with_targets_fixture(3,
        tenant: tenant,
        mechanism_type: :firmware_upgrade,
        campaign_mechanism: [
          max_in_progress_operations: 2,
          max_failure_percentage: 25.0,
          request_retries: 5
        ]
      )

    assert scrape() == []

    Campaigns.mark_campaign_in_progress!(campaign, tenant: tenant)

    labels = ~s({mechanism_type="firmware_upgrade",tenant_slug="#{tenant.slug}"})
    lines = scrape()

    for {metric, value} <- [
          started: 1,
          targets: 3,
          max_in_progress_operations: 2,
          target_groups: 1,
          max_retries: 5,
          max_failure_percentage: 25
        ] do
      assert "edgehog_campaigns_#{metric}_total#{labels} #{value}" in lines or
               "edgehog_campaigns_#{metric}_total#{labels} #{value}.0" in lines
    end
  end

  defp start_metrics do
    [events] = PromExPlugin.event_metrics([])
    assert PromExPlugin in Edgehog.PromEx.plugins()

    start_supervised!(
      {TelemetryMetricsPrometheus.Core,
       name: :campaigns_metrics_test,
       metrics: events.metrics,
       require_seconds: false,
       start_async: false}
    )
  end

  defp scrape do
    :campaigns_metrics_test
    |> TelemetryMetricsPrometheus.Core.scrape()
    |> String.split("\n")
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
  end
end
