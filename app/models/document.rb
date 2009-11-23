class Document < ActiveRecord::Base
  belongs_to :user
  belongs_to :checked_out_by, :foreign_key => "checked_out_by", :class_name => "User"
  has_many :audits
  has_many :shares

  attr_accessible :name, :comment, :document
  validates_presence_of :name
  validates_length_of   :name, :within => 1..254
  validates_format_of   :name, :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => false

  has_attached_file :document,
                    :url => '/:class/:id/download/:style.:extension',
                    :path => ':rails_root/assets/:class/:id_partition/:style.:extension'

  validates_attachment_presence :document
  validates_attachment_content_type :document,
    :content_type => [ 'text/plain', 'application/pdf',
      'application/msword', 'application/vnd.ms-excel', 'application/vnd.ms-powerpoint',
      'application/vnd.oasis.opendocument.text', 'application/vnd.oasis.opendocument.spreadsheet',
      'application/vnd.oasis.opendocument.presentation',
      'image/jpeg', 'image/gif', 'image/png', 'image/bmp', 'image/tiff', 'image/x-xcf', 'image/x-psd',
      'image/x-ms-bmp', 'image/vnd.adobe.photoshop', 'image/svg+xml' ]
  validates_attachment_size :document, :less_than => 20.megabytes

  before_post_process :dont_process

  def downloadable?(user)
    true
  end

  def file_extension
    # Use original
    file = self.document_file_name
    ext = file[file.rindex('.')+1, file.size].downcase

    if EXTENSIONS[ext.to_sym] != self.document_content_type

      # Determine new extension
      if self.document.content_type == "text/plain"
        return "txt"
      elsif self.document.content_type == "image/x-ms-bmp"
        return "bmp"
      elsif self.document.content_type == "image/vnd.adobe.photoshop"
        return "psd"
      else
        return File.extensions.index( self.document.content_type ).to_s
      end

    else
      return ext
    end
  end

  def mime_icon
    mime = self.document_content_type
    if mime == 'application/msword' or mime == 'application/vnd.oasis.opendocument.text'
      return 'document-word.png'
    elsif mime == 'application/vnd.ms-excel' or mime == 'application/vnd.oasis.opendocument.spreadsheet'
      return 'document-excel.png'
    elsif mime == 'application/vnd.ms-powerpoint' or mime == 'application/vnd.oasis.opendocument.presentation'
      return 'document-powerpoint.png'
    elsif mime == 'image/x-psd' or mime == 'image/vnd.adobe.photoshop'
      return 'document-photoshop-image.png'
    elsif mime == 'text/plain'
      return 'document-text.png'
    elsif mime[0,5] == 'image'
      return 'image.png'
    elsif mime == 'application/pdf'
      return 'document-pdf.png'
    else
      return 'document.png'
    end
  end

#  def determine_mime_type
#    # Using file command
#    path = self.document.path.sub(/{RAILS_ROOT}/, "\.")
#    %x[file -br --mime-type {path}].sub(/\n$/, "")
#    # Using mimetype-fu
#    mime = File.mime_type?(self.document.path)
#  end

  #def depts_doc(depts, doc_id)
  #  where = " WHERE "
  #  id = ""
  #  id = doc_id
  #  print id.class
  #  print id
  #  i = 0
  #  for dept in depts
  #    i++
  #    where += '"departments".id = ' + id
  #    where += " OR " unless i == depts.size
  #  end
  #  where += ' AND "documents".id = ' + id
  #  return %{SELECT "documents".* FROM "users" INNER JOIN "departments_users" ON "departments_users".user_id = "users".id INNER JOIN "departments" on "departments_users".department_id = "departments".id INNER JOIN "documents" ON "users".id = "documents".user_id } + where + " LIMIT 1 "
  #end

private

  def dont_process
    nil
  end

end
