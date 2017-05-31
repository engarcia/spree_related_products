Spree::Product.class_eval do
  include Spree::ActsAsRelatable

  def self.relation_filter
    where('spree_products.deleted_at' => nil)
      .where('spree_products.available_on IS NOT NULL')
      .where('spree_products.available_on <= ?', Time.now)
      .references(self)
  end

end
