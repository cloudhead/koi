require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Koi do
  TASK = "buy milk"
  Koi::Path[:root] = '._koi'
  Koi::Path[:db] = '._koi/database.yml'
  Koi::Path[:paths] = '._koi/paths'

  context "in a new project" do
    before(:each) do
      FileUtils.rm_rf(Koi::Path[:root])
      FileUtils.rm_rf(File.join(ENV['HOME'], Koi::Path[:root]))
    end

    it "should initialize the .koi directory" do
      Koi.run(:init)
      File.exist?(Koi::Path[:root]).should == true
      File.exist?(Koi::Path[:db]).should == true
    end

    it "should create a .koi in ~" do
      Koi.run(:init)
      File.exist?(File.join(ENV['HOME'], Koi::Path[:root])).
        should == true
      File.read(File.join(ENV['HOME'], Koi::Path[:paths])).
        split(/\n/).should include(File.expand_path(Dir.pwd))
    end

    it "should warn that the project isn't initialized" do
      -> {Koi.run(:list)}.should raise_error(SystemExit)
    end
  end

  context "in an existing project" do
    before(:all) do
      Koi.init!
    end

    context "with no tasks" do
      it "shouldn't try to init" do
        -> {Koi.run(:init)}.should raise_error(SystemExit)
      end

      it "should warn about invalid commands" do
        -> {Koi.run(:choo)}.should raise_error(SystemExit)
      end

      it "should add tasks" do
        if Koi.run(:add, TASK)
          e = Koi::Database.new(Koi::Path[:db]).find(TASK)
          e.should be_a(Koi::Entity)
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
        Koi.init!
        TASKS.each do |t|
          Koi.run(:add, t)
        end
        @db = Koi::Database.new(Koi::Path[:db])
      end

      it "should remove tasks" do
        Koi.run(:remove, TASKS.last)
        @db.load.find(TASKS.last)[:status].should == :removed
      end

      it "should complete tasks" do
        Koi.run(:did, TASKS.first)
        @db.load.find(TASKS.first)[:status].should == :completed
      end

      it "should tag tasks" do
        Koi.run(:tag, TASKS[1], "food")
        @db.load.find(TASKS[1])[:tags].should include("food")
      end

      it "should rise tasks" do
        Koi.run(:rise, TASKS[2])
        @db.load[1][:title].should == TASKS[2]
      end

      it "should sink tasks" do
        Koi.run(:sink, TASKS[1])
        @db.load.last[:title].should == TASKS[1]
      end

      it "should sticky tasks" do
        Koi.run(:float, TASKS[2])
        @db.load.list[0][:title].should == TASKS[2]
        @db.load.find(TASKS[2])[:sticky].should be_true
      end

      it "should warn when the task wasn't found" do
        -> {Koi.run(:did, "celery")}.should raise_error(SystemExit)
      end
    end
  end

  after(:all) do
    FileUtils.rm_rf(Koi::Path[:root])
    FileUtils.rm_rf(File.join(ENV['HOME'], Koi::Path[:root]))
  end
end

