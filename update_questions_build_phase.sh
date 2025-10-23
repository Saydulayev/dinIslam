#!/bin/bash

# Скрипт для автоматического обновления вопросов во время сборки Xcode
# Добавьте этот скрипт в Build Phases вашего проекта

set -e

# Конфигурация
GITHUB_BASE_URL="https://raw.githubusercontent.com/Saydulayev/dinIslam-questions/main"
LOCAL_RESOURCES_DIR="${SRCROOT}/dinIslam/Resources"

# Проверяем, что мы в правильной директории
if [ ! -d "$LOCAL_RESOURCES_DIR" ]; then
    echo "❌ Директория ресурсов не найдена: $LOCAL_RESOURCES_DIR"
    exit 1
fi

echo "🔄 Проверяем актуальность локальных файлов вопросов..."

# Функция для проверки и обновления файла
check_and_update_file() {
    local filename=$1
    local github_url="${GITHUB_BASE_URL}/${filename}"
    local local_path="${LOCAL_RESOURCES_DIR}/${filename}"
    
    echo "🔍 Проверяем ${filename}..."
    
    # Проверяем, существует ли локальный файл
    if [ ! -f "$local_path" ]; then
        echo "⚠️ Локальный файл ${filename} не найден, загружаем с GitHub..."
        if curl -s -o "$local_path" "$github_url"; then
            echo "✅ ${filename} загружен с GitHub"
        else
            echo "❌ Ошибка при загрузке ${filename}"
            exit 1
        fi
    else
        # Сравниваем размеры файлов (простая проверка)
        local local_size=$(stat -f%z "$local_path" 2>/dev/null || stat -c%s "$local_path" 2>/dev/null || echo "0")
        
        # Получаем размер файла с GitHub
        local remote_size=$(curl -s -I "$github_url" | grep -i content-length | awk '{print $2}' | tr -d '\r\n' || echo "0")
        
        if [ "$local_size" != "$remote_size" ] && [ "$remote_size" != "0" ]; then
            echo "🔄 ${filename} устарел, обновляем..."
            if curl -s -o "$local_path" "$github_url"; then
                echo "✅ ${filename} обновлен"
            else
                echo "❌ Ошибка при обновлении ${filename}"
            fi
        else
            echo "✅ ${filename} актуален"
        fi
    fi
    
    # Проверяем количество вопросов
    local question_count=$(grep -c '"id":' "$local_path" 2>/dev/null || echo "0")
    echo "📊 Количество вопросов в ${filename}: ${question_count}"
}

# Обновляем файлы
check_and_update_file "questions.json"
check_and_update_file "questions_en.json"

echo "🎉 Проверка и обновление завершены!"
