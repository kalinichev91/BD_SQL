DB_CONFIG = {
    "dbname": "food_delivery_pro",
    "user": "postgres",
    "password": "Qweasdzx12qq",
    "host": "127.0.0.1",
    "port": "5432"
}

conn = None

try:
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    print("Успешное подключение к БД!")

    # Запускаем бесконечное меню
    while True:
        print("\n=== ПАНЕЛЬ АДМИНИСТРАТОРА ===")
        print("1. Показать меню ресторана")
        print("2. Массовое изменение цен")
        print("3. Управление стоп-листом")
        print("0. Выход")

        choice = input("Выберите действие (0-3): ").strip()

        if choice == '0':
            print("До свидания!")
            break
        elif choice == '1':
            rest_id = input("Введите ID ресторана: ")
            sql = "SELECT item_name, price, is_available FROM menu_items WHERE restaurant_id = %s ORDER BY id;"
            cursor.execute(sql, (rest_id,))
            items = cursor.fetchall()

            if not items:
                print("Блюд не найдено!")
                continue

            print(f"\n--- МЕНЮ (Ресторан ID {rest_id}) ---")
            for row in items:
                name, price, available = row[0], row[1], row[2]
                status = "" if available else "[НЕТ В НАЛИЧИИ]"
                print(f"- {name:<15} | {price} руб. {status}")

        elif choice == '2':
            rest_id = input("Введите ID ресторана: ")
            percent = float(input("Процент наценки: "))
            # 15% = 1.15
            multiplier = 1 + (percent / 100)

            # Достаем текущие цены
            sql_select = "SELECT id, item_name, price FROM menu_items WHERE restaurant_id = %s AND is_available = TRUE;"
            cursor.execute(sql_select, (rest_id,))
            items = cursor.fetchall()

            if not items:
                print("Нет доступных блюд.")
                continue

            # Предпросмотр
            print("\n--- ПРЕДВАРИТЕЛЬНЫЙ ПРОСМОТР ---")
            for row in items:
                item_id, name, old_price = row[0], row[1], float(row[2])
                new_price = round(old_price * multiplier, 2)
                print(f"{name:<15} | {old_price} ---> {new_price} руб.")

            # Запрашиваем разрешение
            confirm = input("\nПрименить изменения в базе? (Y/N): ").strip().upper()

            if confirm == "Y":
                sql_update = """
                    UPDATE menu_items
                    SET price = price * %s
                    WHERE restaurant_id = %s AND is_available = TRUE;
                """
                cursor.execute(sql_update, (multiplier, rest_id))
                conn.commit()
                print(f"[УСПЕХ] Цены обновлены у {cursor.rowcount} блюд!")
            else:
                print("[ОТМЕНА] Ничего не меняли.")

        elif choice == '3':
            item_id = input("Введите ID блюда для стоп-листа: ")

            sql = "UPDATE menu_items SET is_available = FALSE WHERE id = %s;"
            cursor.execute(sql, (item_id,))

            if cursor.rowcount > 0:
                conn.commit()
                print(f"[УСПЕХ] Блюдо ID {item_id} добавлено в стоп-лист.")
            else:
                conn.rollback()
                print(f"[ОШИБКА] Блюдо с ID {item_id} не найдено.")
        else:
            print("Ошибка: введите цифру от 0 до 3.")

except psycopg2.Error as e:
    print(f"\n[КРИТИЧЕСКАЯ ОШИБКА БД]: {e}")
    if conn:
        conn.rollback()

finally:
    if conn:
        conn.close()
        print("Соединение с базой закрыто.")