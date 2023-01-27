INSERT INTO `items` (`id`, `name`, `label`, `limit`, `rare`, `can_remove`) VALUES (NULL, 'pilotergb', 'Tablette Pilote RGB', '1', '0', '1');

CREATE TABLE `owned_vehicles_phares` (
  `id` int(11) NOT NULL,
  `plate` text NOT NULL,
  `color` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


ALTER TABLE `owned_vehicles_phares`
  ADD PRIMARY KEY (`id`);


ALTER TABLE `owned_vehicles_phares`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
