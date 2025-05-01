FactoryBot.define do
  factory :movie do
    title { Faker::Movie.title[0...100] }
    genre { %w[Action Comedy Drama Thriller Sci-Fi].sample }
    release_year { Faker::Number.between(from: 1881, to: Date.current.year + 1) }
    rating { Faker::Number.between(from: 0, to: 10) }
    director { Faker::Name.name }
    duration { Faker::Number.between(from: 60, to: 240) }
    description { Faker::Lorem.paragraph(sentence_count: 5)[0...1000] }
    premium { [true, false].sample }

    after(:build) do |movie|
      movie.poster.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'poster.jpg')),
        filename: 'poster.jpg',
        content_type: 'image/jpeg'
      )
      movie.banner.attach(
        io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'banner.jpg')),
        filename: 'banner.jpg',
        content_type: 'image/jpeg'
      )
    end

    trait :invalid do
      title { '' }
      genre { '' }
      release_year { 1800 } 
      rating { 11 } 
      director { '' }
      duration { 0 } 
      description { '' }
    end

    trait :without_attachments do
      after(:build) do |movie|
        movie.poster.detach
        movie.banner.detach
      end
    end
  end
end