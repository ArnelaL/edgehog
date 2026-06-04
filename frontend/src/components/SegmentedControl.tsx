import React, { useRef } from "react";
import Nav from "react-bootstrap/Nav";

import Button from "@/components/Button";
import Stack, { StackProps } from "@/components/Stack";
import "./SegmentedControl.scss";
import Icon from "./Icon";

const SegmentedControlStack = React.forwardRef((props: StackProps, ref) => (
  <Stack ref={ref} as="ul" {...props} />
));

type Props<Item, ItemId = Item> = {
  activeId?: ItemId;
  children: (item: Item, isActive: boolean) => React.ReactNode;
  className?: string;
  getItemId?: (item: Item) => ItemId;
  items: Item[];
  onChange?: (itemId: ItemId) => void;
  showControls?: boolean;
};

function SegmentedControl<Item, ItemId = Item>({
  activeId,
  children,
  className = "",
  getItemId = (item: Item) => item as unknown as ItemId,
  items,
  onChange = () => {},
  showControls = false,
}: Props<Item, ItemId>) {
  const itemsRef = useRef<HTMLUListElement>(null);
  const activeItemIndex = items.findIndex(
    (item) => getItemId(item) === activeId,
  );
  const prevItemIndex = activeItemIndex - 1;
  const nextItemIndex = activeItemIndex + 1;
  const canGoPrev = prevItemIndex >= 0;
  const canGoNext = nextItemIndex <= items.length - 1;

  const handleChangeItem = (index: number) => {
    const item = items[index];
    const itemsNode = itemsRef.current;
    const itemNode = itemsNode?.querySelector<HTMLLIElement>(
      `li[data-index="${index}"]`,
    );
    if (!item || !itemsNode || !itemNode) {
      return;
    }
    onChange && onChange(getItemId(item));
    const itemWidth = itemNode.offsetWidth;
    const offsetToItemLeft = itemNode.offsetLeft - itemsNode.offsetLeft;
    const offsetToItemCenter = offsetToItemLeft + itemWidth / 2;
    const containerVisibleWidth = itemsNode.clientWidth;
    itemsNode.scrollLeft = offsetToItemCenter - containerVisibleWidth / 2;
  };

  return (
    <div className={"border-0 overflow-auto hstack gap-2 " + className}>
      {showControls && (
        <Button
          variant="text"
          //   icon="doubleCaretLeft"
          className=" border-0"
          disabled={!canGoPrev}
          onClick={() => handleChangeItem(prevItemIndex)}
        >
          <Icon icon="anglesLeft" />
        </Button>
      )}
      <Nav
        ref={itemsRef}
        role="tablist"
        variant="pills"
        className="nav-tabs border-0 flex-grow-1 flex-nowrap overflow-auto segmented-control-items"
        as={SegmentedControlStack}
        direction="horizontal"
        gap={2}
      >
        {items.map((item, index) => {
          const itemId = getItemId(item);
          const isActive = itemId === activeId;
          return (
            <Nav.Item
              key={index}
              as="li"
              data-index={index}
              role="none presentation"
              className="flex-shrink-0"
              onClick={(event: React.MouseEvent) => {
                event.preventDefault && event.preventDefault();
                handleChangeItem(index);
              }}
            >
              {children(item, isActive)}
            </Nav.Item>
          );
        })}
      </Nav>
      {showControls && (
        <Button
          variant="text"
          className="text-muted border-0"
          disabled={!canGoNext}
          onClick={() => handleChangeItem(nextItemIndex)}
        >
          <Icon icon="anglesRight" />
        </Button>
      )}
    </div>
  );
}

export default SegmentedControl;
