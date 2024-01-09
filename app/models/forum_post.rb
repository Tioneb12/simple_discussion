class ForumPost < ApplicationRecord
  belongs_to :forum_thread, counter_cache: true, touch: true
  belongs_to :user
  
  has_rich_text :body

  validates :user_id, :body, presence: true

  scope :sorted, -> { order(:created_at) }

  after_update :solve_forum_thread, if: :solved?
  before_save :add_nofollow_to_links

  def solve_forum_thread
    forum_thread.update(solved: true)
  end

  private

  def add_nofollow_to_links
    return unless content.present?

    doc = Nokogiri::HTML.fragment(content.body.to_s)

    doc.css('a').each do |link|
      href = link['href']
      unless allowed_domain?(href)
        link['rel'] = 'nofollow'
      end
    end

    self.content = doc.to_html
  end

  def allowed_domain?(url)
    allowed_domains = ['example.com', 'yourdomain.com'] # Add your allowed domains here
    uri = URI.parse(url)
    allowed_domains.any? { |domain| uri.host.end_with?(domain) }
  rescue URI::InvalidURIError
    false
  end

end
