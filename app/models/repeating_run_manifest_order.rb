class RepeatingRunManifestOrder < ActiveRecord::Base
  belongs_to :repeating_run

  scope :for_wday, -> (wday) { where(wday: wday) }

  serialize :manifest_order, Array
end
