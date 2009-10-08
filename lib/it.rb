
require 'yaml'
require 'mutter'
require 'fileutils'

module It

  Path = {root: ".it", db: ".it/database.yml"}

  def self.init dir = Dir.pwd
    unless init?
      FileUtils.mkdir File.join(dir, Path[:root])
      FileUtils.touch File.join(dir, Path[:db])
    end
  end

  def self.init? dir = root
    File.exist? File.join(dir, Path[:root])
  end

  def self.version
    File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).strip
  end

  def self.root
    path = Dir.pwd.split('/').reject {|d| d.empty?}
    (path.size + 1).times do
      if It.init? (sub = File.join('/', *path))
        return sub
      end
      path.pop
    end
    return nil
  end

  class Command
    Commands = [
      :init, :add, :list, :tag,
      :done, :did, :log, :status,
      :remove, :float, :sink,
      :ls, :rm
    ]
    Initializers = [:init, :add]
    Special = {"!" => :done, "?" => :list}

    def initialize cmd, param = nil, args = [], options
      @command = Special[cmd] || cmd.to_sym
      @args = [args].flatten
      @param = param =~ /^\d+$/ ? param.to_i : param
      @db = It.init?? Database.new(File.join(It.root, Path[:db])) : Database.new
      @mut = Mutter.new(blue: '#', underline: "''", cyan: '@@', green: '!!').clear(:default)
    end

    def run
      if Commands.include? @command
        if It.init? or Initializers.include? @command
          if send(@command, *[*@param, *@args].flatten)
            save
          else
            abort "error running #@command"
          end
        else
           abort "'it' is not initialized here, please run `it init`"
        end
      else
        abort "#{@command} is not a valid command."
      end
    end

    def init
      unless It.init
        err "'it' has already been initialized here"
      end; true
    end
    
    #
    # List current tasks
    #
    def list index = -1
      out
      
      @db.reject {|e| [:removed, :completed].include? e[:status]}.each do |e|
        out "#[#{index += 1}]# ''#{e[:title]}'' @@#{e[:tags].join(' ')}@@" unless e[:status] == :removed
      end.tap do |list|
        out "  !!nothing left to do!!" if list.size.zero?
      end

      out
      out "# recently completed"

      @db.select  {|e| e[:status] == :completed}.
          sort_by {|e| e[:completed_at]}[0..5].each do |e|
        out "- !!#{e[:title]}!!"
      end
    end
    alias :ls list

    #
    # Show completed tasks
    #
    def log
    
    end

    def out obj = ""
      if obj.is_a? Hash
        puts "#{obj[:title]} : #{obj[:status]}"
      else
        @mut.say obj.to_s
      end
    end

    def add entry, *tags
      It.init
      @db << Entity.new(title: entry, tags: tags)
    end

    def tag entry, tags
      @db.find(entry)[:tags] << tags
    end

    def did entry = 0
      if obj = @db.find(entry)
        obj[:status] = :completed
        obj[:completed_at] = Time.now
      else
        out "entry not found"
      end
    end
    alias :done did

    def save
      File.open(File.join(It.root, Path[:db]), 'w') {|f| f.write @db.to_yaml}
    end
    
    #
    # Mark task as :removed (doesn't show up anywhere)
    #
    def remove entry
      @db.find(entry)[:status] = :removed
    end
    alias :rm remove

    def err str
      $stderr.puts str
    end
  end

  class Database
    include Enumerable

    def initialize path = nil
      @data = path ? YAML.load_file(path) : []
    end

    def find key
      if key.is_a? String
        @data.find {|e| e[:title].include? key}
      elsif key.is_a? Fixnum
        @data.select {|e| e[:status] == :fresh}[key]
      else
        raise ArgumentError "key must be a String or Fixnum"
      end
    end
    alias :[] find

    def each &blk
      @data.each &blk
    end

    def << entry
      @data << entry
    end

    def to_yaml *args, &blk
      @data.to_yaml *args, &blk
    end
  end

  class Entity
    attr_accessor :data

    def initialize data = {}
      @data = {
        status: :fresh,
        created_at: Time.now,
        tags: []
      }.merge data
    end

    def to_yaml *args, &blk
      @data.to_yaml *args, &blk
    end

    def [] key
      @data[key]
    end

    def []= key, val
      @data[key] = val
    end
  end
end


