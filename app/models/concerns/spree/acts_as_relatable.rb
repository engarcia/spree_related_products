module Spree
  module ActsAsRelatable
    extend ActiveSupport::Concern

    included do
      has_many :relations, -> { order(:position) }, as: :relatable

      validates :relatable_id, uniqueness: { scope: [:related_to_id, :relation_type_id] }

      after_destroy :destroy_relations

      # Returns all the Spree::RelationType's which apply_to this class.
      def self.relation_types
        Spree::RelationType.where(applies_to: to_s).order(:name)
      end


      # The AREL Relations that will be used to filter the resultant items.
      #
      # By default this will remove any items which are deleted, or not yet available.
      #
      # You can override this method to fine tune the filter. For example,
      # to only return relatables with more than 2 items in stock, you could
      # do the following:
      #
      #   def self.relation_filter
      #     set = super
      #     set.where('count_on_hand >= 2')
      #   end
      #
      # This could also feasibly be overridden to sort the result in a
      # particular order, or restrict the number of items returned.
      def self.relation_filter
        where.not(deleted_at: nil).
        references(self)
      end
    end


    # Decides if there is a relevant Spree::RelationType related to this class
    # which should be returned for this method.
    #
    # If so, it calls relations_for_relation_type. Otherwise it passes
    # it up the inheritance chain.
    def method_missing(method, *args)
      # Fix for Ruby 1.9
      raise NoMethodError if method == :to_ary

      relation_type = find_relation_type(method)
      if relation_type.nil?
        super
      else
        relations_for_relation_type(relation_type)
      end
    end

    def has_related_products?(relation_method)
      find_relation_type(relation_method).present?
    end

    def destroy_relations
      # First we destroy relationships "from" this to others.
      relations.destroy_all
      # Next we destroy relationships "to" this.
      Spree::Relation.where(related_to_type: self.class.to_s).where(related_to_id: id).destroy_all
    end

    def relations_to(related_to, relation_name)
      relations.
      includes(:relation_type).
      where(spree_relation_type: { name: relation_name })
      find_by(related_to_id: related_to.id)
    end

    def offer_related_to_price(related_to, relation)
      related_to.price - relations_to(related_to, relation).try(:discount_amount)
    end

    private

    def find_relation_type(relation_name)
      self.class.relation_types.detect { |rt| format_name(rt.name) == format_name(relation_name) }
    rescue ActiveRecord::StatementInvalid
      # This exception is throw if the relation_types table does not exist.
      # And this method is getting invoked during the execution of a migration
      # from another extension when both are used in a project.
      nil
    end

    # Returns all relatables that are related to this record for the given RelationType.
    #
    # Uses the Relations to find all the related items, and then filters
    # them using +Product.relation_filter+ to remove unwanted items.
    def relations_for_relation_type(relation_type)
      # Find all the relations that belong to us for this RelationType, ordered by position
      related_ids = relations.where(relation_type_id: relation_type.id).order(:position).select(:related_to_id)

      # Construct a query for all these records
      result = self.class.where(id: related_ids)

      # Merge in the relation_filter if it's available
      result = result.merge(self.class.relation_filter) if relation_filter

      # make sure results are in same order as related_ids array  (position order)
      if result.present?
        result.where(id: related_ids).order(:position)
      end

      result
    end

    # Simple accessor for the class-level relation_filter.
    # Could feasibly be overloaded to filter results relative to this
    # record (eg. only higher priced items)
    def relation_filter
      self.class.relation_filter
    end

    def format_name(name)
      name.to_s.downcase.gsub(' ', '_').pluralize
    end
  end
end