$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'active_record'
require 'action_view'
require 'action_controller'
require 'rspec/rails'
require 'classy_enum'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

RSpec.configure do |config|
  config.color_enabled = true
end

ActiveRecord::Schema.define(:version => 1) do
  create_table :dogs, :force => true do |t|
    t.string :breed
  end

  create_table :other_dogs, :force => true do |t|
    t.string :other_breed
  end

  create_table :allow_blank_breed_dogs, :force => true do |t|
    t.string :breed
  end

  create_table :allow_nil_breed_dogs, :force => true do |t|
    t.string :breed
  end

  create_table :active_dogs, :force => true do |t|
    t.string :breed
    t.string :color
    t.string :name
    t.integer :age
  end

  create_table :cats, :force => true do |t|
    t.string :breed
  end

  create_table :other_cats, :force => true do |t|
    t.string :breed
  end
end

class Breed < ClassyEnum::Base
  enum_classes :golden_retriever, :snoop, :husky
end

class BreedGoldenRetriever < Breed
end

class BreedSnoop < Breed
end

class BreedHusky < Breed
end

class Dog < ActiveRecord::Base
  classy_enum_attr :breed
end

class AllowBlankBreedDog < ActiveRecord::Base
  classy_enum_attr :breed, :allow_blank => true
end

class AllowNilBreedDog < ActiveRecord::Base
  classy_enum_attr :breed, :allow_nil => true
end

class OtherDog < ActiveRecord::Base
  classy_enum_attr :other_breed, :enum => :breed
end
