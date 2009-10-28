class Document < ActiveRecord::Base
  belongs_to :author, :foreign_key => "user_id"
  belongs_to :checked_out_by, :foreign_key => "checked_out_by_id"
  has_many :audits
  has_many :shares

  has_attached_file :document,
                    :url => '/:class/:id/download/:style.:extension',
                    :path => ':rails_root/assets/:class/:id_partition/:style.:extension'

  validates_attachment_presence :document
  validates_attachment_content_type :document, :content_type => [ 'text/plain' ]
  validates_attachment_size :document, :less_than => 20.megabytes

  attr_accessible :name, :comment, :document

  before_post_process :dont_process

  def downloadable?(user)
    true
  end

  def determine_mime_type
    path = self.document.path.sub(/#{RAILS_ROOT}/, "\.")
    %x[file -br --mime #{path}].sub(/\n$/, "")
  end

private

  def dont_process
    nil
  end

end
