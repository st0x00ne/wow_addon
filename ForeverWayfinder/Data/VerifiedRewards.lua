-- Only record rewards checked against Forever, never infer them from Classic.
local _, addon = ...
addon.VerifiedRewards = {
  [166] = { -- The Defias Brotherhood, beta
    {6087, "Chausses of Westfall"},
    {2041, "Tunic of Westfall"},
    {2042, "Staff of Westfall"},
  },
}
