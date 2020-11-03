
proc showError*(msg: string) =
  raise newException(ValueError, msg)
