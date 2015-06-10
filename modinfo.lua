-----------------------
-- General information!
-----------------------

name = "Health Info"
description = "Version 0.2\nShows exact health of creatures on mouse-over or controller auto-target. This mod is inspired by Tell Me About Health (DS)."
author = "xVars"

version = "0.2"

-- Currently no forum thread.
forumthread = ""

-- Developed for this version of the game.
api_version = 6

-- Custom icon.
icon_atlas = "preview.xml"
icon = "preview.tex"

-----------------
-- Compatibility!
-----------------

-- Only supported for Don't Starve
dont_starve_compatible = true
reign_of_giants_compatible = true

--------------------------------------------------
-- Begin code for configuring all of the settings!
--------------------------------------------------

configuration_options =
{
    {
        name = "show_type",
        label = "Show Type",
        options =
        {
            {description = "Value", data = 0},
            {description = "Percentage", data = 1},
            {description = "Both", data = 2},
        },
        default = 0,
    }
}