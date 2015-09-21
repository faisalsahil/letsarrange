module IdGenerator
	extend ActiveSupport::Concern

	module ClassMethods
	  def compound_id_for(scope, name)
	  	"#{ clean(scope) }-#{ clean(name) }"
	  end

	  def clean(name)
	  	name = name.downcase.gsub(/[\s_]+/, '-').gsub(/[^a-z0-9\-]/, '-')
      name[0] = '' if name[0] == '-'
      name.chomp!('-')
      name
	  end

	  def make_unique id,resource_class
	  	if resource_class.unscoped.exists? uniqueid: id
	  		suffix = resource_class.unscoped.where("uniqueid like '%#{id}%'").lock(true).order(uniqueid: :desc).first.uniqueid.scan( /\d+$/ ).first.to_i + 1

	  		if id.scan(/\d+$/).first
          id.gsub(/\d+$/, suffix.to_s)
	  		else
          id + suffix.to_s
	  		end
	  	else
	  		id
	  	end	
	  end

	end
end