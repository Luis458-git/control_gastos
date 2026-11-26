# Control de Gastos Personales (Ruby + Sinatra + Puma)

Aplicación web para registrar gastos personales, con CRUD completo, total por mes y desglose por categoría. Diseño inspirado en WeTransfer Web (tarjetas blancas sobre fondo gris claro, bordes de 1px, tipografía clara).

## Estructura del proyecto (MVC)

```text
ControlDeGastos/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb  # Configuración base de Sinatra (vistas, public, method_override)
│   │   └── gastos_controller.rb       # Rutas CRUD: solo coordina modelo y vistas
│   ├── helpers/
│   │   └── application_helper.rb      # h() anti-XSS, formato de moneda, meses, badges
│   ├── models/
│   │   └── gasto.rb                   # Entidad Gasto: validaciones y consultas SQL parametrizadas
│   └── views/
│       ├── layout.erb                 # Estructura HTML común
│       └── gastos/
│           ├── index.erb              # Pantalla 1: registro, total del mes y listado
│           └── edit.erb               # Pantalla 2: edición de un gasto
├── config/
│   ├── environment.rb                 # Carga gemas, .env y todas las capas
│   ├── database.rb                    # Conexión SQLite3 / PostgreSQL y creación de tabla
│   └── puma.rb                        # Puerto e hilos del servidor
├── db/
│   └── seeds.rb                       # Datos de ejemplo (solo si la tabla está vacía)
├── public/
│   └── css/styles.css                 # Estilos
├── app.rb                             # Atajo: `ruby app.rb`
├── config.ru                          # Entrada Rack para Puma
├── Gemfile / Gemfile.lock
├── .env.example
├── .gitignore
└── Dockerfile
```

**Responsabilidades:**

- **Modelo** (`gasto.rb`): reglas de negocio. Es el único lugar con SQL.
- **Controlador** (`gastos_controller.rb`): recibe la petición, llama al modelo y elige la vista o redirección.
- **Vistas** (`.erb`): solo presentación; todo dato se imprime con `h(...)`.
- **Config**: arranque y conexión, separado de la lógica.

## Rutas

| Método | Ruta | Acción |
|---|---|---|
| GET | `/?mes=YYYY-MM` o `/?mes=todos` | Listado, total del mes y desglose |
| POST | `/gastos` | Crear gasto |
| GET | `/gastos/:id/editar` | Formulario de edición |
| POST / PATCH | `/gastos/:id` | Actualizar gasto |
| POST | `/gastos/:id/eliminar` | Eliminar gasto |
| DELETE | `/gastos/:id` | Eliminar gasto |

## Correr en local (Windows)

```powershell
ruby -v                 # si dice "no reconocido", cierra y abre la terminal
gem install bundler
bundle install
bundle exec puma        # o: ruby app.rb
```

Luego abre http://localhost:4567

Sin `DATABASE_URL`, se crea automáticamente `db/gastos.sqlite3` con datos de ejemplo. Para cambiar el puerto o la base de datos, copia `.env.example` a `.env` y edítalo.

## Desplegar gratis en Render (PostgreSQL)

1. Sube el proyecto a GitHub.
2. En Render, crea una base **PostgreSQL** (New → PostgreSQL) y copia su *Internal Database URL*.
3. Crea un **Web Service** conectado al repositorio:
   - Build Command: `bundle install`
   - Start Command: `bundle exec puma -C config/puma.rb`
   - (o elige runtime **Docker** para usar el `Dockerfile`)
4. Variables de entorno: `DATABASE_URL` = la URL de PostgreSQL, `RACK_ENV` = `production`.

Al arrancar, la tabla `gastos` se crea sola si no existe.

## Seguridad

- **SQL injection**: todas las consultas usan parámetros (`?` en SQLite, `$1` en PostgreSQL).
- **XSS**: todos los textos en las vistas pasan por `h()` (`Rack::Utils.escape_html`).
- **Asignación masiva**: el controlador solo acepta los campos `descripcion`, `monto`, `categoria` y `fecha`.
