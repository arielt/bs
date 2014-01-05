require 'bs'

class ActiveSessionsController < ApplicationController

  RENDERING_OPT = {
    :autolink => true, :space_after_headers => true, :no_intra_emphasis => true
  }

  def index
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, RENDERING_OPT)
    @rendered_md = @markdown.render(BS::Session.objective)
    @session_config = BS::Session.load_config
    @is_accepted = @session_config["is_accepted"]
  end

end

