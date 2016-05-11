module ApplicationHelper
  # Get a navigation bar list item whose class is set to 'active' if the link is to
  # the current page.
  def nav_link(link_text, link_path)
    class_name = current_page?(link_path) ? 'active' : nil
    
    content_tag(:li, class: class_name) do
      link_to link_text, link_path
    end
  end
  
  # Get the title for the given user's record according to whether the user is
  # the one logged in.
  def full_record_title(user)
    if user.id == user_session.current_user.id
      return 'your record'
    else
      return "#{ user.handle }'s record"
    end
  end
end
