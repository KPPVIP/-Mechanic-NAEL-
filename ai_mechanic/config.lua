-------------------
-- C o n f i g s --
-------------------


companyName = "DVRepairs"       
companyIcon = "CHAR_LS_CUSTOMS" -- https://wiki.gtanet.work/index.php?title=Notification_Pictures
spawnRadius = 100               -- Default Value: 
drivingStyle = 786603           -- Default Value: 786603
simplerRepair = false           -- When enabled, instead of getting out of the vehicle to repair, the mechanic stops his vehicle and the repair happens automatically.
repairComsticDamage = false     -- When enabled, the vehicle's cosmetic damage gets reset.
flipVehicle = false             -- When enabled, the vehicle will be flipped if on roof or side after repair.
 
-- To change the chat command (def. /mechanic), see line 1 of client.lua

-- Edit / Add Drivers and their information here!

mechPeds = {
                --  * Find the icons here:      https://wiki.gtanet.work/index.php?title=Notification_Pictures
                --  * Find the ped models here: https://wiki.gtanet.work/index.php?title=Peds
                --  * Find the vehicles here    https://wiki.gtanet.work/index.php?title=Vehicle_Models
                --  * Find the colours here:    https://wiki.gtanet.work/index.php?title=Vehicle_Colors

                [1] = {name = "Mechanic Dave", icon = "CHAR_MP_MECHANIC", model = "S_M_Y_DockWork_01", vehicle = 'UtilliTruck3', colour = 111, 
                                ['lines'] = {
                                        "Elle est comme neuve.",
                                        "Tout est fait ici.",
                                        "Vous voici, devrait travailler maintenant.",
                                        "C'est fait.",
                                        "Que puis-je dire, je suis un maître de mon métier.",
                                        "J'ai dû saupoudrer un peu de magie, mais ça devrait marcher maintenant.",
                                        "Qui vas-tu appeler? Dave Mechanic!",
                                        "Trop facile!",
                                        "Plus facile sur la pédale d'accélérateur la prochaine fois?",
                                        "La seule chose que je ne peux pas résoudre, c'est mon mariage...",
                                        "Fixé. Passez une bonne journée, conduisez prudemment!",
                                        "C'est un peu un lodge, mais ça marche.",}},

                [2] = {name = "Mechanic Miles", icon = "CHAR_MP_BIKER_MECHANIC", model = "S_M_Y_Construct_01", vehicle = 'BobcatXL', colour = 118, 
                                ['lines'] = {
                                        "Ouais, maintenant elle est plus fraîche qu'un oreiller avec une menthe dessus!",
                                        "Tout est fait ici.",
                                        "Travail accompli.",
                                        "J\'ai fait tout ce que j'ai pu.",
                                        "Je l'ai frappé avec une clé à quelques reprises et je pense que cela a fonctionné! ",
                                        "Notre entreprise décline toute responsabilité en cas de combustion spontanée du moteur.",
                                        "Parfois, je ne pense pas vraiment savoir ce que je fais. Bref, voici votre voiture!",
                                        "Ahh, oui ... Le tuyau d'eau devait être remplacé. Tout va bien maintenant.",
                                        "Elle est en parfait état.",
                                        "*Claque le toit de la voiture * Ce mauvais garçon peut y mettre autant de vis.",
                                        "Devrait fonctionner maintenant."}},

                -- You can use this template to make your own driver.

                --  * Find the icons here:      https://wiki.gtanet.work/index.php?title=Notification_Pictures
                --  * Find the ped models here: https://wiki.gtanet.work/index.php?title=Peds
                --  * Find the colours here:    https://wiki.gtanet.work/index.php?title=Vehicle_Colors
                --  * Driver ID needs to be a number (in sequential order from the previous one. In this example it would be 3).
                --[[
                
                --Edit the NAME, ICON, PED MODEL and TRUCK COLOUR here:
                [driver_ID] = {name = "driver_name", icon = "driver_icon", model = "ped_model", vehicle = 'vehicle_model' colour = 'driver_colour',

                                --You can add or edit any existing vehicle fix lines here:
                                [1] = {"Sample text 1","Sample text 2",}}, -- lines of dialogue.

                  
                ]]
                }
