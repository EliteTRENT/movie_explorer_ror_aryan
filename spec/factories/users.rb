FactoryBot.define do
  factory :user do
    name { Faker::Name.name[0...100].truncate(100, omission: '') }
    email { Faker::Internet.unique.email }
    mobile_number { Faker::PhoneNumber.unique.phone_number.gsub(/[^0-9+]/, '')[0..13] }
    password { "Password@123" }
    notifications_enabled { true }
    role { :user }  
    jti { SecureRandom.uuid }
    device_token { Faker::Base.regexify(/[A-Za-z0-9]{32}/) }

    trait :supervisor do
      role { :supervisor }
    end

    trait :invalid do
      email { "invalid-email" }
      password { nil }
      password_confirmation { nil }
      name { "" }
      mobile_number { nil }
      notifications_enabled { nil }
    end
  end
end