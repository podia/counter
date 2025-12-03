class Reaction < ApplicationRecord
  belongs_to :post, inverse_of: :reactions
end
