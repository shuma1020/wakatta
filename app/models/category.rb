class Category < ApplicationRecord
    has_many :manages
    has_many :articles, through: :manages
end
