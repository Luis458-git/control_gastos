# frozen_string_literal: true

# Controlador base: configuración compartida por todos los controladores.
class ApplicationController < Sinatra::Base
  configure do
    set :root, APP_ROOT
    set :views, File.join(APP_ROOT, 'app', 'views')
    set :public_folder, File.join(APP_ROOT, 'public')
    set :bind, '0.0.0.0'
    set :port, Integer(ENV.fetch('PORT', 4567))
    enable :method_override # permite PATCH/DELETE desde formularios con _method
  end

  helpers ApplicationHelper

  not_found do
    'Recurso no encontrado'
  end
end
