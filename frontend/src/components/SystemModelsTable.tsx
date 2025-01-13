/*
  This file is part of Edgehog.

  Copyright 2021-2025 SECO Mind Srl

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
import { FormattedMessage } from "react-intl";
import { graphql, usePaginationFragment } from "react-relay/hooks";

import type { SystemModelsTable_PaginationQuery } from "../api/__generated__/SystemModelsTable_PaginationQuery.graphql";
import type {
  SystemModelsTable_SystemModelsFragment$key,
  SystemModelsTable_SystemModelsFragment$data,
} from "../api/__generated__/SystemModelsTable_SystemModelsFragment.graphql";

import Table, { createColumnHelper } from "components/Table";
import { Link, Route } from "Navigation";

// We use graphql fields below in columns configuration
/* eslint-disable relay/unused-fields */
const SYSTEM_MODELS_TABLE_FRAGMENT = graphql`
  fragment SystemModelsTable_SystemModelsFragment on RootQueryType
  @refetchable(queryName: "SystemModelsTable_PaginationQuery") {
    systemModels(first: $first, after: $after)
      @connection(key: "SystemModelsTable_systemModels") {
      edges {
        node {
          id
          handle
          name
          hardwareType {
            name
          }
          partNumbers {
            edges {
              node {
                partNumber
              }
            }
          }
        }
      }
    }
  }
`;

type TableRecord = NonNullable<
  NonNullable<
    SystemModelsTable_SystemModelsFragment$data["systemModels"]
  >["edges"]
>[number]["node"];

const columnHelper = createColumnHelper<TableRecord>();
const columns = [
  columnHelper.accessor("name", {
    header: () => (
      <FormattedMessage
        id="components.SystemModelsTable.nameTitle"
        defaultMessage="System Model Name"
      />
    ),
    cell: ({ row, getValue }) => (
      <Link
        route={Route.systemModelsEdit}
        params={{ systemModelId: row.original.id }}
      >
        {getValue()}
      </Link>
    ),
  }),
  columnHelper.accessor("handle", {
    header: () => (
      <FormattedMessage
        id="components.SystemModelsTable.handleTitle"
        defaultMessage="Handle"
      />
    ),
    cell: ({ getValue }) => <span className="text-nowrap">{getValue()}</span>,
  }),
  columnHelper.accessor((row) => row.hardwareType?.name, {
    id: "hardwareType",
    header: () => (
      <FormattedMessage
        id="components.SystemModelsTable.hardwareType"
        defaultMessage="Hardware Type"
      />
    ),
    cell: ({ getValue }) => <span className="text-nowrap">{getValue()}</span>,
  }),
  columnHelper.accessor("partNumbers", {
    header: () => (
      <FormattedMessage
        id="components.SystemModelsTable.partNumbersTitle"
        defaultMessage="Part Numbers"
      />
    ),
    cell: ({ getValue }) =>
      getValue().edges?.map(({ node: { partNumber } }, index) => (
        <React.Fragment key={partNumber}>
          {index > 0 && ", "}
          <span className="text-nowrap">{partNumber}</span>
        </React.Fragment>
      )),
    enableSorting: false,
  }),
];

type Props = {
  className?: string;
  systemModelsRef: SystemModelsTable_SystemModelsFragment$key;
};

const SystemModelsTable = ({ className, systemModelsRef }: Props) => {
  const { data } = usePaginationFragment<
    SystemModelsTable_PaginationQuery,
    SystemModelsTable_SystemModelsFragment$key
  >(SYSTEM_MODELS_TABLE_FRAGMENT, systemModelsRef);

  const tableData = data.systemModels?.edges?.map((edge) => edge.node) ?? [];

  return <Table className={className} columns={columns} data={tableData} />;
};

export default SystemModelsTable;
