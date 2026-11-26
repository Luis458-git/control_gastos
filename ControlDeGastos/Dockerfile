FROM ruby:3.3-slim

# Instalar librerías nativas del sistema para compilar extensiones C (sqlite3 y pg)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      libsqlite3-dev \
      libpq-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instalar gemas en producción (excluyendo grupos de desarrollo y pruebas si existieran)
COPY Gemfile Gemfile.lock* ./
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copiar el código del proyecto
COPY . .

# Variables de entorno por defecto
ENV RACK_ENV=production \
    PORT=4567

EXPOSE 4567

# Puma lee automáticamente config/puma.rb (hilos y puerto dinámico $PORT)
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
