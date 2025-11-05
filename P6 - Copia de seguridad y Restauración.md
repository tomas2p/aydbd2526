**Fecha:** 05 de noviembre de 2025

**Autor:** alu0101474311@ull.edu.es (Tomás Pino Pérez)

---

# 1. Objetivo

El objetivo de esta práctica es realizar una copia de seguridad y su posterior restauración de una base de datos PostgreSQL utilizando herramientas de consola (`pg_dump`, `pg_restore` y `psql`).  
Se busca demostrar la capacidad de exportar, respaldar y recuperar la información sin depender de herramientas gráficas como pgAdmin.
- Analizar las herramientas que PostgreSQL ofrece para la realización de copias de seguridad.
- Implementar un sistema automatizado de copias con Docker Compose.
- Ejecutar una copia de seguridad manual y restaurarla desde consola.
- Comprobar la integridad de los datos después de la restauración.

---

# 2. Entorno y recursos

- Sistema operativo: Ubuntu 22.04 LTS
- Docker Desktop y Docker Compose instalados
- PostgreSQL 15 (contenedor oficial)
- Usuario: `postgres`
- Base de datos: `clientesdb`
- Carpeta de trabajo: `~/adbd/postgresql-backups/src`

---
# 3. Actividad 1 — Automatización de copias de seguridad

## 3.1. Preparación del entorno

1. Verificar instalación de Docker Compose:
```bash
docker compose version
Docker Compose version 2.37.1+ds1-0ubuntu2~24.04.1
```

2. Clonar el repositorio:
```bash
git clone https://github.com/ull-cs/adbd.git
cd adbd/postgresql-backups/src
```

3. Comprobar estructura de archivos:
```bash
ls
backups   db_data             Dockerfile  pg_backup.sh
clean.sh  docker-compose.yml  init.sql
```

---

## 3.2. Ejecución del entorno Docker

Ejecutar:
```bash
sudo docker compose up
[+] Running 3/3
 ✔ Network src_backup_network  Created                                   0.1s 
 ✔ Container src-pgdb-1        Created                                   0.0s 
 ✔ Container src-pgbackup-1    Created                                   0.0s 
Attaching to pgbackup-1, pgdb-1
pgdb-1      | 
pgdb-1      | PostgreSQL Database directory appears to contain a database; Skipping initialization
pgdb-1      | 
pgdb-1      | 2025-11-05 10:01:05.311 UTC [1] LOG:  starting PostgreSQL 16.3 (Debian 16.3-1.pgdg120+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit
pgdb-1      | 2025-11-05 10:01:05.311 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
pgdb-1      | 2025-11-05 10:01:05.311 UTC [1] LOG:  listening on IPv6 address "::", port 5432
pgdb-1      | 2025-11-05 10:01:05.315 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
pgdb-1      | 2025-11-05 10:01:05.324 UTC [29] LOG:  database system was shut down at 2025-11-05 09:49:48 UTC
pgdb-1      | 2025-11-05 10:01:05.336 UTC [1] LOG:  database system is ready to accept connections
```

Esto lanza dos servicios:

- **pgdb:** contenedor PostgreSQL con la base `clientesdb` inicializada mediante `init.sql`.
- **pgbackup:** contenedor con cron configurado para ejecutar `pg_backup.sh` cada minuto.

El script `pg_backup.sh` realiza:

1. Conexión al servidor `pgdb` usando el usuario `postgres`.
2. Ejecución de `pg_dump` sobre `clientesdb`.
3. Almacenamiento del respaldo con nombre timestamp (`backup_clientesdb_YYYYMMDD_HHMMSS.sql`).
4. Eliminación de copias anteriores a 5 minutos.

```bash
ls -l backups/
total 0
-rw-r--r-- 1 root    root       0 nov  5 09:47 clientesdb_backup_2025-11-05_09-47.sql
-rw-r--r-- 1 root    root       0 nov  5 09:48 clientesdb_backup_2025-11-05_09-48.sql
-rw-r--r-- 1 root    root       0 nov  5 09:49 clientesdb_backup_2025-11-05_09-49.sql
-rw-r--r-- 1 root    root       0 nov  5 10:02 clientesdb_backup_2025-11-05_10-02.sql
-rw-r--r-- 1 root    root       0 nov  5 10:03 clientesdb_backup_2025-11-05_10-03.sql
```

---

## 3.3. Verificación de copias generadas

Listar copias desde el contenedor:
```bash
sudo docker exec -it src-pgbackup-1 ls /backups
clientesdb_backup_2025-11-05_10-02.sql
clientesdb_backup_2025-11-05_10-03.sql
clientesdb_backup_2025-11-05_10-04.sql
clientesdb_backup_2025-11-05_10-05.sql
clientesdb_backup_2025-11-05_10-06.sql
```

1 Minuto más tarde:
```bash
sudo docker exec -it src-pgbackup-1 ls /backups
clientesdb_backup_2025-11-05_10-03.sql
clientesdb_backup_2025-11-05_10-04.sql
clientesdb_backup_2025-11-05_10-05.sql
clientesdb_backup_2025-11-05_10-06.sql
clientesdb_backup_2025-11-05_10-07.sql
```

**Comprobación:** cada minuto aparece un nuevo archivo y se eliminan los que superan 5 minutos de antigüedad.

Para detener el entorno:
```bash
sudo docker compose down
[+] Running 3/3
 ✔ Container src-pgbackup-1    Remove...                           10.2s 
 ✔ Container src-pgdb-1        Removed                              0.2s 
 ✔ Network src_backup_network  Remo...                              0.2s
```

---

# 4. Actividad 2 — Copia de seguridad y restauración por consola

## 4.1. Creación del respaldo

Antes de iniciar el respaldo, se comprobó la existencia de la base **`biblioteca`** y de sus tablas principales:
```bash
psql -U postgres -h localhost -d biblioteca -c "\dt"
             List of relations
 Schema |   Name    | Type  |    Owner     
--------+-----------+-------+--------------
 public | autores   | table | admin_biblio
 public | libros    | table | admin_biblio
 public | prestamos | table | admin_biblio
(3 rows)

psql -U postgres -h localhost -d biblioteca -c "SELECT COUNT(*) FROM libros;"
 count 
-------
     7
(1 row)

psql -U postgres -h localhost -d biblioteca -c "SELECT * FROM libros;"
id_libro |                   titulo                   | año_publicacion | id_autor 
----------+--------------------------------------------+-----------------+----------
        1 | Star Wars: Heir to the Empire              |            1991 |        2
        3 | Star Wars: The Last Command                |            1993 |        2
        4 | Star Wars: Revan                           |            2011 |        6
        5 | Star Wars: Darth Bane: Path of Destruction |            2006 |        6
        6 | Star Wars: Darth Plagueis                  |            2012 |        5
        7 | Star Wars: Labyrinth of Evil               |            2005 |        5
        8 | Star Wars: Thrawn                          |            2017 |        2
(7 rows)
```

Posteriormente, se generó el archivo de copia de seguridad en formato personalizado:
```bash
pg_dump -U postgres -h localhost -Fc -f /tmp/backup_biblioteca.dump biblioteca
```

**Explicación de parámetros:**

- `-U postgres`: usuario con privilegios de lectura sobre la base.
- `-h localhost`: servidor local.
- `-Fc`: formato personalizado recomendado para restauraciones selectivas.
- `-f /tmp/backup_biblioteca.dump`: ruta y nombre del archivo resultante.
- `biblioteca`: base de datos origen del respaldo.

Una vez finalizado el proceso, se verificó la creación del archivo:
```bash
ls -lh /tmp/backup_biblioteca.dump
-rw-rw-r-- 1 usuario usuario 9,8K nov  5 10:31 /tmp/backup_biblioteca.dump
```

**Resultado esperado:**  
Un archivo con nombre `backup_biblioteca.dump` y tamaño coherente con la información almacenada.

---

## 4.2. Proceso de restauración

Para probar la restauración, se creó una nueva base de datos denominada **`biblioteca_restaurada`**:
```bash
createdb -U postgres -h localhost biblioteca_restaurada
```

A continuación, se ejecutó el comando de restauración:
```bash
pg_restore -U postgres -h localhost -d biblioteca_restaurada /tmp/backup_biblioteca.dump
```

Durante la ejecución, el sistema reconstruyó las estructuras de tablas, índices y relaciones, insertando posteriormente los datos registrados en el volcado.  
Finalizada la operación, se comprobó el resultado:
```bash
psql -U postgres -h localhost -d biblioteca_restaurada -c "\dt"
             List of relations
 Schema |   Name    | Type  |    Owner     
--------+-----------+-------+--------------
 public | autores   | table | admin_biblio
 public | libros    | table | admin_biblio
 public | prestamos | table | admin_biblio
(3 rows)

psql -U postgres -h localhost -d biblioteca_restaurada -c "SELECT COUNT(*) FROM libros;"
 count 
-------
     7
(1 row)

psql -U postgres -h localhost -d biblioteca_restaurada -c "SELECT * FROM libros;"
id_libro |                   titulo                   | año_publicacion | id_autor 
----------+--------------------------------------------+-----------------+----------
        1 | Star Wars: Heir to the Empire              |            1991 |        2
        3 | Star Wars: The Last Command                |            1993 |        2
        4 | Star Wars: Revan                           |            2011 |        6
        5 | Star Wars: Darth Bane: Path of Destruction |            2006 |        6
        6 | Star Wars: Darth Plagueis                  |            2012 |        5
        7 | Star Wars: Labyrinth of Evil               |            2005 |        5
        8 | Star Wars: Thrawn                          |            2017 |        2
(7 rows)
```

**Resultado esperado:**  
Listado completo de las tablas (`autores`, `libros`, `prestamos`, etc.) y coincidencia en el número de registros con la base original.

---

# 5. Verificación y conclusiones

- [x] Archivo de respaldo generado correctamente
- [x] Base de datos restaurada sin errores
- [x] Estructura y datos coinciden con la base original
- [x] Backup reutilizable para futuras restauraciones
- [x] Cron ejecutó copias cada minuto
- [x] Eliminación de copias antiguas (<5 min)
- [x] Archivo de backup generado correctamente
- [x] Restauración en base nueva exitosa
- [x] Datos verificados e idénticos

**Conclusión:**  
El proceso de copia de seguridad y restauración mediante consola se realizó con éxito, comprobándose la recuperación íntegra de los datos y estructuras originales. El uso de las utilidades `pg_dump` y `pg_restore` demostró ser un método eficaz para generar y restaurar copias lógicas consistentes, automatizables y verificables, garantizando la integridad y disponibilidad de la información. Además, la combinación de PostgreSQL con entornos Docker y tareas programadas mediante `cron` permite automatizar los respaldos y mantener la continuidad operativa ante posibles fallos del sistema.
