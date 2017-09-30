class DocumentAssociation < ActiveRecord::Base
  belongs_to :document, inverse_of: :document_associations
  belongs_to :associable, polymorphic: true, inverse_of: :document_associations
  
  validates :document, presence: true, associated: true
  # validates :document_id, uniqueness: {scope: [:associable_type, :associable_id], message: 'can\'t be associated to the same record more than once.'}
  validates :associable, presence: true
  validate  :ensure_same_owner, if: :owner_exists?
  
  accepts_nested_attributes_for :document, allow_destroy: true
  
  # after_destroy :destroy_orphaned_document

  private
  
  # Destroy associated document if it isn't associated with another model
  def destroy_orphaned_document
    document.destroy unless document.documentable.present?
  end
  
  def owner_exists?
    document.present? && 
    document.documentable_type.present? && 
    document.documentable_id.present?
  end
  
  def ensure_same_owner
    if document.present? and associable.present?
      owner_class = document.documentable_type.underscore
      errors.add(:base, "Document and associable must belong to the same #{owner_class.humanize.downcase}") unless document.documentable == associable.send(owner_class)
    end
  end
end
