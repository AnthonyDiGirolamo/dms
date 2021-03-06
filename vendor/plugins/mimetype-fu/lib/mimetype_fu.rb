class File

  def self.mime_type?(file)
     if file.class == File
       unless RUBY_PLATFORM.include? 'mswin32'
         mime = `file --mime-type -br #{file.path}`.strip
       else
         mime = EXTENSIONS[File.extname(file.path).gsub('.','').downcase.to_sym]
       end
     elsif file.class == String
         mime = `file --mime-type -br #{file}`.strip
         if mime == "application/octet-stream" or mime == "application/zip"
           mime = EXTENSIONS[(file[file.rindex('.')+1, file.size]).downcase.to_sym]
         end
     elsif file.class == StringIO
       temp = File.open(Dir.tmpdir + '/upload_file.' + Process.pid.to_s, "wb")
       temp << file.string
       temp.close
       mime = `file --mime -br #{temp.path}`
       mime = mime.gsub(/^.*: */,"")
       mime = mime.gsub(/;.*$/,"")
       mime = mime.gsub(/,.*$/,"")
       File.delete(temp.path)
     end

     if mime
       return mime
     else
       'unknown/unknown'
     end
   end

  def self.mime_type_ext(file, ext)
    mime = `file --mime-type -br #{file}`.strip
    if mime == "application/octet-stream" or mime == "application/zip"
      if ext == ""
        mime = nil
      else
        mime = EXTENSIONS[ext.downcase.to_sym]
      end
    end
    if mime
      return mime
    else
      'unknown/unknown'
    end
  end
  
  def self.extensions
    EXTENSIONS
  end
  
end
