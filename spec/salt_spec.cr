require "./spec_helper"

describe Salt do
  describe "#alias class" do
    context "Runtime" do
      it "should alias Salt::Middlewares::Runtime" do
        Salt::Middlewares::Runtime.should be_a Salt::Middlewares::Runtime.class
      end
    end

    context "Logger" do
      it "should alias Salt::Middlewares::Logger" do
        Salt::Middlewares::Logger.should be_a Salt::Middlewares::Logger.class
      end
    end

    context "CommonLogger" do
      it "should alias Salt::Middlewares::Runtime" do
        Salt::Middlewares::CommonLogger.should be_a Salt::Middlewares::CommonLogger.class
      end
    end

    context "ShowExceptions" do
      it "should alias Salt::Middlewares::Runtime" do
        Salt::Middlewares::ShowExceptions.should be_a Salt::Middlewares::ShowExceptions.class
      end
    end

    context "Session::Cookie" do
      it "should alias Salt::Middlewares::Runtime" do
        Salt::Middlewares::Session::Cookie.should be_a Salt::Middlewares::Session::Cookie.class
      end
    end
  end
end
