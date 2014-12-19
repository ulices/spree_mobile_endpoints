Spree::OrderContents.class_eval do
  def add(variant, comment, quantity = 1, currency = nil, shipment = nil)
    line_item = add_to_line_item(variant, comment, quantity, currency, shipment)
    reload_totals
    shipment.present? ? shipment.update_amounts : order.ensure_updated_shipments
    #PromotionHandler::Cart.new(order, line_item).activate
    #ItemAdjustments.new(line_item).update
    reload_totals
    line_item
  end

  def add_to_line_item(variant, comment, quantity, currency=nil, shipment=nil)
    line_item = grab_line_item_by_variant(variant)

    if line_item
      line_item.target_shipment = shipment
      line_item.quantity += quantity.to_i
      line_item.currency = currency unless currency.nil?
    else
      line_item = order.line_items.new(quantity: quantity, variant: variant, comment: comment)
      line_item.target_shipment = shipment
      if currency
        line_item.currency = currency
        line_item.price    = variant.price_in(currency).amount
      else
        line_item.price    = variant.price
      end
    end

    line_item.save
    line_item
  end
end
