# CL-VendingMachines
Advanced QBCore Rust inspired vending machine system

Preview video : https://www.youtube.com/watch?v=4r5WMp1WiBY

Discord : https://discord.gg/rp6ynCJTKK

Installation :

1- Run the SQL file - CL-SellMachines.sql

2- Add the item to [qb] > qb-core > shared > items.lua

		["cl_machine"] 				 	 = {["name"] = "cl_machine", 			  			["label"] = "Vending Machine", 					["weight"] = 1000, 		["type"] = "item", 		["image"] = "cl_machine.png", 				["unique"] = false, 	["useable"] = true, 	["shouldClose"] = true,	   ["combinable"] = nil,   ["description"] = "Vending machine that can be used to sell and buy items."},

3 - Add the image from the Image folder to [qb] > qb-inventory > html > images
