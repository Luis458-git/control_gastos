# frozen_string_literal: true

# Punto de entrada Rack (usado por `bundle exec puma`).
require_relative 'config/environment'

run GastosController
