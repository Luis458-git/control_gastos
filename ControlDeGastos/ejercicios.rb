# Archivo de práctica. Ejecútalo con:  ruby ejercicios.rb
# Lee cada sección, mira lo que imprime y luego intenta los RETOS.

puts '=== 1. Variables e interpolación ==='
descripcion = 'Supermercado'
monto = 84.5
puts "Gasté $#{monto} en #{descripcion}"
# RETO: crea una variable `categoria` e inclúyela en el mensaje.

puts "\n=== 2. Arreglos ==="
montos = [84.5, 42.0, 25.0, 65.0, 38.9]
puts "Cantidad de gastos: #{montos.size}"
puts "Total: #{montos.sum}"
puts "Mayor: #{montos.max}"
# RETO: imprime el menor y el promedio (pista: suma / cantidad).

puts "\n=== 3. Bloques ==="
montos.each { |m| puts " - $#{m}" }
caros = montos.select { |m| m > 40 }
puts "Gastos mayores a 40: #{caros.inspect}"
con_iva = montos.map { |m| (m * 1.16).round(2) }
puts "Con IVA: #{con_iva.inspect}"
# RETO: usa `reject` para obtener los gastos de 40 o menos.

puts "\n=== 4. Hashes ==="
gastos = [
  { descripcion: 'Super', monto: 84.5, categoria: 'Alimentación' },
  { descripcion: 'Luz',   monto: 42.0, categoria: 'Servicios' },
  { descripcion: 'Café',  monto: 19.75, categoria: 'Alimentación' }
]
gastos.each do |g|
  puts "#{g[:descripcion].ljust(8)} #{g[:categoria].ljust(14)} $#{g[:monto]}"
end

por_categoria = gastos.group_by { |g| g[:categoria] }
por_categoria.each do |categoria, lista|
  subtotal = lista.sum { |g| g[:monto] }
  puts "#{categoria}: $#{subtotal}"
end
# RETO: agrega un gasto de 'Transporte' y vuelve a ejecutar.

puts "\n=== 5. Métodos ==="
def formato_moneda(cantidad)
  format('$%.2f', cantidad)
end

def es_caro?(cantidad)
  cantidad > 50
end

puts formato_moneda(84.5)
puts "¿84.5 es caro? #{es_caro?(84.5)}"
# RETO: escribe un método `aplicar_descuento(cantidad, porcentaje)`.

puts "\n=== 6. Clases ==="
class Gasto
  attr_reader :descripcion, :monto

  def initialize(descripcion, monto)
    @descripcion = descripcion
    @monto = monto
  end

  def to_s
    "#{descripcion}: $#{format('%.2f', monto)}"
  end
end

cine = Gasto.new('Cine', 38.9)
puts cine
# RETO: agrega un atributo `categoria` y un método `caro?`.

puts "\n¡Listo! Ahora modifica este archivo y vuelve a ejecutarlo."
