#!/bin/bash

# ----------------------------
# CONFIGURACIÓN DEL SCRIPT
# ----------------------------

# Datos del servidor remoto
REMOTE_USER="usuario_remoto"
REMOTE_HOST="ip.o.dominio.remoto"
REMOTE_PORT=22  # Cambia si usas otro puerto SSH
REMOTE_TMP_DIR="/tmp/backup_db"

# Datos generales de MySQL/MariaDB
DB_USER="usuario_db"
DB_PASS="password_db"

# Carpeta local donde guardarás el respaldo
LOCAL_BACKUP_DIR="$HOME/backups"

# ----------------------------
# VALIDACIÓN DE PARÁMETROS
# ----------------------------

if [ $# -lt 1 ]; then
    echo "Uso: $0 <nombre_base_de_datos>"
    exit 1
fi

DB_NAME="$1"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="${DB_NAME}_${DATE}.sql"
COMPRESSED_FILENAME="${BACKUP_FILENAME}.gz"

# ----------------------------
# CREAR RESPALDO EN EL SERVIDOR REMOTO
# ----------------------------

echo "=== [1/5] Creando directorio temporal en el servidor remoto..."
ssh -p "$REMOTE_PORT" ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_TMP_DIR}"

echo "=== [2/5] Generando respaldo de la base de datos '${DB_NAME}' en el servidor remoto..."
ssh -p "$REMOTE_PORT" ${REMOTE_USER}@${REMOTE_HOST} \
    "mysqldump -u${DB_USER} -p'${DB_PASS}' ${DB_NAME} > ${REMOTE_TMP_DIR}/${BACKUP_FILENAME}"

echo "=== [3/5] Comprimiendo respaldo en el servidor remoto..."
ssh -p "$REMOTE_PORT" ${REMOTE_USER}@${REMOTE_HOST} \
    "gzip -f ${REMOTE_TMP_DIR}/${BACKUP_FILENAME}"

# ----------------------------
# DESCARGAR ARCHIVO A LOCAL
# ----------------------------

echo "=== [4/5] Descargando respaldo a la máquina local..."
mkdir -p "${LOCAL_BACKUP_DIR}"
scp -P "$REMOTE_PORT" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_TMP_DIR}/${COMPRESSED_FILENAME} "${LOCAL_BACKUP_DIR}/"

# ----------------------------
# LIMPIAR ARCHIVOS REMOTOS
# ----------------------------

echo "=== [5/5] Eliminando respaldo temporal en el servidor remoto..."
ssh -p "$REMOTE_PORT" ${REMOTE_USER}@${REMOTE_HOST} \
    "rm -f ${REMOTE_TMP_DIR}/${COMPRESSED_FILENAME}"

echo "=== Respaldo completado exitosamente ==="
echo "Archivo guardado en: ${LOCAL_BACKUP_DIR}/${COMPRESSED_FILENAME}"
