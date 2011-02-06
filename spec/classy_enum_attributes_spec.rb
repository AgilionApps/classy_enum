require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "A Dog" do

  context "with valid breed options" do
    before { @dog = Dog.new(:breed => :golden_retriever) }

    it "should have a classy enum breed" do
      @dog.breed.should be_a(BreedGoldenRetriever)
    end

    it "should be valid with a valid option" do
      @dog.should be_valid
    end
  end

  it "should not be valid with a nil breed" do
    Dog.new(:breed => nil).should_not be_valid
  end

  it "should not be valid with a blank breed" do
    Dog.new(:breed => "").should_not be_valid
  end

  context "with invalid breed options" do
    before { @dog = Dog.new(:breed => :fake_breed) }

    it "should not be valid with an invalid option" do
      @dog.should_not be_valid
    end

    it "should have an error message containing the right options" do
      @dog.valid?
      @dog.errors[:breed].should include("must be one of #{Breed.all.map(&:to_sym).join(', ')}")
    end
  end

end

describe "A ClassyEnum that has a different field name than the enum" do
  before { @dog = OtherDog.new(:other_breed => :snoop) }

  it "should have a classy enum breed" do
    @dog.other_breed.should be_a(BreedSnoop)
  end
end
