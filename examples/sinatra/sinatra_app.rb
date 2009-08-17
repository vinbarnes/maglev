require 'rubygems'
require 'sinatra'

# Workaround for issue automatically starting app.
# See comments in README file
configure(:development) do
  set :run,     true
end

get '/' do
  "Sinatra #{Sinatra::VERSION} says Hello"
end