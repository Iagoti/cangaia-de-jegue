# Cangaia de Jegue

Aplicativo Flutter para controle de vendas da Cavalgada Cangaia de Jegue.

## Funcionalidades

- Login de vendedores.
- Registro, edicao e exclusao de vendas.
- Controle de pagamentos e recibos.
- Registro de entrega de camisas com mensagem via WhatsApp.
- Cadastro, edicao e exclusao de despesas.
- Dashboard com totais de vendas, valores recebidos, pendencias e despesas.
- Sincronizacao com Supabase quando houver registros pendentes.
- Icone e logo personalizados do evento.

## Tecnologias

- Flutter
- Dart
- SQLite local com `sqflite`
- Supabase via API REST

## Como Rodar

Instale as dependencias:

```sh
flutter pub get
```

Execute o app:

```sh
flutter run
```

Analise o projeto:

```sh
flutter analyze
```

## Usuarios Padrao

- Usuario: `Elana`
- Usuario: `William`
- Senha: `cangaiadejegue`

Tambem existe acesso administrativo usado na configuracao inicial do banco.
