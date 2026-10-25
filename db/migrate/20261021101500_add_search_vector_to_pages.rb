class AddSearchVectorToPages < ActiveRecord::Migration[8.1]
  def change
    # Generated column: Postgres keeps it in step with name/body, so the GIN
    # index below can never drift from the page contents.
    #
    # The 'simple' text search configuration is used on purpose. It does not
    # stem or drop stop words, so a prefix query ("install:*") matches the
    # words exactly as they are written -- with the english configuration the
    # stem of "installer" ("install") would no longer prefix-match the
    # indexed stem ("instal").
    #
    # Adding a stored generated column rewrites the table, so this wants a
    # quiet moment on a big pages table.
    add_column :pages, :search_vector, :virtual,
               type: :tsvector,
               as: "to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(body, ''))",
               stored: true

    add_index :pages, :search_vector, using: :gin
  end
end
