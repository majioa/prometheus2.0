# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def title(page_title)
    content_for(:title) { page_title.html_safe }
  end

  def srpm_count(srpm_count)
    content_for(:srpms_counter) { srpm_count }
  end

  def keywords(string)
    content_for(:keywords) { string }
  end

  def avatar_url(maintainer)
    gravatar_id = Digest::MD5.hexdigest(maintainer.email.downcase)
    "http://gravatar.com/avatar/#{gravatar_id}.png?s=80&r=g"
  end
end
