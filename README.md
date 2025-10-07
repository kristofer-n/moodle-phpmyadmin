# Moodle Andmebaasi Testandmete Täitmine Dockeriga

See projekt genereerib ja sisestab suuremahulisi testandmeid Moodle andmebaasi, kasutades Docker konteinereid.

## 📋 Eeltingimused

- Docker
- Docker Compose (soovituslik)
- Vähemalt 4GB vaba mälu

## 🏗️ Projekti Struktuur

```
moodle-bulk-data/
├── docker-compose.yml
├── scripts/
│   ├── bulk_fill_moodle.py
│   └── schema.sql
└── README.md
```

## 🚀 Kiirkäivitamine Docker Compose'iga

### 1. Loo projektikaust ja failid

```bash
mkdir moodle-bulk-data
cd moodle-bulk-data
mkdir scripts
```

### 2. Loo docker-compose.yml

```yaml
version: '3.8'

services:
  mariadb:
    image: mariadb:10.11
    container_name: moodle-mariadb
    environment:
      MYSQL_ROOT_PASSWORD: myrootpassword
      MYSQL_DATABASE: moodle
      MYSQL_USER: moodle_user
      MYSQL_PASSWORD: mypassword
    ports:
      - "3306:3306"
    volumes:
      - mariadb_data:/var/lib/mysql
      - ./scripts/schema.sql:/docker-entrypoint-initdb.d/schema.sql:ro
    networks:
      - moodle-network
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      start_period: 10s
      interval: 10s
      timeout: 5s
      retries: 3

  python-app:
    image: python:3.12-alpine
    container_name: moodle-python
    working_dir: /app
    volumes:
      - ./scripts:/app
    networks:
      - moodle-network
    depends_on:
      mariadb:
        condition: service_healthy
    command: >
      sh -c "
        apk add --no-cache mariadb-connector-c-dev build-base &&
        pip install faker mysql-connector-python &&
        echo 'Waiting for database to be ready...' &&
        sleep 15 &&
        python bulk_fill_moodle.py
      "

volumes:
  mariadb_data:

networks:
  moodle-network:
    driver: bridge
```

### 3. Aseta skriptid scripts/ kataloogi

- `scripts/bulk_fill_moodle.py`
- `scripts/schema.sql`

### 4. Käivita süsteem

```bash
docker-compose up
```

## 🛠️ Käsitsi Seadistamine Docker Run käsudega

### 1. Käivita MariaDB konteiner

```bash
docker run -d \
  --name moodle-mariadb \
  -e MYSQL_ROOT_PASSWORD=myrootpassword \
  -e MYSQL_DATABASE=moodle \
  -e MYSQL_USER=moodle_user \
  -e MYSQL_PASSWORD=mypassword \
  -p 3306:3306 \
  -v $(pwd)/scripts/schema.sql:/docker-entrypoint-initdb.d/schema.sql:ro \
  -v mariadb_data:/var/lib/mysql \
  mariadb:10.11
```

### 2. Oota, kuni andmebaas on valmis

```bash
docker exec moodle-mariadb bash -c 'while ! mysqladmin ping -hlocalhost --silent; do sleep 1; done'
```

### 3. Käivita Python skript andmete täitmiseks

```bash
docker run -it --rm \
  --name moodle-python \
  --network container:moodle-mariadb \
  -v $(pwd)/scripts:/app \
  python:3.12-alpine \
  sh -c "
    cd /app &&
    apk add --no-cache mariadb-connector-c-dev build-base &&
    pip install faker mysql-connector-python &&
    python bulk_fill_moodle.py
  "
```

## ⚙️ Skripti Seadistamine

Veendu, et `bulk_fill_moodle.py` failis on õige andmebaasi konfiguratsioon:

```python
DB_CONFIG = {
    "host": "moodle-mariadb",  # Docker Compose puhul konteineri nimi
    # "host": "127.0.0.1",     # Docker run puhul localhost
    "user": "moodle_user",
    "password": "mypassword", 
    "database": "moodle",
    "port": 3306,
    "autocommit": False,
    "auth_plugin": "mysql_native_password"
}
```

## 🔍 Andmete Kontrollimine

### 1. Ühendu andmebaasiga

```bash
docker exec -it moodle-mariadb mysql -u moodle_user -pmypassword moodle
```

### 2. Käivita kontrollpäringud

```sql
-- Ridade arvud
SELECT COUNT(*) FROM courses;
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM course_attachments;
SELECT COUNT(*) FROM user_courses;

-- FK tervikluse kontroll
SELECT COUNT(*) FROM course_attachments ca
LEFT JOIN courses c ON ca.course_id = c.id
WHERE c.id IS NULL;

SELECT COUNT(*) FROM user_courses uc
LEFT JOIN users u ON uc.user_id = u.id
WHERE u.id IS NULL;

SELECT COUNT(*) FROM user_courses uc
LEFT JOIN courses c ON uc.course_id = c.id
WHERE c.id IS NULL;
```

## 🗂️ Andmekogused

Skript genereerib:
- **Kursused (courses)**: 2,000,000 kirjet
- **Kasutajad (users)**: 2,000,000 kirjet  
- **Kursuse manused (course_attachments)**: 2,000,000 kirjet
- **Kasutaja kursused (user_courses)**: 2,000,000 kirjet

## 🐛 Tõrkeotsing

### Kontrolli konteinerite olekut

```bash
# Kontrolli, kas konteinerid töötavad
docker ps

# Vaata logisid
docker logs moodle-mariadb
docker logs moodle-python

# Kontrolli andmebaasi ühendust
docker exec moodle-mariadb mysql -u moodle_user -pmypassword -e "SELECT 1;"
```

### Käsitsi skripti käivitamine

```bash
# Käivita Python konteiner interaktiivselt
docker run -it --rm \
  --network container:moodle-mariadb \
  -v $(pwd)/scripts:/app \
  python:3.12-alpine sh

# Konteineri sees:
cd /app
apk add --no-cache mariadb-connector-c-dev build-base
pip install faker mysql-connector-python
python bulk_fill_moodle.py
```

## 🧹 Puhastamine

### Docker Compose puhul

```bash
# Peata ja kustuta konteinerid
docker-compose down

# Kustuta kõik andmed
docker-compose down -v
```

### Docker Run puhul

```bash
# Peata ja kustuta konteinerid
docker stop moodle-mariadb
docker rm moodle-mariadb

# Kustuta andmevolume
docker volume rm mariadb_data
```

## 📊 Jõudluse Näpunäited

- **Mälu**: Lisa rohkem mälu Docker Desktop'i seadetest (vähemalt 4GB)
- **Partitioning**: Suurte tabelite puhul kaalu partitionimist
- **Batch size**: Muuda `BATCH_SIZE` väärtust skriptis vastavalt süsteemi võimekusele

## 🎯 Lõppkontrollid

Pärast skripti käivitamist kontrolli:

1. **Ridade arvud** - veendu, et kõik tabelid on täidetud
2. **FK terviklus** - veendu, et orvukirjeid pole
3. **Andmete ehtsus** - nimed, e-mailid ja hinded vastavad oodatud formaadile

Skript väljastab lõpp-raporti, mis sisaldab:
- Ridade arvu iga tabeli kohta
- Kogukestust
- FK tervikluse kontrolli tulemusi
- Andmete ehtsuse infot

See Docker-põhine lahendus võimaldab täielikku isoleeritud testkeskkonda ilma vajaduseta hosti süsteemi sõltuvuste järele.
