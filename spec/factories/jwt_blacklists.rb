FactoryBot.define do
  factory :jwt_blacklist do
    jti { "MyString" }
    exp { "2025-05-02 12:04:58" }
  end
end
