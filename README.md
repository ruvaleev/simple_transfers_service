# Simple Transfers Service

Simple service for Alice and Bob to transfer money.

When you create an order, it is assumed to be in processing. The initiator can confirm or cancel it — emulating outcomes that in real life might happen anywhere in between Alice and Bob.

## Installation

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails s
```

## Tests

```bash
bundle exec rspec
```

## Linters

```bash
bundle exec rubocop
```

## Database Consistency

```bash
bundle exec database_consistency
```

## Bundle Audit

```bash
bundle exec bundler-audit --update
```
