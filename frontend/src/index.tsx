/*
  This file is part of Edgehog.

  Copyright 2021-2022 SECO Mind Srl

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

import React from "react";
import ReactDOM from "react-dom";
import { RelayEnvironmentProvider } from "react-relay/hooks";
import { BrowserRouter as RouterProvider } from "react-router-dom";

import { fetchGraphQL, relayEnvironment } from "api";
import AuthProvider from "contexts/Auth";
import I18nProvider from "i18n";
import App from "./App";
import "./index.scss";

ReactDOM.render(
  <React.StrictMode>
    <RelayEnvironmentProvider environment={relayEnvironment}>
      <AuthProvider fetchGraphQL={fetchGraphQL}>
        <RouterProvider>
          <I18nProvider>
            <App />
          </I18nProvider>
        </RouterProvider>
      </AuthProvider>
    </RelayEnvironmentProvider>
  </React.StrictMode>,
  document.getElementById("root"),
);
