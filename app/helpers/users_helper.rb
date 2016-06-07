module UsersHelper
  # Get a Gravatar image tag for a user and context.
  def gravatar_image_tag(user, context = nil)
    context = context.try(:to_sym)
    
    case context
    when :profile
      size = 350
      img_alt = user.handle
    when :nav
      size = 28
      img_alt = ""
    else
      size = 80
      img_alt = user.handle
    end
    
    email = user.nil? ? "" : user.email
    
    image_tag avatar_url(email, size),
                          class: 'avatar img-responsive img-rounded center-block',
                          alt: img_alt
  end
  
  private
  
    # Get URL of Gravatar of given size for given email address.
    def avatar_url(email, size)
      "https://www.gravatar.com/avatar/#{ email_hash(email) }?s=#{ size }"
    end
    
    # Get hash of given email address for use in Gravatar URL.
    def email_hash(email)
      Digest::MD5.hexdigest email.downcase
    end
end
