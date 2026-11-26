# frozen_string_literal: true

# Funciones de presentación disponibles en todas las vistas.
module ApplicationHelper
  MESES = %w[Enero Febrero Marzo Abril Mayo Junio Julio Agosto
             Septiembre Octubre Noviembre Diciembre].freeze

  BADGES = {
    'Alimentación' => 'badge-food',
    'Transporte'   => 'badge-transport',
    'Servicios'    => 'badge-services',
    'Salud'        => 'badge-health',
    'Ocio'         => 'badge-leisure'
  }.freeze

  ICONOS_CATEGORIA = {
    'Alimentación' => '✦',
    'Transporte'   => '↗',
    'Servicios'    => '⚡',
    'Salud'        => '✚',
    'Ocio'         => '◈',
    'Otros'        => '•'
  }.freeze

  AVISOS = {
    'creado'      => 'Movimiento registrado y sincronizado en tu libro.',
    'actualizado' => 'Los cambios del movimiento se guardaron correctamente.',
    'eliminado'   => 'El registro fue eliminado del catálogo.',
    'bienvenido'  => 'Sesión iniciada correctamente. Bienvenido a tu panel.',
    'presupuesto' => 'Meta de presupuesto mensual actualizada.'
  }.freeze

  # Escapa HTML para prevenir XSS. Usar SIEMPRE al imprimir datos.
  def h(texto)
    Rack::Utils.escape_html(texto.to_s)
  end

  def moneda(cantidad)
    entero, decimales = format('%.2f', cantidad.to_f).split('.')
    "$#{entero.reverse.scan(/\d{1,3}/).join(',').reverse}.#{decimales}"
  end

  # Formato estilo Mercury: parte entera grande y centavos en superíndice (.50)
  def moneda_editorial(cantidad)
    entero, decimales = format('%.2f', cantidad.to_f).split('.')
    entero_fmt = entero.reverse.scan(/\d{1,3}/).join(',').reverse
    "<span class=\"curr-sign\">$</span><span class=\"curr-int\">#{h(entero_fmt)}</span><sup class=\"curr-cents\">.#{h(decimales)}</sup>"
  end

  def nombre_mes(yyyy_mm)
    return 'Todos los periodos' if yyyy_mm == Gasto::TODOS

    anio, mes = yyyy_mm.to_s.split('-')
    "#{MESES[mes.to_i - 1]} #{anio}"
  end

  def badge_categoria(categoria)
    BADGES.fetch(categoria.to_s, 'badge-other')
  end

  def icono_categoria(categoria)
    ICONOS_CATEGORIA.fetch(categoria.to_s, '•')
  end

  def aviso(clave)
    AVISOS[clave.to_s]
  end

  def porcentaje(parte, total)
    total.positive? ? format('%.0f%%', (parte.to_f / total) * 100) : '0%'
  end

  def porcentaje_num(parte, total)
    return 0 unless total.to_f.positive?

    [((parte.to_f / total) * 100).round, 100].min
  end

  def monto_input(gasto)
    gasto.monto.is_a?(Numeric) ? format('%.2f', gasto.monto) : gasto.monto.to_s
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:usuario_id] ? Usuario.find(session[:usuario_id]) : nil
  end

  def logged_in?
    !current_user.nil?
  end
end
