-- =========================================
-- PÄRING 1: Kõik kursused ja osalejate arv
-- Eesmärk: Näidata administraatorile, mitu kasutajat igas kursuses osaleb
-- Tulemus: Kursuse ID, nimetus ja osalejate arv, sorteeritud suurimast vähimani
-- Kasutab: LEFT JOIN, GROUP BY, COUNT, ORDER BY
-- =========================================
SELECT
  c.id AS kursuse_id,
  c.title AS kursuse_nimi,
  COUNT(uc.user_id) AS osalejate_arv
FROM
  courses c
LEFT JOIN user_courses uc ON c.id = uc.course_id
GROUP BY c.id, c.title
ORDER BY osalejate_arv DESC;


-- =========================================
-- PÄRING 2: Kasutajad, kes on registreerunud kursusele "Andmebaasid"
-- Eesmärk: Kuvada kursuse "Andmebaasid" osalejad
-- Tulemus: Kasutaja ID, kasutajanimi ja e-mail
-- Kasutab: INNER JOIN, WHERE, ORDER BY
-- =========================================
SELECT
  u.id AS kasutaja_id,
  u.username AS kasutajanimi,
  u.email AS email
FROM
  users u
INNER JOIN user_courses uc ON u.id = uc.user_id
INNER JOIN courses c ON uc.course_id = c.id
WHERE c.title = 'Andmebaasid'
ORDER BY u.username ASC;


-- =========================================
-- PÄRING 3: Kasutajad ja läbitud kursuste arv
-- Eesmärk: Näidata, mitu kursust iga kasutaja on läbinud
-- Tulemus: Kasutaja ID, kasutajanimi ja kursuste arv
-- Kasutab: LEFT JOIN, GROUP BY, HAVING, ORDER BY, LIMIT
-- =========================================
SELECT
  u.id AS kasutaja_id,
  u.username AS kasutajanimi,
  COUNT(uc.course_id) AS kursuste_arv
FROM
  users u
LEFT JOIN user_courses uc ON u.id = uc.user_id
GROUP BY u.id, u.username
HAVING kursuste_arv > 0
ORDER BY kursuste_arv DESC
LIMIT 10;


-- =========================================
-- PÄRING 4: Kursused, millel on manuseid
-- Eesmärk: Kuvada ainult need kursused, millel on vähemalt 1 manus
-- Tulemus: Kursuse ID, nimetus ja manuste arv
-- Kasutab: INNER JOIN, GROUP BY, COUNT, ORDER BY
-- =========================================
SELECT
  c.id AS kursuse_id,
  c.title AS kursuse_nimi,
  COUNT(a.id) AS manuste_arv
FROM
  courses c
INNER JOIN course_attachments a ON c.id = a.course_id
GROUP BY c.id, c.title
ORDER BY manuste_arv DESC;


-- =========================================
-- PÄRING 5: Kõrgeima hindega kasutajad ja nende kursused
-- Eesmärk: Leida kõik kasutajad, kes on saanud hinde "5" või "A"
-- Tulemus: Kasutajanimi, kursuse nimetus ja hinne
-- Kasutab: INNER JOIN, WHERE, ORDER BY
-- =========================================
SELECT
  u.username AS kasutajanimi,
  c.title AS kursuse_nimi,
  uc.grade AS hinne
FROM
  user_courses uc
JOIN users u ON uc.user_id = u.id
JOIN courses c ON uc.course_id = c.id
WHERE uc.grade IN ('5', 'A')
ORDER BY u.username ASC;


-- =========================================
-- PÄRING 6: Populaarsemad kursused koos osalejate ja manuste arvuga
-- Eesmärk: Näidata 5 kõige populaarsemat kursust koos seotud andmetega
-- Tulemus: Kursuse nimetus, osalejate arv, manuste arv
-- Kasutab: 3 tabeli JOIN, GROUP BY, COUNT, ORDER BY, LIMIT
-- =========================================
SELECT
  c.title AS kursuse_nimi,
  COUNT(DISTINCT uc.user_id) AS osalejate_arv,
  COUNT(DISTINCT ca.id) AS manuste_arv
FROM
  courses c
LEFT JOIN user_courses uc ON c.id = uc.course_id
LEFT JOIN course_attachments ca ON c.id = ca.course_id
GROUP BY c.id, c.title
ORDER BY osalejate_arv DESC
LIMIT 5;
