# frozen_string_literal: true

require 'securerandom'

# Controlador base: configuración compartida, sesiones firmadas y helpers.
class ApplicationController < Sinatra::Base
  configure do
    set :root, APP_ROOT
    set :views, File.join(APP_ROOT, 'app', 'views')
    set :public_folder, File.join(APP_ROOT, 'public')
    set :static_cache_control, [:public, max_age: 0]
    set :bind, '0.0.0.0'
    set :port, Integer(ENV.fetch('PORT', 4567))
    enable :method_override

    enable :sessions
    set :session_secret, ENV.fetch('SESSION_SECRET') {
      'wespend_editorial_secret_key_for_sinatra_session_2026_secure_64bytes!'
    }
  end

  helpers ApplicationHelper

  not_found do
    'Recurso no encontrado'
  end
end
