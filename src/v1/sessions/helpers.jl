## useful for resetting Module list
LightTable.raise(LightTable.global_client, "julia.set-modules", @Jewel.d(:modules => [string(m) for m in Jewel.allchildren(Main)]))
