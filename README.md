# ClassyEnum

[![Build Status](https://secure.travis-ci.org/beerlington/classy_enum.png?branch=master)](http://travis-ci.org/beerlington/classy_enum)

ClassyEnum is a Ruby on Rails gem that adds class-based enumerator functionality to ActiveRecord attributes.

## README Topics

* [Example Usage](https://github.com/beerlington/classy_enum#example-usage)
* [Internationalization](https://github.com/beerlington/classy_enum#internationalization)
* [Using Enum as a Collection](https://github.com/beerlington/classy_enum#using-enum-as-a-collection)
* [Reference to Owning Object](https://github.com/beerlington/classy_enum#back-reference-to-owning-object)
* [Serializing as JSON](https://github.com/beerlington/classy_enum#serializing-as-json)
* [Special Cases](https://github.com/beerlington/classy_enum#special-cases)
* [Built-in Model Validation](https://github.com/beerlington/classy_enum#model-validation)
* [Using Enums Outside of ActiveRecord](https://github.com/beerlington/classy_enum#working-with-classyenum-outside-of-activerecord)
* [Formtastic Support](https://github.com/beerlington/classy_enum#formtastic-support)

## Rails & Ruby Versions Supported

*Rails:* 3.0.x - 3.2.x

*Ruby:* 1.8.7, 1.9.2 and 1.9.3

If you need support for Rails 2.3.x, please install [version 0.9.1](https://rubygems.org/gems/classy_enum/versions/0.9.1).
Note: This branch is no longer maintained and will not get bug fixes or new features.

## Installation

The gem is hosted at [rubygems.org](https://rubygems.org/gems/classy_enum)

## Upgrading?

See the [wiki](https://github.com/beerlington/classy_enum/wiki/Upgrading) for notes about upgrading from previous versions.

## Example Usage

The most common use for ClassyEnum is to replace database lookup tables where the content and behavior is mostly static and has multiple "types". In this example, I have an ActiveRecord model called `Alarm` with an attribute called `priority`. Priority is stored as a string (VARCHAR) type in the database and is converted to an enum value when requested.

### 1. Generate the Enum

The fastest way to get up and running with ClassyEnum is to use the built-in Rails generator like so:

```
rails g classy_enum Priority low medium high
```

A new enum template file will be created at app/enums/priority.rb that will look like:

```ruby
class Priority < ClassyEnum::Base
end

class Priority::Low < Priority
end

class Priority::Medium < Priority
end

class Priority::High < Priority
end
```

The class order will define the enum member order as well as additional ClassyEnum behavior, which is described further down in this document.

### 2. Customize the Enum

The generator creates a default setup, but each enum member can be changed to fit your needs.

I have defined three priority levels: low, medium, and high. Each priority level can have different properties and methods associated with it.

I would like to add a method called `#send_email?` that all member subclasses respond to. By default this method will return false, but will be overridden for high priority alarms to return true.

```ruby
class Priority < ClassyEnum::Base
  def send_email?
    false
  end
end

class Priority::Low < Priority
end

class Priority::Medium < Priority
end

class Priority::High < Priority
  def send_email?
    true
  end
end
```

### 3. Setup the ActiveRecord model

My ActiveRecord Alarm model needs a text field that will store a string representing the enum member. An example model schema might look something like:

```ruby
create_table "alarms", :force => true do |t|
  t.string   "priority"
  t.boolean  "enabled"
end
```

Note: Alternatively, you may use an enum type if your database supports it. See
[this issue](https://github.com/beerlington/classy_enum/issues/12) for more information.

Then in my model I've added a line that calls `classy_enum_attr` with a single argument representing the enum I want to associate with my model. I am also delegating the `#send_email?` method to my Priority enum class.

```ruby
class Alarm < ActiveRecord::Base
  classy_enum_attr :priority

  delegate :send_email?, :to => :priority
end
```

With this setup, I can now do the following:

```ruby
@alarm = Alarm.create(:priority => :medium)

@alarm.priority  # => Priority::Medium
@alarm.priority.medium? # => true
@alarm.priority.high? # => false
@alarm.priority.to_s # => 'medium'

# Should this alarm send an email?
@alarm.send_email? # => false
@alarm.priority = :high
@alarm.send_email? # => true
```

The enum field works like any other model attribute. It can be mass-assigned using `#update_attributes`.

## Internationalization

ClassyEnum provides built-in support for translations using Ruby's I18n
library. The translated values are provided via a `#text` method on each
enum object. Translations are automatically applied when a key is found
at `locale.classy_enum.enum_parent_class.enum_value`, or a default value
is used that is equivalent to `#to_s.titleize`.

Given the following file *config/locales/es.yml*

```yml
es:
  classy_enum:
    priority:
      low: 'Bajo'
      medium: 'Medio'
      high: 'Alto'
```

You can now do the following:

```ruby
@alarm.priority = :low
@alarm.priority.text # => 'Low'

I18n.locale = :es

@alarm.priority.text # => 'Bajo'
```

## Using Enum as a Collection

ClassyEnum::Base extends the [Enumerable module](http://ruby-doc.org/core-1.9.3/Enumerable.html)
which provides several traversal and searching methods. This can
be useful for situations where you are working with the collection,
as opposed to the attributes on an ActiveRecord object.

```ruby
# Find the priority based on string or symbol:
Priority.find(:low) # => Priority::Low.new
Priority.find('medium') # => Priority::Medium.new

# Find the lowest priority that can send email:
Priority.find(&:send_email?) # => Priority::High.new

# Find the priorities that are lower than Priority::High
high_priority = Priority::High.new
Priority.select {|p| p < high_priority } # => [Priority::Low.new, Priority::Medium.new]

# Iterate over each priority:
Priority.each do |priority|
  puts priority.send_email?
end
```

## Back reference to owning object

In some cases you may want an enum class to reference the owning object
(an instance of the active record model). Think of it as a `belongs_to`
relationship, where the enum belongs to the model.

By default, the back reference can be called using `#owner`.
If you want to refer to the owner by a different name, you must explicitly declare
the owner name in the classy_enum parent class using the `.owner` class method.

Example using the default `#owner` method:

```ruby
class Priority < ClassyEnum::Base
end

# low and medium subclasses omitted

class Priority::High < Priority
  def send_email?
    owner.enabled?
  end
end
```

Example where the owner reference is explicitly declared:

```ruby
class Priority < ClassyEnum::Base
  owner :alarm
end

# low and medium subclasses omitted

class Priority::High < Priority
  def send_email?
    alarm.enabled?
  end
end
```

In the above examples, high priority alarms are only emailed if the owning alarm is enabled.

```ruby
@alarm = Alarm.create(:priority => :high, :enabled => true)

# Should this alarm send an email?
@alarm.send_email? # => true
@alarm.enabled = false
@alarm.send_email? # => false
```

## Serializing as JSON

By default, the enum will be serialized as a string representing the value:

```ruby
@alarm = Alarm.create(:priority => :high, :enabled => true)
@alarm.to_json.should == "{\"alarm\":{\"priority\":\"high\"}}"
```

This behavior can be overridden by using the `:serialize_as_json => true` option in your ActiveRecord model:

```ruby
class Alarm < ActiveRecord::Base
  classy_enum_attr :priority, :serialize_as_json => true
end

@alarm = Alarm.create(:priority => :high, :enabled => true)
@alarm.to_json.should == "{\"alarm\":{\"priority\":{}}}"
```

## Special Cases

What if your enum class name is not the same as your model's attribute name? No problem! Just use a second argument in `classy_enum_attr` to declare the attribute name. In this case, the model's attribute is called *alarm_priority*.

```ruby
class Alarm < ActiveRecord::Base
  classy_enum_attr :alarm_priority, :enum => 'Priority'
end

@alarm = Alarm.create(:alarm_priority => :medium)
@alarm.alarm_priority  # => Priority::Medium
```

## Model Validation

An ActiveRecord validator `validates_inclusion_of :field, :in => ENUM` is automatically added to your model when you use `classy_enum_attr`.

If your enum only has members low, medium, and high, then the following validation behavior would be expected:

```ruby
@alarm = Alarm.new(:priority => :really_high)
@alarm.valid? # => false
@alarm.priority = :high
@alarm.valid? # => true
```

To allow nil or blank values, you can pass in `:allow_nil` and `:allow_blank` as options to `classy_enum_attr`:

```ruby
class Alarm < ActiveRecord::Base
  classy_enum_attr :priority, :allow_nil => true
end

@alarm = Alarm.new(:priority => nil)
@alarm.valid? # => true
```

## Working with ClassyEnum outside of ActiveRecord

While ClassyEnum was designed to be used directly with ActiveRecord, it can also be used outside of it. Here are some examples based on the enum class defined earlier in this document.

Instantiate an enum member subclass *Priority::Low*

```ruby
# These statements are all equivalent
low = Priority.find(:low)
low = Priority.find('low')
low = Priority::Low.new
```

## Formtastic Support

Built-in Formtastic support has been removed as of 2.0. It is still
available but needs to be enabled manually. To enable support visit
[the wiki](https://github.com/beerlington/classy_enum/wiki/Formtastic-Support)

Then in your Formtastic view forms, use this syntax: `<%= f.input :priority, :as => :enum_select %>`

Note: ClassyEnum respects the `:allow_blank` and `:allow_nil` options and will include a blank select option in these cases

## Copyright

Copyright (c) 2012 [Peter Brown](https://github.com/beerlington). See LICENSE for details.
