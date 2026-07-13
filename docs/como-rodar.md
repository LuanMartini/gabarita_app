# Como Rodar o App

Este guia mostra como preparar o ambiente, instalar dependencias e executar o Gabarita em um celular Android.

## Requisitos

- Flutter instalado.
- Android Studio ou Android SDK instalado.
- Celular Android com depuracao USB ativada.
- Cabo USB.
- Git instalado.

## Instalar dependencias

Na raiz do projeto:

```bash
flutter pub get
```

## Verificar ambiente

```bash
flutter doctor
```

Resolva os itens marcados como erro antes de rodar em celular.

## Ativar modo desenvolvedor no Windows

Se aparecer a mensagem sobre suporte a symlink:

```powershell
start ms-settings:developers
```

Ative o modo desenvolvedor nas configuracoes do Windows.

## Conectar celular Android

No celular:

1. Abra as configuracoes.
2. Entre em "Sobre o telefone".
3. Toque varias vezes em "Numero da versao" para ativar modo desenvolvedor.
4. Volte nas configuracoes.
5. Abra "Opcoes do desenvolvedor".
6. Ative "Depuracao USB".
7. Conecte o celular no computador.
8. Aceite a permissao de depuracao USB no celular.

## Conferir dispositivos

```bash
flutter devices
```

O celular deve aparecer na lista.

## Rodar no celular

```bash
flutter run
```

Se houver mais de um dispositivo:

```bash
flutter run -d ID_DO_DISPOSITIVO
```

## Gerar APK debug

```bash
flutter build apk --debug
```

Arquivo gerado:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Validar codigo

```bash
dart analyze
```

ou:

```bash
flutter analyze
```

## Rodar testes

```bash
flutter test
```

## Problemas comuns

### Push rejeitado no GitHub

Se aparecer `fetch first`:

```bash
git pull --rebase origin main
git push origin main
```

### Celular nao aparece

Tente:

```bash
adb devices
```

Se aparecer `unauthorized`, aceite a permissao no celular.

### Permissoes de camera, GPS e notificacao

No primeiro uso, o Android pode pedir permissao. Permita para testar todos os recursos.
