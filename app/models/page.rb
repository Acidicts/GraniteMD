# == Schema Information
#
# Table name: pages
#
#  id            :bigint           not null, primary key
#  body          :text
#  name          :string
#  search_vector :tsvector
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  folder_id     :bigint           not null
#
# Indexes
#
#  index_pages_on_folder_id      (folder_id)
#  index_pages_on_search_vector  (search_vector) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (folder_id => folders.id)
#
class Page < ApplicationRecord
  belongs_to :folder
  has_one :workspace, through: :folder

  validates :name, presence: true

  attribute :body, default: ""

  # Full-text search over the page name and body, backed by the
  # `search_vector` generated column (GIN indexed).
  #
  # Every term is a prefix ("install:*" also finds "installer") and all
  # terms have to match. When that finds nothing the search is widened to
  # "any term", so a two-word query never comes back empty while one of
  # its words is in the workspace.
  def self.search(query, limit: 20)
    terms = search_terms(query)
    return none if terms.empty?

    # Every term is a prefix, so "install" also finds "installer".
    prefixed = terms.map { |term| "#{term}:*" }

    results = search_with(prefixed.join(" & "), limit: limit)
    return results if results.exists?

    search_with(prefixed.join(" | "), limit: limit)
  end

  # Words of a query, in order and without duplicates. Only letters and
  # digits are kept, which is also what makes the tsquery below safe to
  # build: nothing that tsquery would read as syntax survives.
  def self.search_terms(query)
    query.to_s.scan(/[[:alnum:]]+/).uniq.first(8)
  end

  def self.search_with(tsquery, limit: 20)
    where("pages.search_vector @@ to_tsquery('simple', ?)", tsquery)
      .order(Arel.sql(rank_sql(tsquery)))
      .limit(limit)
  end
  private_class_method :search_with

  # Rank by relevance: pages matching more of the query (and matching it
  # more often) come first.
  def self.rank_sql(tsquery)
    sanitize_sql_array([ "ts_rank(pages.search_vector, to_tsquery('simple', ?)) DESC", tsquery ])
  end
  private_class_method :rank_sql

  # Plain-text excerpt of the body around the first search term, used as
  # the context line under a search result. Markdown syntax is left as it
  # is: the switcher renders the snippet as text, never as markup.
  def search_snippet(query, length: 160)
    flat = body.to_s.gsub(/\s+/, " ").strip
    return "" if flat.empty?

    lower = flat.downcase
    position = self.class.search_terms(query).filter_map { |term| lower.index(term.downcase) }.min
    return flat[0, length] if position.nil?

    start = [ position - length / 3, 0 ].max
    excerpt = flat[start, length].to_s
    excerpt = "…#{excerpt}" if start.positive?
    excerpt = "#{excerpt}…" if start + length < flat.length
    excerpt
  end
end
