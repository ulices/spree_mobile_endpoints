Spree::Order.class_eval do
  def confirmation_required?
    true
  end

  def payment_required?
    true
  end
end