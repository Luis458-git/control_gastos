# frozen_string_literal: true

# Rutas HTTP del recurso Gasto. Solo coordina: recibe parámetros,
# delega al modelo y decide qué vista mostrar o a dónde redirigir.
class GastosController < ApplicationController
  CAMPOS = %w[descripcion monto categoria fecha].freeze

  # Listado + filtro por mes + totales
  get '/' do
    @mes = Gasto.normalizar_mes(params[:mes])
    @gasto = Gasto.new('categoria' => Gasto::CATEGORIAS.first, 'fecha' => Date.today.iso8601)
    cargar_resumen
    erb :'gastos/index'
  end

  # Crear
  post '/gastos' do
    @gasto = Gasto.new(gasto_params)
    if @gasto.save
      redirect "/?mes=#{Rack::Utils.escape(@gasto.mes)}&notice=creado"
    else
      @mes = Gasto.normalizar_mes(params[:mes])
      cargar_resumen
      status 422
      erb :'gastos/index'
    end
  end

  # Formulario de edición
  get '/gastos/:id/editar' do
    @gasto = buscar_gasto!
    erb :'gastos/edit'
  end

  # Actualizar (POST normal o PATCH vía _method)
  post('/gastos/:id')  { actualizar }
  patch('/gastos/:id') { actualizar }

  # Eliminar (POST normal o DELETE vía _method)
  post('/gastos/:id/eliminar') { eliminar }
  delete('/gastos/:id')        { eliminar }

  private

  def actualizar
    @gasto = buscar_gasto!
    if @gasto.update(gasto_params)
      redirect "/?mes=#{Rack::Utils.escape(@gasto.mes)}&notice=actualizado"
    else
      status 422
      erb :'gastos/edit'
    end
  end

  def eliminar
    buscar_gasto!.destroy
    mes = Gasto.normalizar_mes(params[:mes])
    redirect "/?mes=#{Rack::Utils.escape(mes)}&notice=eliminado"
  end

  def buscar_gasto!
    Gasto.find(params[:id]) || halt(404, 'Gasto no encontrado')
  end

  # Lista blanca de campos permitidos (evita asignar campos inesperados).
  def gasto_params
    CAMPOS.to_h { |campo| [campo, params[campo]] }
  end

  def cargar_resumen
    @gastos            = Gasto.por_mes(@mes)
    @total             = Gasto.total(@gastos)
    @desglose          = Gasto.desglose_por_categoria(@gastos)
    @meses_disponibles = Gasto.meses_disponibles
    @totales_por_mes   = Gasto.totales_por_mes
  end
end
