# Arquitetura do Projeto

O Gabarita segue uma estrutura inspirada em Clean Architecture. A ideia e separar responsabilidades para facilitar manutencao, testes e explicacao do codigo.

## Camadas

```text
lib/
  core/
  data/
  domain/
  presentation/
  services/
```

## `core`

Contem configuracoes e constantes compartilhadas.

Exemplos:

- nomes de tabelas e colunas do SQLite;
- inicializacao da fabrica do banco;
- configuracoes que nao pertencem a uma tela especifica.

## `domain`

E a camada de regra de negocio pura.

Contem:

- entidades como `User`, `Question` e `Attempt`;
- contratos de repositorio, como `IQuestionRepository`;
- casos de uso, como `GetQuestionsByFilter`, `SaveAttempt` e `GenerateSimulado`.

Essa camada nao deve depender de Flutter nem de SQLite diretamente.

## `data`

E a camada que sabe como os dados sao armazenados e recuperados.

Contem:

- `DatabaseHelper`;
- models para converter dados entre entidade, JSON e SQLite;
- implementacoes dos repositorios;
- leitura dos JSONs locais do ENEM.

## `presentation`

E a camada visual do app.

Contem:

- telas em `presentation/screens`;
- providers em `presentation/providers`;
- widgets e estados de interface.

Os providers fazem a ponte entre as telas e os casos de uso.

## `services`

Contem integracoes com recursos nativos:

- acelerometro;
- GPS;
- camera;
- notificacoes locais;
- home widgets Android.

## Fluxo geral

```text
Tela
  -> Provider
    -> UseCase
      -> Repository interface
        -> Repository implementation
          -> DatabaseHelper / JSON local / plugin nativo
```

Exemplo ao responder uma questao:

```text
AnswerScreen
  -> QuestionsProvider.confirmSelectedAnswer
    -> SaveAttempt
      -> AttemptRepositoryImpl
        -> DatabaseHelper.insertAttempt
```

## Vantagens

- A tela nao conversa diretamente com SQLite.
- A regra de negocio fica separada da interface.
- O banco pode ser testado sem abrir telas.
- O codigo fica mais facil de explicar na apresentacao.
