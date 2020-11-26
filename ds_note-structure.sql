DROP DATABASE IF EXISTS ds_note;
CREATE DATABASE ds_note;
USE ds_note;

-- Independent table
DROP TABLE IF EXISTS contact_types;
CREATE TABLE contact_types (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Contact type id", 
	name VARCHAR(50) NOT NULL COMMENT "Contact type name",
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Creation time",  
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  		ON UPDATE CURRENT_TIMESTAMP COMMENT "Update time"
) COMMENT "Contact types";

-- Independent table
DROP TABLE IF EXISTS content_types;
CREATE TABLE content_types (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Content type id", 
	name VARCHAR(50) NOT NULL COMMENT "Content type name",
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Creation time",  
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  		ON UPDATE CURRENT_TIMESTAMP COMMENT "Update time"
) COMMENT "Content types";

-- Independent table
DROP TABLE IF EXISTS portal_types;
CREATE TABLE portal_types (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Portal type id", 
	name VARCHAR(50) NOT NULL COMMENT "Portal type name",
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Creation time",  
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  		ON UPDATE CURRENT_TIMESTAMP COMMENT "Update time"
) COMMENT "Portal types";

-- Independent table
DROP TABLE IF EXISTS professional_fields;
CREATE TABLE professional_fields (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Professional fild id", 
	name VARCHAR(50) NOT NULL COMMENT "Professional fild name",
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Creation time",  
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  		ON UPDATE CURRENT_TIMESTAMP COMMENT "Update time"
) COMMENT "Professional filds";

-- Level 2 table
DROP TABLE IF EXISTS senders;
CREATE TABLE senders (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Sender id", 
	name VARCHAR(50) NOT NULL COMMENT "Sender name",
	type_id INT UNSIGNED NOT NULL DEFAULT 1 COMMENT "Contact type",
	FOREIGN KEY (type_id) REFERENCES contact_types(id),
	sender_contact VARCHAR(50) COMMENT "Contact details",
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Creation time",  
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
		ON UPDATE CURRENT_TIMESTAMP COMMENT "Update time"
) COMMENT "Note owner";

-- Level 2 table
DROP TABLE IF EXISTS companies;
CREATE TABLE companies (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Company id", 
	name VARCHAR(100) NOT NULL COMMENT "Company name",
	type_id INT UNSIGNED COMMENT "Contact type",
	FOREIGN KEY (type_id) REFERENCES contact_types(id),
	contact VARCHAR(50) COMMENT "Company contact",
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Creation time",  
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
		ON UPDATE CURRENT_TIMESTAMP COMMENT "Update time"
) COMMENT "Companis";

-- Level 2 table
DROP TABLE IF EXISTS portals;
CREATE TABLE portals (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Portal id", 
	name VARCHAR(50) NOT NULL COMMENT "Portal name",
	type_id INT UNSIGNED NOT NULL COMMENT "Portal type",
	FOREIGN KEY (type_id) REFERENCES portal_types(id),
	link VARCHAR(50) COMMENT "Portal link",
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Creation time",  
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
		ON UPDATE CURRENT_TIMESTAMP COMMENT "Update time"
) COMMENT "Portal";

-- Level 1 table
DROP TABLE IF EXISTS authors;
CREATE TABLE authors (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Id",
	name VARCHAR(50) NOT NULL COMMENT "Author name",
	translit_name VARCHAR(50) COMMENT "Translit name",
	company_id INT UNSIGNED COMMENT "Company",
	FOREIGN KEY (company_id) REFERENCES companies(id),
	type_id INT UNSIGNED COMMENT "Contact type",
	FOREIGN KEY (type_id) REFERENCES contact_types(id),
	contact VARCHAR(50) COMMENT "Author contact",
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Creation time",  
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
		ON UPDATE CURRENT_TIMESTAMP COMMENT "Update time"
) COMMENT "Authors";

-- Транслитерация имени автора
DELIMITER $
DROP FUNCTION IF EXISTS trans_func$
CREATE FUNCTION trans_func(str TEXT CHARSET utf8)
	RETURNS text CHARSET utf8
	DETERMINISTIC SQL SECURITY INVOKER
	BEGIN
		DECLARE sym VARCHAR(3) CHARSET utf8;
		DECLARE prevsub VARCHAR(3) CHARSET utf8;
		DECLARE sub VARCHAR(3) CHARSET utf8;
		DECLARE transliterated TEXT CHARSET utf8;
		DECLARE len INT(3);
		DECLARE i INT(3);
		DECLARE pos INT(3);
		DECLARE letters VARCHAR(100) CHARSET utf8;
	
		SET i = 0;
		SET transliterated = '';
		SET len = CHAR_LENGTH(str);
		SET letters = ' _.абвгдеёжзийклмнопрстуфхцчшщъыьэюя
							АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ';
	
		WHILE i < len DO
	
			SET i = i + 1;
			SET sym = SUBSTR(str, i, 1);
			SET pos = INSTR(letters, sym);
	
			IF sym >= '0' AND sym <= '9'
				OR sym >= 'a' AND sym <= 'z' 
				OR sym >= 'A' AND sym <= 'Z'
				OR sym = '-'
					THEN SET sub = sym;
			ELSE
				SET sub = ELT(pos, ' ', '_', '-',
	                    'a','b','v','g', 'd', 'e', 'yo','zh', 'z',
	                    'i','j','k','l', 'm', 'n', 'o', 'p', 'r',
	                    's','t','u','f', 'h', 'c','ch','sh','sch',
	                    '', 'y', '','e','yu','ya',
	                    'A','B','V','G', 'D', 'E', 'Yo','Zh', 'Z',
	                    'I','J','K','L', 'M', 'N', 'O', 'P', 'R',
	                    'S','T','U','F', 'H', 'C','Ch','Sh','Sch',
	                    '', 'Y', '','E','Yu','Ya');
	
			END IF;
	
			IF sub IS NOT NULL AND NOT(sub = '-' AND prevsub = '-') THEN
				SET transliterated = CONCAT(transliterated, sub);
			END IF;
	
			SET prevsub = sub;
	
		END WHILE;
	
		RETURN transliterated;
	END $

DROP TRIGGER IF EXISTS auto_translit_on_insert$
CREATE TRIGGER auto_translit_on_insert BEFORE INSERT ON authors
FOR EACH ROW
BEGIN
	SET @NAME = NEW.name;
	SET @T_NAME = (SELECT trans_func(@NAME));
	SET NEW.translit_name = @T_NAME;
END $

DELIMITER ;

-- main table
DROP TABLE IF EXISTS notes;
CREATE TABLE notes (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Id",
	title VARCHAR(100) NOT NULL COMMENT "Note title",
	INDEX (title) COMMENT "Added manually",
	portal_id INT UNSIGNED NOT NULL DEFAULT 1 COMMENT "Portal",
	start_at DATETIME COMMENT "Start time",
	FOREIGN KEY (portal_id) REFERENCES portals(id),
	link VARCHAR(200) COMMENT "Note link",
	content_type_id INT UNSIGNED COMMENT "Content type",
	FOREIGN KEY (content_type_id) REFERENCES content_types(id),
	difficulty_level ENUM('Basic', 'Intermediate', 'Proficient')
		NOT NULL DEFAULT 'Basic',
	professional_field_id INT UNSIGNED COMMENT "Professional fild",
	FOREIGN KEY (professional_field_id) REFERENCES professional_fields(id),
	sender_id INT UNSIGNED NOT NULL DEFAULT 1 COMMENT "Note sender",
	FOREIGN KEY (sender_id) REFERENCES senders(id),
	author_id INT UNSIGNED COMMENT "Author",
	FOREIGN KEY (author_id) REFERENCES authors(id),
	description VARCHAR(500) NOT NULL COMMENT "description",
	language ENUM('Russian', 'English') NOT NULL DEFAULT 'Russian',
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Creation time",  
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
		ON UPDATE CURRENT_TIMESTAMP COMMENT "Update time"
) COMMENT "notes table";

-- Запрет вставки ссылки на вебинар без даты начала или без ссылки
DELIMITER $
DROP TRIGGER IF EXISTS null_link_insert$
CREATE TRIGGER null_link_insert BEFORE INSERT ON notes
FOR EACH ROW 
BEGIN 
	IF (NEW.content_type_id = 4) AND 
			((NEW.start_at IS NULL) OR (NEW.link IS NULL))
    	THEN 
		SIGNAL SQLSTATE '45000' 
		SET MESSAGE_TEXT = 'START DATE or LINK of the WEBINAR can not be NULL';
END IF;
END$
DELIMITER ;

-- Independent table
DROP TABLE IF EXISTS words;
CREATE TABLE words (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Word id", 
	word VARCHAR(50) NOT NULL COMMENT "Key word",
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Creation time",  
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  		ON UPDATE CURRENT_TIMESTAMP COMMENT "Update time"
) COMMENT "Key words";

-- Level 0 table
DROP TABLE IF EXISTS key_words_sets;
CREATE TABLE key_words_sets (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT "Id", 
	note_id INT UNSIGNED NOT NULL COMMENT "Note id",
	FOREIGN KEY (note_id) REFERENCES notes(id),
	word_id INT UNSIGNED COMMENT "Word id",
	FOREIGN KEY (word_id) REFERENCES words(id),
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT "Creation time",  
	updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
		ON UPDATE CURRENT_TIMESTAMP COMMENT "Update time"
) COMMENT "Words to notes link";

-- Insert data
INSERT INTO contact_types (name) VALUES
	('Telegram id'), ('E-mail'), ('Cell phone'), ('Website'), ('Other');

INSERT INTO content_types (name) VALUES
	('Tutorial'), ('Lecture'), ('Article'),
	('Webinar'), ('Online course'), ('Other');

INSERT INTO portal_types (name) VALUES
	('Website'), ('Educational portal'), ('Video hosting'),
		('Blog'), ('Other');

INSERT INTO professional_fields (name) VALUES
	('Data Analysis'),
	('Statistics'),
	('Machine Learning'),
	('Econometrics'),
	('Programming'),
	('Linux'),
	('SQL'),
	('DSP');

INSERT INTO senders (name, sender_contact) VALUES
	('Andrey Korzhun', '@AKorzhun'),
	('Dmitry L', '@dmtrLv'),
	('Рома Паномарев', '@loosertag');

INSERT INTO companies (name, type_id, contact) VALUES
	('Санкт-Петербургский государственный экономический университет СПбГЭУ',
	4, 'https://unecon.ru/'),
	('Yandex ML Team', Null, Null),
	('К-Скай WEBIOMED', 4, 'https://webiomed.ai');

INSERT INTO portals (id, name, type_id, link) VALUES
	(1, 'ДМИТРИЙ ФЕДОРОВ', 1, 'http://dfedorov.spb.ru'),
	(2, 'Coursera', 2, 'https://www.coursera.org'),
	(3, 'Youtube', 3, 'https://www.youtube.com'),
	(4, 'Habr', 4, 'https://habr.com'),
	(5, 'Stepik', 2, 'https://stepik.org'),
	(6, 'Geekbrains', 2, 'https://geekbrains.ru'),
	(7, 'Other', 5, Null);

INSERT INTO authors (name, company_id, type_id, contact) VALUES
	('Дима Федоров', 1, 1, '@dm_fedorov'),
	('Tom Fawcett', Null, 5, 'http://www.linkedin.com/pub/tom-fawcett/0/a1/59'),
	('Никита Дмитриев', 2, Null, Null),
	('Лариса Серова', 3, 2, 'lserova@webiomed.ai');

INSERT INTO notes (
	id, title, portal_id, start_at,
	link,
	content_type_id, difficulty_level,
	professional_field_id, sender_id, author_id,
	description, language) VALUES
		(1, 'Введение в Pandas', 1, Null,
			'http://dfedorov.spb.ru/pandas',
			1, 1,
			1, 1, 1,
			'Перевод официальной документации по Pandas с хорошими примерами', 1),
		(2, 'Введение в межгрупповые сравнения', 2, Null,
			'https://www.coursera.org/learn/sravneniye-sozdaniye-grupp/lecture/
				M5k7H/1-1-vviedieniie-v-miezhghruppovyie-sravnieniia',
			2, 1,
			2, 1, Null,
			'Про зависимые и независимые выборки с 5:30', 1),
		(3, 'Learning from Imbalanced Classes', 5, Null,
			'https://www.svds.com/learning-imbalanced-classes',
			3, 2,
			1, 1, 2,
			'Про балансировку классов', 2),
		(4, 'Решение задач классификации при помощи CatBoost', 3, Null,
			'https://www.youtube.com/watch?v=xl1fwCza9C8',
			2, 1,
			3, 1, 3,
			'Мастер-класс от Яндекса', 1),
		(5, 'CatBoost vs. Light GBM vs. XGBoost', 7, Null,
			'https://towardsdatascience.com/catboost-vs-light-gbm-vs-xgboost-5f93620723db',
			3, 2,
			3, 1, Null,
			'Who is going to win this war of predictions and on what cost? Let’s explore', 2),
		(6, 'What is a p-value?', 3, Null,
			'https://www.youtube.com/watch?v=9jW9G8MO4PQ',
			2, 1,
			2, 1, Null,
			'Demystifying one of the trickiest concepts from statistics: p-values!', 2),
		(7, 'Learn about the t-test, the chi square test, the p value and more', 3, Null,
			'https://www.youtube.com/watch?v=I10q6fjPxJ0',
			2, 1,
			2, 1, Null,
			'This introduction to stats will give you an understanding of how to
 				apply statistical tests to different types of data.', 2),
		(8, 'Эконометрика : учебник для вузов', 7, Null,
			'https://urait.ru/book/ekonometrika-449677',
			1, 2,
			4, 1, Null,
			'Учебник охватывает все основные разделы современного курса эконометрики.', 1),
		(9, 'Учимся применять оконные функции', 7, Null,
			'http://thisisdata.ru/blog/uchimsya-primenyat-okonnyye-funktsii',
			3, 2,
			1, 1, Null,
			'Разбирается мощнейший инструмент аналитика', 1),
		(10, 'Интерпретация результатов машинного обучения', 7, Null,
			'https://webiomed.ai/blog/interpretatsiia-rezultatov-mashinnogo-obucheniia',
			3, 2,
			3, 1, Null,
			'Попытка объяснить логику работы чёрного ящика', 1),
		(11, 'Darts: Time Series Made Easy in Python', 7, Null,
			'https://medium.com/unit8-machine-learning-publication/
				darts-time-series-made-easy-in-python-5ac2947a8878',
			3, 2,
			3, 1, Null,
			'Очень хорошая статья по временным рядам', 2),
		(12, 'Python, pandas и решение трёх задач из мира Excel', 7, Null,
			'https://m.habr.com/ru/company/ruvds/blog/500426/',
			1, 2,
			3, 1, Null,
			'Как слезть с Excel и начать в Pandas', 1),		
		(13, 'Stanford CS229: Machine Learning', 3, Null,
			'https://youtu.be/jGwO_UgTS7I',
			2, 1,
			3, 1, Null,
			'Machine learning by Andrew Ng', 2),
		(14, 'Вопросы для интервью по специальности Data Science', 7, Null,
			'https://interview-mds.ru',
			1, 1,
			1, 1, Null,
			'Готовимся к собеседованию', 1),
		(15, 'Top Python Libraries', 7, Null,
			'https://www.linkedin.com/posts/mlindia_datascience-
				machinelearning-python-activity-6729629209196605440-xc9P',
			1, 2,
			3, 2, Null,
			'Для доступа необходим VPN', 2),
		(16, 'CatBoost tutorials', 7, Null,
			'https://github.com/catboost/tutorials',
			1, 1,
			3, 1, Null,
			'Тетрадки с примерами использования CatBoost', 1),		
		(17, 'Настройка гиперпараметров XGBoost с помощью Scikit Optimize', 7, Null,
			'https://www.machinelearningmastery.ru/
				how-to-improve-the-performance-of-xgboost-models-1af3995df8ad/',
			1, 1,
			3, 1, Null,
			'Автоматизация подбора гиперпараметров', 1),
		(18, 'Ace the Data Scientist Interview', 7, Null,
			'https://classroom.udacity.com/courses/ud944',
			5, 2,
			1, 1, Null,
			'Data Science Interview Preparation', 2),
		(19, 'Introduction to Algorithms (SMA 5503)', 7, Null,
			'https://ocw.mit.edu/courses/electrical-engineering-
				and-computer-science/6-046j-introduction-to-algorithms-
					sma-5503-fall-2005/video-lectures/',
			2, 2,
			5, 1, Null,
			'Лекции по алгоритмам MIT', 2),
		(20, 'The Data Science Course 2020: Complete Data Science Bootcamp', 7, Null,
			'https://www.udemy.com/course/the-data-science-
				course-complete-data-science-bootcamp/',
			5, 1,
			3, 1, Null,
			'Курс платный, но иногда отдаётся за символические деньги', 2),		
		(21, 'CheckiO', 7, Null,
			'https://checkio.org/',
			1, 1,
			5, 1, Null,
			'Тренажер навыков программирования', 1),
		(22, 'LeetCode', 7, Null,
			'https://leetcode.com/',
			1, 1,
			5, 1, Null,
			'Тренажер навыков программирования', 1),		
		(23, 'egoroff_channel', 3, Null,
			'https://www.youtube.com/c/egoroffchannel',
			2, 1,
			5, 1, Null,
			'Неплохой канал по Python', 1),
		(24, 'codewars', 7, Null,
			'https://www.codewars.com',
			1, 1,
			5, 2, Null,
			'Тренажер навыков программирования', 1),
		(25, 'Чем отличаются data analyst, data engineer и data scientis', 3, Null,
			'https://www.youtube.com/watch?v=lDkTNURDIaY',
			1, 2,
			5, 1, Null,
			'Особенности профессий в DS', 1),
		(26, 'Поколение Python', 5, Null,
			'https://stepik.org/course/58852/syllabus',
			1, 1,
			5, 1, Null,
			'Курс с большим количеством практики', 1),		
		(27, 'Программирование на Python', 5, Null,
			'https://stepik.org/course/67/syllabus',
			1, 1,
			5, 1, Null,
			'Вводный курс', 1),
		(28, 'Python: основы и применение', 5, Null,
			'https://stepik.org/course/512/syllabus',
			1, 1,
			5, 1, Null,
			'Продолжение курса от Института Биоинформатики', 1),
		(29, 'Введение в Python. Практикум', 5, Null,
			'https://stepik.org/course/56391/syllabus',
			1, 2,
			5, 1, Null,
			'Задачи без теории', 1),
		(30, 'Python для решения практических задач', 5, Null,
			'https://stepik.org/course/4519/syllabus',
			1, 1,
			5, 1, Null,
			'Курс с реальными задачами', 1),
		(31, 'Практикум по математике и Python', 5, Null,
			'https://stepik.org/course/3356/syllabus',
			1, 1,
			5, 1, Null,
			'Разбираются популярные библиотеки, необходимые в DS', 1),
		(32, 'Машинное обучение для людей', 7, Null,
			'https://vas3k.ru/blog/machine_learning',
			3, 1,
			3, 3, Null,
			'Разбираемся простыми словами', 1),
		(33, 'Преобразования Фурье для обработки сигналов с помощью Python', 7, Null,
			'https://proglib.io/p/preobrazovaniya-fure-dlya-obrabotki-signalov-s-
				pomoshchyu-python-2020-11-03',
			3, 2,
			8, 1, Null,
			'Простой практический пример использования преобразования Фурье для
				восстановления зашумленного аудиосигнала с помощью Python и
					библиотеки SciPy', 1),
		(34, 'Основы статистики', 5, Null,
			'https://stepik.org/course/76/syllabus',
			5, 1,
			2, 1, Null,
			'Отличный курс для начала', 1),
		(35, 'Обзор Keras для TensorFlow', 4, Null,
			'https://habr.com/ru/post/482126/',
			3, 2,
			3, 1, Null,
			'Перевод обзорного руководства с сайта Tensorflow.org', 1),
		(36, 'Введение в визуализацию данных на Python', 6, '2020-09-17 19:00',
			'https://geekbrains.ru/events/2664',
			4, 1,
			1, 1, Null,
			'Библиотеки matplotlib и seaborn', 1),
		(37, 'Детали архитектуры MySQL', 6, '2020-07-19 19:00',
			'https://geekbrains.ru/events/2905',
			4, 1,
			7, 1, Null,
			'Затрагиваются такие темы, как: архитектура и подсистемы хранения, 
				структура файлов, управление памятью, полезные утилиты.', 1),
		(38, 'Простые алгоритмы классификации', 6, '2020-11-11 19:00',
			'https://geekbrains.ru/events/2934',
			4, 1,
			1, 1, Null,
			'KNN, Decision Tree, методы и алгоритмы ансамблирования', 1),
		(39, 'Классификация временных рядов с помощью Python', 6, '2020-02-06 19:00',
			'https://geekbrains.ru/events/1601',
			4, 1,
			8, 2, Null,
			'Рассматривается анализ временных рядов для задач классификации', 1),
		(40, 'The Ultimate Markdown Guide (for Jupyter Notebook)', 7, Null,
			'https://medium.com/analytics-vidhya/the-ultimate-markdown-guide-for-
				jupyter-notebook-d5e5abf728fd',
			3, 1,
			1, 1, Null,
			'Наиболее полное описание по оформлению работ в Jupyter Notebook', 2),
		(41, 'Практикум по математике и Python', 5, Null,
			'https://stepik.org/course/3356/syllabus',
			5, 1,
			1, 1, Null,
			'Изначально это был неофициальный набор задач для курса 
				"Математика и Python для анализа данных" от Яндекса и МФТИ', 1),
		(42, 'SQL Exercises', 7, Null,
			'https://www.w3schools.com/sql/sql_exercises.asp',
			1, 1,
			7, 1, Null,
			'Тренажер SQL', 2),
		(43, 'Cтекинг (Stacking) и блендинг (Blending)', 7, Null,
			'https://dyakonov.org/2017/03/10/c%D1%82%D0%B5%D0%BA%D0%B8%D0%BD%D0%B3-
				stacking-%D0%B8-%D0%B1%D0%BB%D0%B5%D0%BD%D0%B4%D0%B8%D0%BD%D0%B3-
					blending/',
			3, 1,
			3, 1, Null,
			'Про ансамблирование алгоритмов', 1),
		(44, 'Эконометрика (Econometrics)', 2, Null,
			'https://www.coursera.org/learn/ekonometrika',
			5, 1,
			4, 1, Null,
			'Эконометрика (включает введение в R)', 1),
		(45, 'StatQuest with Josh Starmer', 3, Null,
			'https://www.youtube.com/c/joshstarmer/search?query=optimization',
			2, 1,
			2, 1, Null,
			'Тут про оптимизацию, но, вообще, интересный канал где простыми
				словами про околоDSные темы.', 2);

INSERT INTO words (id, word) VALUES
	(1, 'Python'),	(2, 'Pandas'),	(3, 'DataFrame'),
	(4, 'imbalanced'),	(5, 'oversampling'), (6, 'undersampling'),
	(7, 'CatBoost'), (8, 'Shap'), (9, 'LightGBM'), (10, 'XGBoost'),
	(11, 'p-value'), (12, 'statistics'), (13, 'hypothesis'),
	(14, 'time-series'), (15, 'ARIMA'), (16, 'regression'),
	(17, 'выборки'), (18, 'критерии'), (19, 'тесты'),
	(20, 'SQL'), (21, 'оконные'), (22, 'OVER'), (23, 'PARTITION'),
	(24, 'искусственный'), (25, 'интеллект'),
	(26, 'машинное'), (27, 'обучение'),	(28, 'интерпритация'),
	(29, 'Excel'), (30, 'VLOOKUP'), (31, 'ВПР'),
	(32, 'вопросы'), (33, 'интервью'), (34, 'interview'),
	(35, 'libraries'), (36, 'библиотеки'), (37, 'sklearn'),
	(38, 'job'), (39, 'questions'), (40, 'preporation'),
	(41, 'algorithms'), (42, 'алгоритмы'), (43, 'SciPy'),
	(44, 'Фурье'), (45, 'DSP'), (46, 'сигналы'), (47, 'Fourier'),
	(48, 'FFT'), (49, 'БПФ'), (50, 'frequency'), (51, 'DFT'),
	(52, 'визуализация'), (53, 'инфографика'), (54, 'Seaborn'),
	(55, 'mysql'), (56, 'структура'), (57, 'управление'),
	(58, 'KNN'), (59, 'ансамблирование'), (60, 'Decision'),
	(61, 'EEG'), (62, 'ЭКГ'), (63, 'alert'), (64, 'div'),
	(65, 'оформление'), (66, 'color'), (67, 'вероятностей'),
	(68, 'optimizations'), (69, 'greedy');

INSERT INTO key_words_sets (note_id, word_id) VALUES
	(1, 1), (1, 2),	(1, 3),	(3, 4), (3, 5),	(3, 6),
	(4, 1), (4, 7), (4, 8),	(5, 7), (5, 9), (5, 10),
	(6, 11), (6, 12), (6, 13), 	(7, 11), (7, 12), (7, 13),
	(8, 14), (8, 15), (8, 16), (2, 17), (2, 18), (2, 19),
	(9, 20), (9, 21), (9, 22), (9, 23), (11, 14), (11, 15),
	(10, 24), (10, 25), (10, 26), (10, 27), (10, 28), (10, 8),
	(12, 29), (12, 30), (12, 31), (12, 1), (12, 2),
	(13, 26), (13, 27), (14, 32), (14, 33), (14, 34), (15, 1),
	(15, 35), (15, 36), (16, 1), (16, 7), (17, 10), (17, 37),
	(18, 38), (18, 39), (18, 40), (18, 32), (18, 33), (18, 34),
	(19, 41), (19, 42), (20, 1), (20, 12), (20, 26), (20, 27),
	(33, 43), (33, 44), (33, 45), (33, 46), (33, 47), (33, 48), 
	(33, 49), (33, 50), (33, 51), (33, 14),	(34, 12), (36, 52),
	(36, 53), (36, 54), (37, 55), (37, 56), (37, 57), (37, 20),
	(38, 1), (38, 58), (38, 59), (38, 60), (39, 14), (39, 61),
	(39, 62), (39, 45), (40, 63), (40, 64), (40, 65), (40, 66),
	(41, 67), (41, 12), (44, 12), (44, 14), (45, 68), (45, 69);		

SELECT * FROM notes;