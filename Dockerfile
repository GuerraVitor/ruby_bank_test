FROM ruby:3.1.2-slim-bullseye

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libyaml-dev \
    nodejs \
    yarn \
    && rm -rf /var/lib/apt/lists/*

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia o Gemfile e Gemfile.lock primeiro para aproveitar o cache do Docker
COPY Gemfile Gemfile.lock ./

# Instala as gems
RUN bundle install --jobs $(nproc) --retry 3

# Copia o restante do código da aplicação
COPY . .

# Expõe a porta que a aplicação Rails usa (padrão é 3000)
EXPOSE 3000

# O comando para iniciar a aplicação será definido no docker-compose.yml
# para garantir que o banco de dados esteja pronto antes.