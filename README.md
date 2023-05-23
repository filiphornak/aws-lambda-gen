# aws-lambda-gen

**AWS Lambda python project generator**

Automates creation of AWS Lambda python project. This script produces poetry project with preconfigured tools
like pytest, coverage, linters, Justfile, and many more.

## Installation

To install this script check that you have all the necessary non-python dependencies, i.e. `python`, `git` and `poetry` installed on your machine. Clone the repository from github.

```bash
git clone https://github.com/filiphornak/aws-lambda-gen.git
```

And create python virtual environment with all the mandatory dependencies.
To simplfy this process you can use `install` recipe.

```bash
cd aws-lambda-gen && just install
```

Create an alias in your `.*rc`, or `.*profile` file, e.g., `~/.zprofile`.

```bash
alias gen-lambda='just --justfile /path/to/aws-lambda-gen --working-directory .'
```

### Troubleshooting

If for some reason you can not use some the default executables addressed in the Justfiles, e.g. because they are not installed on the system `$PATH` or because their name differs from the default one (looking at you fedora users). Just modify the first variables `SYSTEM_PYTHON`, `SYSTEM_GIT`, `SYSTEM_POETRY`.

```Justfile
SYSTEM_PYTHON := "python3.11"
SYSTEM_POETRY := "~/.virtualenvs/poetry-env/bin/poetry"
SYSTEM_GIT    := "/opt/bin/git"
```

> **PROTIP**: Although not required you can also install `rg` and `find-fd` command line tools alongside.

## Usage

To generate lambda project head to directory where you wish to place your freshly created lambda

```bash
cd ~/Develop/my-lambdas
```

And create it by running `new` recipe. This recipe require you to set the `name` variable.

```bash
gen-lambda name=my-aws-lambda new
```

You can also specify custom package name by using `package` variable if you want different name of your package
or even use namespace package.

```bash
gen-lambda name=my-aws-lambda package=my.aws.lambda new
```

The script contains many more configuration options, here is brief description of each of them:

- `python=X.Y`: Change python version used by lambda function. Default: `3.9`
- `changelog=yes|no`: If the script shoud generate `CHANGELOG.md` file in the project. Default: `no`
- `git_project=yes|no`: If the script should use/initialize git. If you create it inside different git project, script will try to reuse that projects `.git` database. Default: `no`.
- `github_actions=yes|no`: If the script should produce github actions file. Default: `no`.
