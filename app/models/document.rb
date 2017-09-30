class Document < ActiveRecord::Base
  belongs_to :documentable, polymorphic: true #, inverse_of: :documents
  has_many :document_associations, inverse_of: :document, dependent: :destroy
  has_paper_trail
  
  has_attached_file :document
  
  #validates :description, presence: true
  # validates :documentable, presence: true
  validates_attachment_presence :document
  validates_attachment_content_type :document, content_type: [
      "image/jpeg", "image/gif", "image/png", # image files (.png, .gif, .jpg)
      "text/plain",                           # plain text files (.txt)
      "application/pdf",                      # PDF (.pdf)
      
      # MS Excel (.xls, .xlsx, .csv)
      "application/vnd.ms-excel", 
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "text/csv",
      
      # MS Word (.doc, .docx)
      "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ], if: lambda { |d| d.document.present? }
  validates_attachment_size :document, :in => 1..2.gigabytes, if: lambda { |d| d.document.present? }
  
  
  # Returns documents that have no associated DocumentAssociation
  scope :unassociated, -> do
    includes(:document_associations)
    .where(document_associations: { document_id: nil} )
  end
  scope :default_order, -> { order(description: :asc) }

end
