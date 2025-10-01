Juhised kuidas käivitada "bulk_fill_moodle.py" faili ning täita "moodle" andmebaasis olevad tabelid:

1. Olla kindel, et seadmel on paiguldatud vähemalt MariaDB 10.4.32 (katsetus oli tehtud just 10.4.32 versiooniga, uuemate versioonides pole kindel, et mis tulemuse saavutab).
2. Mine MariaDB sisse kasutades "mysql -u root" (terminal peaks näitama "MariaDB [(none)]>" kui oled sisse saanud).
    2.1. Kasuta käsku "SOURCE C:/Users/SinuNimi/Downloads/schema.sql;" (SinuNimi kohta peab panema hetkel kasutuses oleva kasutaja nime, ei tea kuidas see töötaks Linuxil või Dockeris).
    2.2. Kontrolli käsuga "SHOW DATABASES;", et näha kas sai schema.sql faili sisse.
    2.3. Kasuta käsku "USE moodle;", et minna "moodle" andmebaasi.
    2.4. Kontrolliks kasuta käsku "SHOW TABLES;", et näha andmebaasis olevaid tabeleid.
3. Veendu, et Pythonil on alla laetud mõlemad _faker_ ja _mysql.connector_. Nende jaoks saab kasutada: python -m pip install faker ja python -m pip install mysql-connector-python
4. Kui eelnevad etapid on õigesti läbitud, siis saab käivitada skripti puhtas Command Prompt aknas (cmd), kasutades käsku: "python bulk_fill_moodle.py", **_ennem oleks vaja liigutada oma asukohta terminalis kohta kus sul skript asub (näiteks: "C:/Users/SinuNimi/Downloads;")_**
5. Skript teeb suurem osa asjadest nähtamatult (peale users osa), kui on valmis siis skript ise annab raporti tulemustest, et mitu rida sai tehtud jne.
