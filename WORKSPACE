workspace(name='pygotham')

# Load is a statement that imports definitions from a .bzl file
# This will execute tools/build_rules/tools_rules.bzl and import the symbols
# pip_dependencies, and pex_requirements into the local environment
load(
    '//tools/build_rules:tools_rules.bzl',
    'pip_dependencies',
    'pex_requirements'
)

# This macro downloads pip, pex, setuptools, wheel and requests and makes them publicly visible
pip_dependencies()

# This macro takes name, packages, extra_index
pex_requirements('analyze_personality', packages=[
    'matplotlib==2.0.0',
    'requests==2.9.1',
    'pandas==0.20.3',


])
pex_requirements('get_tweets', packages=[
    'python-twitter'
])
