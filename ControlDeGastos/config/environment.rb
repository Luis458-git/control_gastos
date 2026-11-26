# frozen_string_literal: true

# Punto único de arranque: carga gemas, variables de entorno,
# base de datos y todas las capas de la aplicación (MVC).

require 'bundler/setup'
require 'date'
require 'dotenv/load'
require 'sinatra/base'
require 'rack/utils'

APP_ROOT = File.expand_path('..', __dir__)

require_relative 'database'
require_relative '../app/models/gasto'
require_relative '../app/helpers/application_helper'
require_relative '../app/controllers/application_controller'
require_relative '../app/controllers/gastos_controller'
require_relative '../db/seeds'

Database.setup!
Seeds.run
