# frozen_string_literal: true

require 'digest'
require 'securerandom'

# Modelo Usuario: autenticación con hash SHA-256 + salt aleatorio,
# gestión de presupuesto mensual y cuenta demo.
class Usuario
  attr_accessor :id, :nombre, :email, :password_hash, :presupuesto_mensual, :created_at
  attr_reader :errors

  def initialize(attrs = {})
    attrs = attrs.transform_keys(&:to_s)
    @id                  = attrs['id']&.to_i
    @nombre              = attrs['nombre'].to_s.strip
    @email               = attrs['email'].to_s.strip.downcase
    @password_hash       = attrs['password_hash'].to_s
    @presupuesto_mensual = (attrs['presupuesto_mensual'] || 1500.0).to_f
    @created_at          = attrs['created_at']&.to_s
    @errors              = []
  end

  def self.find(id)
    return nil unless id.to_s.match?(/\A\d+\z/)

    fila = Database.query('SELECT * FROM usuarios WHERE id = ?', [id.to_i]).first
    fila && new(fila)
  end

  def self.find_by_email(email)
    limpio = email.to_s.strip.downcase
    return nil if limpio.empty?

    fila = Database.query('SELECT * FROM usuarios WHERE email = ?', [limpio]).first
    fila && new(fila)
  end

  def self.count
    Database.query('SELECT COUNT(*) AS total FROM usuarios').first['total'].to_i
  end

  def self.autenticar(email, password)
    usuario = find_by_email(email)
    return nil unless usuario && usuario.verificar_password?(password)

    usuario
  end

  def self.cifrar_password(password, salt = SecureRandom.hex(16))
    hash = Digest::SHA256.hexdigest("#{salt}:#{password}")
    "#{salt}$#{hash}"
  end

  def verificar_password?(password)
    salt, hash_guardado = password_hash.split('$', 2)
    return false if salt.nil? || hash_guardado.nil?

    calculado = Digest::SHA256.hexdigest("#{salt}:#{password}")
    Rack::Utils.secure_compare(calculado, hash_guardado)
  end

  def iniciales
    partes = nombre.split(/\s+/).reject(&:empty?)
    return 'U' if partes.empty?

    partes.first(2).map { |p| p[0].upcase }.join
  end

  def registrar(password)
    @errors = []
    @errors << 'El nombre es obligatorio.' if nombre.empty?
    if email.empty? || !email.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
      @errors << 'Ingresa un correo electrónico válido.'
    elsif Usuario.find_by_email(email)
      @errors << 'Ese correo electrónico ya está registrado.'
    end

    if password.to_s.length < 4
      @errors << 'La contraseña debe tener al menos 4 caracteres.'
    end

    return false unless @errors.empty?

    @password_hash = self.class.cifrar_password(password)
    Database.execute(
      'INSERT INTO usuarios (nombre, email, password_hash, presupuesto_mensual) VALUES (?, ?, ?, ?)',
      [nombre, email, password_hash, presupuesto_mensual]
    )
    creado = Usuario.find_by_email(email)
    @id = creado&.id
    true
  end

  def actualizar_presupuesto(nuevo_monto)
    texto = nuevo_monto.to_s.strip.tr(',', '.')
    return false unless texto.match?(/\A\d+(\.\d{1,2})?\z/) && texto.to_f.positive?

    @presupuesto_mensual = texto.to_f
    Database.execute(
      'UPDATE usuarios SET presupuesto_mensual = ? WHERE id = ?',
      [@presupuesto_mensual, id]
    )
    true
  end
end
