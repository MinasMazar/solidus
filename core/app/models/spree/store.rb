module Spree
  # Records store specific configuration such as store name and URL.
  #
  # `Spree::Store` provides the foundational ActiveRecord model for recording information
  # specific to your store such as its name, URL, and tax location. This model will
  # provide the foundation upon which [support for multiple stores](https://github.com/solidusio/solidus/issues/112)
  # hosted by a single Solidus implementation can be built.
  #
  class Store < Spree::Base
    has_many :store_payment_methods, inverse_of: :store
    has_many :payment_methods, through: :store_payment_methods
    has_many :orders, class_name: "Spree::Order"

    validates :code, presence: true, uniqueness: { allow_blank: true }
    validates :name, presence: true
    validates :url, presence: true
    validates :mail_from_address, presence: true

    before_save :ensure_default_exists_and_is_unique
    before_destroy :validate_not_default

    scope :by_url, lambda { |url| where("url like ?", "%#{url}%") }

    def self.current(store_key)
      current_store = Store.find_by(code: store_key) || Store.by_url(store_key).first if store_key
      current_store || Store.default
    end

    def self.default
      where(default: true).first || new
    end

    def default_cart_tax_location
      @default_cart_tax_location ||=
        Spree::Tax::TaxLocation.new(country: Spree::Country.find_by(iso: cart_tax_country_iso))
    end

    private

    def ensure_default_exists_and_is_unique
      if default
        Spree::Store.where.not(id: id).update_all(default: false)
      elsif Spree::Store.where(default: true).count == 0
        self.default = true
      end
    end

    def validate_not_default
      if default
        errors.add(:base, :cannot_destroy_default_store)
      end
    end
  end
end
