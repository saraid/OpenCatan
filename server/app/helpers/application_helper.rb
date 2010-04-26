# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def include_javascript(javascript)
    ((@javascripts ||= []) << javascript).uniq!
  end
  def onload(&block)
    (@onloads ||= []) << capture(&block)
  end
end
