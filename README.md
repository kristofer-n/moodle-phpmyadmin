Skript bulk_fill_moodle.py täidab Moodle andmebaasi suuremahuliste testandmetega.
Andmebaas peab sisaldama tabeleid, mis on loodud schema.sql abil.

Skript genereerib:
    Kursused (courses)
    Kasutajad (users)
    Kursuse manused (course_attachments)
    Kasutaja kursused (user_courses)

Andmed on juhuslikud, aga ehtsa formaadiga: nimed, e-mailid, failinimed, hinned.

### 1️⃣ Eeltingimused

1. Operatsioonisüsteem: Linux või Docker (Alpine Linux testitud).
2. MariaDB: vähemalt 10.4.32
3. Python: ≥ 3.12
4. Paketid: `python3 -m pip install --user faker mysql-connector-python`
   Dockeris võib kasutada virtualenv või Dockerfile'i lahendust.
5. Andmebaasi kasutaja: skript vajab kasutajat, kellel on täisõigused moodle andmebaasile.

### 2️⃣ Failide paigutus
/home/student/sqlwork/

├── bulk_fill_moodle.py

└── schema.sql

Veendu, et failid on konteineris või Linuxi masinas sama kataloogi all.

### 3️⃣ MariaDB seadistamine
1. Käivita MariaDB:
`sudo systemctl start mariadb`
või Dockeris: `docker run --name mariadb -e MYSQL_ROOT_PASSWORD=mypassword -d mariadb:10.4`
2. Loo andmebaas ja tabeleid:
   
        mysql -u root -p
        CREATE DATABASE moodle;
        USE moodle;
        SOURCE /home/student/sqlwork/schema.sql;
   
4. Loo skriptile sobiv kasutaja (näide):
   
        CREATE USER 'moodle_user'@'%' IDENTIFIED BY 'mypassword';
        GRANT ALL PRIVILEGES ON moodle.* TO 'moodle_user'@'%';
        FLUSH PRIVILEGES;


### 4️⃣ Skripti seadistamine
1. Muuda DB_CONFIG skriptis:

        DB_CONFIG = {
            "host": "127.0.0.1",  # MariaDB host või konteineri IP
            "user": "moodle_user",
            "password": "mypassword",
            "database": "moodle",
            "port": 3306,
            "autocommit": False,
            "auth_plugin": "mysql_native_password"
        }


3. Kui skript käib Docker konteineris, veendu, et failid on konteineris (nt /app):
   
        docker cp bulk_fill_moodle.py <container_id>:/app/
        docker cp schema.sql <container_id>:/app/
   

### 5️⃣ Skripti käivitamine

    cd /home/student/sqlwork
    python3 bulk_fill_moodle.py
    
Skript töötab partiidena, logib edusammu ja väljastab lõpp-raporti.

### 6️⃣ Lõppkontrollid
1. Ridade arvud:
   
        SELECT COUNT(*) FROM courses;
        SELECT COUNT(*) FROM users;
        SELECT COUNT(*) FROM course_attachments;
        SELECT COUNT(*) FROM user_courses;

3. FK tervikluse kontroll:
   
        SELECT COUNT(*) FROM course_attachments ca
        LEFT JOIN courses c ON ca.course_id = c.id
        WHERE c.id IS NULL;

        SELECT COUNT(*) FROM user_courses uc
        LEFT JOIN users u ON uc.user_id = u.id
        WHERE u.id IS NULL;

        SELECT COUNT(*) FROM user_courses uc
        LEFT JOIN courses c ON uc.course_id = c.id
        WHERE c.id IS NULL;
   
5. Ehtsus:
    Nimede ja e-mailide formaat kontrollitud Fakeriga
    Grades: 60% NULL, ülejäänud väärtused lubatud komplektist

### 7️⃣ Näpunäited Dockeris / Alpine Linuxis
1. Kui Python pakette ei saa installeerida (externally managed), tee virtualenv:
   
        python3 -m venv venv
        source venv/bin/activate
        python -m pip install --upgrade pip
        pip install faker mysql-connector-python
   
3. Käivita skript virtualenv-ist:
   
        python bulk_fill_moodle.py
5. Veendu, et MariaDB konteiner on käivitatud ja IP/port õigesti DB_CONFIG-is.

### 8️⃣ Raporti info, mis skript väljastab

Ridade arv iga tabeli kohta - 2 miljon
    
Kogukestus (sekundites) - ~10 minutit
    
FK tervikluse kontroll (orvukirjete arv) - 0 (kõik on korras)

    
**Ehtsusinfo:**

   Locale (et_EE / fallback en_US) ja E-mailide ja nimede formaat - nimed ja e-kirjed on kõik userx@example.com (x on number 0 kuni 1999999)
    
   Grades ja manuste formaadid - üle 60% on NULL ja ülejäänud valitud hulgast on 2, 3, 4, 5, A või MA. Faili nimed on fakeri poolt kokku pandud suvalised nimed.
