# Extensions are files with the .bzl extension
# You use load to import a suymbol from an extension


# This build file gives the convenient name 'tools' to a collection of targets,
# so that they can be referenced by other rules
# In this case, we include everything from /path/to/external/pip/bin/ and recursively include everything
# within the sites-packages directory (** is a recursive wildcard that matches zero or more complete path segments)
# It excludes two files that have names that cant be used as Bazel labels but that pip doesn't actually need
# And makes them available as targets to anyone

_PIP_BUILD_FILE = """
filegroup(
    name='tools',
    srcs=glob(
        include=['bin/*', 'site-packages/**/*'],
        exclude=[
            # Illegal as Bazel labels but are not required by pip.
            "site-packages/setuptools/command/launcher manifest.xml",
            "site-packages/setuptools/*.tmpl",
        ]
    ),
    visibility=['//visibility:public']
)
"""


# This build file gives the convenient name 'bin' to a collection of targets - so that they
# can be referenced by other rules, the srcs is a list of labels - glob is a helper function that can be used wherever a list of
# filenames is expected - takes one or two lists of filename patterns containing the * wildcard
# ** would be the recursive wildcard
# glob returns a sorted list of every file in the package that matches at least one pattern in include
# and does not match any of the patterns in exclude
# glob runs during BUILD file evaluation - matches only files in the source tree - never generated files
# visibility is an attribute common to all build rules - means that anyone can use this rule
# In this situation, this build file makes all the executables downloaded by pip (chardetect*, easy_install*,
# easy_install-3.6* pex*, pip*, pip3.6*, wheel*) and the BUILD file itself available as targets to anyone

_PIP_BIN_BUILD_FILE = """
filegroup(
    name='bin',
    srcs=glob(['*']),
    visibility=['//visibility:public']
)
"""

# TODO change downloads folder to requirements

_PEX_BUILD_FILE = """
filegroup(
    name='requirements',
    srcs=glob(['downloads/**/*', 'MANIFEST']),
    visibility=['//visibility:public']
)
"""


# Implementation functions have exactly one parameter, repository_ctx
# Implementation functions should always return None
# Repository_ctx can be used to access attribute values, and non hermetic functions (finding a binary,
# executing a binary, creating a file in the repository, or downloading a file)
def _pip_tools_impl(repository_ctx):
    # This is accessing the getpip file that got downloaded in pip_dependencies
    getpip = repository_ctx.path(repository_ctx.attr._getpip)  # returns a path from a string or label - resolved relative to the repository directory
    # In this case, the label is the _getpip label defined in _pip_tools
    bin_dir = repository_ctx.path('bin')  # this creates a directory called bin in the external/pip location
    packages = repository_ctx.path('site-packages')  # this creates a directory called site-packages in the external/pip location

    command = ['python3.6', str(getpip)]
    command += list(repository_ctx.attr.packages)
    command += ['--target', str(packages)]
    command += ['--install-option', '--install-scripts=%s' % bin_dir]
    command += ['--no-cache-dir']
    # This creates the command python3.6 path/to/getpip.py pex==1.2.8 setuptools=33.1.1 wheel=0.29.0 requests==2.18.1
    # --target /path/to/pip/site-packages --install option --install-scripts /path/to/external/pip/bin --no-cache-dir
    # TODO write out exactly what this command does!
    result = repository_ctx.execute(command)

    if result.return_code != 0:
        print('stderr:', result.stderr)
        print('try:', ' '.join(command))

    repository_ctx.file('%s/BUILD' % bin_dir, _PIP_BIN_BUILD_FILE, False)  # Create a BUILD file for file for PIP BIN in /path/to/external/pip/bin
    # withthe _PIP_BIN_BUILD FILE content, not executable
    repository_ctx.file('BUILD', _PIP_BUILD_FILE, False)  # Create a BUILD file for file for PIP  in /path/to/external/pip
    # withthe _PIP_BUILD FILE content, not executable


# Implementation functions have exactly one parameter, repository_ctx
# Should always return None
# Repository_ctx can be used to access attribute values, and non hermetic functions (finding a binary,
# executing a binary, creating a file in the repository, or downloading a file)
def _pex_reqs_impl(repository_ctx):
    # This is accessing the _pip (pip3) utility that got downloaded in pip_dependencies
    pip = repository_ctx.path(repository_ctx.attr._pip)
    downloads = repository_ctx.path('downloads')  # this creates a directory called downloads in the external/binaryORlibrary location

    # TODO download only binarys from pypi else, see my special link (speed)

    repository_ctx.execute(['mkdir', '-p', downloads])
    for package in repository_ctx.attr.packages:
        command = [str(pip), 'download']
        command += ['--only-binary', ':all:']
        command += [package]

        for link in repository_ctx.attr.extra_index:
            command += ['--extra-index-url', link]
            command += ['--trusted-host', link.split('//')[1].split('/')[0]]

        command += ['-v']
        command += ['--dest', str(downloads)]
        result = repository_ctx.execute(command)

        if result.return_code != 0:
            print('stderr:', result.stderr)
            print('try:', ' '.join(command))

    # FIXME this is just old stuff

    result = repository_ctx.execute(['ls', '%s' % downloads])
    filenames = result.stdout.strip().split('\n')
    renamed = [e.replace('manylinux1', 'linux') for e in filenames]

    for i in range(len(filenames)):
        old = '%s/%s' % (downloads, filenames[i])
        new = '%s/%s' % (downloads, renamed[i])
        repository_ctx.execute(['mv', old, new])

    # TODO this just turns everything into a wheel
    # for filename in renamed:
    for filename in filenames:
        filepath = '%s/%s' % (downloads, filename)
        repository_ctx.execute([str(pip), 'wheel', filepath, '-w', downloads])

    # TODO create the manifest and the build

    repository_ctx.file('%s/MANIFEST' % downloads, ' '.join(repository_ctx.attr.packages), False)
    repository_ctx.file('BUILD', _PEX_BUILD_FILE, False)

# The _pip_tools macro calls a repository rule (which is native to Bazel)
# Repository rules require an implementation fuction with the logic of the rule
# This executed strictly in the loading phase
# The attribute is a rule argument - you have to list the attributes and their types when you define a repository rule
# So in this case _pip_tools_impl takes 2 attributes, packages - which is a public list of strings
# and _getpip which is a private label. Label creates an attribute of type Target (which is the target referred to by the label)
# It is the only way to specify a dependency to another target
# Its private to prevent a user from overwriting it
_pip_tools = repository_rule(
    _pip_tools_impl,
    attrs={
        'packages': attr.string_list(),  # In this case, this the list of packages passed in _pip_tools (pex, setuptools, wheel, requests)
        '_getpip': attr.label(
            default=Label('@getpip//file:get-pip.py'),  # the default value of the attribute - use Label function to specify a default value - this case the getpip/file/get-pip.py target
            allow_single_file=True,  # This makes it possible for the target to be a file - the label has to correspond to a single file
            executable=True,    # The label has to be executable
            cfg='host'  # The configuration of the attribute - can either be data, host or target, required if executable true
            # host is to be run on local architecture (where the build is taking place), target is to be run on target architecture, and data is a legacy cfg and should be used for data attributes
        )
    }
)

# The pex_requirements macro calls a repository rule (which is native to Bazel)
# Repository rules require an implementation fuction with the logic of the rule
# This executed strictly in the loading phase
# The attribute is a rule argument - you have to list the attributes and their types when you define a repository rule
# So in this case _pex_reqs_impl takes 4 attributes, packages - which is a public list of strings
# and extra index which is a list of strings, _getpip and _pip which are a private labels.
# Labels create an attribute of type Target (which is the target referred to by the label)
# It is the only way to specify a dependency to another target
# Its private to prevent a user from overwriting it
_pex_reqs = repository_rule(
    _pex_reqs_impl,
    attrs={
        'packages': attr.string_list(default=[], allow_empty=True),  # In this case, this the list of packages passed in by _pex_requirements, 3rd party deps
        'extra_index': attr.string_list( # In this case, a link to where we host dependencies in whl files
            default=['https://deps.findmine.com/pypi/'],
            allow_empty=True
        ),
        '_getpip': attr.label(
            default=Label('@getpip//file:get-pip.py'),  # the default value of the attribute, use Label function to specify a default value, in this case getpip/file/get-pip.py target
            allow_single_file=True,  # This makes it possible for the target to be a file - the label has to correspond to a single file
            executable=True,    # The label has to be executable
            cfg='host'  # The configuration of the attribute - can either be data, host or target, required if executable true
            # host is to be run on local architecture (where the build is taking place), target is to be run on target architecture, and data is a legacy cfg and should be used for data attributes
        ),
        '_pip': attr.label(
            default=Label('@pip//bin:pip3'),  # default value of the attribute, use Label function to specify a default value, in this case pip/bin:pip3 target
            executable=True,  # executable
            cfg='host' # configuration of attr
        )
    }
)


# pip_dependencies is a macro that instantiates rules during the loading phase
# a macro must have a name attribute
def pip_dependencies():
    # Native is a built in module to support native rules and other helper functions
    # It's only available for macros in the loading phase
    # http_file is a workspace rule that downloads a file from a URL and makes it available to be used as a file group
    # Targes can specify @getpip//file as a dependency to depend on this file
    # The url to a the get-pip file and the sha256
    # External dependencies are all downloaded and symlinked under a directory named external
    # You can see this directory by running ls $(bazel info output_base)/external
    # This creates the target with then name getpip, which has file/get-pip.py in it
    # To purge external artifacts, you have to run bazel clean --expunge
    native.http_file(
            name="getpip",
            url="https://bootstrap.pypa.io/get-pip.py",
            sha256="19dae841a150c86e2a09d475b5eb0602861f2a5b7761ec268049a662dbd2bd0c"
    )

    # In a .bzl file, symbols starting with _ are private and cannot be loaded from another file
    # This private macro
    # Put a docstring here
    # Macros must have a name, should have the optional visibility, in this case public
    # This macro takes a parameter called packages
    _pip_tools(
        name="pip",
        visibility=['//visibility:public'],
        packages=[
            'pex==1.2.8',
            'setuptools==33.1.1',
            'wheel==0.29.0',
            'requests==2.18.1'
        ]
    )


# pex_requirements is a macro that instantiates rules during the loading phase
def pex_requirements(name, packages=None, extra_index=None):

    _pex_reqs(
        name=name,
        packages=packages,
        extra_index=extra_index,
        visibility=['//visibility:public']
    )
