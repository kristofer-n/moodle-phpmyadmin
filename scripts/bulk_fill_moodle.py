#!/usr/bin/env python3
"""
bulk_fill_moodle.py
Täidab Moodle skeemi suure andmehulgaga (2M+ rida per tabel).
"""

import mysql.connector
from mysql.connector import errorcode
from faker import Faker
import random
import time
from datetime import datetime

# ========== DB SEADISTUS ==========
DB_CONFIG = {
    "host": "moodle-mariadb",
    "user": "moodle_user",
    "password": "mypassword",
    "database": "moodle",
    "port": 3306,
    "autocommit": False,
    "auth_plugin": "mysql_native_password"
}

TARGET_PER_TABLE = 2_000_000
BATCH_SIZE = 5000
SEED = 123456

def now_str():
    return datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")

def connect():
    return mysql.connector.connect(**DB_CONFIG)

# Faker setup
def get_faker():
    try:
        return Faker("et_EE")
    except Exception:
        return Faker("en_US")

F = get_faker()
random.seed(SEED)
F.seed_instance(SEED)

GRADEV = ['2', '3', '4', '5', 'A', 'MA']

# ========== GENERAATORID ==========
def insert_courses(conn, cursor, total, batch_size):
    print(f"[{now_str()}] Alustan courses täitmist: target={total}")
    start = time.time()
    inserted = 0
    while inserted < total:
        batch = []
        for _ in range(min(batch_size, total - inserted)):
            title = F.sentence(nb_words=6)[:100]
            description = F.paragraph(nb_sentences=3)
            batch.append((title, description))
        sql = "INSERT INTO courses (title, description) VALUES (%s, %s)"
        cursor.executemany(sql, batch)
        conn.commit()
        inserted += len(batch)
    elapsed = time.time() - start
    print(f"[{now_str()}] Courses done: {inserted} rows in {elapsed:.1f}s")
    return inserted, elapsed

def insert_users(conn, cursor, total, batch_size):
    print(f"[{now_str()}] Alustan users täitmist: target={total}")
    start = time.time()
    inserted = 0
    global_counter = 0  # globaalse unikaalsuse tagamiseks

    while inserted < total:
        batch = []
        for _ in range(min(batch_size, total - inserted)):
            name = F.name()
            username = f"user{global_counter}"
            email = f"user{global_counter}@example.com"
            password = "pbkdf2_sha256$dummy$" + str(random.randint(100000,999999))
            batch.append((username, email, password))
            global_counter += 1  # globaalselt suurendada
        sql = "INSERT INTO users (username, email, password) VALUES (%s, %s, %s)"
        cursor.executemany(sql, batch)
        conn.commit()
        inserted += len(batch)
        if inserted % (batch_size*10) == 0:
            elapsed = time.time() - start
            print(f"  users: inserted {inserted}/{total} rows (elapsed {elapsed:.1f}s)")

    elapsed = time.time() - start
    print(f"[{now_str()}] Users done: inserted {inserted} rows in {elapsed:.1f}s")
    return inserted, elapsed

def insert_course_attachments(conn, cursor, total, batch_size, course_count):
    print(f"[{now_str()}] Alustan course_attachments täitmist: target={total}")
    start = time.time()
    inserted = 0
    small_content = b"%PDF-1.4\n%placeholder pdf content\n"
    used_filenames = set()
    while inserted < total:
        batch = []
        for _ in range(min(batch_size, total - inserted)):
            course_id = random.randint(1, course_count)
            while True:
                fname = f"{F.word()}_{random.randint(1,99999999)}.pdf"
                if fname not in used_filenames:
                    used_filenames.add(fname)
                    break
            batch.append((course_id, fname, small_content))
        sql = "INSERT INTO course_attachments (course_id, file_name, file_data) VALUES (%s, %s, %s)"
        cursor.executemany(sql, batch)
        conn.commit()
        inserted += len(batch)
    elapsed = time.time() - start
    print(f"[{now_str()}] Attachments done: {inserted} rows in {elapsed:.1f}s")
    return inserted, elapsed

def insert_user_courses(conn, cursor, total, batch_size, user_count, course_count):
    print(f"[{now_str()}] Alustan user_courses täitmist: target={total}")
    start = time.time()
    inserted = 0
    seen_pairs = set()
    while inserted < total:
        batch = []
        for _ in range(min(batch_size, total - inserted)):
            while True:
                uid = random.randint(1, user_count)
                cid = random.randint(1, course_count)
                if (uid, cid) not in seen_pairs:
                    seen_pairs.add((uid, cid))
                    break
            grade = None if random.random() < 0.6 else random.choice(GRADEV)
            batch.append((uid, cid, grade))
        sql = "INSERT INTO user_courses (user_id, course_id, grade) VALUES (%s, %s, %s)"
        cursor.executemany(sql, batch)
        conn.commit()
        inserted += len(batch)
    elapsed = time.time() - start
    print(f"[{now_str()}] user_courses done: {inserted} rows in {elapsed:.1f}s")
    return inserted, elapsed

# ========== LÕPPRAPORT ==========
def get_table_count(cursor, table):
    cursor.execute(f"SELECT COUNT(*) FROM {table}")
    return cursor.fetchone()[0]

def main():
    print("Bulk fill script starting. Target rows per table:", TARGET_PER_TABLE)
    conn = connect()
    cursor = conn.cursor(buffered=True)

    # 1) Courses
    courses_count = TARGET_PER_TABLE
    c_ins, _ = insert_courses(conn, cursor, courses_count, BATCH_SIZE)

    # 2) Users
    users_count = TARGET_PER_TABLE
    u_ins, _ = insert_users(conn, cursor, users_count, BATCH_SIZE)

    # 3) Attachments
    a_ins, _ = insert_course_attachments(conn, cursor, TARGET_PER_TABLE, BATCH_SIZE, c_ins)

    # 4) User_courses
    uc_ins, _ = insert_user_courses(conn, cursor, TARGET_PER_TABLE, BATCH_SIZE, u_ins, c_ins)

    print("\n===== RAPORT =====")
    for t in ("courses", "users", "course_attachments", "user_courses"):
        print(f"{t}: {get_table_count(cursor, t)} rida")
    print("FK kontrollid võiksid ka üle joosta eraldi.")

    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()
