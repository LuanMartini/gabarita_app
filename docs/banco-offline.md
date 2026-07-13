# Banco Offline do ENEM

O Gabarita nao consome API externa para carregar questoes. As questoes ficam em arquivos JSON locais dentro do app.

## Local dos arquivos

```text
assets/data/enem/
```

Essa pasta contem:

- `index.json`;
- `enem_2009.json`;
- `enem_2010.json`;
- arquivos equivalentes ate `enem_2025.json`.

## Como o banco e preparado

1. O app abre.
2. `QuestionsProvider` chama o caso de uso `EnsureLocalEnemBank`.
3. O repositorio usa `EnemLocalDataSource`.
4. O datasource le os JSONs locais.
5. As questoes sao convertidas para entidades `Question`.
6. O `DatabaseHelper` salva as questoes no SQLite.
7. O app passa a consultar o SQLite.

## Por que usar SQLite se ja existe JSON?

O JSON e bom para empacotar dados no app, mas o SQLite e melhor para:

- pesquisar por texto;
- filtrar por disciplina;
- filtrar por ano do ENEM;
- marcar favoritas;
- montar simulados;
- salvar tentativas;
- calcular estatisticas;
- evitar duplicatas.

## Limpeza de questoes

Durante a importacao, o app remove ou ignora questoes que:

- nao possuem enunciado textual;
- nao possuem alternativas completas;
- possuem gabarito invalido;
- dependem de imagem, grafico, tabela ou figura;
- aparecem duplicadas.

## Tabelas principais

### `users`

Guarda o perfil local:

- nome;
- avatar;
- streak;
- total respondido;
- total de acertos.

### `questions`

Guarda as questoes:

- enunciado;
- disciplina;
- topico;
- ano;
- fonte;
- alternativas;
- gabarito;
- explicacao.

### `question_alternatives`

Guarda alternativas normalizadas por questao.

### `attempts`

Guarda cada resposta do aluno:

- usuario;
- questao;
- alternativa marcada;
- se acertou;
- tempo gasto;
- localizacao opcional.

### `study_sessions`

Guarda simulados finalizados.

### `study_progress`

Guarda streak e meta semanal.

### `favorite_questions`

Guarda questoes favoritas por usuario.

### `app_settings`

Guarda configuracoes simples, como a versao do banco offline importado.

## Onde esta o codigo principal?

- `lib/data/datasources/local/enem_local_data_source.dart`
- `lib/data/models/enem_question_remote_model.dart`
- `lib/data/repositories/question_repository_impl.dart`
- `lib/data/datasources/local/database_helper.dart`
