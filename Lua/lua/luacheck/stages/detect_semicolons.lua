local stage = {}

stage.warnings = {
   ["912"] = {message_format = "it is not allowed to use semicolons to seperate statements",
      fields = {}}
}

function stage.run(chstate)
   for _, range in ipairs(chstate.semicolons) do
      chstate:warn_range("912", range)
   end
end

return stage
