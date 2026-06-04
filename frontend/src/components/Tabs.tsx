// This file is part of Edgehog.
//
// Copyright 2021-2026 SECO Mind Srl
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

import intersection from "lodash/intersection";
import keyBy from "lodash/keyBy";
import keys from "lodash/keys";
import union from "lodash/union";
import uniqBy from "lodash/uniqBy";
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

import Button from "@/components/Button";
import SegmentedControl from "@/components/SegmentedControl";
import "./Tabs.scss";

type EventKey = string;

type TabRef = {
  eventKey: EventKey;
  title: React.ReactNode;
};

type TabsContextValue = {
  activeKey: EventKey | undefined;
  registerTab: (tabRef: TabRef) => void;
  unregisterTab: (eventKey: EventKey) => void;
};

const defaultContextValue: TabsContextValue = {
  activeKey: undefined,
  registerTab: () => {},
  unregisterTab: () => {},
};

const TabsContext = createContext<TabsContextValue>(defaultContextValue);

type TabButtonProps = {
  isActive: boolean;
  tabRef: TabRef;
};

const TabButton = ({ isActive, tabRef }: TabButtonProps) => {
  const className = [
    "tab-button border-0",
    isActive ? "px-4 py-3 fw-bold active" : "px-4 py-2 text-muted",
  ].join(" ");
  return (
    <Button variant="text" className={className}>
      {tabRef.title}
    </Button>
  );
};

type TabsProps = {
  children?: React.ReactNode;
  className?: string;
  defaultActiveKey?: EventKey;
  tabsOrder?: EventKey[];
  onChange?: (tabKey: string) => void;
};

const Tabs = ({
  children,
  className,
  defaultActiveKey,
  tabsOrder = [],
  onChange = () => {},
}: TabsProps) => {
  const [selectedKey, setSelectedKey] = useState<EventKey | undefined>(
    defaultActiveKey,
  );

  const [tabRefs, setTabRefs] = useState<TabRef[]>([]);
  const registerTab = useCallback((tabRef: TabRef) => {
    setTabRefs((refs) => {
      return uniqBy([...refs, tabRef], "eventKey");
    });
  }, []);

  const unregisterTab = useCallback((eventKey: EventKey) => {
    setTabRefs((tabRefs) => {
      const newTabRefs = tabRefs.filter(
        (tabRef) => tabRef.eventKey !== eventKey,
      );
      return newTabRefs;
    });
  }, []);

  const activeKey = useMemo(
    () =>
      tabRefs.some((tabRef) => tabRef.eventKey === selectedKey)
        ? selectedKey
        : tabRefs[0]?.eventKey,
    [tabRefs, selectedKey],
  );

  const contextValue = useMemo(
    () => ({
      activeKey,
      registerTab,
      unregisterTab,
    }),
    [activeKey, registerTab, unregisterTab],
  );

  const sortedTabRefs = useMemo(() => {
    const tabRefsByEventKey = keyBy(tabRefs, "eventKey");
    const eventKeys = keys(tabRefsByEventKey);
    // 1. intersect tabsOrder with eventKeys to pick eventKeys in the correct order
    // 2. union the result with eventKeys to pick the remaining eventKeys
    const sortedEventKeys = union(
      intersection(tabsOrder, eventKeys),
      eventKeys,
    );
    return sortedEventKeys.map((eventKey) => tabRefsByEventKey[eventKey]);
  }, [tabRefs, tabsOrder]);

  const handleOnChange = useCallback(
    (selectedKey: string) => {
      setSelectedKey(selectedKey);
      onChange(selectedKey);
    },
    [setSelectedKey, onChange],
  );

  return (
    <TabsContext.Provider value={contextValue}>
      <div className={className}>
        {sortedTabRefs.length > 0 && (
          <SegmentedControl
            activeId={activeKey}
            items={sortedTabRefs}
            getItemId={(tabRef) => tabRef.eventKey}
            onChange={handleOnChange}
            showControls
          >
            {(tabRef, isActive) => (
              <TabButton tabRef={tabRef} isActive={isActive} />
            )}
          </SegmentedControl>
        )}
        {children}
      </div>
    </TabsContext.Provider>
  );
};

const useTabs = (): TabsContextValue => {
  const tabsContextValue = useContext(TabsContext);
  if (tabsContextValue == null) {
    throw new Error("TabsContext has not been Provided");
  }
  return tabsContextValue;
};

type CommonProps<A, B> = {
  [a in keyof (A & B)]: (A & B)[a];
};

type Spread<A, B> = (CommonProps<A, B> & A) | B;

// Use custom Spread type to get all correct props of "div", since TypeScript does not
// support spreading yet: https://github.com/microsoft/TypeScript/issues/10727
type TabProps = Spread<
  React.ComponentProps<"div">,
  {
    children?: React.ReactNode;
    eventKey: EventKey;
    title?: string;
  }
>;

const Tab = ({ eventKey, title, ...restProps }: TabProps) => {
  const { registerTab, unregisterTab, activeKey } = useTabs();

  useEffect(() => {
    registerTab({ eventKey, title });
    return () => unregisterTab(eventKey);
  }, [registerTab, unregisterTab, eventKey, title]);

  const isActive = activeKey === eventKey;

  if (!isActive) {
    return null;
  }

  return <div {...restProps} />;
};

export { Tab };

export default Tabs;
