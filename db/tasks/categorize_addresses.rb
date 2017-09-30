base_rel = Address.unscoped.where(type: nil)
# user address
base_rel.where(is_user_associated: true).update_all(type: 'UserAddress')
# driver address
base_rel.where(is_driver_associated: true).update_all(type: 'DriverAddress')

# customer common address
customer_default_address_ids = Customer.unscoped.pluck(:address_id)
# first dealing with customer mailing addresses
base_rel.where(id: customer_default_address_ids).update_all(type: 'CustomerCommonAddress')
# then those has customer_id specified and has name (if no name, we can take it as a temp address)
base_rel.where.not(customer_id: nil, name: nil).update_all(type: 'CustomerCommonAddress')

# provider common address
base_rel.where.not(provider_id: nil).where(customer_id: nil).update_all(type: 'ProviderCommonAddress')

# temp address
base_rel.update_all(type: 'TempAddress')