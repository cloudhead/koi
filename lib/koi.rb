
require 'yaml'
require 'mutter'
require 'fileutils'

module Koi

  Path = {root: ".koi", db: ".koi/database.yml", paths: ".koi/paths"}

  def self.init dir = Dir.pwd
    unless init?
      FileUtils.mkdir File.join(dir, Path[:root])
      FileUtils.touch File.join(dir, Path[:db])
      FileUtils.mkdir File.join(ENV['HOME'], Path[:root]) rescue nil
      File.open(File.join(ENV['HOME'], Path[:paths]), 'a+') do |f|
        f.write File.expand_path(dir).to_s
      end
    end
  end

  def self.init! dir = Dir.pwd
    FileUtils.rm_rf File.join(dir, Path[:root])
    init dir
  end

  def self.init? dir = root
    File.exist? File.join(dir, Path[:db]) if dir
  end

  def self.run *args
    cmd = Command.new(*args)
    cmd[:silent] = true
    cmd.run
  end

  def self.version
    File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).strip
  end

  def self.root
    path = Dir.pwd.split('/').reject {|d| d.empty? }
    (path.size + 1).times do
      if Koi.init? (sub = File.join('/', *path))
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
      :ls, :rm, :rise
    ]
    Initializers = [:init, :add]
    Special = {"!" => :done, "?" => :status}

    def initialize *all
      cmd, param, args, options = all
      @command = Special[cmd] || cmd.to_sym
      @args = [args || []].flatten
      @param = param =~ /^\d+$/ ? param.to_i : param
      @options = options || {}
      @db = Koi.init?? Database.new(File.join(Koi.root, Path[:db])) : Database.new
      @mut = Mutter.new(blue: '#', underline: "''", red: '++', cyan: '@@', green: '!!', yellow: '^').clear(:default)
    end

    def run
      if Commands.include? @command
        if Koi.init? or Initializers.include? @command
          if !@param or @command == :add or @param = @db.find(@param)
            @param ||= @db.last if [:float, :sink, :rm, :tag, :done].include? @command
            if send(@command, *[@param, *@args].compact.flatten)
              save
            else
              err "error running #@command"
            end
          else
            err "task wasn't found"
          end
        else
           err "'koi' is not initialized here, please run `koi init`"
        end
      else
        err "#{@command} is not a valid command."
      end
    end

    def []= key, val
      @options[key] = val
    end

    def [] key
      @options[key]
    end

    def init
      unless Koi.init
        err "'koi' has already been initialized here"
      else
        true
      end
    end

    def status
      out "in the water (#{@db.select {|e| e.new? }.size})"

      self.list 5

      out "recently fished (#{@db.select {|e| e.completed? }.size})"

      @db.select  {|e| e[:status] == :completed }.
          sort_by {|e| e[:completed_at] }[0..3].reverse.each do |e|
        out "- !!#{e[:title]}!!"
      end

      out
      true
    end

    #
    # List current tasks
    #
    def list count = 10, index = -1
      out

      @db.list[0..count].each do |e|
        out "#[#{index += 1}]##{e.sticky?? "++ + ++" : "   "}''#{e[:title]}'' @@#{e[:tags].join(' ')}@@" unless e[:status] == :removed
      end.tap do |list|
        out "  !!nothing left to do!!" if list.size.zero?
      end

      out
      true
    end
    alias :ls list

    def swim entry, n
      v = @db.index(entry) + @db.size / 3 * n
      @db.delete entry
      @db.insert([[v, 0].max, @db.size].min, entry)
    end

    def rise entry
      swim entry, -1
    end

    def sink entry
      swim entry, 1
    end

    def float entry
      entry[:sticky] = ! entry[:sticky]
      true
    end

    #
    # Show task history
    #
    def log
      @db.map do |entity|
        Entity::Status.map do |status|
          { title:  entity[:title],
            action: status,
            time:   entity[:"#{status}_at"]
          } if entity[:"#{status}_at"]
        end.compact
      end.flatten.sort_by {|e| e[:time]}.reverse.each do |entry|
        out "##{entry[:time]}# ^#{entry[:action]}^ ''#{entry[:title]}''"
      end
    end

    def out obj = ""
      if obj.is_a? Hash
        puts "#{obj[:title]} : #{obj[:status]}"
      else
        @mut.say obj.to_s
      end unless @options[:silent]
    end

    def err str
      @options[:silent] ? abort : abort(str)
    end

    def add entry, *args
      Koi.init
      target = args.find {|a| a.start_with? '@' }[1..-1] rescue nil
      tags = args.select {|a| a.start_with? '#' }
      @db << Entity.new(title: entry, tags: tags, target: target)
    end

    def tag entry, tags
      entry[:tags] << tags
    end

    def did entry = 0
      entry.status = :completed
      entry[:completed_by] = ENV['USER']
    end
    alias :done did
    alias :fish did

    def save
      File.open(File.join(Koi.root, Path[:db]), 'w') {|f| f.write @db.to_yaml }
    end

    #
    # Mark task as :removed (doesn't show up anywhere)
    #
    def remove entry
      entry.status = :removed
    end
    alias :rm remove
    alias :kill remove
  end

  class Database
    include Enumerable

    def initialize path = nil
      if @path = path
        self.load path
      else
        @data = []
      end
    end

    def find key
      if key.is_a? String
        @data.find {|e| e[:title].include? key }
      elsif key.is_a? Fixnum
        @data.select {|e| e[:status] == :created}[key]
      else
        raise ArgumentError, "key must be a String or Fixnum, but is #{key.class}"
      end
    end
    alias :[] find

    def fresh
      @data.select {|e| e.new? }
    end

    def list
      fresh.select(&:sticky?) + fresh.reject(&:sticky?)
    end

    #
    # Hash-like methods on @data
    #
    def size;  fresh.size  end
    def first; fresh.first end
    def last;  fresh.last  end
    def delete(arg)   @data.delete  arg  end
    def insert(*args) @data.insert *args end
    def index(*args, &blk) @data.index *args, &blk end

    def load path = @path || Path[:db]
      @data = if db = YAML.load_file(path)
        db.map {|e| Entity.new(e) }
      else
        []
      end
      self
    end

    def each &blk
      @data.each &blk
    end

    def << entry
      @data << (entry.is_a?(Entity) ? entry : Entity.new(entry))
    end

    def to_yaml *args, &blk
      @data.to_yaml *args, &blk
    end
  end

  class Entity < Hash
    Status = [:created, :completed, :removed]

    def initialize data = {}
      self.replace status:     :created,
                   created_at: Time.now,
                   owner:      ENV['USER'],
                   tags:       [],
                   sticky:     false
      merge!(data)
    end

    def new?
      self[:status] == :created
    end

    def sticky?
      self[:sticky]
    end

    def status= st
      self[:status] = st
      self[:"#{st}_at"] = Time.now
    end

    #
    # Handle things like `self.removed?`
    #
    def method_missing meth, *args, &blk
      if meth.to_s.end_with?('?') && Status.include?(s = meth.to_s.chop.to_sym)
        self[:status] == s
      else
        super
      end
    end
  end
end


