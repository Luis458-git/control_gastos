# frozen_string_literal: true

require 'fileutils'

# Capa de acceso a datos.
# - SQLite3 en desarrollo (por defecto: db/gastos.sqlite3)
# - PostgreSQL si DATABASE_URL empieza con postgres:// o postgresql://
# Todas las consultas son parametrizadas (previene SQL injection).
module Database
  @mutex = Mutex.new

  class << self
    def postgres?
      ENV['DATABASE_URL'].to_s.strip.start_with?('postgres://', 'postgresql://')
    end

    # Expresión SQL fija (no viene del usuario) para comparar la fecha como texto.
    def fecha_como_texto
      postgres? ? 'CAST(fecha AS TEXT)' : 'fecha'
    end

    def setup!
      postgres? ? crear_tablas_postgres : crear_tablas_sqlite
      migrar_columnas_Existentes!
      execute('CREATE INDEX IF NOT EXISTS idx_gastos_fecha ON gastos (fecha DESC)')
    end

    # Devuelve un arreglo de hashes con claves String.
    # Usa "?" como marcador; en PostgreSQL se traduce a $1, $2...
    def query(sql, params = [])
      synchronize do
        rows = if postgres?
                 connection.exec_params(to_pg_placeholders(sql), params).to_a
               else
                 connection.execute(sql, params)
               end
        rows.map { |row| normalize_row(row) }
      end
    end

    def execute(sql, params = [])
      synchronize do
        if postgres?
          connection.exec_params(to_pg_placeholders(sql), params)
        else
          connection.execute(sql, params)
        end
      end
    end

    private

    def synchronize(&block)
      @mutex.owned? ? block.call : @mutex.synchronize(&block)
    end

    def connection
      @connection ||= postgres? ? conectar_postgres : conectar_sqlite
    end

    def conectar_postgres
      require 'pg'
      conn = PG.connect(ENV['DATABASE_URL'])
      conn.type_map_for_results = PG::BasicTypeMapForResults.new(conn)
      conn
    end

    def conectar_sqlite
      require 'sqlite3'
      path = sqlite_path
      FileUtils.mkdir_p(File.dirname(path))
      db = SQLite3::Database.new(path)
      db.results_as_hash = true
      db.busy_timeout = 5000
      db
    end

    def sqlite_path
      url = ENV['DATABASE_URL'].to_s.strip
      relativo = url.sub(%r{\Asqlite3:(//)?}i, '')
      relativo = 'db/gastos.sqlite3' if relativo.empty?
      File.expand_path(relativo, APP_ROOT)
    end

    def crear_tablas_postgres
      execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS usuarios (
          id                  SERIAL PRIMARY KEY,
          nombre              VARCHAR(100)   NOT NULL,
          email               VARCHAR(160)   NOT NULL UNIQUE,
          password_hash       VARCHAR(255)   NOT NULL,
          presupuesto_mensual NUMERIC(12, 2) NOT NULL DEFAULT 1500.00,
          created_at          TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      SQL

      execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS gastos (
          id          SERIAL PRIMARY KEY,
          usuario_id  INTEGER,
          descripcion VARCHAR(180)   NOT NULL,
          monto       NUMERIC(12, 2) NOT NULL CHECK (monto > 0),
          categoria   VARCHAR(50)    NOT NULL,
          metodo_pago VARCHAR(50)    NOT NULL DEFAULT 'Tarjeta',
          fecha       DATE           NOT NULL,
          created_at  TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      SQL
    end

    def crear_tablas_sqlite
      execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS usuarios (
          id                  INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre              TEXT NOT NULL,
          email               TEXT NOT NULL UNIQUE,
          password_hash       TEXT NOT NULL,
          presupuesto_mensual REAL NOT NULL DEFAULT 1500.00,
          created_at          TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
        )
      SQL

      execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS gastos (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          usuario_id  INTEGER,
          descripcion TEXT NOT NULL,
          monto       REAL NOT NULL CHECK (monto > 0),
          categoria   TEXT NOT NULL,
          metodo_pago TEXT NOT NULL DEFAULT 'Tarjeta',
          fecha       TEXT NOT NULL,
          created_at  TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
        )
      SQL
    end

    # Si la tabla gastos ya existía de antes sin usuario_id o metodo_pago, las agrega sin perder datos.
    def migrar_columnas_Existentes!
      if postgres?
        execute('ALTER TABLE gastos ADD COLUMN IF NOT EXISTS usuario_id INTEGER')
        execute("ALTER TABLE gastos ADD COLUMN IF NOT EXISTS metodo_pago VARCHAR(50) NOT NULL DEFAULT 'Tarjeta'")
      else
        cols = query('PRAGMA table_info(gastos)').map { |c| c['name'] }
        execute('ALTER TABLE gastos ADD COLUMN usuario_id INTEGER') unless cols.include?('usuario_id')
        execute("ALTER TABLE gastos ADD COLUMN metodo_pago TEXT NOT NULL DEFAULT 'Tarjeta'") unless cols.include?('metodo_pago')
      end
    end

    def to_pg_placeholders(sql)
      indice = 0
      sql.gsub('?') { "$#{indice += 1}" }
    end

    def normalize_row(row)
      row.each_with_object({}) do |(clave, valor), resultado|
        next unless clave.is_a?(String)

        resultado[clave] = case clave
                           when 'monto', 'presupuesto_mensual' then valor.to_f
                           when 'fecha', 'created_at' then valor.to_s
                           else valor
                           end
      end
    end
  end
end
