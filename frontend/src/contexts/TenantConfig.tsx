// This file is part of Edgehog.
//
// Copyright 2026 SECO Mind Srl
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react";
import type { ReactNode } from "react";
import { FormattedMessage } from "react-intl";

import { fetchGraphQL as defaultFetchGraphQL, type FetchGraphQL } from "@/api";
import Spinner from "@/components/ui/spinner/Spinner";

import { useSession } from "./Session";

const tenantQuery = `
  query Tenant_getTenant_Query {
    tenantInfo {
      config {
        enforceAllowedRegistries
      }
    }
  }
`;

type TenantConfig = {
  config: {
    enforceAllowedRegistries: boolean | null;
  };
};

type TenantConfigContextValue = TenantConfig & {
  refresh: () => Promise<void>;
};

const defaultTenantConfig: TenantConfig["config"] = {
  enforceAllowedRegistries: null,
};

const TenantConfigContext = createContext<TenantConfigContextValue | null>(
  null,
);

type TenantConfigProviderProps = {
  children: ReactNode;
  fetchGraphQL?: FetchGraphQL;
};

const TenantConfigProvider = ({
  children,
  fetchGraphQL = defaultFetchGraphQL,
}: TenantConfigProviderProps) => {
  const { session } = useSession();

  const [tenantConfigState, setTenantConfigState] = useState<{
    tenantSlug: string;
    config: TenantConfig["config"] | null;
  } | null>(null);

  useEffect(() => {
    if (!session) return;

    let cancelled = false;

    fetchGraphQL(tenantQuery, {}, session.tenantSlug, session.authToken)
      .then((response) => {
        if (cancelled) return;

        const config = response.data?.tenantInfo?.config;

        if (!config) {
          setTenantConfigState({
            tenantSlug: session.tenantSlug,
            config: null,
          });
        } else {
          setTenantConfigState({
            tenantSlug: session.tenantSlug,
            config,
          });
        }
      })
      .catch(() => {
        if (cancelled) return;
        setTenantConfigState({ tenantSlug: session.tenantSlug, config: null });
      });

    return () => {
      cancelled = true;
    };
  }, [session, fetchGraphQL]);

  const refresh = useCallback(async () => {
    if (!session) return;

    try {
      const response = await fetchGraphQL(
        tenantQuery,
        {},
        session.tenantSlug,
        session.authToken,
      );

      const config = response.data?.tenantInfo?.config;

      if (!config) {
        throw new Error("Tenant configuration not found");
      }

      setTenantConfigState({
        tenantSlug: session.tenantSlug,
        config,
      });
    } catch {
      setTenantConfigState({ tenantSlug: session.tenantSlug, config: null });
    }
  }, [session, fetchGraphQL]);

  if (!session) {
    return (
      <TenantConfigContext.Provider
        value={{ config: defaultTenantConfig, refresh: async () => {} }}
      >
        {children}
      </TenantConfigContext.Provider>
    );
  }

  const isLoadingTenantConfig =
    !tenantConfigState || tenantConfigState.tenantSlug !== session.tenantSlug;

  if (isLoadingTenantConfig) {
    return (
      <div
        className="vh-100 d-flex justify-content-center align-items-center"
        data-testid="tenant-config-context-loading"
      >
        <Spinner />
      </div>
    );
  }

  if (!tenantConfigState?.config) {
    return (
      <div
        className="vh-100 d-flex flex-column justify-content-center align-items-center"
        data-testid="tenant-config-context-error"
      >
        <h3>
          <FormattedMessage
            id="contexts.TenantConfig.error.title"
            defaultMessage="Could not fetch remote configuration."
          />
        </h3>
        <p>
          <FormattedMessage
            id="contexts.TenantConfig.error.description"
            defaultMessage="Please verify that the app is set up correctly."
          />
        </p>
      </div>
    );
  }

  return (
    <TenantConfigContext.Provider
      value={{ config: tenantConfigState.config, refresh }}
    >
      {children}
    </TenantConfigContext.Provider>
  );
};

const useTenantConfig = (): TenantConfigContextValue => {
  const contextValue = useContext(TenantConfigContext);

  if (contextValue === null) {
    throw new Error("TenantConfigContext has not been provided");
  }

  return contextValue;
};

export { TenantConfigContext, useTenantConfig };

export default TenantConfigProvider;
