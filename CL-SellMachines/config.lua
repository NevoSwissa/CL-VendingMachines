Config = Config or {}

Config.ConnectedOwners = {} -- A table which store all the vending machine owners that are connected

Config.VendingMachineObject = "p_ld_coffee_vend_s" -- The vending machine object

Config.Target = 'qb-target' -- Name of your target (Change this only if you have a custom named target) IT DOES NOT SUPPORT OTHER TARGETS !

Config.ItemsLimit = 7 -- The amount of items the player can sell in the vending machine

Config.MaxInventoryWeight = 120000 -- Set that to your max inventory weight, by defualt 120000

Config.BlackListedNames = {
    -- List of words that players cant use as the vending machine name example :
    "Example",
    "Example2",
    "..."
}

Config.BlackListedItems = {
    -- List of items that players cant sell example :
    "pistol",
    "pisto2",
    "..."
}

Config.BlackListedLocations = {
    -- List of locations that players cant spawn vending machine at
    [1] = {
        Coords = vector3(0.000, 0.000, 0.000), -- Vector3 coords
        Distance = 10.0, -- Distance from the coords which is blacklisted (Circle area)
    },  
}