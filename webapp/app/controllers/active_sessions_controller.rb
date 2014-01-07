require 'bs'

class ActiveSessionsController < ApplicationController

  RENDERING_OPT = {
    :autolink => true, :space_after_headers => true, :no_intra_emphasis => true
  }

  @current_session = nil

  before_filter :set_session

  def set_session
    @current_session = BS::Session.new unless @current_session
    @current_session.accept
  end


  def index
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, RENDERING_OPT)
    @rendered_md = @markdown.render(@current_session.objective)
  end


  # Ajax POST call
  def create
    # lock the session
    return respond_to {|format| format.json {render :json => {status: STATUS_BUSY}}} unless BS::Session.lock()

    # sumbit solution
    if params["submit"] == "TRUE" then
      @current_session.is_active     = FALSE;
      @current_session.finished_at   = Time.now;
      @current_session.forced_finish = FALSE;
      @current_session.save
      @current_session.unlock()
      return respond_to {|format| format.json {render :json => {status: STATUS_OK}}} 
    end
    
    # calculate digest
    request_digest = Digest::MD5.hexdigest(params["check"].to_s)

    # return saved state if there is no change in code
    if request_digest == @current_session.verified_digest
      parse_message()
      
      # if there was a timeout - allow to verify once again
      if @current_session.verified_message.include?("[--bs--]:Oops... We've been waiting for too long")
        @current_session.verified_digest = nil
      end

      @current_session.response = {
        status:   @current_session.verified_status, 
        issues:   JSON.parse(@current_session.verified_issues),
        solution: @current_session.vr_solution
      }.to_json
      @current_session.save
 
      @current_session.unlock()
      return respond_to {|format| format.json {render :json => @current_session.response}}
    end

    # start the verification
    params_hash = {
      user_test_id: @current_session.user_test_id,
      solution: params["check"],
      digest: request_digest,
      session_id: @current_session.id
    }
    Resque.enqueue(Sandbox::First, params_hash)

    @current_session.vr_solution = params["check"];
    @current_session.save!;

    respond_to {|format| format.json { render :json => {status: STATUS_BUSY}}}
  end

end

