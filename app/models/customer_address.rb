# Deprecated
class CustomerAddress < ActiveRecord::Base
  self.table_name = 'addresses_customers'
  belongs_to :customer, -> { with_deleted }
  belongs_to :address, -> { with_deleted }
end