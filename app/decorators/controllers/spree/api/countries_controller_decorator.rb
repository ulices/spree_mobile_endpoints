Spree::Api::CountriesController.class_eval do
  def index
    @countries = Spree::Country.accessible_by(current_ability, :read).ransack(params[:q]).result.
      includes(:states).order('name ASC')
    country = Spree::Country.order("updated_at ASC").last
    if stale?(country)
      respond_with(@countries)
    end
  end
end
