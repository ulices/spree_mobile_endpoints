Spree::Order.class_eval do
  def confirmation_required?
    true
  end
end