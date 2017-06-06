Spree::Admin::VariantsController.class_eval do
  private

  def load_data
    @tax_categories = Spree::TaxCategory.order(:name)
    @relation_types = Spree::Variant.relation_types
  end
end