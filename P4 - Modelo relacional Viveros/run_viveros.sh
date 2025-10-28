#!/bin/bash
# Script para ejecutar modelo_viveros en PostgreSQL

SQL_ORIG="/home/usuario/p04/p04-modelo-viveros.sql"
SQL_TMP="/tmp/p04-modelo-viveros.sql"

# Copiar archivo a /tmp y dar permisos a postgres
echo "Copiando archivo SQL a /tmp..."
sudo cp "$SQL_ORIG" "$SQL_TMP" && \
sudo chown postgres:postgres "$SQL_TMP" && \
sudo chmod 644 "$SQL_TMP"
# Mostrar el número de líneas del archivo copiado para verificar
echo "Número de líneas del archivo copiado a /tmp:"
wc -l < "$SQL_TMP"

# Ejecutar script SQL con postgres
echo "Ejecutando script SQL..."
echo
sudo -u postgres psql -f "$SQL_TMP"

# Borrar archivo temporal
echo "Eliminando archivo temporal..."
sudo rm -f "$SQL_TMP"

echo "Script ejecutado y archivo temporal eliminado."
