export interface LineItem {
  unitPrice: number;
  quantity: number;
}

export function calculateTotal(items: LineItem[]): number {
  return items.reduce((total, item) => total + item.unitPrice * item.quantity, 0);
}
