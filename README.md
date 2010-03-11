koi
===

minimal task management for hackers.

    $ sudo gem install koi

Synopsis
--------

Start by creating a new project folder

    $ mkdir project/
    $ cd project/

**koi** uses folders as projects, in the same way as **git**. We start by initializing our project, and adding two tasks.

    $ koi init
    $ koi add "refactor spaghetti code"
    $ koi add "find a better name"

Let's see what we've got now with `list`:

    $ koi list

     [0]   refactor spaghetti code
     [1]   find a better name

Tasks can be refered to by index `1`, `2` or by name. You don't have to type in the full name though:

    $ koi tag spaghetti #food
    $ koi did 1

I just went ahead and tagged my first task with `#food`, and completed my 2nd one. Let's check our status by just typing `koi`: 

    $ koi

     [0]   refactor spaghetti code #food

     [x]   find a better name

The `status` command, also the default command when you just type `koi`, shows your top 5 tasks, as well as
your recently completed tasks. As you can see, task `1` was completed, shown by an `x` instead of `1`.

You can also specify tags when adding new tasks:

    $ koi add "make pasta" #food #yum #kitchen

And remove tasks:

    $ koi remove pasta
    $ koi kill 2

As well as sticky tasks, with `+` or `float`:

    $ koi + pasta
    $ koi

     [0] + make pasta #food #yum #kitchen
     [1]   refactor spaghetti code
     [2]   find a better name

If you want to show all koi with a specific tag, you can use the `show` command:

    $ koi show #yum
     
     [0]   cucumbers #yum
     [1]   pancakes #yum

And if you want a log of all your activities, just try:

    $ koi log

Bumping tasks up or down
------------------------

To move koi up in the list, use `rise`:

    $ koi rise 3

To move koi down the list, use `sink`:

    $ koi sink burgers

Simple.

**koi** creates a _.koi_ folder in the directory you initialize your project in. Inside that folder is a _database.yml_ with all your tasks for that project.



