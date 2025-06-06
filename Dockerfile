FROM ruby:3.4.2-slim-bullseye

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    postgresql-client \
    libyaml-dev \
    nodejs \
    yarn \
    && rm -rf /var/lib/apt/lists/*

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Copia o Gemfile e Gemfile.lock primeiro para aproveitar o cache do Docker
COPY Gemfile Gemfile.lock ./

ENV PATH="/usr/local/bundle/bin:${PATH}"
# Instala as gems
RUN bundle install --jobs $(nproc) --retry 3

# Copia o restante do código da aplicação
COPY . .

RUN chmod +x /app/bin/*

# Expõe a porta que a aplicação Rails usa (padrão é 3000)
EXPOSE 3000