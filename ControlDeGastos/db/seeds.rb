# frozen_string_literal: true

# Datos de ejemplo: solo se insertan si la tabla está vacía.
module Seeds
  def self.run
    return if Gasto.count.positive?

    hoy = Date.today
    mes_actual = hoy.strftime('%Y-%m')
    mes_anterior = (hoy << 1).strftime('%Y-%m')

    [
      ['Supermercado semanal y frutas',   84.50, 'Alimentación', "#{mes_actual}-03"],
      ['Suscripción fibra óptica y nube', 42.00, 'Servicios',    "#{mes_actual}-05"],
      ['Tarjeta de transporte urbano',    25.00, 'Transporte',   "#{mes_actual}-08"],
      ['Consulta dental y farmacia',      65.00, 'Salud',        "#{mes_actual}-12"],
      ['Cine y cena con amigos',          38.90, 'Ocio',         "#{mes_actual}-15"],
      ['Factura de electricidad',         54.20, 'Servicios',    "#{mes_anterior}-22"],
      ['Libros técnicos y papelería',     31.00, 'Otros',        "#{mes_anterior}-27"]
    ].each do |descripcion, monto, categoria, fecha|
      Gasto.new('descripcion' => descripcion, 'monto' => monto,
                'categoria' => categoria, 'fecha' => fecha).save
    end
  end
end
