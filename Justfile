SYSTEM_PYTHON := 'python'
SYSTEM_POETRY := 'poetry'
SYSTEM_GIT    := 'git'

name           := ''
package        := name
python_version := '3.10'
changelog      := 'no'
git_project    := 'yes'
github_actions := 'no'

_group_name:= if package == name {
    name
} else {
    replace_regex(package, "(\\..*)$", "")
}
_package_path := if package == name {
    name
} else {
    replace(package, ".", "/")
}
_py_version := ( "py" + replace(python_version, ".", "") )
_dest := join(invocation_directory(), name)
_venv := join(justfile_directory(), ".venv")
_vpy := join(_venv, "bin", file_name(SYSTEM_PYTHON))
_tmpl := join(justfile_directory(), "templates")
_git_exists := `cd {{ invocation_directory() }} && [ ! git rev-parse --show-toplevel &>/dev/null ] && echo "yes" || echo "no"`
_git_root := if _git_exists == "yes" {
    `cd {{ invocation_directory() }} && git rev-parse --show-toplevel`
} else {
    _dest
}
_lambda_name := if package == name {
    "handler.py"
} else {
    snakecase(name) + ".py"
}

# Installs lambda-spinup project, i.e. it will create virtualenv with all dependencies
[unix]
install:
    #!/usr/bin/env sh -euo pipefail
    echo "Checking if all required dependencies are installed ..."
    if ! command -v {{ SYSTEM_PYTHON }} &>/dev/null; then
        echo "Python not installed in system. Install python or pyenv to your system first."
        echo "You can find guides how to install python: https://wiki.python.org/moin/BeginnersGuide/Download"
        echo "If you wish to install pyenv, please consult following guide: https://github.com/pyenv/pyenv#installation"
        exit 1
    fi
    if ! command -v poetry &>/dev/null; then
        echo "Poetry is not installed on your machine."
        echo "You can learn more in: https://python-poetry.org/docs/#installation"
        exit 1
    fi
    if ! command -v {{ SYSTEM_GIT }} &>/dev/null; then
        echo "Git is not installed on your machine."
        echo "In order to continue furthe, please install git: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git"
    fi
    echo "Checking if .venv is not already present ..."
    if ! command -v {{ _vpy }} &>/dev/null; then
        echo "Environement is properly installed ..."
        exit 0
    fi
    echo "Creating virtual environment ..."
    {{ SYSTEM_PYTHON }} -m venv {{ _venv }}
    echo "Installing dependencies to {{ _vpy }} ..."
    {{ _vpy }} -m pip install -U setuptools pip wheel jinja2

# Uninstalls lambad-spinput project, i.e. removes virtualenv
[unix]
uninstall:
    @echo "Removing virtual environment ..."
    @rm -rf {{ _venv }}
    @echo "Virtualenv removed sucessfully"


[private]
create-project:
    #!/usr/bin/env sh
    set -euo pipefail
    if [ "{{ name }}" == "" ]; then
        echo "Usage: lambda-spinup new name='lambda' [package='ingestionaas.pipelines.lambda']"
        exit 1
    fi
    echo "Crearing project '{{ name }}' in '{{ invocation_directory() }}'"
    cd {{ invocation_directory() }}
    poetry -n new {{ if name == package { name } else { name + " --name " + package } }}
    cd {{ name }}
    poetry add --group dev \
        pytest \
        pytest-mock \
        coverage \
        boto3 \
        'boto3-stubs[essential]' \
        moto \
        ruff \
        pylint \
        black \
        mypy
    echo "copying files ..."
    cp -f {{ join(_tmpl, "__init__.py") }} "{{ join("./", _package_path) }}"
    if [ "{{ changelog }}" == "yes" ]; then
        cp {{ join(_tmpl, "CHANGELOG.md") }} .
    fi
    echo "copying done"

    if [ "{{ git_project }}" == "yes" ]; then
        echo "Checking git project in current directory ..."
        echo "Is already in git project: {{ _git_exists }}"
        if [ "{{ _git_exists }}" == "no" ]; then
            echo "Initializing git repository ..."
            git init
            echo "Git project initialized"
        fi
    fi


[private]
render: create-project
    #!{{ _vpy }}
    import os.path as pth
    from jinja2 import (
        FileSystemLoader,
        Environment
    )
    PROJECT_PATH = "{{ _dest }}"
    GIT_ROOT = "{{ _git_root }}"
    RELATIVE_PROJECT_PATH = pth.relpath(PROJECT_PATH, GIT_ROOT)

    def read(rel):
        with open(filepath(rel), "r", encoding="utf-8") as fd:
            return fd.read().rstrip()

    def filepath(rel):
        return pth.join(PROJECT_PATH, rel)

    loader = FileSystemLoader("{{ _tmpl }}")
    env = Environment(loader=loader)

    vars = {
        "name": "{{ name }}",
        "package": "{{ package }}",
        "git_root": GIT_ROOT,
        "py_version": "{{ _py_version }}",
        "group_name": "{{ _group_name }}",
        "project_path": RELATIVE_PROJECT_PATH,
        "python_version": "{{ python_version }}",
        "pyproject_toml_content": read("pyproject.toml")
    }

    if "{{ github_actions }}" == "yes" and "{{ git_project }}" == "yes":
        with open(pth.join(GIT_ROOT, ".github/workflows/lambda_{{ snakecase(name) }}_build.yml"), "w", encoding="utf-8") as fd:
            fd.write(env.get_template("build_lambda.yml.jinja").render(**vars))

    with open(filepath("{{ _lambda_name }}"), "w", encoding="utf-8") as fd:
        fd.write(env.get_template("handler.py.jinja").render(**vars))

    template_files = [
        ".gitignore",
        "Justfile",
        "README.md",
        "pyproject.toml"
    ]

    for gen_file in template_files:
        with open(filepath(gen_file), "w", encoding="utf-8") as fd:
            fd.write(env.get_template(f"{gen_file}.jinja").render(**vars))

# Creates new AWS Lambda project in current directory, you have to provide at least name="lambda-name"
[unix]
new: render
    #!/usr/bin/env sh -euo pipefail
    echo "Finalizing project creation ..."
    cd {{ _dest }}
    echo 'Changing dependency python version in pyproject.toml to {{ python_version }}'
    sed -i 's/python = "[^"]+"/python = "{{ python_version }}"/' pyproject.toml
    echo 'Adding "{{ _lambda_name }}" to include in pyproject.toml'
    sed -i '/^packages = [{ include = "{{ _group_name }}"}]$/a include = ["{{ _lambda_name }}"]' pyproject.toml
    cd -
    echo "Lambda project created successfully in {{ _dest }}"
