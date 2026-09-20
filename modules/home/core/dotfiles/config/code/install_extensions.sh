#!/usr/bin/env bash

# 1. Verificar si el comando 'code' está disponible
if ! command -v code &> /dev/null; then
    echo "Error: Visual Studio Code ('code') no está instalado o no se encuentra en el PATH."
    exit 1
fi

# 2. Definir la ruta del archivo de extensiones (en el mismo directorio que el script)
FILENAME="extensions.txt"
SCRIPT_DIR="$(dirname "$0")"
FILE_PATH="$SCRIPT_DIR/$FILENAME"

# 3. Verificar si el archivo existe
if [[ ! -f "$FILE_PATH" ]]; then
    echo "Error: El archivo '$FILENAME' no existe en el directorio $SCRIPT_DIR."
    exit 1
fi

echo "--- Iniciando verificación de extensiones ---"

# 4. Obtener la lista de extensiones ya instaladas (para evitar reinstalar)
INSTALLED_EXTENSIONS=$(code --list-extensions)

# 5. Bucle para leer el archivo e instalar si falta
while IFS= read -r extension || [[ -n "$extension" ]]; do
    # Ignorar líneas vacías o comentarios (que empiecen con #)
    [[ -z "$extension" || "$extension" =~ ^# ]] && continue

    if echo "$INSTALLED_EXTENSIONS" | grep -qi "^$extension$"; then
        echo "[✓] Ya instalada: $extension"
    else
        echo "[+] Instalando: $extension..."
        code --install-extension "$extension"
    fi
done < "$FILE_PATH"

echo "--- Proceso finalizado ---"
