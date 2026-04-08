#!/usr/bin/env bash

set -Eeuo pipefail

BACKUPS_DIR="/backups"
DIR_OWNER="minarca"
DIR_GROUP="minarca"
DIR_MODE="770"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Ce script doit être exécuté en root ou avec sudo." >&2
    exit 1
fi

shopt -s nullglob

available_x=()

for dir in "${BACKUPS_DIR}"/data*; do
    base_name="$(basename "${dir}")"

    if [[ -d "${dir}" && "${base_name}" =~ ^data([1-9][0-9]*)$ ]]; then
        available_x+=("${BASH_REMATCH[1]}")
    fi
done

shopt -u nullglob

if [[ "${#available_x[@]}" -eq 0 ]]; then
    echo "Aucun répertoire de la forme ${BACKUPS_DIR}/dataX n'a été trouvé." >&2
    exit 1
fi

mapfile -t available_x < <(printf "%s\n" "${available_x[@]}" | sort -V -u)

available_x_str="$(IFS=", "; echo "${available_x[*]}")"
echo "Valeurs de X disponibles : ${available_x_str}"

selected_x=""

while true; do
    read -r -p "Choisir la valeur de X : " selected_x

    if [[ ! "${selected_x}" =~ ^[1-9][0-9]*$ ]]; then
        echo "Valeur invalide : merci de saisir un entier positif existant."
        continue
    fi

    found="0"

    for x in "${available_x[@]}"; do
        if [[ "${x}" == "${selected_x}" ]]; then
            found="1"
            break
        fi
    done

    if [[ "${found}" == "1" ]]; then
        break
    fi

    echo "Le répertoire ${BACKUPS_DIR}/data${selected_x} n'existe pas."
done

user_name=""

while true; do
    read -r -p "Nom de l'utilisateur souhaité : " user_name

    if [[ "${user_name}" =~ ^[a-z][a-z0-9_.-]*$ ]]; then
        break
    fi

    echo "Nom invalide."
    echo "Règle : commencer par une lettre minuscule, puis uniquement lettres minuscules, chiffres, _, - ou ."
done

target_dir="${BACKUPS_DIR}/data${selected_x}/${user_name}"

if [[ -e "${target_dir}" && ! -d "${target_dir}" ]]; then
    echo "Erreur : ${target_dir} existe déjà mais n'est pas un répertoire." >&2
    exit 1
fi

mkdir -p "${target_dir}"
chown "${DIR_OWNER}:${DIR_GROUP}" "${target_dir}"
chmod "${DIR_MODE}" "${target_dir}"

echo "Répertoire créé/configuré avec succès : ${target_dir}"
ls -ld "${target_dir}"
