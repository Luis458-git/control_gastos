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
      postgres? ? crear_tabla_postgres : crear_tabla_sqlite
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

    # Puma usa varios hilos: una sola conexión compartida necesita exclusión mutua.
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

    def crear_tabla_postgres
      execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS gastos (
          id          SERIAL PRIMARY KEY,
          descripcion VARCHAR(180)   NOT NULL,
          monto       NUMERIC(12, 2) NOT NULL CHECK (monto > 0),
          categoria   VARCHAR(50)    NOT NULL,
          fecha       DATE           NOT NULL,
          created_at  TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      SQL
    end

    def crear_tabla_sqlite
      execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS gastos (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          descripcion TEXT NOT NULL,
          monto       REAL NOT NULL CHECK (monto > 0),
          categoria   TEXT NOT NULL,
          fecha       TEXT NOT NULL,
          created_at  TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
        )
      SQL
    end

    def to_pg_placeholders(sql)
      indice = 0
      sql.gsub('?') { "$#{indice += 1}" }
    end

    def normalize_row(row)
      row.each_with_object({}) do |(clave, valor), resultado|
        next unless clave.is_a?(String)

        resultado[clave] = case clave
                           when 'monto' then valor.to_f
                           when 'fecha', 'created_at' then valor.to_s
                           else valor
                           end
      end
    end
  end
end
