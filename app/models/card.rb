class Card < ApplicationRecord
  validates :pin, :name, :dr, :box,
    presence: true
end
