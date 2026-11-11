/*
 * This file is part of Edgehog.
 *
 * Copyright 2026 SECO Mind Srl
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import { Suspense } from "react";
import { graphql, useLazyLoadQuery } from "react-relay/hooks";
import { createMockEnvironment } from "relay-test-utils";
import { describe, expect, it } from "vitest";
import { act, screen } from "@testing-library/react";

import type { DeploymentTargetsTableTest_Query } from "@/api/__generated__/DeploymentTargetsTableTest_Query.graphql";
import { renderWithProviders } from "@/setupTests";
import DeploymentTargetsTable from "./DeploymentTargetsTable";

const TEST_QUERY = graphql`
  query DeploymentTargetsTableTest_Query($id: ID!) @relay_test_operation {
    campaign(id: $id) {
      campaignTargets {
        ...DeploymentTargetsTable_CampaignTargetEdgeFragment
      }
    }
  }
`;

const TestRenderer = () => {
  const data = useLazyLoadQuery<DeploymentTargetsTableTest_Query>(TEST_QUERY, {
    id: "campaign-1",
  });

  if (!data.campaign?.campaignTargets) return null;

  return (
    <DeploymentTargetsTable
      campaignTargetsRef={data.campaign.campaignTargets}
      hiddenColumns={["state", "readiness", "retryCount", "latestAttempt"]}
    />
  );
};

describe("DeploymentTargetsTable", () => {
  it("renders error messages from DeploymentResourceEvent union members", async () => {
    const environment = createMockEnvironment();

    renderWithProviders(
      <Suspense fallback={<div>Loading</div>}>
        <TestRenderer />
      </Suspense>,
      { relayEnvironment: environment },
    );

    const operation = environment.mock.getMostRecentOperation();
    await act(async () => {
      environment.mock.resolve(operation, {
        data: {
          campaign: {
            id: "campaign-1",
            campaignTargets: {
              edges: [
                {
                  node: {
                    id: "target-1",
                    device: { id: "dev-1", name: "Device One" },
                    status: "FAILED",
                    retryCount: 0,
                    latestAttempt: null,
                    completionTimestamp: "2026-03-19T10:05:00Z",
                    deployment: {
                      id: "dep-1",
                      state: "STOPPED",
                      isReady: false,
                      events: [
                        {
                          __typename: "DeploymentEvent",
                          resourceId: "dep-1",
                          deploymentStatus: "ERROR",
                          message: "Deployment failed to start",
                          addInfo: [],
                          timestamp: "2026-03-19T10:04:00Z",
                        },
                      ],
                    },
                  },
                },
                {
                  node: {
                    id: "target-2",
                    device: { id: "dev-2", name: "Device Two" },
                    status: "FAILED",
                    retryCount: 1,
                    latestAttempt: null,
                    completionTimestamp: "2026-03-19T10:06:00Z",
                    deployment: {
                      id: "dep-2",
                      state: "PENDING",
                      isReady: false,
                      events: [
                        {
                          __typename: "ContainerDeploymentEvent",
                          resourceId: "cnt-2",
                          containerStatus: "START",
                          message: "Container started",
                          addInfo: [],
                          timestamp: "2026-03-19T10:05:00Z",
                        },
                        {
                          __typename: "ImageDeploymentEvent",
                          resourceId: "img-2",
                          imageStatus: "ERROR",
                          message: "Image pull failed",
                          addInfo: ["manifest unknown"],
                          timestamp: "2026-03-19T10:03:00Z",
                        },
                      ],
                    },
                  },
                },
                {
                  node: {
                    id: "target-3",
                    device: { id: "dev-3", name: "Device Three" },
                    status: "SUCCESSFUL",
                    retryCount: 0,
                    latestAttempt: null,
                    completionTimestamp: "2026-03-19T10:07:00Z",
                    deployment: {
                      id: "dep-3",
                      state: "STARTED",
                      isReady: true,
                      events: [
                        {
                          __typename: "DeploymentEvent",
                          resourceId: "dep-3",
                          deploymentStatus: "STARTED",
                          message: "Deployment started",
                          addInfo: [],
                          timestamp: "2026-03-19T10:07:00Z",
                        },
                      ],
                    },
                  },
                },
              ],
            },
          },
        },
      });
    });

    expect(screen.getByText("Device One")).toBeVisible();
    expect(screen.getByText("Deployment failed to start")).toBeVisible();

    expect(screen.getByText("Device Two")).toBeVisible();
    expect(screen.getByText("Image pull failed")).toBeVisible();

    expect(screen.getByText("Device Three")).toBeVisible();
    expect(screen.queryByText("Deployment started")).not.toBeInTheDocument();
  });
});
