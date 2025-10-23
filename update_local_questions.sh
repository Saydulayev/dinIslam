#!/bin/bash

# Скрипт для автоматического обновления локальных файлов вопросов с GitHub
# Использование: ./update_local_questions.sh

set -e

echo "🔄 Начинаем обновление локальных файлов вопросов..."

# Конфигурация
GITHUB_BASE_URL="https://raw.githubusercontent.com/Saydulayev/dinIslam-questions/main"
LOCAL_RESOURCES_DIR="dinIslam/Resources"
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"

# Создаем директорию для резервных копий
mkdir -p "$BACKUP_DIR"

echo "📁 Создана резервная копия в: $BACKUP_DIR"

# Функция для загрузки и обновления файла
update_questions_file() {
    local filename=$1
    local github_url="${GITHUB_BASE_URL}/${filename}"
    local local_path="${LOCAL_RESOURCES_DIR}/${filename}"
    
    echo "📥 Загружаем ${filename} с GitHub..."
    
    # Создаем резервную копию
    if [ -f "$local_path" ]; then
        cp "$local_path" "${BACKUP_DIR}/${filename}"
        echo "💾 Резервная копия создана: ${BACKUP_DIR}/${filename}"
    fi
    
    # Загружаем новую версию
    if curl -s -o "$local_path" "$github_url"; then
        echo "✅ ${filename} успешно обновлен"
        
        # Проверяем количество вопросов
        local question_count=$(grep -c '"id":' "$local_path")
        echo "📊 Количество вопросов в ${filename}: ${question_count}"
        
        return 0
    else
        echo "❌ Ошибка при загрузке ${filename}"
        
        # Восстанавливаем резервную копию
        if [ -f "${BACKUP_DIR}/${filename}" ]; then
            cp "${BACKUP_DIR}/${filename}" "$local_path"
            echo "🔄 Восстановлена резервная копия ${filename}"
        fi
        
        return 1
    fi
}

# Обновляем файлы
echo "🚀 Обновляем файлы вопросов..."

success_count=0
total_files=2

if update_questions_file "questions.json"; then
    ((success_count++))
fi

if update_questions_file "questions_en.json"; then
    ((success_count++))
fi

echo ""
echo "📊 Результат обновления:"
echo "   Успешно обновлено: ${success_count}/${total_files} файлов"

if [ $success_count -eq $total_files ]; then
    echo "🎉 Все файлы успешно обновлены!"
    echo "🗑️ Резервные копии можно удалить: rm -rf $BACKUP_DIR"
else
    echo "⚠️ Некоторые файлы не удалось обновить"
    echo "💾 Резервные копии сохранены в: $BACKUP_DIR"
fi

echo ""
echo "🔍 Проверка синхронизации:"
echo "📁 Локальные файлы:"
ls -la "${LOCAL_RESOURCES_DIR}/questions*.json"

echo ""
echo "🌐 GitHub файлы:"
echo "   questions.json: ${GITHUB_BASE_URL}/questions.json"
echo "   questions_en.json: ${GITHUB_BASE_URL}/questions_en.json"
