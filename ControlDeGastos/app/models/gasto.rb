# frozen_string_literal: true

# Modelo Gasto: reglas de negocio, validaciones y consultas.
# Ni el controlador ni las vistas escriben SQL; todo pasa por aquí.
class Gasto
  CATEGORIAS = %w[Alimentación Transporte Servicios Salud Ocio Otros].freeze
  TODOS = 'todos'

  attr_accessor :id, :descripcion, :monto, :categoria, :fecha, :created_at
  attr_reader :errors

  def initialize(attrs = {})
    attrs = attrs.transform_keys(&:to_s)
    @id          = attrs['id']&.to_i
    @descripcion = attrs['descripcion'].to_s.strip
    @monto       = attrs['monto']
    @categoria   = attrs['categoria'].to_s.strip
    @fecha       = attrs['fecha'].to_s.strip
    @created_at  = attrs['created_at']&.to_s
    @errors      = []
  end

  # ---------- Consultas (métodos de clase) ----------

  def self.all
    Database.query('SELECT * FROM gastos ORDER BY fecha DESC, id DESC').map { |fila| new(fila) }
  end

  def self.find(id)
    return nil unless id.to_s.match?(/\A\d+\z/)

    fila = Database.query('SELECT * FROM gastos WHERE id = ?', [id.to_i]).first
    fila && new(fila)
  end

  def self.por_mes(mes)
    return all if mes == TODOS

    sql = "SELECT * FROM gastos WHERE #{Database.fecha_como_texto} LIKE ? ORDER BY fecha DESC, id DESC"
    Database.query(sql, ["#{mes}-%"]).map { |fila| new(fila) }
  end

  def self.count
    Database.query('SELECT COUNT(*) AS total FROM gastos').first['total'].to_i
  end

  # Acepta "YYYY-MM" o "todos"; cualquier otro valor se trata como "todos".
  def self.normalizar_mes(valor)
    valor = valor.to_s.strip
    valor.match?(/\A\d{4}-\d{2}\z/) ? valor : TODOS
  end

  def self.meses_disponibles
    meses = Database.query('SELECT fecha FROM gastos').map { |f| f['fecha'][0, 7] }
    meses << Date.today.strftime('%Y-%m')
    meses.uniq.sort.reverse
  end

  def self.total(gastos)
    gastos.sum(&:monto_valor)
  end

  def self.desglose_por_categoria(gastos)
    gastos.group_by(&:categoria)
          .transform_values { |lista| total(lista) }
          .sort_by { |_, subtotal| -subtotal }
  end

  def self.totales_por_mes
    all.group_by(&:mes)
       .transform_values { |lista| total(lista) }
       .sort_by { |mes, _| mes }
       .reverse
  end

  # ---------- Instancia ----------

  def mes
    fecha.to_s[0, 7]
  end

  def monto_valor
    monto.to_f
  end

  def persisted?
    !id.nil?
  end

  def update(attrs)
    attrs = attrs.transform_keys(&:to_s)
    @descripcion = attrs['descripcion'].to_s.strip
    @monto       = attrs['monto']
    @categoria   = attrs['categoria'].to_s.strip
    @fecha       = attrs['fecha'].to_s.strip
    save
  end

  def save
    return false unless valid?

    if persisted?
      Database.execute(
        'UPDATE gastos SET descripcion = ?, monto = ?, categoria = ?, fecha = ? WHERE id = ?',
        [descripcion, monto, categoria, fecha, id]
      )
    else
      Database.execute(
        'INSERT INTO gastos (descripcion, monto, categoria, fecha) VALUES (?, ?, ?, ?)',
        [descripcion, monto, categoria, fecha]
      )
    end
    true
  end

  def destroy
    Database.execute('DELETE FROM gastos WHERE id = ?', [id]) if persisted?
  end

  # ---------- Validaciones ----------

  def valid?
    @errors = []
    validar_descripcion
    validar_monto
    validar_categoria
    validar_fecha
    errors.empty?
  end

  private

  def validar_descripcion
    if descripcion.empty?
      errors << 'La descripción es obligatoria.'
    elsif descripcion.length > 180
      errors << 'La descripción no puede superar los 180 caracteres.'
    end
  end

  def validar_monto
    texto = monto.to_s.strip.tr(',', '.')
    if texto.match?(/\A\d+(\.\d{1,2})?\z/) && texto.to_f.positive?
      @monto = texto.to_f
    else
      errors << 'El monto debe ser un número positivo con hasta 2 decimales (ej. 125.50).'
    end
  end

  def validar_categoria
    errors << 'Selecciona una categoría válida.' unless CATEGORIAS.include?(categoria)
  end

  def validar_fecha
    unless fecha.match?(/\A\d{4}-\d{2}-\d{2}\z/)
      errors << 'La fecha debe tener el formato YYYY-MM-DD.'
      return
    end
    @fecha = Date.iso8601(fecha).iso8601
  rescue Date::Error
    errors << 'La fecha ingresada no existe en el calendario.'
  end
end
