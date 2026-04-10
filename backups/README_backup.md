# Parte 3 — Backup e Recovery com mysqldump (arquivo: README_backup.md e comandos de exemplo)

Objetivo: comandos práticos para gerar backups do banco ecommerce, de múltiplos bancos, incluindo routines, events e triggers, e como restaurar.

Comandos de backup (Linux/macOS/Windows WSL)
Backup de um único banco (inclui dados e esquema):

```bash
mysqldump -u root -p --databases ecommerce > ecommerce_backup_$(date +%F).sql
```

Backup incluindo routines, events e triggers (recomendado para DB com procedures/events):

```bash
mysqldump -u root -p --routines --events --triggers --databases ecommerce > ecommerce_full_backup_$(date +%F).sql
```

Backup de múltiplos bancos (ex.: ecommerce e analytics):

```bash
mysqldump -u root -p --routines --events --triggers --databases ecommerce analytics > multi_db_backup_$(date +%F).sql
```

Backup de todos os bancos (todas as DBs):

```bash
mysqldump -u root -p --routines --events --triggers --all-databases > all_databases_backup_$(date +%F).sql
```

Backup somente da estrutura (sem dados):

```bash
mysqldump -u root -p --no-data --databases ecommerce > ecommerce_schema_$(date +%F).sql
```

Backup somente dos dados (sem CREATE TABLE):

```bash
mysqldump -u root -p --no-create-info --databases ecommerce > ecommerce_data_$(date +%F).sql
```

Compressão do backup para economizar espaço:

```bash
mysqldump -u root -p --routines --events --triggers --databases ecommerce | gzip > ecommerce_full_backup_$(date +%F).sql.gz
```

Comandos de restore / recovery
Restaurar de arquivo SQL simples:

```bash
mysql -u root -p < ecommerce_full_backup_2026-04-09.sql
```

Restaurar de arquivo compactado (.gz):

```bash
gunzip < ecommerce_full_backup_2026-04-09.sql.gz | mysql -u root -p
```

Restaurar apenas um banco específico de um dump que contém múltiplos bancos:

Abra o arquivo .sql e extraia a seção do banco desejado (ou use sed/awk), ou importe todo o dump (se não houver conflito de nomes).

Exemplo simples (extrair entre -- Current Database: \ecommerce\`` e próximo -- Current Database):

```bash
awk '/^-- Current Database: `ecommerce`/,/^-- Current Database: /{print}' multi_db_backup.sql > ecommerce_only.sql
mysql -u root -p < ecommerce_only.sql
```

Restaurar apenas routines (procedures/functions) se necessário:

Se o dump foi gerado com --routines, as rotinas estarão no arquivo. Para restaurar apenas rotinas, extraia as seções DELIMITER/CREATE PROCEDURE e execute.

Atenção a privilégios: o usuário que restaura precisa ter CREATE ROUTINE e ALTER ROUTINE.

Boas práticas e observações
Usuário e privilégios: use um usuário com privilégios suficientes para criar objetos (tables, routines, events). Para segurança, prefira criar backups com um usuário dedicado.

Consistência: para bancos com alta atividade, use --single-transaction (apenas para engines transacionais como InnoDB) para dump consistente sem bloquear tabelas:

```bash
mysqldump -u root -p --single-transaction --routines --events --triggers --databases ecommerce > ecommerce_consistent.sql
```

Bloqueio de tabelas: se usar MyISAM, considere --lock-tables.

Testar restore: sempre testar o restore em ambiente de homologação antes de produção.

Versionamento no Git: não comite arquivos de backup muito grandes no Git (repositórios Git não são ideais para binários grandes). Se o backup for pequeno e for requisito do exercício, inclua o .sql (ou .sql.gz) e documente o tamanho. Alternativa: usar Git LFS ou armazenar em storage externo e colocar link no README.
