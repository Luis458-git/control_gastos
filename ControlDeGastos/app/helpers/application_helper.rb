# frozen_string_literal: true

# Funciones de presentación disponibles en todas las vistas.
module ApplicationHelper
  MESES = %w[Enero Febrero Marzo Abril Mayo Junio Julio Agosto
             Septiembre Octubre Noviembre Diciembre].freeze

  BADGES = {
    'Alimentación' => 'badge-food',
    'Transporte' => 'badge-transport',
    'Servicios' => 'badge-services',
    'Salud' => 'badge-health',
    'Ocio' => 'badge-leisure'
  }.freeze

  AVISOS = {
    'creado' => 'Gasto registrado correctamente.',
    'actualizado' => 'Los cambios se guardaron correctamente.',
    'eliminado' => 'El gasto fue eliminado.'
  }.freeze

  # Escapa HTML para prevenir XSS. Usar SIEMPRE al imprimir datos.
  def h(texto)
    Rack::Utils.escape_html(texto.to_s)
  end

  def moneda(cantidad)
    entero, decimales = format('%.2f', cantidad.to_f).split('.')
    "$#{entero.reverse.scan(/\d{1,3}/).join(',').reverse}.#{decimales}"
  end

  def nombre_mes(yyyy_mm)
    return 'Todos los meses' if yyyy_mm == Gasto::TODOS

    anio, mes = yyyy_mm.to_s.split('-')
    "#{MESES[mes.to_i - 1]} #{anio}"
  end

  def badge_categoria(categoria)
    BADGES.fetch(categoria.to_s, 'badge-other')
  end

  def aviso(clave)
    AVISOS[clave.to_s]
  end

  def porcentaje(parte, total)
    total.positive? ? format('%.0f%%', parte / total * 100) : '0%'
  end

  # Valor del input de monto: con 2 decimales si ya es número, o tal cual lo escribió el usuario.
  def monto_input(gasto)
    gasto.monto.is_a?(Numeric) ? format('%.2f', gasto.monto) : gasto.monto.to_s
  end
end
