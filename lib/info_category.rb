# 
# info_category.rb
# 

class InfoCategory

  @@captions = {}
  
  def self.categories
    [:permissions, :workflows, :settings, :plugins, :wiki_macros, :rails_info, :version]
  end

  def self.caption(sym)
    case sym.to_sym
    when :permissions
      :label_permissions_report
    when :workflows
      :label_workflow
    when :version
      :label_information_plural
    else
      ('label_' + sym.to_s).to_sym
    end
  end
  
  
  def self.hide_map
    map = {}
    InfoCategory.categories.each {|catsym|
      map['hide_' + catsym.to_s] = (catsym.to_s == "rails_info") ? true : false
    }
    map
  end

  
  def self.push_menu(menu, catsym, opts = {})
    url = {:controller => :info, :action => :show}
    copts = opts.clone

    url[:id] = catsym
    copts[:if] = Proc.new { (InfoCategory::is_shown?(catsym) or User.current.admin?) }

    copts[:caption] = self.caption(catsym)

    menu.push(catsym, url, copts)
  end
    
  
  def self.is_shown?(catsym)
    hidekey = 'hide_' + catsym.to_s
    return !Setting.plugin_redmine_information[hidekey]
  end

  
end
