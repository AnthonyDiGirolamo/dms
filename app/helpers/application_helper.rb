# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def format_short_time(time)
    if time.year == Time.now.year
      time.strftime("%m/%d %H:%M")
    else
      time.strftime("%Y/%m/%d %H:%M")
    end
  end

  def format_time(time)
    time.strftime("%a, %b %d, %Y %I:%M %p")
  end

  def format_date(date)
    date.strftime("%a, %b %d %Y")
  end

  def sort_class_helper(param)
    result = %{action #{param}} if params[:sort] == param
    result = %{action #{param}_desc} if params[:sort] == param + "_desc"
    return result
  end
  
  def sort_link_helper(text, param, action)
    key = param
    key += "_desc" if params[:sort] == param
    options = {
        :url => {:action => action, :params => params.merge({:sort => key, :page => nil})},
        :update => 'table',
        :before => "Element.show('spinner')",
        :success => "Element.hide('spinner')"
    }
    html_options = {
      :title => "Sort by this field",
      :class => sort_class_helper(param),
      :href => url_for(:action => 'list', :params => params.merge({:sort => key, :page => nil}))
    }
    link_to_remote(text, options, html_options)
  end

end
