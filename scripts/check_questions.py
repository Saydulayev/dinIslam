#!/usr/bin/env python3
"""Проверка банка вопросов перед загрузкой в репозиторий dinIslam-questions.

Использование:
    python3 scripts/check_questions.py questions.json questions_en.json
    python3 scripts/check_questions.py --previous old/questions.json questions.json questions_en.json

Скрипт только проверяет и ничего не записывает: вопросы и ответы правит автор.

Ответ, который ссылается на остальные («Всё перечисленное», «Оба», «All of the above»),
приложение распознаёт само (Answer.refersToOtherAnswers, те же шаблоны) и при перемешивании
оставляет последним, если он стоит последним в файле.

--previous — файл банка, который сейчас у пользователей (того же языка, что и первый проверяемый файл).
Прогресс пользователей привязан к id, поэтому id старого вопроса не должен пропадать
или доставаться другому вопросу.

Ошибки (код выхода 1): то, из-за чего вопрос не попадёт в приложение или попадёт неправильно.
Предупреждения: то, что стоит проверить вручную.
"""

import argparse
import difflib
import json
import re
import sys

TOPICS = {"aqida", "pillars", "prophets", "seerah", "companions", "quran", "fiqh", "history", "akhlaq"}
DIFFICULTIES = {"easy", "medium", "hard"}
MIN_ANSWERS = 2
# Экраны викторины и экзамена прокручиваются, поэтому верхнего предела нет; больше этого — стоит проверить
MANY_ANSWERS = 6

# Нумерация или сноска внутри ответа: признак того, что при импорте склеились пункты списка
FOOTNOTE_PATTERN = re.compile(r"(^|\s)\d+\.\s+[А-ЯЁA-Z«‘]|^примечание", re.IGNORECASE)

# Ответ, который ссылается на другие варианты и поэтому должен стоять последним.
# Те же шаблоны в приложении: Answer.refersToOtherAnswers (Question.swift)
AGGREGATE_PATTERNS = [re.compile(p, re.IGNORECASE) for p in (
    r"\bвс[её]\s+(выше\s*)?(перечисленн|сказанн|названн|указанн)",
    r"\bвс[её]\s+вышеперечисленн",
    r"\bвсе\s+(варианты|ответы|эти)\b",
    r"\bвсеми\s+(выше\s*)?перечисленн",
    r"^(на\s+)?(оба|обе|обоих)\b",
    r"\bни\s+(один|одно|одна)\s+из\s+(выше\s*)?(перечисленн|вариант|ответ|них|этих)",
    r"\ball\s+(of\s+)?(the\s+)?(above|listed|mentioned|these|options|answers)\b",
    r"\ball\s+of\s+them\b",
    r"\bnone\s+of\s+(the\s+above|these|them)\b",
    r"^(on\s+)?both\b",
)]


def is_aggregate(answer):
    return any(p.search(answer.strip()) for p in AGGREGATE_PATTERNS)


def last_answer_is_aggregate(question):
    filled = [a for a in question.get("a") or [] if isinstance(a, str) and a.strip()]
    return bool(filled) and is_aggregate(filled[-1])


def question_id_key(question_id):
    digits = re.sub(r"\D", "", question_id)
    return (int(digits) if digits else 0, question_id)


class Report:
    def __init__(self):
        self.errors = []
        self.warnings = []

    def error(self, path, qid, message):
        self.errors.append(f"{path}: {qid}: {message}")

    def warning(self, path, qid, message):
        self.warnings.append(f"{path}: {qid}: {message}")


def load(path, report):
    try:
        with open(path, encoding="utf-8") as file:
            data = json.load(file)
    except (OSError, json.JSONDecodeError) as error:
        report.error(path, "-", f"файл не читается: {error}")
        return None
    if not isinstance(data, list):
        report.error(path, "-", "в файле должен быть массив вопросов")
        return None
    return data


def check_question(path, question, report):
    qid = question.get("id")
    if not isinstance(qid, str) or not qid.strip():
        report.error(path, "?", f"нет id: {json.dumps(question, ensure_ascii=False)[:80]}")
        return
    text = question.get("q")
    if not isinstance(text, str) or not text.strip():
        report.error(path, qid, "пустой текст вопроса")

    answers = question.get("a")
    if not isinstance(answers, list) or not all(isinstance(a, str) for a in answers):
        report.error(path, qid, "ответы должны быть массивом строк")
        return
    filled = [a for a in answers if a.strip()]
    if len(filled) < len(answers):
        report.warning(path, qid, "есть пустой ответ: приложение его пропускает")
    if len(filled) < MIN_ANSWERS:
        report.error(path, qid, f"ответов меньше {MIN_ANSWERS}")
    elif len(filled) > MANY_ANSWERS:
        report.warning(path, qid, f"ответов {len(filled)} — проверить, что это варианты, а не склеенный список")
    for answer in filled:
        if FOOTNOTE_PATTERN.search(answer):
            report.warning(path, qid, f"ответ похож на сноску или пункт списка: «{answer[:60]}»")
    if len({a.strip().lower() for a in filled}) < len(filled):
        report.warning(path, qid, "повторяющиеся ответы")

    correct = question.get("c")
    if not isinstance(correct, int) or isinstance(correct, bool) or not 0 <= correct < len(answers):
        report.error(path, qid, f"индекс правильного ответа c={correct!r} вне списка ответов")
    elif not answers[correct].strip():
        report.error(path, qid, "правильный ответ пустой")

    if question.get("cat") not in TOPICS:
        report.error(path, qid, f"неизвестная тема cat={question.get('cat')!r}")
    if question.get("d") not in DIFFICULTIES:
        report.error(path, qid, f"неизвестная сложность d={question.get('d')!r}")

    # Пустые ответы приложение отбрасывает, поэтому «последний» — последний непустой
    for answer in filled[:-1]:
        if is_aggregate(answer):
            report.warning(path, qid, f"ответ «{answer}» ссылается на другие, но стоит не последним — при перемешивании окажется где угодно")


def check_previous(previous_path, path, questions, report):
    previous = load(previous_path, report)
    if previous is None:
        return
    current = {q.get("id"): q for q in questions if isinstance(q, dict)}
    for old in previous:
        qid = old.get("id")
        new = current.get(qid)
        if new is None:
            report.error(path, qid, f"id есть в {previous_path}, но пропал — прогресс по вопросу потеряется")
            continue
        old_text, new_text = str(old.get("q", "")), str(new.get("q", ""))
        if difflib.SequenceMatcher(None, old_text.lower(), new_text.lower()).ratio() < 0.5:
            report.error(path, qid, f"id занят другим вопросом: было «{old_text[:50]}…», стало «{new_text[:50]}…»")


def main():
    parser = argparse.ArgumentParser(description="Проверка банка вопросов dinIslam")
    parser.add_argument("files", nargs="+", help="файлы банка: questions.json, questions_en.json")
    parser.add_argument("--previous", help="банк, который сейчас у пользователей: проверить, что id не сменились")
    args = parser.parse_args()

    report = Report()
    banks = {}
    for path in args.files:
        data = load(path, report)
        if data is not None:
            banks[path] = data

    # id: уникальность в файле и одинаковый набор во всех файлах
    id_sets = {}
    for path, questions in banks.items():
        seen = set()
        for question in questions:
            qid = question.get("id") if isinstance(question, dict) else None
            if qid in seen:
                report.error(path, qid, "id повторяется")
            seen.add(qid)
        id_sets[path] = seen
    if len(id_sets) > 1:
        reference_path, reference = next(iter(id_sets.items()))
        for path, ids in id_sets.items():
            for qid in sorted(reference - ids, key=question_id_key):
                report.error(path, qid, f"есть в {reference_path}, нет в этом файле")
            for qid in sorted(ids - reference, key=question_id_key):
                report.error(path, qid, f"нет в {reference_path}")

    for path, questions in banks.items():
        for question in questions:
            if isinstance(question, dict):
                check_question(path, question, report)
            else:
                report.error(path, "?", "элемент массива не является вопросом")

    if args.previous and banks:
        first_path, first_questions = next(iter(banks.items()))
        check_previous(args.previous, first_path, first_questions, report)

    # Один и тот же вопрос в разных языках
    if len(banks) > 1:
        by_id = {}
        for path, questions in banks.items():
            for question in questions:
                if isinstance(question, dict):
                    by_id.setdefault(question.get("id"), []).append((path, question))
        for qid, versions in sorted(by_id.items(), key=lambda item: question_id_key(str(item[0]))):
            if len(versions) < 2:
                continue
            for field, title in (("c", "индекс правильного ответа"), ("cat", "тема"), ("d", "сложность")):
                if len({json.dumps(q.get(field)) for _, q in versions}) > 1:
                    report.warning(versions[0][0], qid, f"{title} различается в языках")
            if len({len(q.get("a") or []) for _, q in versions}) > 1:
                report.warning(versions[0][0], qid, "число ответов различается в языках")
            last_fixed = {last_answer_is_aggregate(q) for _, q in versions}
            if len(last_fixed) > 1:
                report.warning(versions[0][0], qid, "«всё перечисленное» последним распознано не во всех языках — порядок ответов будет разным")

    for title, lines in (("Предупреждения", report.warnings), ("Ошибки", report.errors)):
        if lines:
            print(f"\n{title} ({len(lines)}):")
            for line in lines:
                print("  " + line)

    total = sum(len(q) for q in banks.values())
    print(f"\nВопросов: {total} в {len(banks)} файл(ах). Ошибок: {len(report.errors)}, предупреждений: {len(report.warnings)}.")
    return 1 if report.errors else 0


if __name__ == "__main__":
    sys.exit(main())
