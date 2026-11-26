# frozen_string_literal: true

# Configuración de Puma (se carga automáticamente con `bundle exec puma`).
hilos = Integer(ENV.fetch('PUMA_MAX_THREADS', 5))
threads hilos, hilos

port        ENV.fetch('PORT', 4567)
environment ENV.fetch('RACK_ENV', 'development')
