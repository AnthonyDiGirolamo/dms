# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def format_time(time)
    time.strftime("%a, %b %d, %Y - %I:%M %p")
  end

  def format_date(date)
    date.strftime("%a, %b %d %Y")
  end
end
