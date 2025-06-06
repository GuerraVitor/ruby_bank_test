# Ruby Bank Test

Projeto para vaga de estágio.

## Pré-requisitos

Para executar este projeto, você precisará ter instalado:

*   [Docker](https://docs.docker.com/get-docker/)
*   [Docker Compose](https://docs.docker.com/compose/install/) 

## Como Executar o Projeto (Usando Docker)

1.  **Clone o Repositório (ou extraia o arquivo .zip):**
    ```bash
    git clone <URL_DO_SEU_REPOSITORIO_GIT>
    cd ruby_bank_test
    ```
    Ou, se você forneceu um arquivo .zip, extraia-o e navegue para o diretório do projeto.

2.  **Construa as Imagens e Inicie os Containers:**
    No diretório raiz do projeto (`ruby_bank_test`), execute o seguinte comando:
    ```bash
    docker compose up --build
    ```
    *   Este comando irá:
        *   Construir a imagem Docker para a aplicação Rails (se ainda não existir ou se houver alterações no `Dockerfile`).
        *   Baixar a imagem do PostgreSQL.
        *   Iniciar os containers da aplicação e do banco de dados.
        *   Aguardar o PostgreSQL ficar pronto.
        *   Criar o banco de dados (`bank_app_development`).
        *   Executar as migrações do banco de dados.
        *   Popular o banco de dados com dados iniciais (`db/seeds.rb`), incluindo os usuários de exemplo.
        *   Iniciar o servidor Rails.

    *   (Opcional) Para rodar em segundo plano (detached mode), adicione `-d`:
        ```bash
        docker compose up --build -d
        ```

3.  **Acesse a Aplicação:**
    Após os containers iniciarem e o servidor Rails estiver rodando (você verá logs indicando isso no terminal), abra seu navegador e acesse:
    *   **URL da Aplicação Web:** http://localhost:3000

## Banco de Dados e Usuários de Exemplo

*   **Banco de Dados:** O projeto utiliza PostgreSQL, configurado e gerenciado via Docker.
    *   **Host (para acesso externo, se necessário):** `localhost`
    *   **Porta (mapeada no host):** `5432`
    *   **Usuário:** `postgres`
    *   **Senha:** `password`
    *   **Nome do Banco (desenvolvimento):** `bank_app_development`

*   **Usuários de Exemplo (criados via `db/seeds.rb`):**
    As seguintes contas de usuário foram criadas para demonstração. A senha para todos é `1234`.

    *   Usuário: `12345` | Senha: `1234`
    *   Usuário: `54321` | Senha: `1234` (VIP)
    *   Usuário: `11111` | Senha: `1234`

## Para Parar a Aplicação

*   Se você executou `docker compose up` diretamente no terminal, pressione `Ctrl+C` na janela do terminal onde os containers estão rodando.
*   Se você executou com a flag `-d` (detached mode), use o seguinte comando no diretório do projeto:
    ```bash
    docker compose down
    ```
    Este comando irá parar e remover os containers. Os dados do banco de dados persistirão no volume Docker (`ruby_bank_test_postgres_data`) para execuções futuras, a menos que o volume seja removido manualmente.

