USE `rework`;

INSERT INTO `addon_account` (name, label, shared) VALUES
	('society_groove', 'Mécano', 1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
	('society_groove', 'Mécano', 1)
;

INSERT INTO `jobs` (name, label) VALUES
	('groove', 'Mécano')
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
	('groove',0,'recrue','Recrue',12,'{}','{}'),
	('groove',1,'novice','Novice',24,'{}','{}'),
	('groove',2,'experimente','Experimente',36,'{}','{}'),
	('groove',3,'chief',"Chef d\'équipe",48,'{}','{}'),
	('groove',4,'boss','Patron',0,'{}','{}')
;

INSERT INTO `items` (name, label, `limit`) VALUES
	('gazbottle', 'bouteille de gaz', 11),
	('fixtool', 'outils réparation', 6),
	('carotool', 'outils carosserie', 4),
	('blowpipe', 'Chalumeaux', 10),
	('fixkit', 'Kit réparation', 5),
	('carokit', 'Kit carosserie', 3)
;
