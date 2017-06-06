Deface::Override.new(
  virtual_path: 'spree/admin/variants/_form',
  name: 'add_related_variants',
  insert_after: '[data-hook="admin_variant_form_additional_fields"]',
  partial: 'spree/admin/variants/related_variants'
)
