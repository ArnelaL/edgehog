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

import { graphql } from "react-relay/hooks";

export const DEPLOYMENT_RESOURCE_EVENT_FIELDS_FRAGMENT = graphql`
  fragment deploymentResourceEvents_eventFields on DeploymentResourceEvent {
    __typename
    ... on DeploymentEvent {
      resourceId
      deploymentStatus: status
      message
      addInfo
      timestamp
    }
    ... on ContainerDeploymentEvent {
      resourceId
      containerStatus: status
      message
      addInfo
      timestamp
    }
    ... on ImageDeploymentEvent {
      resourceId
      imageStatus: status
      message
      addInfo
      timestamp
    }
    ... on VolumeDeploymentEvent {
      resourceId
      volumeStatus: status
      message
      addInfo
      timestamp
    }
    ... on NetworkDeploymentEvent {
      resourceId
      networkStatus: status
      message
      addInfo
      timestamp
    }
    ... on EnvFileEvent {
      resourceId
      envFileStatus: status
      message
      addInfo
      timestamp
    }
    ... on FileBindEvent {
      resourceId
      fileBindStatus: status
      message
      addInfo
      timestamp
    }
  }
`;

export type ResourceEventType =
  | "DeploymentEvent"
  | "ContainerDeploymentEvent"
  | "ImageDeploymentEvent"
  | "VolumeDeploymentEvent"
  | "NetworkDeploymentEvent"
  | "EnvFileEvent"
  | "FileBindEvent";

export type Event = {
  readonly __typename: ResourceEventType | string;
  readonly resourceId: string;
  readonly status: string;
  readonly message: string;
  readonly addInfo: readonly string[];
  readonly timestamp?: string | null;
};

export type RawUnionEvent =
  | {
      readonly __typename: "DeploymentEvent";
      readonly resourceId: string;
      readonly deploymentStatus: string;
      readonly message: string;
      readonly addInfo: readonly string[];
      readonly timestamp?: string | null;
    }
  | {
      readonly __typename: "ContainerDeploymentEvent";
      readonly resourceId: string;
      readonly containerStatus: string;
      readonly message: string;
      readonly addInfo: readonly string[];
      readonly timestamp?: string | null;
    }
  | {
      readonly __typename: "ImageDeploymentEvent";
      readonly resourceId: string;
      readonly imageStatus: string;
      readonly message: string;
      readonly addInfo: readonly string[];
      readonly timestamp?: string | null;
    }
  | {
      readonly __typename: "VolumeDeploymentEvent";
      readonly resourceId: string;
      readonly volumeStatus: string;
      readonly message: string;
      readonly addInfo: readonly string[];
      readonly timestamp?: string | null;
    }
  | {
      readonly __typename: "NetworkDeploymentEvent";
      readonly resourceId: string;
      readonly networkStatus: string;
      readonly message: string;
      readonly addInfo: readonly string[];
      readonly timestamp?: string | null;
    }
  | {
      readonly __typename: "EnvFileEvent";
      readonly resourceId: string;
      readonly envFileStatus: string;
      readonly message: string;
      readonly addInfo: readonly string[];
      readonly timestamp?: string | null;
    }
  | {
      readonly __typename: "FileBindEvent";
      readonly resourceId: string;
      readonly fileBindStatus: string;
      readonly message: string;
      readonly addInfo: readonly string[];
      readonly timestamp?: string | null;
    }
  | {
      readonly __typename: "%other";
    };

export const normalizeUnionEvent = (
  rawEvent: RawUnionEvent | null | undefined,
): Event | null => {
  if (!rawEvent) return null;

  let status: string;
  switch (rawEvent.__typename) {
    case "DeploymentEvent":
      status = rawEvent.deploymentStatus;
      break;
    case "ContainerDeploymentEvent":
      status = rawEvent.containerStatus;
      break;
    case "ImageDeploymentEvent":
      status = rawEvent.imageStatus;
      break;
    case "VolumeDeploymentEvent":
      status = rawEvent.volumeStatus;
      break;
    case "NetworkDeploymentEvent":
      status = rawEvent.networkStatus;
      break;
    case "EnvFileEvent":
      status = rawEvent.envFileStatus;
      break;
    case "FileBindEvent":
      status = rawEvent.fileBindStatus;
      break;
    default:
      return null;
  }

  return {
    __typename: rawEvent.__typename,
    resourceId: rawEvent.resourceId,
    status,
    message: rawEvent.message,
    addInfo: rawEvent.addInfo,
    timestamp: rawEvent.timestamp,
  };
};

export const findLatestErrorEvent = (
  events: readonly RawUnionEvent[] | null | undefined,
): Event | null => {
  if (!events) return null;

  for (const rawEvent of events) {
    const event = normalizeUnionEvent(rawEvent);
    if (event?.status === "ERROR") {
      return event;
    }
  }

  return null;
};
