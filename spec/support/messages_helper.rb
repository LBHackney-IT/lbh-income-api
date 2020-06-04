module MessagesHelper
  def example_templates
    [{
      "id": "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}",
      "name": Faker::Movies::HitchhikersGuideToTheGalaxy.planet,
      "body": Faker::Movies::HitchhikersGuideToTheGalaxy.quote
    }, {
      "id": "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}",
      "name": Faker::Movies::HitchhikersGuideToTheGalaxy.planet,
      "body": Faker::Movies::HitchhikersGuideToTheGalaxy.quote
    }]
  end
end
