class Image < ActiveRecord::Base
  belongs_to :imageable, polymorphic: true
  has_paper_trail
  
  has_attached_file :image, styles: { medium: "300x300>", thumb: "100x100>" }

  validates :imageable, presence: true
  validates_attachment_presence :image
  validates_attachment_content_type :image, content_type: [
      "image/jpeg", "image/gif", "image/png" # image files (.png, .gif, .jpg)
    ], message: "should be JPEG, PNG, or GIF", if: lambda { |d| d.image.present? }
  validates_attachment_size :image, :in => 1..2.gigabytes, if: lambda { |d| d.image.present? }
end
