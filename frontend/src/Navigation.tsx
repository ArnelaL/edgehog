/*
  This file is part of Edgehog.

  Copyright 2021-2023 SECO Mind Srl

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  SPDX-License-Identifier: Apache-2.0
*/

import { useCallback } from "react";
import { generatePath as routerGeneratePath, matchPath } from "react-router";
import { useNavigate as useRouterNavigate } from "react-router";
import { Link as RouterLink } from "react-router-dom";
import type { LinkProps as RouterLinkProps } from "react-router-dom";

enum Route {
  devices = "/devices",
  devicesEdit = "/devices/:deviceId/edit",
  deviceGroups = "/device-groups",
  deviceGroupsEdit = "/device-groups/:deviceGroupId/edit",
  deviceGroupsNew = "/device-groups/new",
  systemModels = "/system-models",
  systemModelsNew = "/system-models/new",
  systemModelsEdit = "/system-models/:systemModelId/edit",
  hardwareTypes = "/hardware-types",
  hardwareTypesNew = "/hardware-types/new",
  hardwareTypesEdit = "/hardware-types/:hardwareTypeId/edit",
  baseImageCollections = "/base-image-collections",
  baseImageCollectionsNew = "/base-image-collections/new",
  baseImageCollectionsEdit = "/base-image-collections/:baseImageCollectionId/edit",
  baseImagesNew = "/base-image-collections/:baseImageCollectionId/base-images/new",
  baseImagesEdit = "/base-image-collections/:baseImageCollectionId/base-images/:baseImageId/edit",
  updateChannels = "/update-channels",
  updateChannelsEdit = "/update-channels/:updateChannelId/edit",
  updateChannelsNew = "/update-channels/new",
  updateCampaigns = "/update-campaigns",
  updateCampaignsEdit = "/update-campaigns/:updateCampaignId",
  login = "/login",
  logout = "/logout",
}

const matchPaths = (routes: Route | Route[], path: string) => {
  const r = Array.isArray(routes) ? routes : [routes];
  return r.some((route: Route) => matchPath(route, path) != null);
};

type ParametricRoute =
  | { route: Route.devices }
  | { route: Route.devicesEdit; params: { deviceId: string } }
  | { route: Route.deviceGroups }
  | { route: Route.deviceGroupsEdit; params: { deviceGroupId: string } }
  | { route: Route.deviceGroupsNew }
  | { route: Route.systemModels }
  | { route: Route.systemModelsNew }
  | { route: Route.systemModelsEdit; params: { systemModelId: string } }
  | { route: Route.hardwareTypes }
  | { route: Route.hardwareTypesNew }
  | { route: Route.hardwareTypesEdit; params: { hardwareTypeId: string } }
  | { route: Route.baseImageCollections }
  | { route: Route.baseImageCollectionsNew }
  | {
      route: Route.baseImageCollectionsEdit;
      params: { baseImageCollectionId: string };
    }
  | {
      route: Route.baseImagesEdit;
      params: { baseImageCollectionId: string; baseImageId: string };
    }
  | {
      route: Route.baseImagesNew;
      params: { baseImageCollectionId: string };
    }
  | { route: Route.updateChannels }
  | { route: Route.updateChannelsEdit; params: { updateChannelId: string } }
  | { route: Route.updateChannelsNew }
  | { route: Route.updateCampaigns }
  | { route: Route.updateCampaignsEdit; params: { updateCampaignId: string } }
  | { route: Route.login }
  | { route: Route.logout };

type LinkProps = Omit<RouterLinkProps, "to"> & ParametricRoute;

const generatePath = (route: ParametricRoute): string => {
  if ("params" in route && route.params) {
    return routerGeneratePath(route.route, route.params);
  }
  return route.route;
};

const Link = (props: LinkProps) => {
  let to, forwardProps;
  if ("params" in props) {
    const { route, params, ...rest } = props;
    to = routerGeneratePath(route, params);
    forwardProps = rest;
  } else {
    const { route, ...rest } = props;
    to = route;
    forwardProps = rest;
  }

  return <RouterLink to={to} {...forwardProps} />;
};

const useNavigate = () => {
  const routerNavigate = useRouterNavigate();
  const navigate = useCallback(
    (route: ParametricRoute | string) => {
      const path = typeof route === "string" ? route : generatePath(route);
      routerNavigate(path);
    },
    [routerNavigate]
  );
  return navigate;
};

export { Link, Route, matchPaths, useNavigate };
export type { LinkProps, ParametricRoute };
