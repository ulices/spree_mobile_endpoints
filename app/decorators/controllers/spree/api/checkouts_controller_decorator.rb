require 'httparty'

Spree::Api::CheckoutsController.class_eval do
  Spree::PermittedAttributes.checkout_attributes << [:type, :time]

  def create
    compouse_order

    authorize! :update, @order, order_token

    unless order_next_state
      invalid_resource!(@order)
    end

    send_push_notification
    respond_with(@order, default_template: 'spree/api/orders/show') if @order.confirm?
  end

  private
  def compouse_order
    authorize! :create, Spree::Order
    order_user = Spree.user_class.find(params[:user_id])

    @order = Spree::Core::Importer::Order.import(order_user, {})
    params[:id] = @order.to_param
    params[:order_token] = @order.guest_token
  end

  def order_next_state
    return true if @order.confirm?

    return false unless @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)

    return false unless params[:order][:line_items]

    if current_api_user.has_spree_role?('admin') && user_id.present?
      @order.associate_user!(Spree.user_class.find(params[:user_id]))
    end

    add_order_line_items if @order.cart?

    after_update_attributes

    if @order.next
      state_callback(:after)
      order_next_state
    else
      false
    end
  end

  def add_order_line_items
    params[:order][:line_items].each do |item|
      variant = Spree::Variant.find(item[:variant_id])
      @order.contents.add(variant, item[:comment], item[:quantity] || 1)
    end
  end

  def skip_state_validation?
    true
  end

  def notification_params
    {
      data: {
        alert: "Nuevo Pedido de: #{current_user_full_name}",
        userPic: current_api_user.image_url,
        orderToken: @order.guest_token,
        orderNumber: @order.number,
        userChannel: current_api_user.channel
      },
      channels: ["requests"]
    }
  end

  def current_user_full_name
    "#{current_api_user.ship_address.try(:firstname)} #{current_api_user.ship_address.try(:last_name)}"
  end

  def send_push_notification
    HTTParty.post("https://api.parse.com/1/push",
                  body: notification_params.to_json,
                  headers: {
                    "X-Parse-Application-Id" => "M9XmhjQ8B2iqs3CdNLASwl6hypCXnI8rRJLqFy0x",
                    "X-Parse-REST-API-Key" => "coIbuuMhojZGYZVv0MuVRNwyUTD9aliN1bP9lNg8",
                    "Content-Type" => "application/json"
                  }
                 )
  end
end
