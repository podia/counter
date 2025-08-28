class CigaretteCounter < Counter::Definition
  calculated_value ->(user) { user.grumpy? ? 212 : 4 }
end
