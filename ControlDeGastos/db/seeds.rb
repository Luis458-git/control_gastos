# frozen_string_literal: true

# Datos iniciales: crea la cuenta demo y gastos de muestra si la base está vacía.
module Seeds
  DEMO_EMAIL = 'demo@wespend.app'
  DEMO_PASS  = 'demo1234'

  def self.run
    demo_user = Usuario.find_by_email(DEMO_EMAIL)
    unless demo_user
      demo_user = Usuario.new(
        'nombre' => 'Valeria Montes',
        'email' => DEMO_EMAIL,
        'presupuesto_mensual' => 1200.00
      )
      demo_user.registrar(DEMO_PASS)
    end

    return if Gasto.count.positive?

    hoy = Date.today
    mes_actual = hoy.strftime('%Y-%m')
    mes_anterior = (hoy << 1).strftime('%Y-%m')

    [
      ['Supermercado orgánico y café de grano', 94.50, 'Alimentación', 'Tarjeta Crédito', "#{mes_actual}-03"],
      ['Suscripción fibra óptica + Cloud Pro',  48.00, 'Servicios',    'Débito / Cuenta', "#{mes_actual}-05"],
      ['Pase mensual movilidad eléctrica',      32.00, 'Transporte',   'Tarjeta Crédito', "#{mes_actual}-08"],
      ['Consulta médica y vitaminas',           75.00, 'Salud',        'Débito / Cuenta', "#{mes_actual}-12"],
      ['Noche de cine de autor y cena',         44.90, 'Ocio',         'Tarjeta Crédito', "#{mes_actual}-15"],
      ['Panadería artesanal y brunch',          26.75, 'Alimentación', 'Efectivo',        "#{mes_actual}-18"],
      ['Factura de energía sustentable',        58.20, 'Servicios',    'Transferencia',   "#{mes_anterior}-22"],
      ['Libros de diseño y papelería japonesa', 39.00, 'Otros',        'Tarjeta Crédito', "#{mes_anterior}-27"]
    ].each do |descripcion, monto, categoria, metodo, fecha|
      Gasto.new(
        'usuario_id'  => demo_user&.id,
        'descripcion' => descripcion,
        'monto'       => monto,
        'categoria'   => categoria,
        'metodo_pago' => metodo,
        'fecha'       => fecha
      ).save
    end
  end
end
