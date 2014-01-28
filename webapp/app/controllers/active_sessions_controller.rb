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

  SECTION_SOLUTION      = 0
  SECTION_VERIFICATION  = 1
  SECTION_LINKAGE       = 2
  SECTION_TEST          = 3
  SECTION_BS            = 4

  CPP_SECTIONS = {
    "[--build-solution--]"      => SECTION_SOLUTION,
    "[--build-verification--]"  => SECTION_VERIFICATION,
    "[--build-linkage--]"       => SECTION_LINKAGE,
    "[--test--]"                => SECTION_TEST,
    "[--bs--]"                  => SECTION_BS
  }


  @current_session = nil

  before_filter :set_session

  def set_session
    @current_session = BS::Session.new unless @current_session
    @current_session.update

    return render_inactive_session unless @current_session.config['is_active']
  end


  def index
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, RENDERING_OPT)
    @rendered_md = @markdown.render(@current_session.objective)
  end


  def parse_cpp_message(message)
    verified_issues = []
    section         = nil;
    automatic       = FALSE;

    puts "PARSING"
    puts message

    return verified_issues unless message
    message.split(/\r?\n|\r/).each do |line|
      if CPP_SECTIONS[line]
        section = CPP_SECTIONS[line]
        next
      end

      case section
      when SECTION_SOLUTION
        if (line[/solution.cpp:.+:.+:.+:.+/])
          verified_issues.push({type: "error", section: "test", line: nil, data: line})
          automatic = TRUE
        elsif automatic
           verified_issues.push({type: "error", section: "test", line: nil, data: line})
        else
          automatic = FALSE
        end
      when SECTION_VERIFICATION
        parts = line.split(':')
        type = parts[3].strip unless parts[3].nil?
        if (type != "note")
          line = parts[1]
          parts[0] = "build:internal"
          verified_issues.push({type: type, section: "build", line: line, data: parts.join(':')})
        end
      when SECTION_LINKAGE
        parts = line.split(':')
        if parts[0] == "verification.cpp"
          parts.delete_at(0)
          parts.delete_at(0)
          verified_issues.push({type: "error", section: "build", line: nil, data: "build: #{parts.join(':')}"})
        end
      when SECTION_TEST
        if (p = /verification.cpp[^:]*:[^:]*:/.match line)
          verified_issues.push({type: "error", section: "test", line: nil, data: p.post_match})
        end
      when SECTION_BS
        # put bs section messages as is
        verified_issues.push({type: "error", section: "test", line: nil, data: line})
      else
        # unknown section - probably long output
        verified_issues.push({type: "error", section: "test", line: nil, data: "Something is basically wrong with this code"})
        break;
      end
    end
    verified_issues.to_json()
  end

  # Ajax POST call
  def create
    # lock the session
    return respond_to {|format| format.json {render :json => {status: STATUS_BUSY}}} unless @current_session.lock()

    # submit solution
    if params["submit"] == "TRUE" then
      config = @current_session.load_config
      config['is_active']     = FALSE;
      config['finished_at']   = Time.now;
      config['forced_finish'] = FALSE;
      @current_session.save_config
      @current_session.unlock()
      return respond_to {|format| format.json {render :json => {status: STATUS_OK}}} 
    end
   
    # calculate digest
    request_digest = Digest::MD5.hexdigest(params["check"].to_s)
    puts request_digest
    @current_session.config['verified_digest']

    # return saved state if there is no change in code
    if request_digest == @current_session.config['verified_digest']
      @current_session.config['verified_issues'] = parse_cpp_message(@current_session.config['verified_message'])

      
      # if there was a timeout - allow to verify once again
      if @current_session.config['verified_message'].include?("[--bs--]:Oops... We've been waiting for too long")
        @current_session.config['verified_digest'] = nil
      end

      @current_session.config['response'] = {
        status:   @current_session.config['verified_status'], 
        issues:   JSON.parse(@current_session.config['verified_issues']),
        solution: @current_session.config['solution']
      }.to_json
      @current_session.save_config
 
      @current_session.unlock()
      return respond_to {|format| format.json {render :json => @current_session.config['response']}}
    end

    # start the verification
    file = File.open('/opt/bs/session/solution.cpp', 'w')
    file << params['check']
    file.close

    @current_session.config['request_digest'] = request_digest
    @current_session.config['solution'] = params['check']
    @current_session.save_config

    # schedule for background processing. fork on desktop.
    system("/opt/bs/bin/bs session verify &")

    respond_to {|format| format.json { render :json => {status: STATUS_BUSY}}}
  end

end

