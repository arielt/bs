require 'bs'

class ActiveSessionsController < ApplicationController

  def index
    puts "index here"
    f  = File.open('/opt/bs/config/bs.yml')
    f.close
    puts BS::Session.objective
  end

end
