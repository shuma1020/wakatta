class Member < ApplicationRecord
    class << self
      def search(query)
        rel = order("id")
        if query.present?
          rel = rel.where("name LIKE ? OR full_name LIKE ?",
            "%#{query}%", "%#{query}%")
        end
        rel
      end
    end
  end
  