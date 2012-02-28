require "spec_helper"

describe "Intercom::User" do
  it "to_hash'es itself" do
    created_at = Time.now
    user = Intercom::User.new("email" => "jim@example.com", :user_id => "12345", :created_at => created_at, :name => "Jim Bob")
    as_hash = user.to_hash
    as_hash["email"].must_equal "jim@example.com"
    as_hash["user_id"].must_equal "12345"
    as_hash["created_at"].must_equal created_at.to_i
    as_hash["name"].must_equal "Jim Bob"
  end

  it "presents created_at and last_impression_at as Date" do
    now = Time.now
    user = Intercom::User.new(:created_at => now, :last_impression_at => now)
    user.created_at.must_be_kind_of Time
    user.created_at.to_s.must_equal now.to_s
    user.last_impression_at.must_be_kind_of Time
    user.last_impression_at.to_s.must_equal now.to_s
  end

  it "is ok on missing methods" do
    user = Intercom::User.new
    user.created_at.must_be_nil
    user.last_impression_at.must_be_nil
    user.email.must_be_nil
    user.social_profiles.must_equal([])
  end

  it "presents a complete user record correctly" do
    user = Intercom::User.new(test_user)
    user.session_count.must_equal 123
    user.social_profiles.size.must_equal 4
    twitter_account = user.social_profiles.first
    twitter_account.must_be_kind_of Intercom::SocialProfile
    twitter_account.type.must_equal "twitter"
    twitter_account.username.must_equal "abc"
    twitter_account.url.must_equal "http://twitter.com/abc"
    user.custom_data["a"].must_equal "b"
    user.custom_data["b"].must_equal 2
  end

  it "has read-only social accounts" do
    user = Intercom::User.new(:social_profiles => [:url => "http://twitter.com/abc", "username" => "abc", "type" => "twitter"])
    user.social_profiles.size.must_equal 1
    twitter = user.social_profiles.first
    twitter.type.must_equal "twitter"
    twitter.url.must_equal "http://twitter.com/abc"
    twitter.username.must_equal "abc"
    user.to_hash["social_profiles"].must_equal nil
    proc { user.social_profiles << "a" }.must_raise RuntimeError, "can't modify frozen array"
    proc { Intercom::User.new.social_profiles << "a" }.must_raise RuntimeError, "can't modify frozen array"
  end

  it "has read-only location data" do
    Intercom::User.new.location_data.must_equal({})
    user = Intercom::User.new(:location_data => {"city" => "Dublin"})
    user.location_data.must_equal({"city" => "Dublin"})
    proc { user.location_data["change"] = "123" }.must_raise RuntimeError, "can't modify frozen hash"
    user.to_hash["location_data"].must_equal nil
  end

  it "allows easy setting of custom data" do
    now = Time.now
    user = Intercom::User.new()
    user.custom_data["mad"] = 123
    user.custom_data["other"] = now
    user.custom_data["thing"] = "yay"
    user.to_hash["custom_data"].must_equal "mad" => 123, "other" => now, "thing" => "yay"
  end

  it "rejects nested data structures in custom_data" do
    user = Intercom::User.new()
    proc { user.custom_data["thing"] = [1] }.must_raise ArgumentError
    proc { user.custom_data["thing"] = {1 => 2} }.must_raise ArgumentError
  end

  it "fetches a user" do
    Intercom.expects(:get).with("users", {"email" => "bo@example.com"}).returns(test_user)
    user = Intercom::User.find("email" => "bo@example.com")
    user.email.must_equal "bo@example.com"
    user.name.must_equal "Joe Schmoe"
    user.session_count.must_equal 123
  end

  it "saves a user" do
    user = Intercom::User.new("email" => "jo@example.com", :user_id => "i-1224242")
    Intercom.expects(:post).with("users", {"email" => "jo@example.com", "user_id" => "i-1224242"})
    user.save
  end

  it "can use User.create for convenience" do
    Intercom.expects(:post).with("users", {"email" => "jo@example.com", "user_id" => "i-1224242"}).returns({"email" => "jo@example.com", "user_id" => "i-1224242"})
    user = Intercom::User.create("email" => "jo@example.com", :user_id => "i-1224242")
    user.email.must_equal "jo@example.com"
  end

  it "updates the @user with attributes as set by the server" do
    Intercom.expects(:post).with("users", {"email" => "jo@example.com", "user_id" => "i-1224242"}).returns({"email" => "jo@example.com", "user_id" => "i-1224242", "session_count" => 4})
    user = Intercom::User.create("email" => "jo@example.com", :user_id => "i-1224242")
    user.session_count.must_equal 4
  end
end