require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe It do
  TASK = "buy milk"

  context "in a new project" do
    before(:each) do
      FileUtils.rm_rf(It::Path[:root])
    end

    it "should initialize the directory" do
      It.run(:init)
      File.exist?(It::Path[:root]).should be_true
      File.exist?(It::Path[:db]).should be_true
    end

    it "should warn that the project isn't initialized" do
      -> {It.run(:list)}.should raise_error(SystemExit)
    end
  end

  context "in an existing project" do
    before(:all) do
      It.init!
    end
 
    context "with no tasks" do
      it "shouldn't try to init" do
        -> {It.run(:init)}.should raise_error(SystemExit)
      end
      
      it "should warn about invalid commands" do
        -> {It.run(:choo)}.should raise_error(SystemExit)
      end

      it "should add tasks" do
        if It.run(:add, TASK)
          e = It::Database.new(It::Path[:db]).find(TASK)
          e.should be_a(It::Entity)
          e[:status].should == :created
          e[:tags].should == []
        else
          fail
        end
      end
    end

    context "with a couple tasks" do
      TASKS = ["milk", "eggs", "bananas"]
      before(:each) do
        It.init!
        TASKS.each do |t|
          It.run(:add, t)
        end
        @db = It::Database.new(It::Path[:db])
      end

      it "should remove tasks" do
        It.run(:remove, TASKS.last)
        @db.load.find(TASKS.last)[:status].should == :removed
      end

      it "should complete tasks" do
        It.run(:did, TASKS.first)
        @db.load.find(TASKS.first)[:status].should == :completed
      end

      it "should tag tasks" do
        It.run(:tag, TASKS[1], ["food"])
        @db.load.find(TASKS[1])[:tags].should include("food")
      end

      it "should warn when the task wasn't found" do
        -> {It.run(:did, "celery")}.should raise_error(SystemExit)
      end
    end
  end
end
