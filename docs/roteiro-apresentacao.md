# Roteiro para Apresentacao

Este roteiro pode ser usado para explicar o projeto em sala.

## 1. Ideia do projeto

O Gabarita e um app de estudos para alunos treinarem questoes do ENEM de forma offline.

Ele permite:

- resolver questoes;
- receber feedback;
- criar simulados;
- acompanhar estatisticas;
- revisar erros;
- manter progresso e streak.

## 2. Diferencial offline

O app nao depende de uma API externa para carregar questoes.

As questoes ficam em JSON dentro do proprio aplicativo e sao importadas para SQLite.

Isso permite:

- estudar sem internet;
- filtrar questoes rapidamente;
- salvar respostas e progresso localmente.

## 3. Arquitetura

Explique a divisao:

- `domain`: regras de negocio;
- `data`: banco, JSON e repositorios;
- `presentation`: telas e providers;
- `services`: recursos do celular.

Frase util:

> A tela nao fala diretamente com o banco. Ela chama um Provider, que chama um caso de uso, que chama um repositorio.

## 4. Banco de dados

Mostre o `DatabaseHelper`.

Pontos importantes:

- cria tabelas;
- abre SQLite;
- salva questoes;
- salva tentativas;
- atualiza streak;
- atualiza estatisticas;
- remove duplicatas;
- filtra questoes por ano, disciplina e favoritas.

## 5. Providers

Explique que Provider e o gerenciador de estado.

Exemplos:

- `UserProvider`: perfil, nome, foto, meta e streak;
- `QuestionsProvider`: questoes, filtros, resposta e favoritos;
- `SessionProvider`: simulados;
- `StatisticsProvider`: graficos e desempenho.

## 6. Telas

Apresente as telas principais:

1. Splash
2. Home
3. Questoes
4. Responder Questao
5. Feedback
6. Simulado
7. Estatisticas
8. Revisao Inteligente
9. Perfil

## 7. Widgets obrigatorios

Destaque:

- `LinearProgressIndicator`: progresso semanal, progresso da questao, acerto por disciplina;
- `Slider`: quantidade de questoes do simulado;
- `ChoiceChip`: filtros de disciplinas;
- `DropdownButton`: filtro por ano do ENEM;
- `TabBar`: abas da revisao inteligente.

## 8. Recursos nativos

Explique:

- camera: foto de perfil;
- GPS: local de estudo;
- acelerometro: Modo Foco;
- notificacoes: lembretes/revisao;
- home widgets: atalhos Android.

## 9. Demonstracao sugerida

1. Abrir o app.
2. Mostrar Home e progresso.
3. Abrir Questoes.
4. Filtrar por ENEM especifico.
5. Responder uma questao.
6. Mostrar Feedback.
7. Abrir Simulado e mover Slider.
8. Abrir Estatisticas.
9. Abrir Revisao Inteligente.
10. Abrir Perfil e trocar foto.

## 10. Fechamento

Frase final sugerida:

> O projeto demonstra uma aplicacao Flutter completa, offline, com persistencia local, Clean Architecture, Provider, sensores do dispositivo e uma interface educacional focada em desempenho e revisao.
