require 'bs'

class ActiveSessionsController < ApplicationController

  # verification status
  STATUS_OK       = 0
  STATUS_NOK      = 1
  STATUS_BUSY     = 2
  STATUS_NEW      = 3
  STATUS_ERR      = 4

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
    puts "LOCK"
    return respond_to {|format| format.json {render :json => {status: STATUS_BUSY}}} unless BS::Sandbox::Desktop.lock()

    puts "GOING FORWARD"

    # sumbit solution
    if params["submit"] == "TRUE" then
      puts "SUBMIT"
      config = @current_session.load_config
      config['is_active']     = false;
      config['finished_at']   = Time.now;
      config['forced_finish'] = FALSE;
      @current_session.save_config
      BS::Sandbox::Desktop.unlock()
      return respond_to {|format| format.json {render :json => {status: STATUS_OK}}} 
    end
   
    puts "GOING FORWARD" 
    # calculate digest
    request_digest = Digest::MD5.hexdigest(params["check"].to_s)

    # return saved state if there is no change in code
    if request_digest == @current_session.config['verified_digest']
      parse_message()
      
      # if there was a timeout - allow to verify once again
      if @current_session.config['verified_message'].include?("[--bs--]:Oops... We've been waiting for too long")
        @current_session.config['verified_digest'] = nil
      end

      @current_session.config['response'] = {
        status:   @current_session.config['verified_status'], 
        issues:   JSON.parse(@current_session.config['verified_issues']),
        solution: @current_session.config['vr_solution']
      }.to_json
      @current_session.save_config
 
      BS::Sandbox::Desktop.unlock()
      return respond_to {|format| format.json {render :json => @current_session.config['response']}}
    end

    # start the verification
    file = File.open('/opt/bs/session/solution.cpp', 'w')
    file << params['check']
    file.close

    params = [@current_session.config['task'], '/opt/bs/session/solution.cpp']
    BS::Sandbox::Desktop.perform(params)

    respond_to {|format| format.json { render :json => {status: STATUS_BUSY}}}
  end

end

