**Fecha:** 19 de septiembre del 2025
**Autor:** alu0101474311@ull.edu.es (Tomás Pino Pérez)

---
## Configurar entorno
Editar esos dos archivos y reiniciar postgresql (`sudo systemctl restart postgresql`):

- Dejar esta línea sin comentar:
```conf
# /etc/postgresql/16/main/postgresql.conf
listen_addresses = '*'
```

- Añadir esta línea al archivo:
```conf
# /etc/postgresql/16/main/pg_hba.conf
host    all             all             0.0.0.0/0               md5
```

## 1.1. Creación de la base de datos
```postgresql
-- Conectar como superusuario (sudo -u postgres psql)
postgres=# CREATE DATABASE biblioteca;  
CREATE DATABASE

-- Conectar a la base de datos (sudo -u postgres psql -d biblioteca)
biblioteca=#
```
## 1.2. Creacion de usuario y roles 
```postgresql
-- Crear usuarios (admin_biblio, usuario_biblio)
biblioteca=# CREATE USER admin_biblio WITH LOGIN PASSWORD 'adminpass' CREATEROLE;  
CREATE ROLE
biblioteca=# CREATE USER usuario_biblio WITH LOGIN PASSWORD 'usuariopass';  
CREATE ROLE

-- Concederle a admin_biblio privilegios para administrar la base de datos (cualquiera de los dos comandos sirve)
biblioteca=# GRANT ALL PRIVILEGES ON DATABASE biblioteca TO admin_biblio; 
GRANT
biblioteca=# ALTER DATABASE biblioteca OWNER TO admin_biblio;  
ALTER DATABASE

-- Crear rol de solo lectura
biblioteca=# CREATE ROLE lectores NOLOGIN;  
CREATE ROLE

-- Asignar permisos de solo lectura
biblioteca=> GRANT CONNECT ON DATABASE biblioteca TO lectores;  
GRANT  
biblioteca=> GRANT USAGE ON SCHEMA public TO lectores;  
GRANT  
biblioteca=> GRANT SELECT ON ALL TABLES IN SCHEMA public TO lectores;  
GRANT

-- Asignar usuario_biblio al rol
biblioteca=# GRANT lectores TO usuario_biblio;  
GRANT ROLE

-- Cambiar contraseña del usuario_biblio
biblioteca=# ALTER USER usuario_biblio WITH PASSWORD 'nuevo_usuario123';  
ALTER ROLE

-- Consultar todos los roles
biblioteca=> SELECT rolname FROM pg_roles;  
          rolname              
-----------------------------  
pg_database_owner  
pg_read_all_data  
pg_write_all_data  
pg_monitor  
pg_read_all_settings  
pg_read_all_stats  
pg_stat_scan_tables  
pg_read_server_files  
pg_write_server_files  
pg_execute_server_program  
pg_signal_backend  
pg_checkpoint  
pg_use_reserved_connections  
pg_create_subscription  
postgres  
admin_biblio  
usuario_biblio  
lectores  
(18 rows)

-- Revocar permisos de eliminación
biblioteca=# REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM usuario_biblio;  
REVOKE
```
## 1.3. Creación de tablas
```postgresql
-- Tabla autores 
biblioteca=> CREATE TABLE autores (
biblioteca(> id_autor SERIAL PRIMARY KEY,
biblioteca(> nombre VARCHAR(100) NOT NULL,
biblioteca(> nacionalidad VARCHAR(50)
biblioteca(> );
CREATE TABLE

-- Tabla libros
biblioteca=> CREATE TABLE libros (  
biblioteca(> id_libro SERIAL PRIMARY KEY,  
biblioteca(> titulo VARCHAR(200) NOT NULL,  
biblioteca(> año_publicacion INT,  
biblioteca(> id_autor INT REFERENCES autores(id_autor) ON DELETE CASCADE  
biblioteca(> );  
CREATE TABLE

-- Tabla prestamos
biblioteca=> CREATE TABLE prestamos (  
biblioteca(> id_prestamo SERIAL PRIMARY KEY,  
biblioteca(> id_libro INT REFERENCES libros(id_libro) ON DELETE CASCADE,  
biblioteca(> fecha_prestamo DATE NOT NULL,  
biblioteca(> fecha_devolucion DATE,  
biblioteca(> usuario_prestatario VARCHAR(100) NOT NULL  
biblioteca(> );
CREATE TABLE
```
## 1.4. Inserción de datos
```postgresql
-- Insertar autores
biblioteca=> INSERT INTO autores (nombre, nacionalidad) VALUES  
biblioteca-> ('George Lucas', 'Estadounidense'),  
biblioteca-> ('Tymothy Zahn', 'Estadounidense'),  
biblioteca-> ('R.A. Salvatore', 'Estadounidense'),  
biblioteca-> ('Michael Stackpole', 'Estadounidense'),  
biblioteca-> ('James Luceno', 'Estadounidense'),  
biblioteca-> ('Drew Karpyshyn', 'Canadiense');  
INSERT 0 6

-- Insertar libros
biblioteca=> INSERT INTO libros (titulo, año_publicacion, id_autor) VALUES
biblioteca-> ('Star Wars: Heir to the Empire', 1991, 2),
biblioteca-> ('Star Wars: Dark Force Rising', 1992, 2),
biblioteca-> ('Star Wars: The Last Command', 1993, 2),
biblioteca-> ('Star Wars: Revan', 2011, 6),
biblioteca-> ('Star Wars: Darth Bane: Path of Destruction', 2006, 6),
biblioteca-> ('Star Wars: Darth Plagueis', 2012, 5),
biblioteca-> ('Star Wars: Labyrinth of Evil', 2005, 5),
biblioteca-> ('Star Wars: Thrawn', 2017, 2);
INSERT 0 8

-- Insertar préstamos
biblioteca=> INSERT INTO prestamos (id_libro, fecha_prestamo, fecha_devolucion, usuario_prestatario) VALUES
biblioteca-> (1, '2025-09-01', NULL, 'Juan Pérez'),
biblioteca-> (3, '2025-09-05', '2025-09-12', 'Ana Gómez'),
biblioteca-> (4, '2025-09-10', NULL, 'Luis Torres'),
biblioteca-> (5, '2025-09-12', NULL, 'Marta Díaz'),
biblioteca-> (6, '2025-09-15', '2025-09-20', 'Carlos Ruiz');
INSERT 0 5
```
## 1.5. Consultas básicas
```postgresql
-- Listar todos los libros con su autor
biblioteca=> SELECT l.titulo, a.nombre AS autor
biblioteca-> FROM libros l
biblioteca-> JOIN autores a ON l.id_autor = a.id_autor;
                  titulo                   |     autor         
--------------------------------------------+----------------  
Star Wars: Heir to the Empire              | Tymothy Zahn  
Star Wars: Dark Force Rising               | Tymothy Zahn  
Star Wars: The Last Command                | Tymothy Zahn  
Star Wars: Revan                           | Drew Karpyshyn  
Star Wars: Darth Bane: Path of Destruction | Drew Karpyshyn  
Star Wars: Darth Plagueis                  | James Luceno  
Star Wars: Labyrinth of Evil               | James Luceno  
Star Wars: Thrawn                          | Tymothy Zahn  
(8 rows)

-- Préstamos sin fecha de devolución
biblioteca=> SELECT * FROM prestamos WHERE fecha_devolucion IS NULL;  
id_prestamo | id_libro | fecha_prestamo | fecha_devolucion | usuario_prestatario    
--------------+----------+----------------+------------------+---------------------  
           1 |        1 | 2025-09-01     |                  | Juan Pérez  
           3 |        4 | 2025-09-10     |                  | Luis Torres  
           4 |        5 | 2025-09-12     |                  | Marta Díaz  
(3 rows)

-- Autores con más de un libro
biblioteca=> SELECT a.nombre, COUNT(l.id_libro) AS num_libros  
biblioteca-> FROM autores a  
biblioteca-> JOIN libros l ON a.id_autor = l.id_autor  
biblioteca-> GROUP BY a.nombre  
biblioteca-> HAVING COUNT(l.id_libro) > 1;  
    nombre     | num_libros    
----------------+------------  
Tymothy Zahn   |          4  
James Luceno   |          2  
Drew Karpyshyn |          2  
(3 rows)
```
## 1.6. Consultas con agregación
```postgresql
-- Número total de préstamos
biblioteca=> SELECT COUNT(*) AS total_prestamos FROM prestamos;  
total_prestamos    
-----------------  
              5  
(1 row)

-- Número de libros prestados por usuario
biblioteca=> SELECT usuario_prestatario, COUNT(*) AS libros_prestados  
biblioteca-> FROM prestamos  
biblioteca-> GROUP BY usuario_prestatario;  
usuario_prestatario | libros_prestados    
---------------------+------------------  
Marta Díaz          |                1  
Luis Torres         |                1  
Ana Gómez           |                1  
Carlos Ruiz         |                1  
Juan Pérez          |                1  
(5 rows)
```
## 1.7. Modificación de datos
```postgresql
-- Actualizar fecha de devolución
biblioteca=> UPDATE prestamos  
biblioteca-> SET fecha_devolucion = '2025-09-18'  
biblioteca-> WHERE id_prestamo = 1;
UPDATE 1

-- Eliminar un libro (ON DELETE CASCADE afecta a préstamos)
biblioteca=> DELETE FROM libros WHERE id_libro = 2;  
DELETE 1
```
## 1.8. Creación de vistas
```postgresql
-- Crear vista_libros_prestados (título, autor, nombre_prestatario)
biblioteca=> CREATE VIEW vista_libros_prestados AS  
biblioteca-> SELECT l.titulo, a.nombre AS autor, p.usuario_prestatario  
biblioteca-> FROM prestamos p  
biblioteca-> JOIN libros l ON p.id_libro = l.id_libro  
biblioteca-> JOIN autores a ON l.id_autor = a.id_autor;  
CREATE VIEW

-- Conceder permisos de consulta a usuario_biblio
biblioteca=> GRANT SELECT ON vista_libros_prestados TO usuario_biblio;  
GRANT

-- Uso de la vista creada
biblioteca=> SELECT * FROM vista_libros_prestados;  
                  titulo                   |     autor      | usuario_prestatario    
--------------------------------------------+----------------+---------------------  
Star Wars: The Last Command                | Tymothy Zahn   | Ana Gómez  
Star Wars: Revan                           | Drew Karpyshyn | Luis Torres  
Star Wars: Darth Bane: Path of Destruction | Drew Karpyshyn | Marta Díaz  
Star Wars: Darth Plagueis                  | James Luceno   | Carlos Ruiz  
Star Wars: Heir to the Empire              | Tymothy Zahn   | Juan Pérez  
(5 rows)
```
## 1.9. Funciones y consultas avanzadas
```postgresql
-- Función para obtener libros de un autor
biblioteca=> CREATE OR REPLACE FUNCTION libros_por_autor(nombre_autor VARCHAR)  
biblioteca-> RETURNS TABLE(titulo VARCHAR) AS $$  
biblioteca$> BEGIN  
biblioteca$> RETURN QUERY  
biblioteca$> SELECT l.titulo  
biblioteca$> FROM libros l  
biblioteca$> JOIN autores a ON l.id_autor = a.id_autor  
biblioteca$> WHERE a.nombre = nombre_autor;  
biblioteca$> END;  
biblioteca$> $$ LANGUAGE plpgsql;  
CREATE FUNCTION

-- Uso de la función creada
biblioteca=> SELECT * FROM libros_por_autor('Tymothy Zahn');  
           titulo                
-------------------------------  
Star Wars: Heir to the Empire  
Star Wars: The Last Command  
Star Wars: Thrawn  
(3 rows)

-- Consulta de los tres libros más prestados
biblioteca=> SELECT l.titulo, COUNT(p.id_prestamo) AS veces_prestado  
biblioteca-> FROM libros l  
biblioteca-> JOIN prestamos p ON l.id_libro = p.id_libro  
biblioteca-> GROUP BY l.titulo  
biblioteca-> ORDER BY veces_prestado DESC  
biblioteca-> LIMIT 3;  
                  titulo                   | veces_prestado    
--------------------------------------------+----------------  
Star Wars: Darth Bane: Path of Destruction |              1  
Star Wars: Darth Plagueis                  |              1  
Star Wars: The Last Command                |              1  
(3 rows)
```
## 1.10. Exportación e importación de datos
```postgresql
-- Exportar libros a CSV
biblioteca=> \copy libros TO 'libro.csv' CSV HEADER;  
COPY 7

-- Importar autores desde CSV
biblioteca=> \copy autores(nombre, nacionalidad) FROM 'autores_extra.csv' CSV HEADER;
COPY 2
```
## Comandos adicionales
```postgresql
-- Mostrar lista de roles (usuarios)
biblioteca=# \du  
                               List of roles  
  Role name    |                         Attributes                            
----------------+------------------------------------------------------------  
admin_biblio   |    
lectores       | Cannot login  
postgres       | Superuser, Create role, Create DB, Replication, Bypass RLS  
usuario_biblio |
```
