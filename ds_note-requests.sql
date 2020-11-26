-- Выводим названия статей для которых есть ключевые слова, а также их описание
CREATE OR REPLACE VIEW words_list AS
	SELECT n.id, n.title,
		(SELECT GROUP_CONCAT(word SEPARATOR ' / ')
		 FROM notes AS nn
		 	JOIN key_words_sets AS kws
			  ON nn.id = kws.note_id
			JOIN words
			  ON words.id = kws.word_id
		   WHERE note_id = n.id) 'Key words',
		description
		FROM notes n
	   WHERE id IN 
	  		(SELECT DISTINCT note_id
	  		 FROM key_words_sets);
		
SELECT * FROM words_list ORDER BY id;

-- Считаем сколько записей в каждой профессиональной области
CREATE OR REPLACE VIEW professional_fields_total AS
	SELECT name AS 'Field',
	COUNT(notes.professional_field_id)
	FROM notes
		JOIN professional_fields
		  ON professional_fields.id = notes.professional_field_id
	GROUP BY professional_field_id;
		 
SELECT * FROM professional_fields_total;

-- Выводим заголовок, ссылку и описание для записей из области Статистики
SELECT title, link, description,
	name AS 'Field'
	FROM notes
		JOIN professional_fields
		  ON professional_fields.id = notes.professional_field_id
	   WHERE name = "Statistics";
		  
-- топ-10 записей с наибольшим количеством ключевых слов
SELECT title, COUNT(kws.id) words_number
	FROM notes AS n
		LEFT JOIN key_words_sets AS kws
			   ON n.id = kws.note_id
		 GROUP BY n.id
		 ORDER BY words_number DESC LIMIT 10;

-- Вывод типов ресурсов со ссылками по ключевому слову 'Python' (на русском) 
SELECT nn.title, pt.name AS 'type', nn.link, nn.`language`
	FROM notes AS nn
 	JOIN key_words_sets AS kws
	  ON nn.id = kws.note_id
	JOIN words AS ww
	  ON ww.id = kws.word_id
	JOIN portals AS p
	  ON nn.portal_id = p.id 
	JOIN portal_types pt
	  ON p.type_id = pt.id 
   WHERE word = 'Python' AND nn.`language` = 'Russian';