# frozen_string_literal: true

# Rutas HTTP: Página Principal (/welcome), Autenticación (/login, /registro, /demo)
# y Panel Financiero de Gastos (CRUD + Presupuesto + Filtros por mes y categoría).
class GastosController < ApplicationController
  CAMPOS = %w[descripcion monto categoria metodo_pago fecha].freeze

  # ---------- PÁGINA PRINCIPAL (LANDING EDITORIAL) ----------
  get '/welcome' do
    @total_historico = Gasto.total(Gasto.all)
    @conteo_historico = Gasto.count
    erb :home
  end

  # ---------- AUTENTICACIÓN (LOGIN / REGISTRO / DEMO) ----------
  get '/login' do
    @error = nil
    erb :'auth/login'
  end

  post '/login' do
    usuario = Usuario.autenticar(params[:email], params[:password])
    if usuario
      session[:usuario_id] = usuario.id
      redirect '/?notice=bienvenido'
    else
      @error = 'Correo o contraseña incorrectos. Verifica tus datos o usa la Cuenta Demo.'
      @email_intento = params[:email]
      status 401
      erb :'auth/login'
    end
  end

  get '/registro' do
    @usuario = Usuario.new
    erb :'auth/register'
  end

  post '/registro' do
    @usuario = Usuario.new(
      'nombre' => params[:nombre],
      'email' => params[:email],
      'presupuesto_mensual' => params[:presupuesto_mensual].to_s.empty? ? 1500.0 : params[:presupuesto_mensual]
    )
    if @usuario.registrar(params[:password])
      session[:usuario_id] = @usuario.id
      redirect '/?notice=bienvenido'
    else
      status 422
      erb :'auth/register'
    end
  end

  post '/demo' do
    demo = Usuario.find_by_email(Seeds::DEMO_EMAIL)
    session[:usuario_id] = demo.id if demo
    redirect '/?notice=bienvenido'
  end

  post '/logout' do
    session.clear
    redirect '/welcome'
  end

  get '/logout' do
    session.clear
    redirect '/welcome'
  end

  # ---------- PRESUPUESTO MENSUAL ----------
  post '/presupuesto' do
    usuario = current_user || Usuario.find_by_email(Seeds::DEMO_EMAIL)
    usuario&.actualizar_presupuesto(params[:presupuesto_mensual])
    mes = Gasto.normalizar_mes(params[:mes])
    redirect "/?mes=#{Rack::Utils.escape(mes)}&notice=presupuesto"
  end

  # ---------- DASHBOARD Y CRUD DE GASTOS ----------
  get '/' do
    @mes = Gasto.normalizar_mes(params[:mes])
    @categoria_filtro = params[:categoria].to_s.strip
    @gasto = Gasto.new(
      'categoria'   => Gasto::CATEGORIAS.first,
      'metodo_pago' => Gasto::METODOS_PAGO.first,
      'fecha'       => Date.today.iso8601
    )
    cargar_resumen
    erb :'gastos/index'
  end

  # Crear gasto
  post '/gastos' do
    atributos = gasto_params
    atributos['usuario_id'] = current_user&.id
    @gasto = Gasto.new(atributos)

    if @gasto.save
      redirect "/?mes=#{Rack::Utils.escape(@gasto.mes)}&notice=creado"
    else
      @mes = Gasto.normalizar_mes(params[:mes])
      @categoria_filtro = ''
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

  # Actualizar (POST o PATCH)
  post('/gastos/:id')  { actualizar }
  patch('/gastos/:id') { actualizar }

  # Eliminar (POST o DELETE)
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

  def gasto_params
    CAMPOS.to_h { |campo| [campo, params[campo]] }
  end

  def cargar_resumen
    uid = current_user&.id
    todos_del_mes      = Gasto.por_mes(@mes, usuario_id: uid)
    @gastos            = Gasto.por_mes(@mes, usuario_id: uid, categoria: @categoria_filtro)
    @total             = Gasto.total(todos_del_mes)
    @total_filtrado    = Gasto.total(@gastos)
    @mayor_gasto       = Gasto.mayor_gasto(todos_del_mes)
    @promedio_diario   = Gasto.promedio_diario(todos_del_mes)
    @desglose          = Gasto.desglose_por_categoria(todos_del_mes)
    @meses_disponibles = Gasto.meses_disponibles(usuario_id: uid)
    @totales_por_mes   = Gasto.totales_por_mes(usuario_id: uid)

    usuario_activo     = current_user || Usuario.find_by_email(Seeds::DEMO_EMAIL)
    @presupuesto       = usuario_activo ? usuario_activo.presupuesto_mensual : 1500.0
  end
end
