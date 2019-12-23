# frozen_string_literal: true

require 'rubygems'
require 'sinatra'
require 'dotenv'

Dotenv.load('.env')

require './app.rb'

run Sinatra::Application
