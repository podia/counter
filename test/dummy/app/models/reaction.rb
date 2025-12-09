class Reaction < ApplicationRecord
  belongs_to :reactable, polymorphic: true, inverse_of: :reactions
end
