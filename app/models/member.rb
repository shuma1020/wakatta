class Member < ApplicationRecord
    has_secure_password
    validates :name, presence: true,
        format: {
            with: /\A[A-Za-z][A-Za-z0-9]*\z/, 
            allow_blank: true,
            message: :invalid_member_name
        },
        length: {minimum: 2, maximum: 20, allow_blank: true},
        uniqueness: {case_sensitive: false}
    validates :email, email: {allow_blank: true}

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
  