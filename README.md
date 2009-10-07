it
==

minimal task management for hackers.

    $ sudo gem install it -s http://gemcutter.org

_Note: this project is still under heavy development!_

Synopsis
--------

Start by creating a new project folder

    $ mkdir project/
    $ cd project/

`it` uses folders as projects, in the same way as `git`. We start by initializing our project, and adding two tasks.

    $ it init
    $ it add "refactor spaghetti code"
    $ it add "find a better name"

Let's see what we've got now with `list`:

    $ it list

    [0] refactor spaghetti code
    [1] find a better name

Tasks can be refered to by index (`1`, `2`) or by name. You don't have to type in the full name though:

    $ it tag spaghetti @R
    $ it done 1

I just went ahead and tagged my first task with `@R`, and completed my 2nd one. Here's the new list:

    $ it list

    [0] refactor spaghetti code @R
    
    # recently completed
    - find a better name

You can also specify tags when adding new tasks:

  $ it add "make pasta" @food @yum @kitchen

And remove tasks:

  $ it remove pasta

**it** creates an _.it_ folder in the directory you initialize your project in. Inside that folder is a _database.yml_ with all your tasks for that project.



