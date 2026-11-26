# frozen_string_literal: true

# Atajo para desarrollo: `ruby app.rb`
# Toda la lógica vive en app/ y config/; este archivo solo arranca el servidor.
require_relative 'config/environment'

GastosController.run! if $PROGRAM_NAME == __FILE__
