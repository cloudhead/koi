koi
===

minimal task management for hackers.

    $ sudo gem install koi -s http://gemcutter.org

_Note: this project is still under heavy development!_

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

    [0] refactor spaghetti code
    [1] find a better name

Tasks can be refered to by index `1`, `2` or by name. You don't have to type in the full name though:

    $ koi tag spaghetti @R
    $ koi done 1

I just went ahead and tagged my first task with `@R`, and completed my 2nd one. Here's the new list:

    $ koi list

    [0] refactor spaghetti code @R
    
    # recently completed
    - find a better name

You can also specify tags when adding new tasks:

    $ koi add "make pasta" @food @yum @kitchen

And remove tasks:

    $ koi remove pasta

**koi** creates an _.koi_ folder in the directory you initialize your project in. Inside that folder is a _database.yml_ with all your tasks for that project.



