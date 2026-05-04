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

defmodule EdgehogWeb.Schema.Subscriptions.Campaign.CampaignTargetSubscriptionsTest do
  @moduledoc false
  use EdgehogWeb.SubsCase

  import Edgehog.CampaignsFixtures

  alias Edgehog.Campaigns

  test "receive data on campaign target update for a specific campaign", %{
    socket: socket,
    tenant: tenant
  } do
    campaign =
      campaign_with_targets_fixture(2, tenant: tenant, mechanism_type: :deployment_deploy)

    [campaign_target] =
      campaign
      |> Ash.load!(:campaign_targets)
      |> Map.get(:campaign_targets, [])
      |> Enum.take(1)

    subscribe(socket,
      variables: %{
        "campaignId" => AshGraphql.Resource.encode_relay_id(campaign)
      }
    )

    Campaigns.mark_target_as_successful(campaign_target)

    assert_push "subscription:data", push
    assert_updated("campaignTargetsByCampaign", campaign_targets_data, push)

    assert campaign_targets_data["id"] == AshGraphql.Resource.encode_relay_id(campaign_target)
  end

  test "receives multiple updates for the same campaign", %{
    socket: socket,
    tenant: tenant
  } do
    campaign =
      campaign_with_targets_fixture(2, tenant: tenant, mechanism_type: :deployment_deploy)

    [t1, t2] =
      campaign
      |> Ash.load!(:campaign_targets)
      |> Map.get(:campaign_targets)

    subscribe(socket,
      variables: %{
        "campaignId" => AshGraphql.Resource.encode_relay_id(campaign)
      }
    )

    Campaigns.mark_target_as_successful(t1)
    assert_push "subscription:data", _

    Campaigns.mark_target_as_successful(t2)
    assert_push "subscription:data", _
  end

  test "payload contains expected fields", %{
    socket: socket,
    tenant: tenant
  } do
    campaign =
      campaign_with_targets_fixture(1, tenant: tenant, mechanism_type: :deployment_deploy)

    [target] =
      campaign
      |> Ash.load!(:campaign_targets)
      |> Map.get(:campaign_targets)

    subscribe(socket,
      variables: %{
        "campaignId" => AshGraphql.Resource.encode_relay_id(campaign)
      }
    )

    Campaigns.mark_target_as_successful(target)

    assert_push "subscription:data", push
    assert_updated("campaignTargetsByCampaign", data, push)

    assert Map.has_key?(data, "id")
    assert Map.has_key?(data, "status")
    assert Map.has_key?(data, "device")
  end

  test "does not receive updates for a different campaign", %{
    socket: socket,
    tenant: tenant
  } do
    campaign1 =
      campaign_with_targets_fixture(1, tenant: tenant, mechanism_type: :deployment_deploy)

    campaign2 =
      campaign_with_targets_fixture(1, tenant: tenant, mechanism_type: :deployment_deploy)

    [target1] =
      campaign1
      |> Ash.load!(:campaign_targets)
      |> Map.get(:campaign_targets)

    [target2] =
      campaign2
      |> Ash.load!(:campaign_targets)
      |> Map.get(:campaign_targets)

    subscribe(socket,
      variables: %{
        "campaignId" => AshGraphql.Resource.encode_relay_id(campaign1)
      }
    )

    Campaigns.mark_target_as_successful(target2)

    refute_push "subscription:data", _

    Campaigns.mark_target_as_successful(target1)

    assert_push "subscription:data", _
  end

  defp subscribe(socket, opts) do
    default_sub_gql = """
    subscription($campaignId: ID!) {
      campaignTargetsByCampaign(campaignId: $campaignId) {
        updated {
          id
          status
          device {
            id
            name
          }
        }
      }
    }
    """

    sub_gql = Keyword.get(opts, :query, default_sub_gql)
    variables = Keyword.get(opts, :variables, %{})

    ref = push_doc(socket, sub_gql, variables: variables)
    assert_reply ref, :ok, %{subscriptionId: subscription_id}

    subscription_id
  end
end
