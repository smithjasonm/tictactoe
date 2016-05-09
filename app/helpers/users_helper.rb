module UsersHelper
  # TODO: define current_user
  def current_user
    nil
  end
  
  # Get a Gravatar image tag for a user and context.
  def gravatar_image_tag(user, context = nil)
    context = context.try(:to_sym)
    case context
    when :profile
      size = 350
    else
      size = 80
    end
    email = user.nil? ? "" : user.email
    
    image_tag avatar_url(email, size),
                          class: 'avatar img-responsive img-rounded center-block',
                          alt: 'Avatar'
  end
  
  private
  
    # Get URL of Gravatar of given size for given email address.
    def avatar_url(email, size)
      "http://www.gravatar.com/avatar/#{ email_hash(email) }?s=#{ size }"
    end
    
    # Get hash of given email address for use in Gravatar URL.
    def email_hash(email)
      Digest::MD5.hexdigest email.downcase
    end
end
