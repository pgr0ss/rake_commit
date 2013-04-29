# rake_commit

[![Gem Version](https://badge.fury.io/rb/rake_commit.png)](http://badge.fury.io/rb/rake_commit)
[![Build Status](https://travis-ci.org/pgr0ss/rake_commit.png?branch=master)](https://travis-ci.org/pgr0ss/rake_commit)

This gem automates a pretty standard workflow when committing code to git, svn, and git-svn.  Run rake_commit in  your current project, which does the following, depending on source control:

### git

```
  1. Checks in current changes into a temp commit just in case
  2. Resets soft back to origin/branch (in order to collapse changes into one commit)
  3. Adds new files to git and removes deleted files
  4. Prompts for a commit message
  5. Commits to git
  6. Pulls changes from origin (and does a rebase to keep a linear history)
  7. Runs the default rake task (which should run the tests)
  8. Pushes the commit to origin
```

### git-svn

```
  1. Adds new files to git and removes deleted files
  2. Prompts for a commit message
  3. Commits to local git
  4. Pulls changes from SVN
  5. Runs the default rake task (which should run the tests)
  6. Pushes the commit to SVN
```

### subversion

```
  1. Prompts for a commit message
  2. Adds new files to subversion
  3. Deletes missing files from subversion
  4. svn update
  5. Runs the default rake task (which should run the tests)
  6. Checks in the code
```


The first version started with the code posted at Jay Field's Blog: http://blog.jayfields.com/2006/12/ruby-rake-commit.html.
Improvements have been added in from several more projects.

## Installation

```bash
gem install rake_commit
```

## Usage

```bash
cd /path/to/project
rake_commit
```

### Command line arguments

```bash
--help
```

Print help information.

```bash
--incremental
```

This will prompt as normal and then commit without running tests or pushing. This is useful for make incremental commits while working.

```bash
--no-collapse
```

This tells rake_commit not to prompt and make a new commit. This is useful when you've done a merge by hand and want to preserve the commit. It will stil run rake and then push if rake succeeds.

```bash
--without-prompt <prompt>
```

This will cause rake_commit to skip the named prompt. For example, if you are working by yourself and do not need to prompt for a pair, you can use `--without-prompt pair`.

## License

rake_commit is released under the [MIT license](http://www.opensource.org/licenses/MIT).
