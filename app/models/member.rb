class Member < ApplicationRecord
    has_secure_password

    has_many :entries, dependent: :destroy
    has_many :votes, dependent: :destroy
    has_many :voted_entries, through: :votes, source: :entry
    has_one_attached :profile_picture
    has_many :comments
    has_many :articeles, dependent: :destroy
    attribute :new_profile_picture

    validates :name, presence: true,
        format: {
            with: /\A[A-Za-z][A-Za-z0-9]*\z/, 
            allow_blank: true,
            message: :invalid_member_name
        },
        length: {minimum: 2, maximum: 20, allow_blank: true},
        uniqueness: {case_sensitive: false}
    validates :email, email: {allow_blank: true}
    
    attr_accessor :current_password
    validates :password, presence: {if: :current_password}

    before_save do
        if new_profile_picture
          self.profile_picture = new_profile_picture
        end
      end
      def votable_for?(entry)
        entry && entry.author != self && !votes.exists?(entry_id: entry.id)
      end

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
  